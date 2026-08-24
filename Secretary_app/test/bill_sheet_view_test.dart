import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secretary_app/domain/models/bill_sheet.dart';
import 'package:secretary_app/widgets/bill_sheet_view.dart';

/// The figures from a real February run: charges 3,196.15 over arrears of
/// 11,219.21.
BillSheetData _bill() => BillSheetData(
  societyName: 'Green Acres CHS',
  registrationNo: null,
  address: null,
  ownerName: 'A Sharma',
  flatNo: '102',
  wingName: 'A',
  area: '850 sq.ft',
  billDate: DateTime(2026, 8, 8),
  dueDate: DateTime(2026, 8, 18),
  lines: const [
    BillLine('Maintenance Charges', 2800.00),
    BillLine('Sinking Fund', 396.15),
  ],
  charges: 3196.15,
  forward: 11219.21,
);

/// The rendered width of one Text, as laid out on screen.
double _widthOf(WidgetTester tester, String text) =>
    tester.getSize(find.text(text)).width;

void main() {
  testWidgets('totals labels lay out on one line, not one character per line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: BillSheetView(bill: _bill())),
        ),
      ),
    );

    // The regression: the label column collapsed so far that each glyph wrapped
    // onto its own line. A label rendered that way is barely wider than one
    // character, so its width is the thing to assert on.
    final duesLabel = 'Dues as of 08-08-2026:';
    expect(find.text(duesLabel), findsOneWidget);
    expect(
      _widthOf(tester, duesLabel),
      greaterThan(100),
      reason: 'label column collapsed — text is wrapping per character',
    );

    // And it must not have been clipped away to achieve that.
    expect(find.text('Total:'), findsOneWidget);
    expect(find.text('Grand Total:'), findsOneWidget);
    expect(find.text('Amount in Words:'), findsOneWidget);
  });

  testWidgets('grand total sums charges and arrears', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: BillSheetView(bill: _bill())),
        ),
      ),
    );

    // 3,196.15 + 11,219.21 = 14,415.36, as the screenshot showed.
    expect(find.text('₹ 14,415.36'), findsOneWidget);
    expect(find.text('₹ 3,196.15'), findsOneWidget);
    expect(find.text('₹ 11,219.21'), findsOneWidget);
  });

  test('amount in words spells the grand total, paise included', () {
    expect(
      amountInWords(14415.36),
      'Fourteen Thousand Four Hundred Fifteen Rupees and Thirty Six Paise Only',
    );
    expect(amountInWords(0), 'Zero Rupees Only');
    // Indian numbering, not the western million.
    expect(amountInWords(2500000).startsWith('Twenty Five Lakh'), isTrue);
  });
}
