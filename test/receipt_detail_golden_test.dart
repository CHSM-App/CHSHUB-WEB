import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/receipt_detail_screen.dart';

import 'fakes.dart';

class _Repo extends FakeBillingRepository {
  @override
  Future<Map<String, dynamic>> getReceipt(int id) async => {
    'receipt': {
      'receipt_no': 'RCP-0142',
      'date': '2026-08-12',
      'bill_status': 'Paid',
      'name': 'A Sharma',
      'unit': 'A-101',
      'society_name': 'Green Acres CHS',
      'pay_mode': 'Cheque',
      'transaction_ref': '556677',
      'bank_name': 'HDFC Bank',
      'paid_amount': 4140.50,
    },
    'lines': [
      {'Billno': 'MB-0611', 'bill_ref': 'June 2026', 'amount': 1500.00},
      {'Billno': 'MB-0712', 'bill_ref': 'July 2026', 'amount': 2500.50},
      {'Billno': 'MB-0713', 'bill_ref': 'July 2026', 'amount': 140.00},
    ],
  };
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

  testWidgets('receipt page', (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
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
          home: const ReceiptDetailScreen(receiptId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ReceiptDetailScreen),
      matchesGoldenFile('golden/receipt-detail.png'),
    );
  });
}
