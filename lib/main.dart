import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/auth_event_provider.dart';
import 'core/network/token_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';

/// Kept for the ScaffoldMessenger, so background work can surface a snackbar
/// without a BuildContext. Navigation deliberately does *not* go through a
/// global key — the interceptor raises `authEventProvider` and the root widget
/// below routes, which keeps the network layer out of the widget tree.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

    final token = ref.watch(tokenProvider);

    // main() has already awaited loadTokens, so this only shows if something
    // else puts the notifier back into a loading state.
    if (token.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return token.isLoggedIn ? const HomeShell() : const LoginScreen();
  }
}
