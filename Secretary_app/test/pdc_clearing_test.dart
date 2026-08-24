import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/domain/models/pdc_request.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/pdc_screen.dart';

import 'fakes.dart';

/// Cheques as sp_pdc_reminder's `pdc_clear_grid_show` really spells them:
/// `chqno` and `che_date`, with the outcome held in three separate bit
/// columns rather than one status.
class _ClearingBillingRepository extends FakeBillingRepository {
  String? lastFrom;
  String? lastTo;
  PdcClearRequest? lastClear;
  int? lastClearId;

  @override
  Future<RowList> getPdcClearing({String? from, String? to}) async {
    lastFrom = from;
    lastTo = to;
    return const RowList(
      items: [
        {
          'pdc_rem_id': 41,
          'chqno': '1000000',
          'owner_name': 'Aniket',
          'che_date': '2026-08-14',
          'che_amount': 6830.76,
          'che_dep': 0,
          'che_ret': 0,
          'che_can': 0,
        },
      ],
      count: 1,
    );
  }

  int? deletedId;
  PdcRequest? lastCreated;

  @override
  Future<Map<String, dynamic>> getPdcOwnerDetails(int ownerId) async => {
    'owner_id': ownerId,
    'wing_id': 4,
    'build_name': 'Tower A',
    'w_name': 'Wing 1',
    'pre_mob': '9876500000',
  };

  @override
  Future<RowList> getPdcOwners() async => const RowList(
    items: [
      {'owner_id': 12, 'name': 'Bhushan Gawade', 'Unit': 'A-101'},
    ],
    count: 1,
  );

  @override
  Future<void> createPdc(PdcRequest request) async => lastCreated = request;

  @override
  Future<RowList> getPdcList({String? search}) async => const RowList(
    items: [
      {
        'pdc_rem_id': 77,
        'chqno': '12345',
        'name': 'Bhushan Gawade',
        'Unit': 'A-101',
        'che_date': '2026-09-02',
        'che_amount': 1000.0,
        'che_dep': 0,
        'che_ret': 0,
        'che_can': 0,
      },
    ],
    count: 1,
  );

  @override
  Future<void> deletePdc(int id) async => deletedId = id;

  @override
  Future<void> clearPdc(int id, PdcClearRequest request) async {
    lastClearId = id;
    lastClear = request;
  }
}

/// Opens the screen on the clearing tab, where the date window lives.
Future<_ClearingBillingRepository> _openClearing(WidgetTester tester) async {
  final repo = _ClearingBillingRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeOverrides(),
        billingRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: PdcScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(find.text('PDC Clearing'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  return repo;
}

/// A register whose cheques are spread across months, and listed out of date
/// order — the fitted window has to reach both ends regardless of row order.
class _SpreadBillingRepository extends _ClearingBillingRepository {
  @override
  Future<RowList> getPdcList({String? search}) async => const RowList(
    items: [
      {'pdc_rem_id': 1, 'chqno': '1', 'che_date': '2026-11-05'},
      {'pdc_rem_id': 2, 'chqno': '2', 'che_date': '2026-07-15'},
      {'pdc_rem_id': 3, 'chqno': '3', 'che_date': '2027-01-20'},
    ],
    count: 3,
  );
}

/// Opens the screen on the reminder tab, which is where it lands by default.
Future<_ClearingBillingRepository> _openReminder(WidgetTester tester) async {
  final repo = _ClearingBillingRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeOverrides(),
        billingRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: PdcScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  return repo;
}

void main() {
  group('PDC Reminder tab', () {
    testWidgets('a cheque carries Edit and Delete on the row itself', (
      tester,
    ) async {
      await _openReminder(tester);

      // Both sit on the card, as the website's two row buttons do — tapping
      // the row no longer opens a menu to reach them.
      expect(find.text('Bhushan Gawade'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('deleting asks first, then removes that cheque', (
      tester,
    ) async {
      final repo = await _openReminder(tester);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Remove this cheque?'), findsOneWidget);
      expect(repo.deletedId, isNull);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(repo.deletedId, 77);
    });

    testWidgets('Add opens a full page, prefilled for nothing', (tester) async {
      await _openReminder(tester);

      await tester.tap(find.text('Add cheque'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // A page, not a sheet — it carries its own app bar and a back arrow.
      expect(find.widgetWithText(AppBar, 'Add cheque'), findsOneWidget);
      expect(find.text('Save cheque'), findsOneWidget);
    });

    testWidgets('Edit opens the same page with the cheque already in it', (
      tester,
    ) async {
      await _openReminder(tester);

      await tester.tap(find.text('Edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.widgetWithText(AppBar, 'Edit cheque'), findsOneWidget);
      // The row's own values are in the fields, not a blank form.
      expect(find.widgetWithText(TextFormField, '12345'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('a new cheque carries the resident wing to the API', (
      tester,
    ) async {
      final repo = await _openReminder(tester);

      await tester.tap(find.text('Add cheque'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Select resident'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Bhushan Gawade — A-101').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cheque number'),
        '54321',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '2500',
      );
      await tester.tap(find.text('Save cheque'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(repo.lastCreated?.ownerId, 12);
      // Absent, the API defaults wing_id to 0 and the cheque is filed against
      // no wing — which is what the server rejected.
      expect(repo.lastCreated?.wingId, 4);
      expect(repo.lastCreated?.chequeNo, '54321');
      expect(repo.lastCreated?.amount, 2500);
    });

    testWidgets('the clearing outcomes are not offered here', (tester) async {
      await _openReminder(tester);

      // Banking a cheque belongs to the other tab. Offering the same three
      // outcomes on both left it unclear which list was being worked through.
      expect(find.text('Mark this cheque as'), findsNothing);
      expect(find.text('Deposited'), findsNothing);
    });
  });

  testWidgets('the clearing list is fetched for a real date window', (
    tester,
  ) async {
    final repo = await _openClearing(tester);

    // The endpoint requires both — without them the server rejects the call,
    // so an absent window is a broken screen, not an unfiltered one.
    expect(repo.lastFrom, isNotNull);
    expect(repo.lastTo, isNotNull);
    expect(repo.lastFrom, matches(r'^\d{4}-\d{2}-\d{2}$'));
    expect(repo.lastTo, matches(r'^\d{4}-\d{2}-\d{2}$'));
  });

  testWidgets('the window is fitted to the cheques actually on file', (
    tester,
  ) async {
    final repo = await _openClearing(tester);

    // The register holds one cheque dated 2026-09-02, so that is the window —
    // not a guessed span, which either misses cheques dated beyond it or
    // opens on a stretch with nothing in it. Both read as a broken screen.
    expect(repo.lastFrom, '2026-09-02');
    expect(repo.lastTo, '2026-09-02');
  });

  testWidgets('the window spans the earliest cheque to the latest', (
    tester,
  ) async {
    final repo = _SpreadBillingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeOverrides(),
          billingRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: PdcScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Out of order in the register, and the fit still reaches both ends —
    // every cheque on file is inside the window the screen opens on.
    expect(repo.lastFrom, '2026-07-15');
    expect(repo.lastTo, '2027-01-20');
  });

  testWidgets('a cheque shows its number and date, not a blank', (
    tester,
  ) async {
    await _openClearing(tester);

    // Read from `chqno` and `che_date` — the columns the procedure returns.
    // Looking for `cheque_no` here left both cells empty.
    expect(find.textContaining('1000000'), findsWidgets);
    expect(find.text('Aniket'), findsOneWidget);
    expect(find.textContaining('Due 14'), findsOneWidget);
  });

  testWidgets('an untouched cheque reads as pending', (tester) async {
    await _openClearing(tester);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('the outcome is picked from the row, without opening anything', (
    tester,
  ) async {
    await _openClearing(tester);

    // All three sit on the card, as the website's radio buttons do — the row
    // does not have to be opened first.
    expect(find.text('Deposited'), findsOneWidget);
    expect(find.text('Returned'), findsOneWidget);
    expect(find.text('Bounced'), findsOneWidget);
  });

  testWidgets('depositing is confirmed before it raises a receipt', (
    tester,
  ) async {
    final repo = await _openClearing(tester);

    await tester.tap(find.text('Deposited'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Tapping asks first — nothing has been sent yet.
    expect(find.text('Mark cheque deposited?'), findsOneWidget);
    expect(repo.lastClear, isNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Deposit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repo.lastClearId, 41);
    expect(repo.lastClear?.deposited, isTrue);
    // The server refuses a deposit that does not acknowledge the receipt.
    expect(repo.lastClear?.confirm, isTrue);
  });

  testWidgets('cancelling the confirmation sends nothing', (tester) async {
    final repo = await _openClearing(tester);

    await tester.tap(find.text('Deposited'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repo.lastClear, isNull);
  });

  testWidgets('a bounced cheque is sent as cancelled, and needs no confirm', (
    tester,
  ) async {
    final repo = await _openClearing(tester);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    // "Bounced" is what the website and the legacy page call this outcome;
    // the flag underneath is still che_can.
    await tester.tap(find.text('Bounced'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repo.lastClear?.cancelled, isTrue);
    expect(repo.lastClear?.deposited, isFalse);
    expect(repo.lastClear?.confirm, isFalse);
  });

  testWidgets('clearing reloads the same window it was showing', (
    tester,
  ) async {
    final repo = await _openClearing(tester);
    final openedWith = repo.lastFrom;

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Returned'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repo.lastClear?.returned, isTrue);
    // A reload that dropped the dates would come back empty and the cheque
    // the operator just acted on would vanish.
    expect(repo.lastFrom, openedWith);
    expect(repo.lastFrom, isNotNull);
  });
}
