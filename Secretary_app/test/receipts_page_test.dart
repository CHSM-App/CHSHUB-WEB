import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/domain/models/receipt_request.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/billing_screen.dart';
import 'package:secretary_app/screens/billing/receipt_entry_screen.dart';
import 'package:secretary_app/screens/billing/receipt_detail_screen.dart';
import 'package:secretary_app/screens/billing/receipts_screen.dart';

import 'fakes.dart';

class _ReceiptsRepository extends FakeBillingRepository {
  @override
  Future<RowList> getReceipts() async => const RowList(
    items: [
      {
        'receipt_id': 1,
        'receipt_no': 'R-1',
        'paid_amount': 1500.00,
        'flat_no': '101',
      },
    ],
    count: 1,
    totalCollected: 1500.00,
  );

  @override
  Future<RowList> getReceiptResidents() async => const RowList(
    items: [
      {
        'flat_id': 7,
        'building_name': 'A',
        'flat_no': '101',
        'owner_name': 'A Sharma',
      },
    ],
    count: 1,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  FakeBillingRepository? repository,
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeOverrides(),
        billingRepositoryProvider.overrideWithValue(
          repository ?? _ReceiptsRepository(),
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _listTests();
  _refreshTests();

  testWidgets('the billing hub lists receipts once, not as two entries', (
    tester,
  ) async {
    await _pump(tester, const BillingScreen());

    expect(find.text('Receipts'), findsOneWidget);
    // "Receipt entry" was a separate tile leading to the same workflow; the
    // form now opens over the list instead.
    expect(find.text('Receipt entry'), findsNothing);
  });

  testWidgets('Record payment opens the form as a page of its own', (
    tester,
  ) async {
    await _pump(tester, const ReceiptsScreen());

    expect(find.byType(ReceiptEntryScreen), findsNothing);

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    // A page, not a sheet: the list is gone behind it and the form carries its
    // own app bar.
    expect(find.byType(ReceiptEntryScreen), findsOneWidget);
    expect(find.byType(ReceiptsScreen), findsNothing);
    expect(find.text('Record a payment'), findsOneWidget);
    expect(find.text('Who is paying'), findsOneWidget);
  });

  testWidgets('backing out of the form returns to the list', (tester) async {
    await _pump(tester, const ReceiptsScreen());

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptEntryScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ReceiptEntryScreen), findsNothing);
    expect(find.byType(ReceiptsScreen), findsOneWidget);
  });
}

/// Three receipts across two residents, one of them cancelled.
class _ListRepository extends FakeBillingRepository {
  @override
  Future<RowList> getReceipts() async => const RowList(
    items: [
      {
        'receipt_id': 1,
        'receipt_no': 'R-1',
        'paid_amount': 1500.00,
        'flat_no': '101',
        'building_name': 'A',
        // `owner` is the key Grid_Show actually returns — the app read only
        // `owner_name` and left every card's name blank.
        'owner': 'A Sharma',
        'transaction_ref': 'CHQ-556677',
        'pay_mode': 'Cheque',
      },
      {
        'receipt_id': 2,
        'receipt_no': 'R-2',
        'paid_amount': 2400.00,
        'flat_no': '202',
        'building_name': 'B',
        'owner': 'B Patel',
        'pay_mode': 'PDC',
      },
      {
        'receipt_id': 3,
        'receipt_no': 'R-3',
        'paid_amount': 900.00,
        'flat_no': '303',
        'building_name': 'C',
        'owner': 'C Rao',
        'status': 'Cancelled',
      },
    ],
    count: 3,
    totalCollected: 4800.00,
  );

  @override
  Future<Map<String, dynamic>> getReceipt(int id) async => {
    'receipt': {
      'receipt_no': 'R-$id',
      'name': 'A Sharma',
      'unit': 'A-101',
      'pay_mode': 'Cheque',
      'bank_name': 'HDFC',
      'paid_amount': 1500.00,
    },
    'lines': [
      {'Billno': 'MB-11', 'bill_ref': 'Jun 2026', 'amount': 1500.00},
    ],
  };
}

void _listTests() {
  testWidgets('the list shows resident names and no cancel action', (
    tester,
  ) async {
    await _pump(tester, const ReceiptsScreen(), repository: _ListRepository());

    expect(find.text('A Sharma'), findsOneWidget);
    expect(find.text('B Patel'), findsOneWidget);

    // Cancelling is a reversal that cannot be undone from the app; it must not
    // sit one stray tap away in a list.
    expect(find.text('Cancel receipt'), findsNothing);

    // The card is the target now — a View button on every row only cost
    // height.
    expect(find.text('View'), findsNothing);
    expect(find.text('RCPT-0088'), findsNothing);
    // Receipt number and reference ride on the card.
    expect(find.text('R-1'), findsOneWidget);
    expect(find.text('Ref CHQ-556677'), findsOneWidget);
  });

  testWidgets('search narrows the list by name', (tester) async {
    await _pump(tester, const ReceiptsScreen(), repository: _ListRepository());

    await tester.enterText(find.byType(TextField).first, 'Patel');
    await tester.pumpAndSettle();

    expect(find.text('B Patel'), findsOneWidget);
    expect(find.text('A Sharma'), findsNothing);
  });

  testWidgets('search also matches flat and receipt number', (tester) async {
    await _pump(tester, const ReceiptsScreen(), repository: _ListRepository());

    await tester.enterText(find.byType(TextField).first, '202');
    await tester.pumpAndSettle();
    expect(find.text('B Patel'), findsOneWidget);
    expect(find.text('A Sharma'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'R-3');
    await tester.pumpAndSettle();
    expect(find.text('C Rao'), findsOneWidget);
    expect(find.text('B Patel'), findsNothing);
  });

  testWidgets('a search matching nothing says so, and can be cleared', (
    tester,
  ) async {
    await _pump(tester, const ReceiptsScreen(), repository: _ListRepository());

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();

    // Not the same as having no receipts at all.
    expect(find.text('No receipts match'), findsOneWidget);
    expect(find.text('No receipts yet'), findsNothing);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('A Sharma'), findsOneWidget);
  });

  testWidgets('View opens the receipt with its settled bills', (tester) async {
    await _pump(tester, const ReceiptsScreen(), repository: _ListRepository());

    await tester.tap(find.text('A Sharma'));
    await tester.pumpAndSettle();

    // A page of its own, not a sheet over the list.
    expect(find.byType(ReceiptDetailScreen), findsOneWidget);
    expect(find.byType(ReceiptsScreen), findsNothing);

    // Drawn as a document, in the maintenance bill's format.
    expect(find.text('MAINTENANCE RECEIPT'), findsOneWidget);
    expect(find.text('Receipt No: R-1'), findsOneWidget);
    expect(find.text('Resident: A Sharma'), findsOneWidget);
    // The bills it cleared, and the total spelled out.
    expect(find.text('MB-11'), findsOneWidget);
    expect(find.text('Amount Received:'), findsOneWidget);
    expect(find.text('One Thousand Five Hundred Rupees Only'), findsOneWidget);

    // The three exports live in the page's own app bar.
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    expect(find.text('Bank: HDFC'), findsOneWidget);
  });

  testWidgets('a cancelled receipt still opens', (tester) async {
    await _pump(tester, const ReceiptsScreen(), repository: _ListRepository());

    // Reading what a reversed payment settled is exactly when this matters.
    expect(find.text('C Rao'), findsOneWidget);
    await tester.tap(find.text('C Rao'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptDetailScreen), findsOneWidget);
  });
}

/// A repository whose receipts list grows when a payment is recorded, the way
/// the server's does.
class _GrowingRepository extends FakeBillingRepository {
  final List<Map<String, dynamic>> _receipts = [
    {
      'receipt_id': 1,
      'receipt_no': 'R-1',
      'paid_amount': 1500.00,
      'owner': 'A Sharma',
      'flat_no': '101',
    },
  ];

  @override
  Future<RowList> getReceipts() async =>
      RowList(items: List.of(_receipts), count: _receipts.length);

  @override
  Future<RowList> getReceiptResidents() async => const RowList(
    items: [
      {
        'flat_id': 7,
        'building_name': 'A',
        'flat_no': '101',
        'owner_name': 'A Sharma',
      },
    ],
    count: 1,
  );

  @override
  Future<RowList> getOutstandingBills(int flatId) async => const RowList(
    items: [
      {'bill_no': '55', 'BillNo': 'MB-55', 'Amount': 800.00, 'BillType': 1},
    ],
    count: 1,
  );

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => const RowList();

  @override
  Future<RowList> getReceiptPdc(int flatId) async => const RowList();

  @override
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) async {
    _receipts.add({
      'receipt_id': 2,
      'receipt_no': 'R-2',
      'paid_amount': request.paidAmount,
      'owner': 'B Patel',
      'flat_no': '202',
    });
    return {'receipt_no': 'R-2'};
  }
}

void _refreshTests() {
  testWidgets('a recorded payment shows in the list straight away', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeOverrides(),
          billingRepositoryProvider.overrideWithValue(_GrowingRepository()),
        ],
        child: const MaterialApp(home: ReceiptsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A Sharma'), findsOneWidget);
    expect(find.text('B Patel'), findsNothing);

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    // Fill the form: flat, bill, cheque details.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A · 101 · A Sharma').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MB-55'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Transaction ID / cheque no.'),
      '556677',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bank name'),
      'HDFC',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record payment').last);
    await tester.pumpAndSettle();

    // Back on the list, with the new receipt already on it — a payment that
    // does not appear reads as one that was not recorded.
    expect(find.byType(ReceiptsScreen), findsOneWidget);
    expect(find.byType(ReceiptEntryScreen), findsNothing);
    expect(find.text('B Patel'), findsOneWidget);
  });
}
