import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/network/token_provider.dart';
import 'package:secretary_app/main.dart';
import 'package:secretary_app/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_secure_storage talks to a platform channel that does not exist in
  // a test binding, so a real read never completes — which is what made this
  // file hang for ten minutes instead of failing. Answer the channel with an
  // empty store: no tokens saved means "signed out", which is the state these
  // tests want anyway.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => switch (call.method) {
            'readAll' => <String, String>{},
            'read' => null,
            _ => null,
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  testWidgets('AuthGate shows the login screen when there is no session', (
    tester,
  ) async {
    // TokenNotifier starts in isLoading, and main() clears that by awaiting
    // loadTokens before runApp. Do the same here so the gate can decide.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(tokenProvider.notifier).loadTokens();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SecretaryApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('AuthGate shows a spinner while tokens are still loading', (
    tester,
  ) async {
    // No loadTokens call: TokenState.isLoading is true from construction.
    await tester.pumpWidget(const ProviderScope(child: SecretaryApp()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
