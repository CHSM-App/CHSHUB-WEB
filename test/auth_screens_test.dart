import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/screens/auth/auth_shell.dart';
import 'package:secretary_app/screens/auth/forgot_password_screen.dart';
import 'package:secretary_app/screens/auth/login_screen.dart';

import 'fakes.dart';

/// Sign in and Reset password share AuthShell, which changes shape at the
/// tablet breakpoint. These pump both screens at a phone, a tablet and a
/// desktop width and assert nothing overflows — the failure mode a fixed
/// 460pt column hid, and the one a two-panel layout can reintroduce.
void main() {
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
              default:
                return null;
            }
          },
        );
  });

  /// Logical sizes, one per branch in Breakpoints.
  const sizes = <String, Size>{
    'phone': Size(390, 844),
    'tablet': Size(834, 1112),
    'desktop': Size(1440, 900),
  };

  Future<void> pumpAt(WidgetTester tester, Size size, Widget screen) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeOverrides(),
        child: MaterialApp(home: screen),
      ),
    );
    // The login screen stages its entrance over 1.5s; settle past it so the
    // final laid-out frame is the one under test.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  for (final entry in sizes.entries) {
    testWidgets('the login screen lays out on a ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value, const LoginScreen());

      expect(tester.takeException(), isNull);
      expect(find.text('SECRETARY'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('the reset screen lays out on a ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value, const ForgotPasswordScreen());

      expect(tester.takeException(), isNull);
      // Shares the shell, so the brand is present here too — this is the
      // regression the plain-AppBar version had.
      expect(find.text('SECRETARY'), findsOneWidget);
      expect(find.text('Reset it here'), findsOneWidget);
      expect(find.byType(AuthShell), findsOneWidget);
    });
  }

  testWidgets('the brand panel only appears once there is width for it', (
    tester,
  ) async {
    await pumpAt(tester, sizes['phone']!, const LoginScreen());
    expect(
      find.text('Billing and receipts'),
      findsNothing,
      reason: 'a phone has no room for the pitch beside the form',
    );

    await pumpAt(tester, sizes['desktop']!, const LoginScreen());
    expect(find.text('Billing and receipts'), findsOneWidget);
  });

  testWidgets('the reset screen keeps its task free of the pitch', (
    tester,
  ) async {
    await pumpAt(tester, sizes['desktop']!, const ForgotPasswordScreen());

    // showTagline: false — someone mid-reset is not being sold the app.
    expect(find.text('Billing and receipts'), findsNothing);
  });

  testWidgets('the strength meter appears only once a password is typed', (
    tester,
  ) async {
    await pumpAt(tester, sizes['phone']!, const ForgotPasswordScreen());

    expect(find.text('Weak'), findsNothing);
    expect(find.text('Strong'), findsNothing);

    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Str0ng!Passw0rd',
    );
    await tester.pump();

    expect(find.text('Strong'), findsOneWidget);
  });
}
