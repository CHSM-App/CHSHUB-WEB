import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/screens/billing/defaulters_screen.dart';

import 'fakes.dart';

class _Repo extends FakeBillingRepository {
  @override
  Future<RowList> getDefaulters() async => const RowList(
    items: [
      {
        'flat_id': 7,
        'owner_name': 'Anil Sharma',
        'Unit': 'A-101',
        'bed': '2BHK',
        'pre_mob': '9876543210',
        'email': 'anil@example.com',
        'due': 12450.75,
      },
      {
        'flat_id': 8,
        'owner_name': 'Bhavna Patel',
        'Unit': 'B-202',
        'bed': '3BHK',
        'pre_mob': '9123456780',
        'due': 8900.00,
      },
      {
        'flat_id': 9,
        'owner_name': 'Chetan Rao',
        'Unit': 'C-303',
        'bed': '1BHK',
        'pre_mob': '9000011122',
        'due': 4140.50,
      },
    ],
    count: 3,
    totalDue: 84133.00,
  );

  @override
  Future<RowList> getOwnerDues(int flatId) async => const RowList();
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

  testWidgets('defaulters list', (tester) async {
    tester.view.physicalSize = const Size(430, 700);
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
          home: const DefaultersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DefaultersScreen),
      matchesGoldenFile('golden/defaulters.png'),
    );
  });
}
