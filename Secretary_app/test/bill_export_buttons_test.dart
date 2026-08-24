import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/bill_detail_screen.dart';

import 'fakes.dart';

/// A run with two flats, so the detail screen has something to export.
class _StockedBillingRepository extends FakeBillingRepository {
  @override
  Future<Map<String, dynamic>> getBillDetail(int billId, {int? flatId}) async =>
      {
        'items': [
          {
            'flat_no': '101',
            'w_name': 'A',
            'owner_name': 'A Sharma',
            'society_name': 'Green Acres CHS',
            'gen_date': '2026-07-08',
            'due_date': '2026-07-18',
            'col1_name': 'Maintenance Charges',
            'col1_amount': 2800.00,
            'amt_forward': 0,
          },
          {
            'flat_no': '102',
            'w_name': 'A',
            'owner_name': 'B Patel',
            'society_name': 'Green Acres CHS',
            'gen_date': '2026-07-08',
            'due_date': '2026-07-18',
            'col1_name': 'Maintenance Charges',
            'col1_amount': 2800.00,
            'amt_forward': 1200.50,
          },
        ],
        'chargeColumns': [
          {'nameKey': 'col1_name', 'amountKey': 'col1_amount'},
        ],
      };
}

/// A run the server returns empty.
class _EmptyBillingRepository extends FakeBillingRepository {
  @override
  Future<Map<String, dynamic>> getBillDetail(int billId, {int? flatId}) async =>
      {'items': <Map<String, dynamic>>[], 'chargeColumns': <dynamic>[]};
}

Future<void> _pump(
  WidgetTester tester, {
  FakeBillingRepository? repository,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeOverrides(),
        billingRepositoryProvider.overrideWithValue(
          repository ?? _StockedBillingRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const BillDetailScreen(billId: 1, period: 'July 2026'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// The action icons carried by the app bar.
Finder _appBarIcon(IconData icon) =>
    find.descendant(of: find.byType(AppBar), matching: find.byIcon(icon));

void main() {
  _plateTests();

  testWidgets('the app bar carries download, print and share', (tester) async {
    await _pump(tester);

    expect(_appBarIcon(Icons.download_rounded), findsOneWidget);
    expect(_appBarIcon(Icons.print_rounded), findsOneWidget);
    expect(_appBarIcon(Icons.share_rounded), findsOneWidget);
  });

  testWidgets('the summary stays in the body, the buttons do not', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('2 flat(s)'),
      ),
      findsOneWidget,
    );

    // The old in-body pair is gone; nothing under the bar duplicates it.
    expect(find.widgetWithText(Row, 'Download'), findsNothing);
  });

  testWidgets('an empty run offers no export actions', (tester) async {
    await _pump(tester, repository: _EmptyBillingRepository());

    // Three live-looking actions over a run with no bills would each do
    // nothing when tapped.
    expect(_appBarIcon(Icons.download_rounded), findsNothing);
    expect(_appBarIcon(Icons.print_rounded), findsNothing);
    expect(_appBarIcon(Icons.share_rounded), findsNothing);
    expect(find.text('No bills in this run'), findsOneWidget);
  });

  testWidgets('tapping a bill opens that flat with its own actions', (
    tester,
  ) async {
    await _pump(tester);

    // Flat 102 carries arrears, so its sheet shows the dues line.
    await tester.tap(find.text('Owner Name: B Patel'));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    // Twice: once on the list underneath, once on the sheet above it.
    expect(find.text('Dues as of 08-07-2026:'), findsNWidgets(2));
  });

  testWidgets('the flat sheet spreads its three actions evenly', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Owner Name: B Patel'));
    await tester.pumpAndSettle();

    Rect boxOf(String label) => tester.getRect(
      find
          .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
          .first,
    );

    final share = boxOf('Share');
    final save = boxOf('Save');
    final print = boxOf('Print');

    // Equal widths on one line — an odd one out reads as a layout fault.
    expect(share.width, closeTo(save.width, 1.0));
    expect(save.width, closeTo(print.width, 1.0));
    expect(share.top, closeTo(print.top, 1.0));
    expect(share.height, greaterThan(38));
  });
}

/// Styling of the app-bar actions. These assert the plate, not just the icon:
/// the icons rendered fine as bare grey glyphs too, which is the look this
/// replaced.
void _plateTests() {
  testWidgets('each app-bar action sits on its own tinted plate', (
    tester,
  ) async {
    await _pump(tester);

    Material plateOf(IconData icon) => tester.widget<Material>(
      find
          .ancestor(of: _appBarIcon(icon), matching: find.byType(Material))
          .first,
    );

    final download = plateOf(Icons.download_rounded);
    final print = plateOf(Icons.print_rounded);
    final share = plateOf(Icons.share_rounded);

    // Tinted, not the bar's own background.
    expect(download.color, AppTheme.surfaceFor(AppTheme.primary));
    expect(print.color, AppTheme.surfaceFor(AppTheme.violet));
    expect(share.color, AppTheme.surfaceFor(AppTheme.teal));

    // Three distinct hues — the point of the plates is telling them apart.
    expect({download.color, print.color, share.color}.length, 3);
  });

  testWidgets('the icons carry their accent colour, not flat grey', (
    tester,
  ) async {
    await _pump(tester);

    Color? colourOf(IconData icon) =>
        tester.widget<Icon>(_appBarIcon(icon)).color;

    expect(colourOf(Icons.download_rounded), AppTheme.primary);
    expect(colourOf(Icons.print_rounded), AppTheme.violet);
    expect(colourOf(Icons.share_rounded), AppTheme.teal);
  });

  testWidgets('each action is a real tap target', (tester) async {
    await _pump(tester);

    for (final icon in [
      Icons.download_rounded,
      Icons.print_rounded,
      Icons.share_rounded,
    ]) {
      final box = tester.getRect(
        find
            .ancestor(of: _appBarIcon(icon), matching: find.byType(SizedBox))
            .last,
      );
      expect(box.width, greaterThanOrEqualTo(38));
      expect(box.height, greaterThanOrEqualTo(38));
    }
  });
}
