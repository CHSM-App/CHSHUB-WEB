import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/defaulter_detail_screen.dart';
import 'package:secretary_app/screens/billing/defaulters_screen.dart';

import 'fakes.dart';

class _Repo extends FakeBillingRepository {
  int? duesAskedFor;

  @override
  Future<RowList> getDefaulters() async => const RowList(
    items: [
      {
        'flat_id': 7,
        'owner_name': 'A Sharma',
        'Unit': 'A-101',
        'pre_mob': '9876543210',
        'email': 'a@example.com',
        'due': 4140.50,
      },
      {
        'flat_id': 8,
        'owner_name': 'B Patel',
        'Unit': 'B-202',
        'pre_mob': '9123456780',
        'due': 900.00,
      },
    ],
    count: 2,
    totalDue: 5040.50,
  );

  @override
  Future<RowList> getOwnerDues(int flatId) async {
    duesAskedFor = flatId;
    return const RowList(
      items: [
        {
          'month': 'June 2026',
          'tax_interest_amt': 30.00,
          'amt_forward': 1500.00,
        },
        {
          'month': 'July 2026',
          'tax_interest_amt': 60.50,
          'amt_forward': 2550.00,
        },
      ],
      count: 2,
    );
  }
}

Future<void> _pump(WidgetTester tester, {_Repo? repo}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeOverrides(),
        billingRepositoryProvider.overrideWithValue(repo ?? _Repo()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DefaultersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('each defaulter offers a view into its dues', (tester) async {
    await _pump(tester);

    expect(find.text('A Sharma'), findsOneWidget);
    expect(find.text('View details'), findsNWidgets(2));
  });

  testWidgets('opening one shows its months, tax and forward amounts', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo: repo);

    await tester.tap(find.text('A Sharma'));
    await tester.pumpAndSettle();

    // The dues were fetched for the flat that was tapped, not another.
    expect(repo.duesAskedFor, 7);
    expect(find.byType(DefaulterDetailScreen), findsOneWidget);

    // The legacy grid's three columns.
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    expect(find.text('Amount Forward'), findsOneWidget);
    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('OUTSTANDING MONTHS (2)'), findsOneWidget);

    // Total is tax + forward, as the legacy page computed it:
    // (30 + 1500) + (60.50 + 2550) = 4,140.50.
    expect(find.text('₹4,140.50'), findsOneWidget);
  });

  testWidgets('selecting flats reveals the reminder actions', (tester) async {
    await _pump(tester);

    // Nothing ticked: no send buttons to press.
    expect(find.byIcon(Icons.sms_outlined), findsNothing);
    expect(find.byIcon(Icons.mail_outline_rounded), findsNothing);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
  });

  testWidgets('select all ticks every flat, and clears again', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsNothing);
  });

  testWidgets('ticking a checkbox does not open the detail page', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // The card opens the breakdown, but the checkbox is its own target —
    // ticking for a reminder must not navigate away mid-selection.
    expect(find.byType(DefaulterDetailScreen), findsNothing);
    expect(find.byType(DefaultersScreen), findsOneWidget);
  });

  testWidgets('emailing a flat with no address on file says so', (
    tester,
  ) async {
    await _pump(tester);

    // B Patel has a mobile but no email.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mail_outline_rounded));
    await tester.pumpAndSettle();

    expect(
      find.text('None of the selected flats has an email address on file.'),
      findsOneWidget,
    );
  });
}
