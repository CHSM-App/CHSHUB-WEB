import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/receipt_entry_screen.dart';

import 'fakes.dart';

/// A flat mid-entry: bills ticked, arrears showing, an advance on file.
class _ShowcaseRepository extends FakeBillingRepository {
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
        'bill_no': '11',
        'BillNo': 'MB-0611',
        'Amount': 1500.00,
        'DueDate': '2026-06-08',
        'Status': 'Overdue',
        'BillType': 1,
      },
      {
        'bill_no': '12',
        'BillNo': 'MB-0712',
        'Amount': 2500.50,
        'DueDate': '2026-07-08',
        'Status': 'Pending',
        'BillType': 1,
      },
      {
        'bill_no': '13',
        'BillNo': 'MB-0713',
        'Amount': 640.00,
        'DueDate': '2026-07-20',
        'Status': 'Pending',
        'BillType': 0,
      },
      {'bill_no': '14', 'Amount': 75.00, 'BillType': 2},
    ],
    count: 4,
  );

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => const RowList(
    items: [
      {'advance': 320.00},
    ],
    count: 1,
  );

  @override
  Future<RowList> getReceiptPdc(int flatId) async => const RowList();
}

Future<void> _shoot(WidgetTester tester, Size size, String name) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeOverrides(),
        billingRepositoryProvider.overrideWithValue(_ShowcaseRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReceiptEntryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Pick the flat, then tick a bill so the summary has something to show.
  await tester.tap(find.byType(DropdownButtonFormField<int>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('A · 101 · A Sharma').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('MB-0611'));
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(ReceiptEntryScreen),
    matchesGoldenFile('golden/$name.png'),
  );
}

/// Load a real font.
///
/// The test environment ships no glyphs, so every Text renders as a filled
/// box — legible as layout, useless as a picture of the design. Roboto sits in
/// the SDK's own cache, which is why it can be loaded without adding an asset
/// to the app.
Future<void> _loadRoboto() async {
  // The test runner is flutter_tester.exe, buried several levels inside
  // bin/cache/artifacts/engine/<platform>/. Rather than count directories —
  // the depth differs by platform — walk up until the cache is in view.
  Directory? dir = File(Platform.resolvedExecutable).parent;
  File? font;

  while (dir != null) {
    for (final name in ['roboto-regular.ttf', 'Roboto-Regular.ttf']) {
      final candidate = File(
        '${dir.path}${Platform.pathSeparator}material_fonts'
        '${Platform.pathSeparator}$name',
      );
      if (candidate.existsSync()) font = candidate;
    }
    if (font != null) break;

    final parent = dir.parent;
    dir = parent.path == dir.path ? null : parent;
  }

  if (font == null) return;

  final bytes = await font.readAsBytes();
  // The theme asks for Roboto by name; Material's own widgets fall back to the
  // engine default, so both names are registered.
  for (final family in ['Roboto', 'packages/secretary_app/Roboto']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadRoboto);

  testWidgets(
    'phone',
    (t) => _shoot(t, const Size(430, 1500), 'receipt-phone'),
  );
  testWidgets(
    'desktop',
    (t) => _shoot(t, const Size(1280, 1000), 'receipt-desktop'),
  );
}
