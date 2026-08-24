import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/domain/models/receipt_request.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/receipt_entry_screen.dart';

import 'fakes.dart';

/// A flat with two outstanding bills and an advance on the ledger.
///
/// The screen reads all three from the API; this stands in for the server so
/// the test drives the same code path a real device does.
class _LedgerBillingRepository extends FakeBillingRepository {
  ReceiptRequest? lastReceipt;

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
  Future<RowList> getOutstandingBills(int flatId) async => RowList(
    items: [
      {
        'bill_no': '11',
        'BillNo': 'MB-11',
        'Amount': 1500.00,
        'DueDate': '2026-06-08',
        'Status': 'Overdue',
        'BillType': 1,
      },
      {
        'bill_no': '12',
        'BillNo': 'MB-12',
        'Amount': 2500.50,
        'DueDate': '2026-07-08',
        'Status': 'Pending',
        'BillType': 1,
      },
    ],
    count: 2,
  );

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => RowList(
    items: [
      {'advance': 320.00},
    ],
    count: 1,
  );

  @override
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) async {
    lastReceipt = request;
    return {'receipt_no': 'R-1'};
  }
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(420, 1400),
  FakeBillingRepository? repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeOverrides(),
        billingRepositoryProvider.overrideWithValue(
          repository ?? _LedgerBillingRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReceiptEntryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fill the cheque details every receipt now requires.
///
/// Both payment modes are cheques, as on the website, so a submit without a
/// number, bank and date is refused — these are what make a payment traceable.
Future<void> _fillCheque(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Transaction ID / cheque no.'),
    '556677',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Bank name'),
    'HDFC',
  );
  await tester.pumpAndSettle();

  // The date picker is a dialog, not a field.
  await tester.tap(find.text('Not set'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Choose the only flat the fake serves, which loads its dues.
Future<void> _pickFlat(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('A · 101 · A Sharma').last);
  await tester.pumpAndSettle();
}

void main() {
  _websiteParityTests();
  _pdcTests();
  _loadStateTests();
  _noPdcTests();

  testWidgets('the flat list comes from the API, not a fixed list', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();

    expect(find.text('A · 101 · A Sharma'), findsWidgets);
  });

  testWidgets('picking a flat shows its real bills and advance', (
    tester,
  ) async {
    await _pump(tester);
    await _pickFlat(tester);

    // Both outstanding bills, with the amounts the server sent.
    expect(find.text('MB-11'), findsOneWidget);
    expect(find.text('MB-12'), findsOneWidget);
    expect(find.text('₹1,500.00'), findsOneWidget);
    expect(find.text('₹2,500.50'), findsOneWidget);

    // And the advance already on the flat.
    expect(find.textContaining('holds ₹320.00 in credit'), findsOneWidget);
  });

  testWidgets('the summary totals the ticked bills against the amount', (
    tester,
  ) async {
    await _pump(tester);
    await _pickFlat(tester);

    await tester.tap(find.text('MB-11'));
    await tester.pump();

    // Selected total tracks the tick, and the header counts it.
    expect(find.text('1 of 2 selected'), findsOneWidget);

    // Ticking proposed the bill's own amount, so it already settles exactly.
    expect(find.text('Settles the selected bills exactly.'), findsOneWidget);

    // Ticking the second bill re-proposes the pair's total.
    await tester.tap(find.text('MB-12'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2 selected'), findsOneWidget);
    expect(find.text('Settles the selected bills exactly.'), findsOneWidget);

    // Both bills here are Regular, so the amount is fixed at their total and
    // the field is locked — there is no shortfall to show, by design.
    final amount = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(amount.enabled, isFalse);
    expect(amount.controller!.text, '4000.50');
  });

  testWidgets('a shortfall is called out once an add-on opens the amount', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(420, 1900),
      repository: _TypedBillingRepository(),
    );
    await _pickFlat(tester);

    // Regular MB-21 (1,000) plus Add-On MB-20 (400) = 1,400 payable.
    await tester.tap(find.text('MB-21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MB-20'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '1200');
    await tester.pump();
    expect(find.textContaining('₹200.00 short'), findsOneWidget);
  });

  testWidgets('a surplus is called out as advance, not as a shortfall', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(420, 1900),
      repository: _TypedBillingRepository(),
    );
    await _pickFlat(tester);

    await tester.tap(find.text('MB-21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MB-20'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '1900');
    await tester.pump();

    expect(find.textContaining('₹500.00 over'), findsOneWidget);
  });

  testWidgets('select all ticks every bill, and clears them again', (
    tester,
  ) async {
    await _pump(tester);
    await _pickFlat(tester);

    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(find.text('2 of 2 selected'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pump();
    expect(find.text('0 of 2 selected'), findsOneWidget);
  });

  testWidgets('submitting sends the real ticked bills to the API', (
    tester,
  ) async {
    final repo = _LedgerBillingRepository();
    // Tall enough that the button is not clipped: the bill rows now carry a
    // type, due date and status, so the form runs longer than it did.
    await _pump(tester, size: const Size(420, 1800), repository: repo);
    await _pickFlat(tester);

    await tester.tap(find.text('MB-11'));
    await tester.pumpAndSettle();

    // Ticking already proposed 1,500.00; typing it again only confirms it.
    await tester.enterText(find.byType(TextFormField).first, '1500');
    await tester.pumpAndSettle();

    await _fillCheque(tester);
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    // The request carries what was actually on screen — the flat picked, the
    // bill ticked and the amount typed.
    expect(repo.lastReceipt, isNotNull);
    expect(repo.lastReceipt!.flatId, 7);
    expect(repo.lastReceipt!.paidAmount, 1500.0);
    expect(repo.lastReceipt!.billNos, ['11']);
  });

  testWidgets('the form lays out in one column on a phone', (tester) async {
    await _pump(tester);
    await _pickFlat(tester);

    // Bills sit above the payment card rather than beside it.
    final bills = tester.getRect(find.text('Bills this payment settles'));
    final payment = tester.getRect(find.text('Payment'));
    expect(payment.top, greaterThan(bills.top));
    expect(payment.left, closeTo(bills.left, 1.0));
  });

  testWidgets('on a wide window the bills sit beside the payment fields', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1400, 1200));
    await _pickFlat(tester);

    final bills = tester.getRect(find.text('Bills this payment settles'));
    final payment = tester.getRect(find.text('Payment'));

    // Side by side: the payment column starts to the right of the bills one.
    expect(payment.left, greaterThan(bills.right));
  });
}

/// A flat carrying one Regular bill, one Add-On, and one note-only charge —
/// the three bill types the website distinguishes.
class _TypedBillingRepository extends FakeBillingRepository {
  ReceiptRequest? lastReceipt;

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
      // Add-On first, so ordering has something to actually reorder.
      {
        'bill_no': '20',
        'BillNo': 'MB-20',
        'Amount': 400.00,
        'BillType': 0,
        'Status': 'Pending',
      },
      {
        'bill_no': '21',
        'BillNo': 'MB-21',
        'Amount': 1000.00,
        'BillType': 1,
        'Status': 'Overdue',
      },
      {'bill_no': '22', 'BillNo': 'MB-22', 'Amount': 75.00, 'BillType': 2},
    ],
    count: 3,
  );

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => const RowList();

  @override
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) async {
    lastReceipt = request;
    return {'receipt_no': 'R-2'};
  }
}

void _websiteParityTests() {
  testWidgets('a note-only charge is never offered as tickable', (
    tester,
  ) async {
    await _pump(tester, repository: _TypedBillingRepository());
    await _pickFlat(tester);

    expect(find.text('MB-20'), findsOneWidget);
    expect(find.text('MB-21'), findsOneWidget);
    // bill_type 2 is carried, not settled — it must not be a row to tick.
    expect(find.text('MB-22'), findsNothing);
    expect(find.text('0 of 2 selected'), findsOneWidget);
    expect(
      find.textContaining('an additional ₹75.00 is carried'),
      findsOneWidget,
    );
  });

  testWidgets('ticking a bill proposes its amount', (tester) async {
    await _pump(tester, repository: _TypedBillingRepository());
    await _pickFlat(tester);

    await tester.tap(find.text('MB-21'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(field.controller!.text, '1000.00');

    // Untick and the proposal goes with it.
    await tester.tap(find.text('MB-21'));
    await tester.pumpAndSettle();
    expect(field.controller!.text, '');
  });

  testWidgets('a regular bill alone locks the amount at its full value', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(420, 1900),
      repository: _TypedBillingRepository(),
    );
    await _pickFlat(tester);

    await tester.tap(find.text('MB-21'));
    await tester.pumpAndSettle();

    // The totals row states the floor...
    expect(find.textContaining('Minimum amount is ₹1,000.00'), findsOneWidget);
    // ...and the amount field explains why it cannot be edited, in the
    // website's words.
    expect(find.text('Regular bills must be cleared in full'), findsOneWidget);

    // Under-paying is not merely refused on submit — it cannot be typed. A
    // Regular-only selection fixes the figure outright.
    final amount = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(amount.enabled, isFalse);
    expect(amount.controller!.text, '1000.00');
  });

  testWidgets('an add-on in the selection reopens the amount, with a floor', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(420, 1900),
      repository: _TypedBillingRepository(),
    );
    await _pickFlat(tester);

    await tester.tap(find.text('MB-21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MB-20'));
    await tester.pumpAndSettle();

    // Add-On bills may be part paid, so the box opens with the Regular
    // portion as its floor.
    final amount = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(amount.enabled, isTrue);
    expect(
      find.text('Minimum ₹1,000.00 — only add-on bills may be part paid'),
      findsOneWidget,
    );

    // Typing under that floor is refused on submit, in the website's words.
    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.pumpAndSettle();
    await _fillCheque(tester);
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Amount entered is less than the minimum amount ₹1,000.00',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an add-on alone carries no floor', (tester) async {
    await _pump(tester, repository: _TypedBillingRepository());
    await _pickFlat(tester);

    await tester.tap(find.text('MB-20'));
    await tester.pumpAndSettle();

    // Add-On bills may be part paid, so nothing is locked.
    expect(find.textContaining('Minimum amount is'), findsNothing);
  });

  testWidgets('regular bills are sent ahead of add-on ones', (tester) async {
    final repo = _TypedBillingRepository();
    await _pump(tester, size: const Size(420, 1900), repository: repo);
    await _pickFlat(tester);

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    await _fillCheque(tester);
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    // Regular (21) before Add-On (20), whatever order the server listed them
    // in — the settlement proc consumes the list in order.
    expect(repo.lastReceipt, isNotNull);
    expect(repo.lastReceipt!.billNos, ['21', '20']);
    expect(repo.lastReceipt!.paidAmount, 1400.0);
  });
}

/// A flat with one bill and two post-dated cheques on file.
class _PdcBillingRepository extends FakeBillingRepository {
  ReceiptRequest? lastReceipt;

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
      {
        'bill_no': '30',
        'BillNo': 'MB-30',
        'Amount': 1200.00,
        'BillType': 1,
        'Status': 'Pending',
      },
    ],
    count: 1,
  );

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => const RowList();

  @override
  Future<RowList> getReceiptPdc(int flatId) async => const RowList(
    items: [
      {
        'pdc_rem_id': 55,
        'chqno': 900123,
        'che_amount': 1200.00,
        'che_date': '2026-09-10',
        'bank_name': 'HDFC',
      },
    ],
    count: 1,
  );

  @override
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) async {
    lastReceipt = request;
    return {'receipt_no': 'R-3'};
  }
}

/// Switch the payment mode.
///
/// A segmented control, as on the website — both options are on screen, so
/// this is one tap rather than opening a menu.
Future<void> _pickMode(WidgetTester tester, String mode) async {
  await tester.tap(find.text(mode));
  await tester.pumpAndSettle();
}

/// Choose the flat's only post-dated cheque.
///
/// The cheque picker is the only dropdown on the form now that payment mode
/// is a segmented control.
Future<void> _pickCheque(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('900123').last);
  await tester.pumpAndSettle();
}

void _pdcTests() {
  testWidgets('PDC mode lists the cheques on file for the flat', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(420, 1800),
      repository: _PdcBillingRepository(),
    );
    await _pickFlat(tester);
    await _pickMode(tester, 'PDC cheque');

    expect(find.text('Post-dated cheque'), findsOneWidget);

    // The cheques themselves only exist while the menu is open.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();

    // Number, amount, date and bank, as the website labels them.
    expect(find.textContaining('900123'), findsWidgets);
    expect(find.textContaining('₹1,200.00'), findsWidgets);
    expect(find.textContaining('HDFC'), findsWidgets);
  });

  testWidgets('choosing a cheque fills its details and locks them', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(420, 1800),
      repository: _PdcBillingRepository(),
    );
    await _pickFlat(tester);
    await _pickMode(tester, 'PDC cheque');

    await _pickCheque(tester);

    // The cheque supplies number, bank and amount.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '1200.00',
    );
    expect(find.text('Set by the selected cheque'), findsOneWidget);

    // And those fields stop being editable — the cheque is already written.
    final chequeNo = tester.widget<TextField>(
      find.widgetWithText(TextField, '900123'),
    );
    expect(chequeNo.enabled, isFalse);
  });

  testWidgets('switching mode away from PDC clears the cheque details', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(420, 1800),
      repository: _PdcBillingRepository(),
    );
    await _pickFlat(tester);
    await _pickMode(tester, 'PDC cheque');

    await _pickCheque(tester);
    expect(find.textContaining('900123'), findsWidgets);

    await _pickMode(tester, 'Cheque');

    // Nothing of the cheque survives — otherwise one cheque's number would
    // ride along on a payment made by other means.
    expect(find.text('900123'), findsNothing);
    expect(find.text('HDFC'), findsNothing);
  });

  testWidgets('PDC mode refuses to submit without a cheque chosen', (
    tester,
  ) async {
    final repo = _PdcBillingRepository();
    await _pump(tester, size: const Size(420, 1800), repository: repo);
    await _pickFlat(tester);

    await tester.tap(find.text('MB-30'));
    await tester.pumpAndSettle();
    await _pickMode(tester, 'PDC cheque');

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    // The field's own validator catches it, so the message lands on the
    // picker rather than in a snackbar the secretary has to read and dismiss.
    expect(find.text('Select a post-dated cheque'), findsOneWidget);
    expect(repo.lastReceipt, isNull);
  });

  testWidgets('a PDC receipt sends the cheque details through', (tester) async {
    final repo = _PdcBillingRepository();
    await _pump(tester, size: const Size(420, 1800), repository: repo);
    await _pickFlat(tester);

    await tester.tap(find.text('MB-30'));
    await tester.pumpAndSettle();
    await _pickMode(tester, 'PDC cheque');

    await _pickCheque(tester);

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    // The backend takes no pdcId — a PDC is a source of cheque details, so
    // they travel as ordinary cheque fields.
    expect(repo.lastReceipt, isNotNull);
    expect(repo.lastReceipt!.payMode, 'PDC');
    expect(repo.lastReceipt!.chequeNo, '900123');
    expect(repo.lastReceipt!.bankName, 'HDFC');
    expect(repo.lastReceipt!.paidAmount, 1200.0);
  });
}

/// A flat whose bill lookup fails.
class _FailingBillsRepository extends FakeBillingRepository {
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
  Future<RowList> getOutstandingBills(int flatId) async =>
      throw Exception('gateway down');

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => const RowList();

  @override
  Future<RowList> getReceiptPdc(int flatId) async => const RowList();
}

void _loadStateTests() {
  testWidgets('a failed bill lookup says so rather than showing none', (
    tester,
  ) async {
    await _pump(tester, repository: _FailingBillsRepository());
    await _pickFlat(tester);

    // The danger this guards: an empty list reads as "owes nothing", and a
    // secretary would record a payment against bills that never loaded.
    expect(find.text('This flat has no outstanding bills.'), findsNothing);
    expect(
      find.textContaining('Could not load this flat\'s bills'),
      findsOneWidget,
    );
    expect(find.textContaining('Do not record a payment'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('an empty result still reads as nothing owed', (tester) async {
    await _pump(tester, repository: _EmptyBillsRepository());
    await _pickFlat(tester);

    // The other side of the same coin: a genuine zero must not look like a
    // failure either.
    expect(find.text('This flat has no outstanding bills.'), findsOneWidget);
    expect(find.textContaining('Could not load'), findsNothing);
  });
}

/// A flat that genuinely owes nothing.
class _EmptyBillsRepository extends FakeBillingRepository {
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
  Future<RowList> getOutstandingBills(int flatId) async => const RowList();

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => const RowList();

  @override
  Future<RowList> getReceiptPdc(int flatId) async => const RowList();
}

/// A flat with a bill but no post-dated cheques at all.
class _NoPdcRepository extends FakeBillingRepository {
  ReceiptRequest? lastReceipt;

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
      {'bill_no': '40', 'BillNo': 'MB-40', 'Amount': 900.00, 'BillType': 1},
    ],
    count: 1,
  );

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => const RowList();

  /// None on file — this is the case that slipped through.
  @override
  Future<RowList> getReceiptPdc(int flatId) async => const RowList();

  @override
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) async {
    lastReceipt = request;
    return {'receipt_no': 'R-9'};
  }
}

void _noPdcTests() {
  testWidgets('PDC mode with no cheques on file cannot record a payment', (
    tester,
  ) async {
    final repo = _NoPdcRepository();
    await _pump(tester, size: const Size(420, 1900), repository: repo);
    await _pickFlat(tester);

    await tester.tap(find.text('MB-40'));
    await tester.pumpAndSettle();
    await _pickMode(tester, 'PDC cheque');

    expect(
      find.text('No post-dated cheques on file for this flat.'),
      findsOneWidget,
    );

    await _fillCheque(tester);
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    // The bug: with no cheques the picker renders a plain note carrying no
    // validator, so the form validated cleanly and the payment was recorded
    // against a post-dated cheque that does not exist.
    expect(repo.lastReceipt, isNull);
    expect(find.textContaining('Select a post-dated cheque'), findsOneWidget);
  });
}
