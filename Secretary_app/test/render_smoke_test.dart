import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/core/theme/responsive.dart';
import 'package:secretary_app/widgets/app_widgets.dart';
import 'package:secretary_app/widgets/bottom_bar_view.dart';
import 'package:secretary_app/widgets/charts.dart';
import 'package:secretary_app/widgets/secretary_app_bar.dart';

/// Renders each shared widget on its own so a layout assertion names the
/// widget that caused it, instead of surfacing as one of a hundred identical
/// "RenderBox was not laid out" lines in the browser console.
Future<void> _pump(WidgetTester tester, Widget child, {Size? size}) async {
  tester.view.physicalSize = size ?? const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: child));
  await tester.pump();
}

void main() {
  group('ResponsiveGrid', () {
    // clamp(lo, hi) asserts when lo > hi, which a single child used to produce
    // against a hard-coded minimum of two columns.
    testWidgets('renders with one child', (tester) async {
      await _pump(
        tester,
        const Scaffold(body: ResponsiveGrid(children: [Text('only')])),
      );
      expect(find.text('only'), findsOneWidget);
    });

    testWidgets('renders with four children', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: ResponsiveGrid(
            children: [Text('a'), Text('b'), Text('c'), Text('d')],
          ),
        ),
      );
      expect(find.text('d'), findsOneWidget);
    });

    testWidgets('renders inside a scrolling list', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            child: ResponsiveGrid(children: [Text('a'), Text('b')]),
          ),
        ),
      );
      expect(find.text('a'), findsOneWidget);
    });
  });

  testWidgets('GradientPanel sizes to its content', (tester) async {
    await _pump(
      tester,
      const Scaffold(body: GradientPanel(child: Text('hero'))),
    );
    expect(find.text('hero'), findsOneWidget);
  });

  testWidgets('StatTile renders inside a grid', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        body: ResponsiveGrid(
          children: [
            StatTile(
              label: 'Residents',
              value: '10',
              icon: Icons.people,
              color: AppTheme.info,
            ),
            StatTile(
              label: 'Dues',
              value: '₹88,117',
              icon: Icons.wallet,
              color: AppTheme.error,
              trend: 'Needs chasing',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Residents'), findsOneWidget);
  });

  testWidgets('AppCard with accent spine renders', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        body: AppCard(accent: AppTheme.error, child: Text('row')),
      ),
    );
    expect(find.text('row'), findsOneWidget);
  });

  testWidgets('SecretaryAppBar renders with a badge', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        appBar: SecretaryAppBar(
          greeting: 'Hello, Test Secretary',
          subtitle: 'Gokuldham',
          notificationCount: 3,
        ),
        body: SizedBox(),
      ),
    );
    expect(find.text('Hello, Test Secretary'), findsOneWidget);
    expect(find.text('Gokuldham'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('SecretaryAppBar takes initials from the name, not the role', (
    tester,
  ) async {
    await _pump(
      tester,
      const Scaffold(
        appBar: SecretaryAppBar(
          greeting: 'Hello, Pallavi Patade (Secretary)',
          avatarName: 'Pallavi Patade',
          subtitle: 'Gokuldham',
        ),
        body: SizedBox(),
      ),
    );

    expect(find.text('Hello, Pallavi Patade (Secretary)'), findsOneWidget);
    expect(find.text('PP'), findsOneWidget);
  });

  testWidgets('SecretaryAppBar strips the bracketed role when no avatarName', (
    tester,
  ) async {
    // The fallback path: without an explicit name the greeting is parsed, and
    // the role in brackets must not leak into the initials.
    await _pump(
      tester,
      const Scaffold(
        appBar: SecretaryAppBar(
          greeting: 'Hello, Pallavi Patade (Secretary)',
          subtitle: 'Gokuldham',
        ),
        body: SizedBox(),
      ),
    );

    expect(find.text('PP'), findsOneWidget);
  });

  testWidgets('BottomBarView renders its tabs and marks the selected one', (
    tester,
  ) async {
    var tapped = -1;

    await _pump(
      tester,
      Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: BottomBarView(
          currentIndex: 0,
          onTap: (i) => tapped = i,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Labels are shown, as CHSHUB's real bar does.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);

    // The selected tab uses the filled icon, the rest the outlined one.
    expect(find.byIcon(Icons.dashboard), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);

    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  group('charts', () {
    testWidgets('DonutChart renders with data', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: DonutChart(
            data: [
              ChartDatum(label: 'Due', value: 88117, color: AppTheme.warning),
              ChartDatum(
                label: 'Collection',
                value: 235291,
                color: AppTheme.success,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Due'), findsOneWidget);
    });

    // Every branch of sp_dashboard can come back empty, so the empty state has
    // to lay out too.
    testWidgets('DonutChart renders with no data', (tester) async {
      await _pump(tester, const Scaffold(body: DonutChart(data: [])));
      expect(find.text('No figures yet'), findsOneWidget);
    });

    testWidgets('BarChartCard renders with data', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: BarChartCard(
            data: [
              ChartDatum(
                label: 'January',
                value: 9165,
                color: AppTheme.primary,
              ),
              ChartDatum(label: 'March', value: 10311, color: AppTheme.primary),
            ],
          ),
        ),
      );
      expect(find.byType(BarChartCard), findsOneWidget);
    });

    testWidgets('ChartCard wraps a chart', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: ChartCard(
            title: 'Income tracker',
            subtitle: 'Collected against due',
            child: DonutChart(data: []),
          ),
        ),
      );
      expect(find.text('Income tracker'), findsOneWidget);
    });
  });

  testWidgets('ResponsiveRow stacks on a phone', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        body: ResponsiveRow(children: [Text('left'), Text('right')]),
      ),
    );
    expect(find.text('left'), findsOneWidget);
  });

  testWidgets('ResponsiveRow sits side by side on a wide window', (
    tester,
  ) async {
    await _pump(
      tester,
      const Scaffold(
        body: ResponsiveRow(children: [Text('left'), Text('right')]),
      ),
      size: const Size(1400, 900),
    );
    expect(find.text('right'), findsOneWidget);
  });

  testWidgets('skeletons render', (tester) async {
    await _pump(tester, const Scaffold(body: ListSkeleton(count: 3)));
    expect(find.byType(Skeleton), findsWidgets);
  });

  group('AppDropdown', () {
    Widget dropdown({int? value, ValueChanged<int?>? onChanged}) => Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppDropdown<int?>(
          value: value,
          label: 'Year',
          icon: Icons.event_outlined,
          options: const [
            AppOption(null, 'All years'),
            AppOption(2026, '2026'),
            AppOption(2025, '2025'),
          ],
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );

    testWidgets('shows the label and the current choice', (tester) async {
      await _pump(tester, dropdown(value: 2026));
      expect(find.text('Year'), findsOneWidget);
      // The field renders through selectedItemBuilder, not the menu row — so
      // the chosen year appears exactly once while the menu is shut.
      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets('opens a menu of every option', (tester) async {
      await _pump(tester, dropdown(value: 2026));

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      expect(find.text('All years'), findsWidgets);
      expect(find.text('2025'), findsWidgets);
    });

    /// Checks that are actually visible.
    ///
    /// Every row renders the check widget so the labels stay aligned as the
    /// selection moves; the unselected ones are painted transparent. So
    /// counting the icons would always give the option count — it is the
    /// coloured ones that mean "selected".
    int visibleChecks(WidgetTester tester) => tester
        .widgetList<Icon>(find.byIcon(Icons.check_rounded))
        .where((i) => i.color == AppTheme.primary)
        .length;

    testWidgets('marks the selected row with a check', (tester) async {
      await _pump(tester, dropdown(value: 2026));

      // Shut, nothing is checked — the check belongs to the menu row, and the
      // field draws itself from selectedItemBuilder instead.
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      // Exactly one row is current, so exactly one check is visible.
      expect(visibleChecks(tester), 1);
    });

    testWidgets('reports the chosen value', (tester) async {
      int? chosen;
      var called = false;

      await _pump(
        tester,
        dropdown(
          value: 2026,
          onChanged: (v) {
            chosen = v;
            called = true;
          },
        ),
      );

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025').last);
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(chosen, 2025);
    });

    testWidgets('a null value selects the placeholder option', (tester) async {
      await _pump(tester, dropdown());

      // 'All years' is a real option carrying null, not a hint — so it shows
      // in the shut field and is the checked row once opened.
      expect(find.text('All years'), findsOneWidget);

      await tester.tap(find.text('All years'));
      await tester.pumpAndSettle();
      expect(visibleChecks(tester), 1);
    });

    testWidgets('tints only the selected row, not the whole menu', (
      tester,
    ) async {
      await _pump(tester, dropdown(value: 2026));
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      // Every option draws a _MenuRow container, but only the current one is
      // filled — Material's own grey focus band is cleared in the theme, so a
      // second tinted row here would mean it had come back.
      final tinted = tester.widgetList<Container>(find.byType(Container)).where(
        (c) {
          final d = c.decoration;
          return d is BoxDecoration && d.color == AppTheme.primarySurface;
        },
      );

      expect(tinted.length, 1);
    });

    group('menuWidth', () {
      // A separate code path: DropdownButtonFormField cannot narrow its menu,
      // so this switches to a hand-built FormField + DropdownButton. It has to
      // behave the same in every other respect.
      Widget narrow({int? value, ValueChanged<int?>? onChanged}) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppDropdown<int?>(
            value: value,
            label: 'Year',
            menuWidth: 150,
            options: const [
              AppOption(null, 'All years'),
              AppOption(2026, '2026'),
              AppOption(2025, '2025'),
            ],
            onChanged: onChanged ?? (_) {},
          ),
        ),
      );

      testWidgets('renders the field and opens its menu', (tester) async {
        await _pump(tester, narrow(value: 2026));
        expect(find.text('Year'), findsOneWidget);
        expect(find.text('2026'), findsOneWidget);

        await tester.tap(find.text('2026'));
        await tester.pumpAndSettle();
        expect(find.text('2025'), findsWidgets);
      });

      testWidgets('reports the chosen value', (tester) async {
        int? chosen;
        await _pump(tester, narrow(value: 2026, onChanged: (v) => chosen = v));

        await tester.tap(find.text('2026'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2025').last);
        await tester.pumpAndSettle();

        expect(chosen, 2025);
      });

      testWidgets('drops a menu narrower than the field', (tester) async {
        await _pump(tester, narrow(value: 2026));
        final fieldWidth = tester.getSize(find.byType(InputDecorator)).width;

        await tester.tap(find.text('2026'));
        await tester.pumpAndSettle();

        // The menu rows are laid out at menuWidth, not at the field's width —
        // which is the whole point of this path.
        final rowWidth = tester.getSize(find.text('2025').last).width;
        expect(rowWidth, lessThan(fieldWidth));
      });
    });

    testWidgets('the selected plate spans the row, not just its label', (
      tester,
    ) async {
      await _pump(tester, dropdown(value: 2026));
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      // Sized to its text the plate came out as a tab crammed against the
      // check. It should reach nearly the full row instead — the label is
      // four characters, so a shrink-wrapped plate would be far narrower.
      final plate = find
          .descendant(
            of: find.byType(Scrollable).last,
            matching: find.byWidgetPredicate((w) {
              final d = w is Container ? w.decoration : null;
              return d is BoxDecoration && d.color == AppTheme.primarySurface;
            }),
          )
          .first;

      // Compared against the menu, not against the label: the Text is itself
      // Expanded, so it already reports the row's width and would make the
      // check vacuous.
      //
      // The plate gives up its own 8pt margin on each side and the menu adds
      // 8pt of list padding, so 32pt short of the menu is the expected result
      // — a plate sized to "2026" would be a third of this.
      final plateWidth = tester.getSize(plate).width;
      final menuWidth = tester.getSize(find.byType(Scrollable).last).width;

      expect(plateWidth, greaterThanOrEqualTo(menuWidth - 32));
    });

    testWidgets('renders option icons when given', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: AppDropdown<String>(
            value: 'Cash',
            label: 'Payment mode',
            isDense: false,
            options: const [
              AppOption('Cash', 'Cash', icon: Icons.payments_outlined),
              AppOption('UPI', 'UPI', icon: Icons.qr_code_rounded),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code_rounded), findsOneWidget);
    });
  });
}
