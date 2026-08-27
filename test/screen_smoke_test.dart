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
import 'package:secretary_app/screens/community/announcements_screen.dart';
import 'package:secretary_app/screens/community/community_screen.dart';
import 'package:secretary_app/screens/community/noc_certificate_screen.dart';
import 'package:secretary_app/screens/community/polls_screen.dart';
import 'package:secretary_app/screens/community/visitors_screen.dart';
import 'package:secretary_app/screens/create_dialog.dart';
import 'package:secretary_app/screens/dashboard/dashboard_screen.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/home_shell.dart';
import 'package:secretary_app/widgets/app_widgets.dart';

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

  /// The gate log itself — its summary, its tabs and its cards.
  group('VisitorsScreen list', () {
    /*
     * Tapped through the tab's own InkWell: "Inside" and "Expected" also label
     * the status chips on the cards below, so the bare text matches several
     * widgets.
     */
    Future<void> tapTab(WidgetTester tester, String label) async {
      await tester.tap(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('leads with who is inside and who is still due', (
      tester,
    ) async {
      await _pump(tester, const VisitorsScreen());

      // One line, not a panel of figures: the tabs below carry the breakdown,
      // so this says only how the log stands as a whole.
      expect(find.text('1 inside now · 4 in the log'), findsOneWidget);

      // Opens on Inside, so the visitor still in the society leads — not the
      // delivery that came and went.
      expect(find.text('Ramesh Pawar'), findsOneWidget);
      expect(find.text('Swiggy Delivery'), findsNothing);
    });

    testWidgets('each tab shows its own slice of the log', (tester) async {
      await _pump(tester, const VisitorsScreen());

      await tapTab(tester, 'Expected');
      expect(find.text('Anita Deshmukh'), findsOneWidget);
      expect(find.text('Ramesh Pawar'), findsNothing);

      await tapTab(tester, 'All');
      // Every entry, whatever state it is in.
      expect(find.text('Ramesh Pawar'), findsOneWidget);
      expect(find.text('Swiggy Delivery'), findsOneWidget);
      expect(find.text('Anita Deshmukh'), findsOneWidget);
    });

    testWidgets('offers Check out only to a visitor who is still inside', (
      tester,
    ) async {
      await _pump(tester, const VisitorsScreen());

      // Inside: the one visitor here can be stamped out.
      expect(find.text('Check out'), findsOneWidget);

      // Expected: nobody has arrived, so there is nothing to stamp out.
      await tapTab(tester, 'Expected');
      expect(find.text('Check out'), findsNothing);
    });

    testWidgets('a checked-out visitor moves to Left, with its exit stamp', (
      tester,
    ) async {
      await _pump(tester, const VisitorsScreen());

      /*
       * Left has its own tab because checking someone out drops them off the
       * Inside tab the screen opens on — without somewhere to land, the entry
       * read as deleted and the exit time that had just been written was
       * nowhere on screen.
       */
      await tapTab(tester, 'Left');
      expect(find.text('Swiggy Delivery'), findsOneWidget);
      expect(find.textContaining('Out 10:40AM'), findsOneWidget);

      // And it is not among those still inside.
      await tapTab(tester, 'Inside');
      expect(find.text('Swiggy Delivery'), findsNothing);
    });

    testWidgets('every entry lands in exactly one tab', (tester) async {
      await _pump(tester, const VisitorsScreen());

      /*
       * Two traps the real data sets. in_time is written by the insert for
       * every visitor, so counting it as an arrival left Expected permanently
       * empty; and some rows carry an exit with no arrival, which put the same
       * visitor under both Expected and Left and made the counts overshoot.
       */
      /*
       * Read by the badge's own key rather than by walking up to an enclosing
       * widget: "Inside" also names a status chip on the cards below, and
       * picking the last Text under a shared ancestor found "Check out" as
       * soon as the pill laid its label and count out in a row.
       */
      int countOn(String tab) {
        final badge = find.byKey(tabCountKey(tab));
        expect(badge, findsOneWidget);
        return int.parse((tester.widget<Text>(badge)).data!);
      }

      // One inside, one expected, two left — and they add up to All.
      expect(countOn('Inside'), 1);
      expect(countOn('Expected'), 1);
      expect(countOn('Left'), 2);
      expect(countOn('All'), 4);
      expect(
        countOn('Inside') + countOn('Expected') + countOn('Left'),
        countOn('All'),
      );
    });

    testWidgets('a visitor stamped out but never in counts as Left', (
      tester,
    ) async {
      await _pump(tester, const VisitorsScreen());

      await tapTab(tester, 'Left');
      expect(find.text('Prakash Jadhav'), findsOneWidget);

      // Not still waiting to arrive: the exit stamp settles it.
      await tapTab(tester, 'Expected');
      expect(find.text('Prakash Jadhav'), findsNothing);
    });

    testWidgets('shows when the visitor came in', (tester) async {
      await _pump(tester, const VisitorsScreen());

      /*
       * The `visitor` view hands dates back already formatted — in_date as
       * "25 Aug 2026" via CONVERT(..., 106), which DateTime.tryParse rejects.
       * Every card read "In —" until asDate learned that shape.
       */
      expect(find.textContaining('In 25 Aug'), findsOneWidget);
      expect(find.text('In —'), findsNothing);
    });

    testWidgets('asks before stamping a visitor out', (tester) async {
      await _pump(tester, const VisitorsScreen());

      await tester.tap(find.text('Check out'));
      await tester.pumpAndSettle();

      // The exit time is written from the clock and cannot be undone from the
      // list, so the tap alone must not commit it.
      expect(
        find.widgetWithText(AlertDialog, 'Check out visitor'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  /// Narrowing the gate log by date and by visitor type.
  ///
  /// The filters live in a sheet behind one button rather than as chips down
  /// the page: two rows of chips cost every screen of the list two lines to
  /// say "all time, all types", which is how the log is nearly always read.
  group('VisitorsScreen filters', () {
    /// Opens the filter menu beside the search box.
    ///
    /// The icon is the outlined one while nothing is filtered and the filled
    /// one once something is, exactly as the NOC screen's menu behaves.
    Future<void> openFilters(WidgetTester tester) async {
      final button = find.byIcon(Icons.filter_alt_outlined).evaluate().isEmpty
          ? find.byIcon(Icons.filter_alt)
          : find.byIcon(Icons.filter_alt_outlined);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('the filter button opens a menu of date presets', (
      tester,
    ) async {
      await _pump(tester, const VisitorsScreen());
      await openFilters(tester);

      // Every preset, so today's log is a tap away from the whole one.
      for (final preset in ['All time', 'Today', '7 days', '30 days']) {
        expect(find.text(preset), findsOneWidget);
      }
      // Custom is not a preset but an entry that opens the calendar.
      expect(find.text('Between dates…'), findsOneWidget);
    });

    testWidgets('a date window narrows the log and the summary says so', (
      tester,
    ) async {
      await _pump(tester, const VisitorsScreen());

      // Unfiltered, the line speaks for the whole log.
      expect(find.text('1 inside now · 4 in the log'), findsOneWidget);

      await openFilters(tester);
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      /*
       * The fake log is stamped 25–26 Aug 2026, so "Today" matches none of it
       * unless the suite is run on one of those days. What matters here is
       * that the line switches to saying how much is being hidden — which the
       * tabs, counting only what survives the window, cannot say themselves.
       */
      expect(find.textContaining('of 4 shown · Today'), findsOneWidget);
      expect(find.text('1 inside now · 4 in the log'), findsNothing);
    });

    testWidgets('Clear puts the whole log back', (tester) async {
      await _pump(tester, const VisitorsScreen());

      await openFilters(tester);
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.textContaining('of 4 shown · Today'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('1 inside now · 4 in the log'), findsOneWidget);
    });

    testWidgets('every tab keeps its full label on a phone', (tester) async {
      await _pump(tester, const VisitorsScreen());

      /*
       * Splitting a phone's width four ways left no room for an icon, a label
       * and a two-digit count together, so a real society's log rendered
       * "Insi… 26" and "Exp… 11" — the two tabs read most were the two that
       * lost their names. The bar scrolls instead, sizing each pill to its
       * own contents.
       *
       * Checked by laying the text out at the size it was given: a Text with
       * ellipsis truncates during paint, so the widget still carries the whole
       * string and finding it by text would pass either way.
       */
      for (final label in ['Inside', 'Expected', 'Left', 'All']) {
        final badge = find.byKey(tabCountKey(label));
        expect(badge, findsOneWidget, reason: '$label tab is missing');

        // Scoped to the pill: "Inside", "Expected" and "Left" also label the
        // status chips on the cards below, so a bare find.text matches several.
        final labelInPill = find.descendant(
          of: find.ancestor(of: badge, matching: find.byType(Row)).first,
          matching: find.text(label),
        );
        expect(labelInPill, findsOneWidget);

        final text = tester.widget<Text>(labelInPill);
        final painter = TextPainter(
          text: TextSpan(text: text.data, style: text.style),
          textDirection: TextDirection.ltr,
        )..layout();

        expect(
          tester.getSize(labelInPill).width,
          greaterThanOrEqualTo(painter.width - 0.5),
          reason: '$label is truncated: the pill is too narrow for its label',
        );
      }
    });

    testWidgets('Between dates opens the calendar rather than filtering', (
      tester,
    ) async {
      await _pump(tester, const VisitorsScreen());
      await openFilters(tester);

      await tester.tap(find.text('Between dates…'));
      await tester.pumpAndSettle();

      // The app's own compact picker, not Flutter's full-screen range dialog.
      expect(find.text('Apply'), findsOneWidget);
    });
  });

  /// The add-visitor form's unit picker.
  ///
  /// A society runs to dozens of flats across several buildings, so the flat is
  /// chosen in two steps: the building first, then only that building's flats.
  group('VisitorsScreen add-visitor form', () {
    /// Opens the sheet behind the "Add visitor" button.
    Future<void> openForm(WidgetTester tester) async {
      await _pump(tester, const VisitorsScreen());
      await tester.tap(find.text('Add visitor'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens as a page of its own, not a bottom sheet', (
      tester,
    ) async {
      await openForm(tester);

      /*
       * A page, so the whole form is reachable: as a sheet it showed about a
       * third at a time, and with the keyboard up the building and flat
       * pickers — where the visitor's unit is chosen — were off screen.
       */
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.widgetWithText(AppBar, 'Add visitor'), findsOneWidget);

      // And it can be backed out of, which a sheet got from its drag handle.
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('shows the arrival date and time, defaulted to now', (
      tester,
    ) async {
      await openForm(tester);

      /*
       * Both were written silently from DateTime.now() with nothing on the
       * form — so a secretary writing up yesterday's entry had no way to say
       * so, and the log recorded the visitor arriving when the form was filled
       * in rather than when they came.
       */
      expect(find.text('In date'), findsOneWidget);
      expect(find.text('In time'), findsOneWidget);

      // Defaulted to today, which is the common case at the gate.
      final now = DateTime.now();
      expect(find.text(prettyDate(now)), findsOneWidget);
    });

    /// Taps one of the two picker fields at the bottom of the form.
    ///
    /// Dragged into place rather than relying on ensureVisible alone: the
    /// field sits in a page taller than the test viewport, and a tap that
    /// lands outside it only warns — which would leave the assertions below
    /// passing against a dialog that never opened.
    Future<void> openPicker(WidgetTester tester, String label) async {
      // The form's own list, not the gate log's behind the route.
      await tester.dragUntilVisible(
        find.text(label),
        find.descendant(of: find.byType(Form), matching: find.byType(ListView)),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      /*
       * The InkWell wrapping the field, not the label text: the label is
       * painted by an InputDecorator that does not hit-test where the text
       * sits, so tapping it lands on the decoration behind and only warns.
       */
      await tester.tap(
        find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first,
        warnIfMissed: true,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens the app calendar and clock, not Material defaults', (
      tester,
    ) async {
      await openForm(tester);

      /*
       * Both fields used to open Flutter's full-screen pickers, which look
       * nothing like the six other screens that pick a date through
       * showSingleDateDialog. A form asking for a date and a time should not
       * open two different-looking things.
       */
      // The form is taller than the test viewport, so the two fields sit
      // below the fold — without scrolling, the tap lands on nothing and
      // Flutter only warns.
      await tester.ensureVisible(find.text('In date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('In date'));
      await tester.pumpAndSettle();
      expect(find.text('Arrived on'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      // Material's own dialog would carry OK, and no header of ours.
      expect(find.byType(CalendarDatePicker), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await openPicker(tester, 'In time');
      expect(find.text('Arrived at'), findsOneWidget);
      // Two lists, and the half-of-day toggle.
      expect(find.text('Hour'), findsOneWidget);
      expect(find.text('Minute'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('the clock offers every minute, not just the fives', (
      tester,
    ) async {
      await openForm(tester);

      await openPicker(tester, 'In time');

      /*
       * The clock face this replaced could only hold twelve hours and a few
       * minutes at a tappable size, so 3:02 needed a separate stepper. A list
       * holds all sixty — 02 is picked directly.
       */
      final minutes = find.byType(ListView).last;
      await tester.scrollUntilVisible(
        find.descendant(of: minutes, matching: find.text('02')),
        -80,
        scrollable: find.descendant(
          of: minutes,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.descendant(of: minutes, matching: find.text('02')));
      await tester.pumpAndSettle();

      // The header echoes the choice, so the value is confirmed before Apply.
      expect(find.textContaining(':02'), findsOneWidget);
    });

    /// Switches the visitor type through the dropdown's own callback.
    ///
    /// Not by tapping: the field sits in a page taller than the test viewport,
    /// so the menu it opens is off screen.
    Future<void> chooseType(WidgetTester tester, String type) async {
      tester
          .widget<AppDropdown<String>>(
            find.byWidgetPredicate(
              (w) => w is AppDropdown<String> && w.label == 'Type',
            ),
          )
          .onChanged!(type);
      await tester.pumpAndSettle();
    }

    testWidgets('shows the inputs each visitor type calls for', (tester) async {
      await openForm(tester);

      // Guest: somewhere to note the address and why they came.
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Purpose of visit'), findsOneWidget);
      expect(find.text('Vehicle number'), findsNothing);

      // Cab: the firm, the plate, and where the trip runs.
      await chooseType(tester, 'Cab');
      expect(find.text('Cab company'), findsOneWidget);
      expect(find.text('Vehicle number'), findsOneWidget);
      expect(find.text('Pickup / drop location'), findsOneWidget);
      expect(find.text('Address'), findsNothing);

      // Delivery and Service share the shape but not the wording — the same
      // labels the website's visitors page uses.
      await chooseType(tester, 'Delivery');
      expect(find.text('Delivery company'), findsOneWidget);
      expect(find.text('Package description'), findsOneWidget);

      await chooseType(tester, 'Service');
      expect(find.text('Service company'), findsOneWidget);
      expect(find.text('Nature of work'), findsOneWidget);
    });

    testWidgets('drops what a type no longer asks for', (tester) async {
      await openForm(tester);

      await chooseType(tester, 'Cab');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cab company'),
        'Ola',
      );
      expect(find.text('Ola'), findsOneWidget);

      /*
       * Guest has no company box. The controller outlives the swap, so without
       * clearing it the visitor would be saved with a company written from a
       * field no longer on screen — invisible and unclearable.
       */
      await chooseType(tester, 'Guest');
      expect(find.text('Ola'), findsNothing);

      await chooseType(tester, 'Cab');
      expect(find.text('Ola'), findsNothing);
    });

    /// The building picker, found by its label.
    AppDropdown<String> buildingField(WidgetTester tester) =>
        tester.widget<AppDropdown<String>>(
          find.byWidgetPredicate(
            (w) => w is AppDropdown<String> && w.label == 'Building',
          ),
        );

    /// Chooses a building through the field's own callback.
    ///
    /// Not by tapping: the field is inside a bottom sheet taller than the test
    /// viewport, so the tap lands outside it and Flutter only warns.
    Future<void> chooseBuilding(WidgetTester tester, String name) async {
      buildingField(tester).onChanged!(name);
      await tester.pumpAndSettle();
    }

    testWidgets('offers each building once, not one entry per flat', (
      tester,
    ) async {
      await openForm(tester);

      // The fake holds four flats across two buildings — three of them in
      // Ganesh Bhavan, spread over two wings. Grouping by the building, rather
      // than by the `build_wing` text, is what keeps it to one entry each.
      expect(buildingField(tester).options.map((o) => o.label).toList(), [
        'Ganesh Bhavan',
        'Shiv Kunj',
      ]);
    });

    /// The flat picker's current choices, read off the widget.
    ///
    /// Asserted here rather than by opening the menu: the form is a bottom
    /// sheet taller than the test viewport, so the flat field sits below the
    /// fold and a tap on it silently misses — which a warning, not a failure,
    /// would have let through as a passing test.
    List<String> flatOptions(WidgetTester tester) => tester
        .widget<AppDropdown<int>>(
          find.byWidgetPredicate(
            (w) => w is AppDropdown<int> && w.label == 'Visiting flat',
          ),
        )
        .options
        .map((o) => o.label)
        .toList();

    testWidgets('offers no flats until a building is chosen', (tester) async {
      await openForm(tester);
      expect(flatOptions(tester), isEmpty);
    });

    testWidgets('lists only the chosen building\'s flats, in number order', (
      tester,
    ) async {
      await openForm(tester);
      await chooseBuilding(tester, 'Ganesh Bhavan');

      // Counted from the building, so the label confirms the filter ran.
      expect(find.text('3 flat(s) in this building'), findsOneWidget);

      // Wing first, then 9 before 10 — the number compared as a number, so the
      // picker reads in the order someone looking for a flat expects. Sorting
      // as text would put 10 first, and Grid_Show returns them newest-first.
      //
      // Each label names its wing: A and B each run a flat 9, so the number
      // alone would offer the same choice twice.
      //
      // Shiv Kunj's flat 2 is absent, which is the filter doing its job.
      expect(flatOptions(tester), ['A · 9', 'A · 10', 'B · 9']);
    });

    testWidgets('switching building drops the flat chosen under the old one', (
      tester,
    ) async {
      await openForm(tester);
      await chooseBuilding(tester, 'Ganesh Bhavan');

      final flatField = tester.widget<AppDropdown<int>>(
        find.byWidgetPredicate(
          (w) => w is AppDropdown<int> && w.label == 'Visiting flat',
        ),
      );
      flatField.onChanged!(flatField.options.first.value);
      await tester.pumpAndSettle();

      await chooseBuilding(tester, 'Shiv Kunj');

      // Left set, the form would save a Ganesh Bhavan flat against a visitor
      // the sheet says is going to Shiv Kunj.
      expect(
        tester
            .widget<AppDropdown<int>>(
              find.byWidgetPredicate(
                (w) => w is AppDropdown<int> && w.label == 'Visiting flat',
              ),
            )
            .value,
        isNull,
      );
      expect(flatOptions(tester), ['A · 2']);
    });
  });

  group('AnnouncementsScreen', () {
    /// Opens the date filter and picks one of its options.
    ///
    /// Matched inside the overlay with `.last`: "Upcoming" and "Past" can also
    /// appear on the screen behind the menu, so the bare text finds more than
    /// one widget once it is open.
    Future<void> pickFilter(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip('Filter by date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    /// Switches to one of the three kind tabs.
    ///
    /// Scoped to the segmented control: the plural also labels the empty
    /// states and the summary line, so bare text matches more than the tab.
    Future<void> pickTab(WidgetTester tester, String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedTabBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens on notices, showing the ones still current', (
      tester,
    ) async {
      await _pump(tester, const AnnouncementsScreen());

      // Two of the three are current: the dated one that has not ended, and
      // the standing one with no end date at all.
      expect(find.text('Water tank cleaning'), findsOneWidget);
      expect(find.text('Society office hours'), findsOneWidget);

      // Ended last week, so it is not on the default view.
      expect(find.text('Diwali lighting'), findsNothing);
    });

    testWidgets('each tab carries its own count', (tester) async {
      await _pump(tester, const AnnouncementsScreen());

      // The counts describe the whole list behind each tab, not the slice the
      // date filter is showing — that is what makes them worth reading before
      // opening the tab.
      expect(find.widgetWithText(SegmentedTabBar, 'Notices'), findsOneWidget);
      expect(find.widgetWithText(SegmentedTabBar, 'Meetings'), findsOneWidget);
      expect(find.widgetWithText(SegmentedTabBar, 'Events'), findsOneWidget);

      // Each badge counts the whole list behind its tab, not the slice the
      // date filter is showing.
      expect(find.widgetWithText(SegmentedTabBar, '3'), findsOneWidget);
      expect(find.widgetWithText(SegmentedTabBar, '2'), findsNWidgets(2));
    });

    testWidgets('the date filter shows its own slice of the list', (
      tester,
    ) async {
      await _pump(tester, const AnnouncementsScreen());

      await pickFilter(tester, 'Past');
      expect(find.text('Diwali lighting'), findsOneWidget);
      expect(find.text('Water tank cleaning'), findsNothing);

      await pickFilter(tester, 'All');
      expect(find.text('Water tank cleaning'), findsOneWidget);
      expect(find.text('Diwali lighting'), findsOneWidget);
      expect(find.text('Society office hours'), findsOneWidget);
    });

    testWidgets('switching tabs shows that kind and its add button', (
      tester,
    ) async {
      await _pump(tester, const AnnouncementsScreen());

      await pickTab(tester, 'Meetings');
      expect(find.text('Monthly committee meeting'), findsOneWidget);
      expect(
        find.widgetWithText(FloatingActionButton, 'New meeting'),
        findsOneWidget,
      );

      await pickTab(tester, 'Events');
      expect(find.text('Ganesh Utsav'), findsOneWidget);
      expect(
        find.widgetWithText(FloatingActionButton, 'New event'),
        findsOneWidget,
      );
    });

    testWidgets('every row offers Edit, which opens the form filled in', (
      tester,
    ) async {
      await _pump(tester, const AnnouncementsScreen());

      // Spelled out on the card rather than left to a tap on the row.
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      // The same form page as New notice, in edit mode and carrying the
      // notice's own values.
      expect(find.text('Edit notice'), findsWidgets);
      expect(find.text('Save changes'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Water tank cleaning'),
        findsOneWidget,
      );
    });

    testWidgets('the new-notice form opens empty, ready to publish', (
      tester,
    ) async {
      await _pump(tester, const AnnouncementsScreen());

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New notice'));
      await tester.pumpAndSettle();

      expect(find.text('Publish notice'), findsOneWidget);
      expect(find.text('Save changes'), findsNothing);
      // Nothing prefilled from a row.
      expect(
        find.widgetWithText(TextFormField, 'Water tank cleaning'),
        findsNothing,
      );
    });

    testWidgets('a meeting cannot be called without a date', (tester) async {
      await _pump(
        tester,
        const AnnouncementsScreen(initialKind: AnnouncementKind.meeting),
      );

      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'New meeting'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subject'),
        'Lift replacement',
      );
      await tester.tap(find.text('Call meeting'));
      await tester.pumpAndSettle();

      // The date is a picker, which no validator covers — the form says so
      // itself rather than letting the route reject the save.
      expect(find.text('Pick the meeting date.'), findsOneWidget);
    });

    testWidgets('says who a chosen recipient group reaches', (tester) async {
      await _pump(tester, const AnnouncementsScreen());

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New notice'));
      await tester.pumpAndSettle();

      // Before a group is picked, the note speaks generally.
      expect(
        find.text('Residents in the chosen group get a push notification.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Recipients'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Members').last);
      await tester.pumpAndSettle();

      // Once picked, it names the audience the server will actually push to.
      expect(find.text('Committee members only.'), findsOneWidget);
    });

    /// Fills in the form and publishes, against a repository whose POST
    /// answers with [notified].
    Future<void> publish(
      WidgetTester tester, {
      required Map<String, dynamic> notified,
    }) async {
      final repo = FakeCommunityRepository()
        ..createNoticeReply = {'notice_id': 9, 'notified': notified};

      await _pump(
        tester,
        const AnnouncementsScreen(),
        overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      );

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New notice'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Lift maintenance',
      );
      await tester.tap(find.text('Publish notice'));
      await tester.pumpAndSettle();
    }

    testWidgets('publishing reports how many residents were notified', (
      tester,
    ) async {
      await publish(
        tester,
        notified: {'sent': 12, 'failed': 0, 'recipients': 12, 'pushable': 12},
      );

      expect(
        find.text('Notice published. 12 residents notified.'),
        findsOneWidget,
      );
    });

    testWidgets('says the notice is waiting in-app when no push could be sent', (
      tester,
    ) async {
      // Saved and filed for eight people, but none of them has opened the app,
      // so there was no token to push to. That is not a failure — it must just
      // not be reported as a delivery.
      await publish(
        tester,
        notified: {'sent': 0, 'failed': 0, 'recipients': 8, 'pushable': 0},
      );

      expect(
        find.text(
          'Notice published to 8 residents — they will see it in the app.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says so when the chosen group has nobody in it', (
      tester,
    ) async {
      await publish(
        tester,
        notified: {'sent': 0, 'failed': 0, 'recipients': 0, 'pushable': 0},
      );

      expect(
        find.text('Notice published. No one in that group yet.'),
        findsOneWidget,
      );
    });
  });

  group('PollsScreen', () {
    testWidgets('lists the polls with their votes and whether they are open', (
      tester,
    ) async {
      await _pump(tester, const PollsScreen());

      expect(find.text('Paint the building this year?'), findsOneWidget);
      expect(find.text('Gym equipment for the clubhouse'), findsOneWidget);

      // One still taking votes, one whose closing date has passed.
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('14 votes'), findsOneWidget);
    });

    testWidgets('offers Delete but not Edit', (tester) async {
      await _pump(tester, const PollsScreen());

      // sp_polls has no update branch, and a question changed after people
      // had voted would leave those votes answering something else.
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('the form opens with two options and can add more', (
      tester,
    ) async {
      await _pump(tester, const PollsScreen());

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New poll'));
      await tester.pumpAndSettle();

      // Two is the minimum the route accepts, so the form starts there.
      expect(find.widgetWithText(TextFormField, 'Option 1'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Option 2'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Option 3'), findsNothing);

      await tester.tap(find.text('Add option'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Option 3'), findsOneWidget);
    });
    testWidgets('a poll cannot be started without a closing date', (
      tester,
    ) async {
      // Opened at desktop height so the whole form is on screen: the submit
      // button sits under four fields and two switches, and a ListView does
      // not build what it has not scrolled to.
      await _pump(tester, const PollsScreen(), size: desktop);

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New poll'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Topic'),
        'Repaint the lobby?',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Option 1'),
        'Yes',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Option 2'),
        'No',
      );

      // The submit button sits under four fields, the option rows and two
      // switches — past the bottom of even the desktop viewport, and a
      // ListView does not build what it has not scrolled to.
      await tester.dragUntilVisible(
        find.text('Start poll'),
        find.descendant(of: find.byType(Form), matching: find.byType(ListView)),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start poll'));
      await tester.pumpAndSettle();

      // The date is a picker, which no validator covers.
      expect(find.text('Pick the date voting closes.'), findsOneWidget);
    });

    testWidgets('rejects an option containing a comma', (tester) async {
      await _pump(tester, const PollsScreen(), size: desktop);

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New poll'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Topic'),
        'Repaint the lobby?',
      );
      // sp_PollOptions splits the joined string on commas, so one inside an
      // option would silently become two options.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Option 1'),
        'Yes, definitely',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Option 2'),
        'No',
      );

      // The submit button sits under four fields, the option rows and two
      // switches — past the bottom of even the desktop viewport, and a
      // ListView does not build what it has not scrolled to.
      await tester.dragUntilVisible(
        find.text('Start poll'),
        find.descendant(of: find.byType(Form), matching: find.byType(ListView)),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start poll'));
      await tester.pumpAndSettle();

      expect(find.text('No commas, please'), findsOneWidget);
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
      expect(find.text('Event'), findsOneWidget);

      expect(find.text('Poll'), findsOneWidget);
    });

    testWidgets('a create tile opens that add form, over its own list', (
      tester,
    ) async {
      await _pump(tester, const HomeShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meeting'));
      await tester.pumpAndSettle();

      // The form itself, not the list it saves into.
      expect(find.text('Call a meeting'), findsWidgets);

      // And the list is underneath, on the matching tab — so saving or going
      // back lands on the meetings rather than on the dashboard.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AnnouncementsScreen), findsOneWidget);
      expect(
        find.widgetWithText(FloatingActionButton, 'New meeting'),
        findsOneWidget,
      );
    });

    testWidgets('the poll tile opens its form over the polls list', (
      tester,
    ) async {
      await _pump(tester, const HomeShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Poll'));
      await tester.pumpAndSettle();

      // The app bar's title rather than the submit button, which sits below
      // the fold on a phone once the option fields are in.
      expect(find.text('New poll'), findsWidgets);

      // A poll has its own screen rather than an Announcements tab: it asks a
      // question and collects answers, where the other three announce a date.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PollsScreen), findsOneWidget);
      expect(
        find.widgetWithText(FloatingActionButton, 'New poll'),
        findsOneWidget,
      );
    });

    testWidgets('shows a navigation rail on a desktop', (tester) async {
      await _pump(tester, const HomeShell(), size: desktop);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('NocCertificateScreen', () {
    testWidgets('lists the certificates with their type and validity', (
      tester,
    ) async {
      await _pump(tester, const NocCertificateScreen());

      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Meera Joshi'), findsOneWidget);

      // One still valid, one whose end date has passed. Matched on the row
      // chips, since the summary bar above carries the same two words.
      expect(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.text('Valid'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.text('Expired'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the summary counts issued, valid and expired', (
      tester,
    ) async {
      await _pump(tester, const NocCertificateScreen());

      // Two issued, of which one has lapsed.
      expect(find.text('Issued'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // valid and expired
    });

    testWidgets('an Other certificate is listed by its own title', (
      tester,
    ) async {
      await _pump(tester, const NocCertificateScreen());

      // Not the word "Other" — the society named this one itself. Matched on
      // the row's own line, since the filter chips carry the type names too.
      expect(find.text('Pet ownership NOC · Flat B-402'), findsOneWidget);
      expect(find.text('Sale / transfer · Flat A-1203'), findsOneWidget);
    });

    testWidgets('opening a certificate shows the letter and its actions', (
      tester,
    ) async {
      await _pump(tester, const NocCertificateScreen());

      await tester.tap(find.text('Rahul Sharma'));
      await tester.pumpAndSettle();

      expect(find.text('NO OBJECTION CERTIFICATE'), findsOneWidget);
      expect(find.text('NOC/2026/00001'), findsOneWidget);
      // The clause it was issued with, not one derived from the type.
      expect(find.textContaining('no claim, charge or lien'), findsOneWidget);

      // The three document actions, as icons on the right of the title bar.
      // No Close: the app bar's back arrow is the way off this page.
      expect(find.byIcon(Icons.print_outlined), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.text('Close'), findsNothing);
    });

    testWidgets('issuing opens the certificate, and back returns to the list', (
      tester,
    ) async {
      // A tall viewport so the whole form fits: the button sits under a live
      // preview that grows as the fields fill, and scrolling to it mid-typing
      // races the relayout.
      await _pump(
        tester,
        const NocCertificateScreen(),
        size: const Size(500, 2400),
      );

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New NOC'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Member name'),
        'Shiv Kumar',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Flat number'),
        '302',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Issue certificate'));

      // Mid-save, before the certificate route is pushed: the form is still
      // on top, so the list never flashes past on the way to the letter.
      await tester.pump();
      expect(find.text('NOC certificates'), findsNothing);

      await tester.pumpAndSettle();

      // Straight to the letter — the form is gone, not merely covered.
      expect(find.text('NO OBJECTION CERTIFICATE'), findsOneWidget);
      expect(find.text('Issue certificate'), findsNothing);
      expect(find.text('New NOC certificate'), findsNothing);

      // The freshly issued certificate can be acted on right here, without
      // going back to the list to find it again.
      expect(find.byIcon(Icons.print_outlined), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);

      // And it carries the number the server allocated, not a placeholder.
      expect(find.text('NOC/2026/00007'), findsOneWidget);

      // And back from there is the list, not the form again.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('NOC certificates'), findsOneWidget);
    });

    testWidgets('search narrows by member, flat or certificate number', (
      tester,
    ) async {
      await _pump(tester, const NocCertificateScreen());

      final box = find.widgetWithText(
        TextField,
        'Search member, flat or no.',
      );

      await tester.enterText(box, 'Meera');
      await tester.pumpAndSettle();
      expect(find.text('Meera Joshi'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsNothing);

      // By flat, not only by name.
      await tester.enterText(box, 'A-1203');
      await tester.pumpAndSettle();
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Meera Joshi'), findsNothing);

      // A search matching nothing says so, and offers the way back.
      await tester.enterText(box, 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches'), findsOneWidget);

      await tester.tap(find.text('Show all'));
      await tester.pumpAndSettle();
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Meera Joshi'), findsOneWidget);
    });

    testWidgets('delete asks before removing a certificate', (tester) async {
      await _pump(tester, const NocCertificateScreen());

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Named, so the secretary can see which one they are about to remove.
      // Two matches: the card's own reference line, and the dialog's text.
      expect(find.text('Delete this certificate?'), findsOneWidget);
      expect(
        find.textContaining('NOC/2026/00001 for Rahul Sharma'),
        findsOneWidget,
      );

      // Keep backs out without deleting.
      await tester.tap(find.widgetWithText(TextButton, 'Keep'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this certificate?'), findsNothing);
      expect(find.text('Rahul Sharma'), findsOneWidget);
    });

    testWidgets('back from a certificate returns to the list', (tester) async {
      await _pump(tester, const NocCertificateScreen());

      await tester.tap(find.text('Rahul Sharma'));
      await tester.pumpAndSettle();
      expect(find.text('NO OBJECTION CERTIFICATE'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // The list, not an empty route: the certificate was pushed over it.
      expect(find.text('NOC certificates'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
    });

    testWidgets('the form fills in the standard clause for the chosen type', (
      tester,
    ) async {
      await _pump(tester, const NocCertificateScreen());

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New NOC'));
      await tester.pumpAndSettle();

      // No dues is the default, so its wording is already in the box.
      expect(
        find.textContaining('maintenance charges and other dues'),
        findsOneWidget,
      );

      await tester.tap(find.text('Renovation'));
      await tester.pumpAndSettle();

      // Switching type replaces the wording rather than keeping the old one.
      expect(find.textContaining('renovation work'), findsOneWidget);
      expect(
        find.textContaining('maintenance charges and other dues'),
        findsNothing,
      );
    });

    testWidgets('Other asks for a title of its own', (tester) async {
      await _pump(tester, const NocCertificateScreen());

      await tester.tap(find.widgetWithText(FloatingActionButton, 'New NOC'));
      await tester.pumpAndSettle();

      expect(find.text('Certificate title'), findsNothing);

      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      expect(find.text('Certificate title'), findsOneWidget);
    });
  });
}
