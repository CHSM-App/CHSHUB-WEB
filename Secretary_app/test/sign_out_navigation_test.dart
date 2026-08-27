import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/network/auth_event_provider.dart';
import 'package:secretary_app/core/network/token_provider.dart';
import 'package:secretary_app/main.dart';
import 'package:secretary_app/screens/auth/login_screen.dart';

import 'fakes.dart';

/// AuthGate sits at the bottom of the route stack as MaterialApp's `home`, so
/// clearing the tokens rebuilds it *underneath* whatever the user pushed on
/// top. Before the fix that meant signing out from Profile — itself a pushed
/// route — left the user looking at Profile with the login screen rendered
/// invisibly below it.
///
/// These tests drive the real AuthGate rather than a stand-in, because the
/// bug lived in the interaction between the gate and the navigator rather
/// than in either one alone.
void main() {
  // TokenNotifier writes through to flutter_secure_storage, a platform channel
  // with no implementation under `flutter test`. Unmocked, saveTokens awaits a
  // reply that never comes and every test here hangs to its timeout rather
  // than failing — so this stand-in is what makes them run at all.
  TestWidgetsFlutterBinding.ensureInitialized();

  final stored = <String, String>{};

  setUp(() {
    stored.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            switch (call.method) {
              case 'write':
                stored[call.arguments['key'] as String] =
                    call.arguments['value'] as String;
                return null;
              case 'read':
                return stored[call.arguments['key'] as String];
              case 'readAll':
                return Map<String, String>.from(stored);
              case 'delete':
                stored.remove(call.arguments['key'] as String);
                return null;
              case 'deleteAll':
                stored.clear();
                return null;
              default:
                return null;
            }
          },
        );
  });

  /// A signed-in app with a stand-in for HomeShell.
  ///
  /// The real HomeShell fetches on mount for four tabs, which is a lot of
  /// unrelated surface for a navigation test; what matters here is only that
  /// something logged-in renders and that routes can be pushed over it.
  Future<ProviderContainer> pumpSignedIn(WidgetTester tester) async {
    // A phone-sized surface. The default 800x600 test window is narrower than
    // the login screen's own layout wants, and the resulting overflow is
    // reported as a test failure — which would say nothing about the
    // navigation these tests are actually about.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: fakeOverrides());
    addTearDown(container.dispose);

    await container
        .read(tokenProvider.notifier)
        .saveTokens('access-token', 'refresh-token');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: const AuthGate(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  /// Stands in for Profile — a screen reached by pushing over the gate.
  Future<void> pushDetailScreen(WidgetTester tester) async {
    rootNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('Profile'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
  }

  testWidgets('signing out from a pushed screen lands on the login screen', (
    tester,
  ) async {
    final container = await pumpSignedIn(tester);
    await pushDetailScreen(tester);

    // What AuthViewModel.logout() ultimately does.
    await container.read(tokenProvider.notifier).clearTokens();
    await tester.pumpAndSettle();

    expect(
      find.text('Profile'),
      findsNothing,
      reason: 'the pushed screen must come off the stack, not stay on top of '
          'a login screen the user cannot see',
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('an expired session unwinds the stack too', (tester) async {
    final container = await pumpSignedIn(tester);
    await pushDetailScreen(tester);

    // The interceptor's path: clear the tokens, then raise the event that
    // tells the user why.
    await container.read(tokenProvider.notifier).clearTokens();
    container.read(authEventProvider.notifier).state = AuthEvent.sessionExpired;
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('Your session has expired. Please sign in again.'),
      findsOneWidget,
    );
  });

  testWidgets('an open dialog is torn down with the rest of the stack', (
    tester,
  ) async {
    final container = await pumpSignedIn(tester);
    await pushDetailScreen(tester);

    // The sign-out confirmation is itself a route, so it must not survive the
    // sign-out it triggered.
    unawaited(
      showDialog<void>(
        context: rootNavigatorKey.currentContext!,
        builder: (_) => const AlertDialog(content: Text('Sign out?')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await container.read(tokenProvider.notifier).clearTokens();
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsNothing);
    expect(find.text('Profile'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('signing back in does not leave an orphaned login screen', (
    tester,
  ) async {
    final container = await pumpSignedIn(tester);
    await pushDetailScreen(tester);

    await container.read(tokenProvider.notifier).clearTokens();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // The gate rebuilds rather than pushing, so there is exactly one login
    // screen to replace — a pushed one would still be on the stack here.
    await container
        .read(tokenProvider.notifier)
        .saveTokens('access-token-2', 'refresh-token-2');
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
  });
}

/// `showDialog` returns a future that completes when the route is popped;
/// awaiting it here would deadlock the test.
void unawaited(Future<void> future) {}
