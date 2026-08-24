import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/presentation/providers/viewmodel_provider.dart';
import 'package:secretary_app/screens/accounts/vendor_bills_screen.dart';

import 'fakes.dart';

/// A society with one vendor on file and one bill already raised.
///
/// The screen reads the list, the vendor register and the form lookups from
/// the API, so all three are answered here and the test drives the same code
/// path a real device does.
class _VendorRepository extends FakeAccountsRepository {
  Map<String, dynamic>? lastBill;
  Map<String, dynamic>? lastVendor;
  Map<String, dynamic>? lastPayment;

  @override
  Future<RowList> getVendorBills({String? search}) async => const RowList(
    items: [
      {
        'bill_id': 5,
        'bill_number': 'SRV-202608-101500',
        'vendor_name': 'Acme Services',
        'bill_date': '2026-08-10',
        'total_amount': 2400.00,
        'paid_amount': 400.00,
        'remaining_amount': 2000.00,
        'payment_status': 'Partially Paid',
        'bill_status': 'Pending',
      },
    ],
    count: 1,
  );

  @override
  Future<RowList> getVendors({String? search}) async => const RowList(
    items: [
      {
        'vendor_id': 3,
        'vendor_name': 'Acme Services',
        'contact_person': 'R Patil',
        'contact_no': '9876543210',
        'gst_no': '27ABCDE1234F1Z5',
      },
    ],
    count: 1,
  );

  @override
  Future<Map<String, dynamic>> getVendorBillFormData() async => {
    'vendors': [
      {
        'vendor_id': 3,
        'vendor_name': 'Acme Services',
        'gst_no': '27ABCDE1234F1Z5',
      },
    ],
    'staff': <dynamic>[],
    'staffRoles': <dynamic>[],
    'approvers': <dynamic>[],
    'chargeHeads': <dynamic>[],
  };

  @override
  Future<void> createVendorBill(Map<String, dynamic> body) async {
    lastBill = body;
  }

  @override
  Future<void> createVendor(Map<String, dynamic> body) async {
    lastVendor = body;
  }

  @override
  Future<void> payVendorBill(int id, Map<String, dynamic> body) async {
    lastPayment = {'id': id, ...body};
  }
}

/// A society whose one bill was rejected and so cannot be paid.
class _RejectedBillRepository extends _VendorRepository {
  @override
  Future<RowList> getVendorBills({String? search}) async => const RowList(
    items: [
      {
        'bill_id': 5,
        'bill_number': 'SRV-202608-101500',
        'vendor_name': 'Acme Services',
        'bill_date': '2026-08-10',
        'total_amount': 2400.00,
        'paid_amount': 0.00,
        'remaining_amount': 2400.00,
        'payment_status': 'Unpaid',
        'status': 4,
        'bill_status': 'Rejected',
      },
    ],
    count: 1,
  );
}

/// A bill somebody has already turned down, with their reason on the row.
class _RejectedApprovalRepository extends _VendorRepository {
  @override
  Future<Map<String, dynamic>> getVendorBill(int id) async => {
    'bill': {
      'bill_id': 5,
      'bill_number': 'SRV-202608-101500',
      'vendor_name': 'Acme Services',
      'total_amount': 2400.00,
      'status': 4,
      'bill_status': 'Rejected',
    },
    'items': <dynamic>[],
    'approvals': [
      {
        'approval_id': 42,
        'user_id': 11,
        'name': 'S Kulkarni',
        'approval_status': 4,
        'approval_date': '2026-08-22',
        'remarks': 'Quote is above the approved budget',
      },
    ],
    'payments': <dynamic>[],
  };
}

/// A bill awaiting two approvals: one asked of the signed-in secretary
/// (user 98, per FakeAuthRepository.me) and one asked of somebody else.
class _AwaitingApprovalRepository extends _VendorRepository {
  Map<String, dynamic>? lastDecision;

  @override
  Future<Map<String, dynamic>> getVendorBill(int id) async => {
    'bill': {
      'bill_id': 5,
      'bill_number': 'SRV-202608-101500',
      'vendor_name': 'Acme Services',
      'total_amount': 2400.00,
    },
    'items': <dynamic>[],
    'approvals': [
      {
        'approval_id': 41,
        'user_id': 98,
        'name': 'Test Secretary',
        'approval_status': 1,
      },
      {
        'approval_id': 42,
        'user_id': 11,
        'name': 'S Kulkarni',
        'approval_status': 1,
      },
    ],
    'payments': <dynamic>[],
  };

  @override
  Future<void> decideVendorBill(
    int billId,
    int approvalId,
    Map<String, dynamic> body,
  ) async {
    lastDecision = {'billId': billId, 'approvalId': approvalId, ...body};
  }
}

/// The same society, with committee members who can approve a bill.
class _ApproverRepository extends _VendorRepository {
  @override
  Future<Map<String, dynamic>> getVendorBillFormData() async => {
    'vendors': [
      {
        'vendor_id': 3,
        'vendor_name': 'Acme Services',
        'gst_no': '27ABCDE1234F1Z5',
      },
    ],
    'staff': <dynamic>[],
    'staffRoles': <dynamic>[],
    'approvers': [
      {'user_id': 11, 'name': 'S Kulkarni', 'role': 'Treasurer'},
      {'user_id': 12, 'name': 'M Deshpande', 'role': 'Chairman'},
    ],
    'chargeHeads': <dynamic>[],
  };
}

Future<void> _pump(
  WidgetTester tester, {
  required _VendorRepository repository,
  Size size = const Size(420, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // The screen kicks its own loads off a Future.microtask in initState, which
  // a widget test never awaits — so the container is held here and the same
  // loads are driven explicitly below. Without that the lists sit on their
  // skeletons forever and nothing the screen draws can be asserted on.
  final container = ProviderContainer(
    overrides: [
      // This goes last on purpose: fakeOverrides() registers a plain
      // FakeAccountsRepository too, and the later entry is the one that
      // wins — listing it first would quietly serve sampleRows() instead.
      ...fakeOverrides(),
      accountsRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const VendorBillsScreen(),
      ),
    ),
  );

  // The approvals list only offers a decision on the signed-in user's own
  // line, so the session has to be loaded for those buttons to appear at all.
  await container.read(authViewModelProvider.notifier).loadMe();

  final vm = container.read(accountsViewModelProvider.notifier);
  await vm.loadVendorBills();
  await vm.loadVendors();
  await vm.loadVendorFormData();
  await _settle(tester);
}

/// Pump until the rows have landed, without waiting for every animation.
///
/// `pumpAndSettle` never returns on this screen: both tabs of the TabBarView
/// stay mounted, and a tab whose list is still empty draws a ListSkeleton
/// whose shimmer repeats forever. Fixed pumps advance past the microtask that
/// resolves the fetches without ever asking the tree to go still.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pump until [finder] matches, then stop.
///
/// The rows arrive over a couple of frames and the shimmer never lets the
/// tree go still, so waiting on the widget itself is both quicker and more
/// honest than guessing a frame count.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60; i++) {
    if (finder.evaluate().isNotEmpty) return;
    // runAsync lets the repository's futures actually complete: `pump` alone
    // only advances the frame clock, so a list still waiting on its fetch
    // would never fill however many frames were pumped at it.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Scroll to the Save button and tap it.
///
/// The form runs to several cards once a service type is picked, so on a
/// phone-sized window the button sits well below the fold.
Future<void> _tapSaveBill(WidgetTester tester) async {
  // Scroll the form itself rather than ensureVisible: the item fields sit in
  // their own horizontal scroller, and ensureVisible walks up to that inner
  // viewport instead of the page and never reaches the button.
  final save = find.text('Save bill');
  await tester.scrollUntilVisible(
    save,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await _settle(tester);
  await tester.tap(save, warnIfMissed: false);
  await _settle(tester);
}

/// The item-row box under the column heading [label].
///
/// The item grid carries its headings above the boxes rather than as floating
/// labels — a dense field in a top-aligned row has no room for one to rise
/// into, so it was clipped on focus. That puts the heading outside the field,
/// so the box is found through the column that holds both.
Finder _itemBox(String label) {
  return find.descendant(
    of: find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first,
    matching: find.byType(TextFormField),
  );
}

/// Tap the Pay button on the first bill.
///
/// It sits at the foot of the bill card, below the stat tiles and the search
/// box, so on a phone-sized window it starts off-screen — `ensureVisible`
/// scrolls the list to it first rather than tapping at nothing.
Future<void> _tapPay(WidgetTester tester) async {
  final pay = find.byTooltip('Pay bill');
  await _pumpUntil(tester, pay);
  await tester.ensureVisible(pay);
  await _settle(tester);
  await tester.tap(pay);
  await _settle(tester);
}

void main() {
  testWidgets('the bill list shows what the society owes', (tester) async {
    await _pump(tester, repository: _VendorRepository());

    expect(find.text('Acme Services'), findsWidgets);
    // The number shares its line with the bill date.
    expect(find.textContaining('SRV-202608-101500'), findsOneWidget);
    // What is still owed is called out against what has been paid — it is
    // what decides whether the bill needs anything doing to it.
    expect(find.textContaining('due'), findsOneWidget);
    expect(find.textContaining('paid'), findsOneWidget);
    // Pay is offered only while something is owed.
    expect(find.byTooltip('Pay bill'), findsOneWidget);
  });

  testWidgets('the pill tabs carry a count and switch the list', (
    tester,
  ) async {
    await _pump(tester, repository: _VendorRepository());

    // One bill and one vendor are on file, so both pills say so.
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Vendors'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));

    // Bills are in front, so the action adds a bill.
    expect(
      find.widgetWithText(FloatingActionButton, 'Add bill'),
      findsOneWidget,
    );

    await tester.tap(find.text('Vendors'));
    await _settle(tester);

    // Switching swaps both the action and what the search box searches.
    expect(
      find.widgetWithText(FloatingActionButton, 'Add vendor'),
      findsOneWidget,
    );
    expect(find.text('Search vendors'), findsOneWidget);
  });

  testWidgets('a rejected bill offers no way to pay it', (tester) async {
    await _pump(tester, repository: _RejectedBillRepository());

    // Money is still outstanding on it, so only the rejection keeps Pay away.
    expect(find.textContaining('2,400'), findsWidgets);
    expect(find.byTooltip('Pay bill'), findsNothing);

    // And the card says why rather than showing an amount still due.
    expect(find.text('Not payable'), findsOneWidget);
    expect(find.textContaining('due'), findsNothing);
  });

  testWidgets('a bill opens from its View button, not a tap on the card', (
    tester,
  ) async {
    await _pump(tester, repository: _VendorRepository());

    // Tapping the card body does nothing — Pay and Delete sit on it, and a
    // stray tap opening the bill made those easy to hit by accident.
    await tester.tap(find.text('Acme Services').first);
    await _settle(tester);
    expect(find.text('Approvals'), findsNothing);

    await tester.tap(find.byTooltip('View bill'));
    await _settle(tester);
    expect(find.text('Approvals'), findsOneWidget);
  });

  testWidgets('only the approver it was asked of can decide', (tester) async {
    final repository = _AwaitingApprovalRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.byTooltip('View bill'));
    await _settle(tester);

    // Both approvers are listed and both are still pending.
    expect(find.text('Test Secretary'), findsOneWidget);
    expect(find.text('S Kulkarni'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(2));

    // But only the signed-in user's own line offers a decision — the API
    // refuses anyone else, so the other row says what it is waiting on.
    expect(find.widgetWithText(TextButton, 'Approve'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Reject'), findsOneWidget);
    expect(find.text('Waiting on them to decide.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Approve'));
    await _settle(tester);

    // The decision carries the bill, so the API can check the approval
    // belongs to the caller before recording it.
    expect(repository.lastDecision?['billId'], 5);
    expect(repository.lastDecision?['approvalId'], 41);
    expect(repository.lastDecision?['decision'], 'approve');
  });

  testWidgets('a rejection shows the reason it was given', (tester) async {
    await _pump(tester, repository: _RejectedApprovalRepository());

    await tester.tap(find.byTooltip('View bill'));
    await _settle(tester);

    // The API insists on a reason before it records a rejection; it was being
    // stored and then never shown, leaving a bill marked Rejected with
    // nothing saying why.
    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('Quote is above the approved budget'), findsOneWidget);
  });

  testWidgets('rejecting asks for a reason first', (tester) async {
    final repository = _AwaitingApprovalRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.byTooltip('View bill'));
    await _settle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Reject'));
    await _settle(tester);

    // Dismissing the reason dialog records nothing: the API requires a
    // remark on a rejection.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await _settle(tester);
    expect(repository.lastDecision, isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Reject'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Quote was not approved');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reject'));
    await _settle(tester);

    expect(repository.lastDecision?['decision'], 'reject');
    expect(repository.lastDecision?['remarks'], 'Quote was not approved');
  });

  testWidgets('a vendor edits from its own button', (tester) async {
    await _pump(tester, repository: _VendorRepository());

    await tester.tap(find.text('Vendors'));
    await _settle(tester);

    await tester.tap(find.byTooltip('Edit vendor'));
    await _settle(tester);

    // The form opens filled in with the vendor being edited.
    expect(find.text('Edit vendor'), findsWidgets);
    expect(find.text('Save vendor'), findsOneWidget);
  });

  testWidgets('Add bill opens the form', (tester) async {
    await _pump(tester, repository: _VendorRepository());

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);

    expect(find.text('New vendor bill'), findsOneWidget);
    // Nothing else is asked for until the service type is known — it decides
    // which sub-form the bill even has.
    expect(find.text('Service type'), findsWidgets);
    expect(find.text('Save bill'), findsNothing);
  });

  testWidgets('picking a service type reveals the rest of the form and '
      'stamps a bill number', (tester) async {
    await _pump(tester, repository: _VendorRepository());

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);

    await tester.tap(find.text('Service type').last);
    await _settle(tester);
    await tester.tap(find.text('Vendor-Service Payment').last);
    await _settle(tester);

    expect(find.text('Save bill'), findsOneWidget);
    expect(find.text('Bill number'), findsOneWidget);
    // A service bill is raised against a vendor, and costs what it costs.
    expect(find.text('Vendor name'), findsWidgets);
    expect(find.text('Service cost'), findsOneWidget);

    // The number is stamped for the picked type: SRV-YYYYMM-HHMMSS.
    final field = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Bill number'),
    );
    expect(
      RegExp(r'^SRV-\d{6}-\d{6}$').hasMatch(field.controller!.text),
      isTrue,
      reason:
          'expected a generated SRV number, got "${field.controller!.text}"',
    );
  });

  testWidgets('a service bill saves what was typed', (tester) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);
    await tester.tap(find.text('Service type').last);
    await _settle(tester);
    await tester.tap(find.text('Vendor-Service Payment').last);
    await _settle(tester);

    await tester.tap(find.text('Vendor name').last);
    await _settle(tester);
    await tester.tap(find.text('Acme Services').last);
    await _settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Service cost'),
      '5000',
    );
    await _settle(tester);

    await _tapSaveBill(tester);
    await _settle(tester);

    final sent = repository.lastBill;
    expect(sent, isNotNull);
    expect(sent!['serviceType'], 3);
    expect(sent['vendorIds'], ['3']);
    // Subtotal is the service cost, and with no tax the total matches it.
    expect(sent['subtotal'], 5000);
    expect(sent['totalAmount'], 5000);
    // Nothing was paid on the form, so no payment rides along with the bill.
    expect(sent.containsKey('payment'), isFalse);
  });

  testWidgets('an inventory bill totals its line items', (tester) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);
    await tester.tap(find.text('Service type').last);
    await _settle(tester);
    await tester.tap(find.text('Vendor-Inventory Payment').last);
    await _settle(tester);

    await tester.tap(find.text('Vendor name').last);
    await _settle(tester);
    await tester.tap(find.text('Acme Services').last);
    await _settle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Add item'));
    await _settle(tester);

    await tester.enterText(_itemBox('Description'), 'Water pump');
    await tester.enterText(_itemBox('Qty'), '2');
    await tester.enterText(_itemBox('Unit price'), '1000');
    await tester.enterText(_itemBox('Tax %'), '10');
    await _settle(tester);

    await _tapSaveBill(tester);
    await _settle(tester);

    final sent = repository.lastBill;
    expect(sent, isNotNull);
    expect(sent!['serviceType'], 2);
    // 2 × 1000, plus 10% on that line — the same expression the legacy items
    // grid evaluated per row.
    expect(sent['subtotal'], 2200);
    expect((sent['items'] as List).single['totalAmount'], 2200);
  });

  testWidgets('a staff bill will not save without a payment', (tester) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);
    await tester.tap(find.text('Service type').last);
    await _settle(tester);
    await tester.tap(find.text('Staff Payment').last);
    await _settle(tester);

    await _tapSaveBill(tester);
    await _settle(tester);

    // No staff on file to pick, so the run is refused before it reaches the
    // API — a staff bill with nobody on it is not a bill.
    expect(repository.lastBill, isNull);
  });

  testWidgets('Add vendor opens the register form and saves it', (
    tester,
  ) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    // The action follows the tab in front, so Vendors offers Add vendor.
    await tester.tap(find.text('Vendors').last);
    await _settle(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add vendor'));
    await _settle(tester);

    expect(find.text('Add vendor'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vendor name'),
      'Bright Cleaners',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contact number (optional)'),
      '9812345678',
    );
    await _settle(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add vendor'));
    await _settle(tester);

    expect(repository.lastVendor?['name'], 'Bright Cleaners');
    expect(repository.lastVendor?['contactNo'], '9812345678');
  });

  testWidgets('a vendor without a name is refused', (tester) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.text('Vendors').last);
    await _settle(tester);
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add vendor'));
    await _settle(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add vendor'));
    await _settle(tester);

    // The website saved a blank vendor here; this one asks for the name.
    expect(find.text('Enter the vendor name'), findsOneWidget);
    expect(repository.lastVendor, isNull);
  });

  testWidgets('Pay opens with the balance filled in and cannot overpay', (
    tester,
  ) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await _tapPay(tester);

    expect(find.text('Record payment'), findsOneWidget);

    await tester.tap(find.text('Cash').last);
    await _settle(tester);

    // The sheet opens with the outstanding balance already in the box.
    final amount = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Amount'),
    );
    expect(amount.controller!.text, '2000.00');

    // Paying more than is owed is the more consequential mistake, so it is
    // refused rather than sent.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '5000',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save payment'));
    await _settle(tester);

    expect(repository.lastPayment, isNull);
    expect(find.textContaining('more than the'), findsOneWidget);
  });

  testWidgets('a cash payment within the balance is recorded', (tester) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await _tapPay(tester);

    await tester.tap(find.text('Cash').last);
    await _settle(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save payment'));
    await _settle(tester);

    expect(repository.lastPayment?['id'], 5);
    expect(repository.lastPayment?['mode'], 'Cash');
    expect(repository.lastPayment?['amount'], 500);
  });

  testWidgets('a cheque payment must carry its own details', (tester) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await _tapPay(tester);

    await tester.tap(find.text('Cheque').last);
    await _settle(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save payment'));
    await _settle(tester);

    // A cheque with no number cannot be matched to a bank statement.
    expect(find.text('Enter the cheque number'), findsOneWidget);
    expect(repository.lastPayment, isNull);
  });

  testWidgets('payment modes are shown as buttons, not behind a dropdown', (
    tester,
  ) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await _tapPay(tester);

    // All three are on screen at once — no tap needed to discover them.
    expect(find.text('Cheque'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    // Nothing is picked yet, so the details below stay hidden.
    expect(
      find.text('Pick a payment mode to enter the details.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Amount'), findsNothing);

    // Picking a mode reveals only that mode's boxes.
    await tester.tap(find.text('Cheque').last);
    await _settle(tester);
    expect(find.widgetWithText(TextFormField, 'Cheque number'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Transaction reference'),
      findsNothing,
    );

    // Switching swaps them rather than stacking both modes' fields.
    await tester.tap(find.text('Online').last);
    await _settle(tester);
    expect(
      find.widgetWithText(TextFormField, 'Transaction reference'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Cheque number'), findsNothing);
  });

  testWidgets('a cheque pairs its boxes two to a row', (tester) async {
    await _pump(tester, repository: _VendorRepository());

    await _tapPay(tester);
    await tester.tap(find.text('Cheque').last);
    await _settle(tester);

    /// The top of a field, to tell which boxes share a row.
    double topOf(String label) =>
        tester.getTopLeft(find.widgetWithText(TextFormField, label)).dy;

    final chequeNo = topOf('Cheque number');
    final bank = topOf('Bank name');
    final amount = topOf('Amount');

    // Cheque number sits beside its date, and the bank beside the amount
    // drawn on it — so the second row starts below the first.
    expect(bank, greaterThan(chequeNo));
    expect(amount, equals(bank));

    // The date is a tappable box rather than a TextFormField, so it is
    // matched on its own and checked against the number it belongs with.
    final date = tester.getTopLeft(find.text('Not set')).dy;
    expect(date, greaterThan(chequeNo - 40));
    expect(date, lessThan(bank));
  });

  testWidgets('a payment with no mode picked is refused', (tester) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await _tapPay(tester);

    // The mode is not a form field, so submitting without one has to be
    // caught on its own rather than by the Form's validators.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save payment'));
    await _settle(tester);

    expect(repository.lastPayment, isNull);
    expect(find.text('Pick a payment mode'), findsOneWidget);
  });

  testWidgets('the picked vendor puts its GST beside the name', (tester) async {
    await _pump(tester, repository: _VendorRepository());

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);
    await tester.tap(find.text('Service type').last);
    await _settle(tester);
    await tester.tap(find.text('Vendor-Service Payment').last);
    await _settle(tester);

    // Nothing picked yet, so the GST box stands empty rather than absent.
    expect(find.text('GST number'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    await tester.tap(find.text('Vendor name').last);
    await _settle(tester);
    await tester.tap(find.text('Acme Services').last);
    await _settle(tester);

    // Filled from the vendor, never typed.
    expect(find.text('27ABCDE1234F1Z5'), findsOneWidget);
  });

  testWidgets('Add vendor inside the bill opens a dialog, not a page', (
    tester,
  ) async {
    final repository = _VendorRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);
    await tester.tap(find.text('Service type').last);
    await _settle(tester);
    await tester.tap(find.text('Vendor-Service Payment').last);
    await _settle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Add vendor'));
    await _settle(tester);

    // A dialog, so the half-filled bill is still behind it.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Save vendor'), findsOneWidget);
    expect(find.text('New vendor bill'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vendor name'),
      'Bright Cleaners',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save vendor'));
    await _settle(tester);

    expect(repository.lastVendor?['name'], 'Bright Cleaners');
    // The dialog closes back onto the bill being written.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('New vendor bill'), findsOneWidget);
  });

  testWidgets('approvers are added through a picker and open on tap', (
    tester,
  ) async {
    await _pump(tester, repository: _ApproverRepository());

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add bill'));
    await _settle(tester);
    await tester.tap(find.text('Service type').last);
    await _settle(tester);
    await tester.tap(find.text('Vendor-Inventory Payment').last);
    await _settle(tester);

    // The roster lives behind the picker rather than on the form.
    expect(find.text('Add approver'), findsOneWidget);
    expect(find.text('No approvers added yet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Add approver'));
    await _settle(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('S Kulkarni').last);
    await _settle(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add 1'));
    await _settle(tester);

    // Chosen approvers are listed on the form.
    expect(find.text('S Kulkarni'), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);

    // Tapping one opens their details, where they can be dropped again.
    await tester.tap(find.text('S Kulkarni'));
    await _settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Treasurer'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await _settle(tester);
    expect(find.text('No approvers added yet.'), findsOneWidget);
  });
}
