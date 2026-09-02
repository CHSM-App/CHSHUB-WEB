import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/auth_event_provider.dart';
import 'core/network/token_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';

/// Kept for the ScaffoldMessenger, so background work can surface a snackbar
/// without a BuildContext. The interceptor still does *not* navigate — it
/// raises `authEventProvider` and AuthGate below does the routing, which keeps
/// the network layer out of the widget tree.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// AuthGate is `home:`, so it sits at the *bottom* of the route stack.
/// Anything pushed over it — Profile, a bill detail, an edit form — stays on
/// top when the gate rebuilds, which is why clearing the tokens on its own did
/// not visibly sign anyone out: the login screen was rendered underneath the
/// screen the user was still looking at. This key is what lets the gate pop
/// those routes off when the session ends.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm the container *before* runApp and then hand that same container to the
  // tree. Reading tokens into a throwaway ProviderContainer and letting
  // ProviderScope build its own would discard the work.
  final container = ProviderContainer();
  await container.read(tokenProvider.notifier).loadTokens();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SecretaryApp(),
    ),
  );
}

class SecretaryApp extends ConsumerWidget {
  const SecretaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Secretary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        // Dismiss the keyboard on a tap outside any field — these screens are
        // form-heavy and the keyboard otherwise covers the save button.
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}

/// Decides between the login screen and the app, and reacts to a session that
/// expires while the app is open.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  Widget build(BuildContext context) {
    // TokenInterceptor sets this when a refresh fails. Clearing the tokens is
    // what actually switches the tree below; the snackbar explains why.
    ref.listen<AuthEvent?>(authEventProvider, (_, next) {
      if (next == AuthEvent.sessionExpired) {
        rootScaffoldMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please sign in again.'),
              backgroundColor: AppTheme.error,
            ),
          );
        ref.read(authEventProvider.notifier).state = null;
      }
    });

    // The one place a sign-out is turned into navigation, so it behaves the
    // same however the session ended — the Sign out button, or a refresh that
    // failed mid-request while the user was several screens deep.
    //
    // Watching the transition rather than `authEventProvider` is deliberate:
    // an explicit sign-out raises no event, and cleared tokens are the single
    // fact both paths share.
    ref.listen<bool>(tokenProvider.select((t) => t.isLoggedIn), (was, now) {
      if (was == true && now == false) _returnToLogin();
    });

    final token = ref.watch(tokenProvider);

    // main() has already awaited loadTokens, so this only shows if something
    // else puts the notifier back into a loading state.
    if (token.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return token.isLoggedIn ? const HomeShell() : const LoginScreen();
  }

  /// Tears down everything stacked over the gate so the login screen is what
  /// the user is actually looking at.
  ///
  /// `popUntil(isFirst)` rather than `pushAndRemoveUntil(LoginScreen)`: the
  /// gate is already the first route and already rebuilds to the login screen
  /// on cleared tokens, so pushing another one would leave a second, orphaned
  /// LoginScreen above a gate that no longer governs it — and signing back in
  /// would swap the tree underneath without that copy ever going away.
  ///
  /// Dialogs and bottom sheets are routes too, so the sign-out confirmation
  /// and any open sheet come off in the same pass.
  void _returnToLogin() {
    // Fired from a listener during a build; navigating now would mutate the
    // tree mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = rootNavigatorKey.currentState;
      if (navigator == null || !navigator.mounted) return;
      navigator.popUntil((route) => route.isFirst);
    });
  }
}
