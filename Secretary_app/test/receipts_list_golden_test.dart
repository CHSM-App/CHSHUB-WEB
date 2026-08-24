import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/receipts_screen.dart';

import 'fakes.dart';

class _Repo extends FakeBillingRepository {
  @override
  Future<RowList> getReceipts() async => const RowList(
    items: [
      {
        'receipt_id': 1,
        'receipt_no': 'RCPT-2026-0088',
        'receipt_date': '2026-08-21',
        'paid_amount': 996.15,
        'flat_no': '101',
        'building_name': 'A',
        'owner': 'A Sharma',
        'transaction_ref': '556677',
        'pay_mode': 'Cheque',
      },
      {
        'receipt_id': 2,
        'receipt_no': 'RCPT-2026-0086',
        'receipt_date': '2026-08-08',
        'paid_amount': 2292.30,
        'flat_no': '202',
        'building_name': 'B',
        'owner': 'B Patel',
        'transaction_ref': '901234',
        'pay_mode': 'PDC',
      },
      {
        'receipt_id': 3,
        'receipt_no': 'RCPT-2026-0087',
        'receipt_date': '2026-08-08',
        'paid_amount': 1000.00,
        'flat_no': '303',
        'building_name': 'C',
        'owner': 'C Rao',
        'pay_mode': 'Cheque',
      },
      {
        'receipt_id': 4,
        'receipt_no': 'RCPT-2026-0082',
        'receipt_date': '2026-06-11',
        'paid_amount': 996.15,
        'flat_no': '404',
        'building_name': 'D',
        'owner': 'D Mehta',
        'transaction_ref': '778899',
        'bill_status': 'Cancelled',
      },
    ],
    count: 4,
    totalCollected: 13751.88,
  );
}

Future<void> _loadRoboto() async {
  Directory? dir = File(Platform.resolvedExecutable).parent;
  File? font;
  while (dir != null) {
    for (final name in ['roboto-regular.ttf', 'Roboto-Regular.ttf']) {
      final f = File(
        '${dir.path}${Platform.pathSeparator}material_fonts'
        '${Platform.pathSeparator}$name',
      );
      if (f.existsSync()) font = f;
    }
    if (font != null) break;
    final parent = dir.parent;
    dir = parent.path == dir.path ? null : parent;
  }
  if (font == null) return;

  final bytes = await font.readAsBytes();
  for (final family in ['Roboto', 'packages/secretary_app/Roboto']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadRoboto);

  testWidgets('receipts list', (tester) async {
    tester.view.physicalSize = const Size(430, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeOverrides(),
          billingRepositoryProvider.overrideWithValue(_Repo()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReceiptsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ReceiptsScreen),
      matchesGoldenFile('golden/receipts-list.png'),
    );
  });
}
