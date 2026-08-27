import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secretary_app/core/theme/app_theme.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/presentation/providers/viewmodel_provider.dart';
import 'package:secretary_app/screens/community/noc_certificate_screen.dart';

import 'fakes.dart';

/// The repo the screen sees when the NOC table has not been created yet.
class _ThrowingRepo extends FakeCommunityRepository {
  @override
  Future<RowList> getNocCertificates({String? search}) async =>
      throw Exception('Invalid object name dbo.noc_certificate.');
}

void main() {
  test('loadNocCertificates swallows the failure into the collection', () async {
    final container = ProviderContainer(
      overrides: [
        ...fakeOverrides(),
        communityRepositoryProvider.overrideWithValue(_ThrowingRepo()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(communityViewModelProvider.notifier)
        .loadNocCertificates();

    final rows = container.read(communityViewModelProvider).rows('nocCertificates');
    expect(rows.hasError, isTrue);
  });

  testWidgets('NOC list survives the table not existing', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeOverrides(),
          communityRepositoryProvider.overrideWithValue(_ThrowingRepo()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NocCertificateScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(find.text('Could not load'), findsOneWidget);
  });
}
