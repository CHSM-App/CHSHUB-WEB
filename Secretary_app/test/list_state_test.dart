import 'package:flutter_test/flutter_test.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/presentation/viewModels/list_state.dart';

class _VM extends ListViewModel {}

void main() {
  test('loadAll keeps every collection, whatever order they land in', () async {
    final vm = _VM();

    // The regression: both fetches spread the same pre-await snapshot of the
    // collections map, so whichever resolved last erased the other's rows.
    // The receipt screen lost its outstanding bills to the advance lookup this
    // way, and reported "no outstanding bills" over a flat that had two.
    await vm.loadAll({
      'fast': () async => const RowList(
        items: [
          {'k': 'fast'},
        ],
        count: 1,
      ),
      'slow': () async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const RowList(
          items: [
            {'k': 'slow'},
          ],
          count: 1,
        );
      },
    });

    expect(vm.state.items('fast'), [
      {'k': 'fast'},
    ]);
    expect(vm.state.items('slow'), [
      {'k': 'slow'},
    ]);
  });

  test('a failing fetch does not take its siblings down', () async {
    final vm = _VM();

    await vm.loadAll({
      'ok': () async => const RowList(
        items: [
          {'k': 'ok'},
        ],
        count: 1,
      ),
      'bad': () async => throw StateError('boom'),
    });

    expect(vm.state.items('ok'), [
      {'k': 'ok'},
    ]);
    expect(vm.state.rows('bad').error, isNotNull);
  });

  test('every key is marked loading before any fetch resolves', () async {
    final vm = _VM();

    final pending = vm.loadAll({
      'a': () async => const RowList(),
      'b': () async => const RowList(),
    });

    expect(vm.state.isBusy('a'), isTrue);
    expect(vm.state.isBusy('b'), isTrue);
    await pending;
  });

  test(
    'items() returns empty on an errored collection instead of throwing',
    () async {
      final vm = _VM();

      await vm.loadAll({'bad': () async => throw StateError('boom')});

      // The regression: `value` rethrows on an AsyncError, so a screen that
      // called items() to decide what to draw crashed on the very error it was
      // about to render a message about. The receipt screen died this way when
      // its bill lookup failed.
      expect(() => vm.state.items('bad'), returnsNormally);
      expect(vm.state.items('bad'), isEmpty);
      expect(vm.state.rows('bad').error, isNotNull);
    },
  );
}
