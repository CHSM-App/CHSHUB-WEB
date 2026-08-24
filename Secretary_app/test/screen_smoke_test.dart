import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/screens/accounts/accounts_screen.dart';
import 'package:secretary_app/screens/auth/login_screen.dart';
import 'package:secretary_app/screens/billing/billing_screen.dart';
import 'package:secretary_app/screens/billing/defaulters_screen.dart';
import 'package:secretary_app/screens/billing/generate_bills_screen.dart';
import 'package:secretary_app/screens/community/community_screen.dart';
import 'package:secretary_app/screens/create_dialog.dart';
import 'package:secretary_app/screens/dashboard/dashboard_screen.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/home_shell.dart';

import 'fakes.dart';

/// Renders the real screens against fake repositories, at a phone width and a
/// desktop one.
///
/// The widget smoke test covers the shared pieces in isolation; this catches
/// the layout faults that only appear once a screen composes them — which is
/// how the overflow that broke the dashboard reached the browser.
Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(400, 900),

  /// Appended after the defaults, so a later override of the same provider
  /// replaces the fake for this test only.
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...fakeOverrides(), ...overrides],
      child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
    ),
  );

  // Screens kick their fetches off in a microtask; settle so the loaded state
  // renders rather than only the skeletons.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_secure_storage talks to a platform channel that does not exist in
  // a test binding, so a real read or write never completes. The screens
  // cache the session there after signing in, so without this the tests hang
  // rather than fail.
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

  const phone = Size(400, 900);
  const tablet = Size(820, 1180);
  const desktop = Size(1440, 960);

  group('LoginScreen', () {
    // pumpAndSettle rather than the shared _pump's fixed pumps: the wordmark
    // and card are staged behind timers, so the card is not on screen yet at
    // 350ms.
    for (final entry in {'phone': phone, 'desktop': desktop}.entries) {
      testWidgets('renders on a ${entry.key}', (tester) async {
        await _pump(tester, const LoginScreen(), size: entry.value);
        await tester.pumpAndSettle();

        expect(find.text('SECRETARY'), findsOneWidget);
        expect(find.text('Sign in to continue'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
      });
    }
  });

  group('DashboardScreen', () {
    for (final entry in {
      'phone': phone,
      'tablet': tablet,
      'desktop': desktop,
    }.entries) {
      testWidgets('renders on a ${entry.key}', (tester) async {
        await _pump(tester, const DashboardScreen(), size: entry.value);
        expect(find.text('Residents'), findsOneWidget);
      });
    }

    testWidgets('greets the signed-in user and names their society', (
      tester,
    ) async {
      await _pump(tester, const DashboardScreen());

      // Comes from /auth/me, which wraps the user in `{ user: {...} }` — a
      // shape the app parsed wrongly at first, leaving the bar on defaults.
      expect(find.text('Hello, Test Secretary (Secretary)'), findsOneWidget);
      expect(find.text('Gokuldham'), findsOneWidget);
    });
  });

  group('hub screens', () {
    testWidgets('billing renders on a phone', (tester) async {
      await _pump(tester, const BillingScreen());
      expect(find.text('Generate bills'), findsOneWidget);
    });

    testWidgets('billing renders as a grid on a desktop', (tester) async {
      await _pump(tester, const BillingScreen(), size: desktop);
      expect(find.text('Defaulters'), findsOneWidget);
    });

    testWidgets('accounts renders', (tester) async {
      await _pump(tester, const AccountsScreen());
      expect(find.text('Society expenses'), findsOneWidget);
    });

    testWidgets('community renders', (tester) async {
      await _pump(tester, const CommunityScreen());
      expect(find.text('Helpdesk'), findsOneWidget);
    });
  });

  group('GenerateBillsScreen', () {
    for (final entry in {'phone': phone, 'desktop': desktop}.entries) {
      testWidgets('shows the preview on a ${entry.key}', (tester) async {
        await _pump(tester, const GenerateBillsScreen(), size: entry.value);

        // The three figures the website's page leads with.
        expect(find.text('26 flats'), findsOneWidget);
        expect(find.text('Regular'), findsOneWidget);
        expect(find.text('Add-on'), findsOneWidget);

        // Charge heads, with their per-flat share.
        expect(find.text('gardening'), findsOneWidget);
        expect(find.text('sinking'), findsOneWidget);

        // The server's own warning, shown verbatim. Matched on the full
        // string: the run panel below says "already exists" too, in its own
        // words, so a substring match finds both.
        expect(
          find.text(
            'A bill run already exists for the current month; gen_bill will '
            'skip regular billing.',
          ),
          findsOneWidget,
        );
      });
    }

    // Whether the society bills itself changes what pressing the button
    // means, so the screen says which case it is.
    testWidgets('says bills are manual-only when auto billing is off', (
      tester,
    ) async {
      await _pump(tester, const GenerateBillsScreen());

      expect(find.text('Off · manual only'), findsOneWidget);
      expect(
        find.textContaining('only raised when someone runs them here'),
        findsOneWidget,
      );
    });

    testWidgets('says the nightly run would raise them when auto is on', (
      tester,
    ) async {
      await _pump(
        tester,
        const GenerateBillsScreen(),
        overrides: [
          billingRepositoryProvider.overrideWithValue(
            FakeBillingRepository(autoBillGeneration: true),
          ),
        ],
      );

      expect(find.text('On · day 2'), findsOneWidget);
      expect(find.textContaining('would be raised on day 2'), findsOneWidget);
    });

    testWidgets('offers the regular run when nothing blocks it', (
      tester,
    ) async {
      await _pump(
        tester,
        const GenerateBillsScreen(),
        overrides: [
          billingRepositoryProvider.overrideWithValue(
            FakeBillingRepository(alreadyGeneratedThisMonth: false),
          ),
        ],
      );

      expect(find.text('Generate regular bills'), findsOneWidget);
    });

    testWidgets('says so instead when this month is already generated', (
      tester,
    ) async {
      // The fake's default, matching the live society: a run exists for the
      // current month, so gen_bill would skip it.
      await _pump(tester, const GenerateBillsScreen());

      expect(find.text('Generate regular bills'), findsNothing);
      expect(
        find.text('This month’s regular bills have already been generated.'),
        findsOneWidget,
      );

      // Add-on charges are not covered by the monthly guard, so they stay
      // runnable.
      expect(find.textContaining('Raise add-on charges'), findsOneWidget);
    });

    testWidgets('hides the regular run when the society bills itself', (
      tester,
    ) async {
      await _pump(
        tester,
        const GenerateBillsScreen(),
        overrides: [
          billingRepositoryProvider.overrideWithValue(
            FakeBillingRepository(
              autoBillGeneration: true,
              alreadyGeneratedThisMonth: false,
            ),
          ),
        ],
      );

      // The nightly gen_bill already raises these; a second trigger would
      // invite raising bills that were coming anyway.
      expect(find.text('Generate regular bills'), findsNothing);

      // Add-on stays, because the automatic run never calls
      // sp_new_maintenance — hiding it would strand pending charges.
      expect(find.textContaining('Raise add-on charges'), findsOneWidget);
    });

    testWidgets('add-on asks for a bill period and previews the due date', (
      tester,
    ) async {
      // A tall viewport so the run panel — which sits below the charge tables
      // and the settings card — is on screen without scrolling. The scroll
      // itself is not what this test is about.
      await _pump(
        tester,
        const GenerateBillsScreen(),
        size: const Size(400, 2400),
      );

      await tester.tap(find.textContaining('Raise add-on charges'));
      await tester.pumpAndSettle();

      expect(find.text('Raise add-on charges'), findsWidgets);
      expect(find.text('Bill period (months)'), findsOneWidget);
      // The due date is worked out as the number is typed, as the legacy form
      // did — so the effect is visible before the run happens.
      expect(find.textContaining('Due date:'), findsOneWidget);

      // The charge heads being raised, with their per-flat share. The head is
      // named twice — once in the page's table, once in the sheet — so this
      // asserts on the sheet's own per-flat column instead.
      expect(find.text('Nature of charges'), findsOneWidget);
      expect(find.textContaining('/ flat'), findsWidgets);
    });
  });

  group('DefaultersScreen', () {
    testWidgets('renders its summary and rows', (tester) async {
      await _pump(tester, const DefaultersScreen());
      expect(find.text('TOTAL OUTSTANDING'), findsOneWidget);
      expect(find.text('Aniket'), findsOneWidget);
    });

    testWidgets('renders on a desktop', (tester) async {
      await _pump(tester, const DefaultersScreen(), size: desktop);
      expect(find.text('Aniket'), findsOneWidget);
    });
  });

  group('HomeShell', () {
    testWidgets('shows the notched bottom bar on a phone', (tester) async {
      await _pump(tester, const HomeShell());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Community'), findsWidgets);
      // The FAB opens the create menu — the receipt shortcut lives in the
      // dashboard's quick actions instead.
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('the create button opens a dialog of community actions', (
      tester,
    ) async {
      await _pump(tester, const HomeShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CreateDialog), findsOneWidget);
      expect(find.text('Notice'), findsOneWidget);
      expect(find.text('Meeting'), findsOneWidget);
      expect(find.text('Poll'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
    });

    testWidgets('shows a navigation rail on a desktop', (tester) async {
      await _pump(tester, const HomeShell(), size: desktop);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });
}
