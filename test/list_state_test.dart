import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:secretary_app/domain/models/json_utils.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/domain/usecase/community_usecase.dart';
import 'package:secretary_app/presentation/viewModels/community_viewmodel.dart';
import 'package:secretary_app/presentation/viewModels/list_state.dart';
import 'package:secretary_app/widgets/app_widgets.dart';

import 'fakes.dart';

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

  test('a reply shows without reopening the ticket', () async {
    final vm = CommunityViewModel(CommunityUsecase(FakeCommunityRepository()));

    await vm.openHelpdeskTicket(7);
    expect(asRows(vm.openTicket!['comments']), isEmpty);

    await vm.addHelpdeskComment(7, 'We have sent a plumber.');

    // The regression: addHelpdeskComment ran inside `run(guard: 'ticket')` and
    // its onSuccess called openHelpdeskTicket, which asks for the same guard.
    // `run` sees the guard already held and returns false without fetching, so
    // the thread was never re-read and a posted reply only appeared after the
    // page was closed and opened again.
    final comments = asRows(vm.openTicket!['comments']);
    expect(comments, hasLength(1));
    expect(comments.single['description'], 'We have sent a plumber.');
  });

  test('a status change from the ticket page refreshes its thread', () async {
    final repo = FakeCommunityRepository();
    final vm = CommunityViewModel(CommunityUsecase(repo));

    await vm.openHelpdeskTicket(7);
    final before = repo.helpdeskTicketFetches;

    await vm.updateHelpdeskStatus(7, 3);

    // Same nested-guard bug: the page kept showing the old status.
    expect(repo.helpdeskTicketFetches, greaterThan(before));
    expect(asRow(vm.openTicket!['ticket'])['status'], 3);
  });

  test('a status change from the list leaves the open ticket alone', () async {
    final repo = FakeCommunityRepository();
    final vm = CommunityViewModel(CommunityUsecase(repo));

    final before = repo.helpdeskTicketFetches;
    await vm.updateHelpdeskStatus(7, 3, refreshDetail: false);

    // The list has no thread on screen, so fetching one would only overwrite
    // `openTicket` with a ticket the secretary has not opened.
    expect(repo.helpdeskTicketFetches, before);
    expect(vm.openTicket, isNull);
  });

  test('the complaint types drop the trailing null row', () async {
    final vm = CommunityViewModel(CommunityUsecase(FakeCommunityRepository()));

    await vm.loadHelpdeskLookups();
    final categories = asRows(vm.helpdeskLookups!['categories']);

    // sp_usefull_contact's ComplaintType branch ends with an all-null row.
    // Offered as-is it would be a blank, unselectable entry under the real
    // types, so the picker keeps only rows that carry an id.
    final offered = categories
        .where((c) => pickInt(c, ['c_type_id', 'p_type_id', 'id']) != null)
        .toList();

    expect(categories, hasLength(3));
    expect(offered, hasLength(2));
    expect(offered.first['c_type_name'], 'Maintenance Issues');
  });

  test('a read notification leaves the bell immediately', () async {
    final repo = FakeCommunityRepository();
    final vm = CommunityViewModel(CommunityUsecase(repo));

    await vm.loadNotifications();
    final before = vm.state.items(CommunityKeys.notifications);
    final id = asInt(before.first['notify_status_id'] ?? before.first['id']);

    await vm.markNotificationSeen(id!);

    // Dropped from the list without waiting for a refetch: the server only
    // returns unseen rows, so a reload would drop it anyway, and leaving it
    // under the tap that dismissed it reads as a dead control.
    final after = vm.state.items(CommunityKeys.notifications);
    expect(after, hasLength(before.length - 1));
    expect(repo.seenNotifications, [id]);
  });

  test('a community complaint is raised without a flat', () async {
    final repo = FakeCommunityRepository();
    final vm = CommunityViewModel(CommunityUsecase(repo));

    await vm.createHelpdeskTicket(
      flatId: null,
      category: 1,
      query: 'The lift is out.',
      categoryType: 'community',
      urgent: false,
    );

    // The lift belongs to the society, not to a flat, so the form does not
    // ask for one and the body carries no flatId at all.
    expect(repo.createdHelpdeskTickets.single.flatId, isNull);
    expect(repo.createdHelpdeskTickets.single.categoryType, 'community');
  });

  test('a personal complaint still names its flat', () async {
    final repo = FakeCommunityRepository();
    final vm = CommunityViewModel(CommunityUsecase(repo));

    await vm.createHelpdeskTicket(
      flatId: 5,
      category: 1,
      query: 'Tap is leaking.',
      categoryType: 'personal',
      urgent: false,
    );

    expect(repo.createdHelpdeskTickets.single.flatId, 5);
  });

  test('photos are attached to the ticket they were raised with', () async {
    final repo = FakeCommunityRepository();
    final vm = CommunityViewModel(CommunityUsecase(repo));

    await vm.createHelpdeskTicket(
      flatId: 5,
      category: 1,
      query: 'Tap is leaking.',
      categoryType: 'personal',
      urgent: true,
      images: [File('a.jpg'), File('b.jpg')],
    );

    // HelpdeskImages rows are keyed by helpdesk_id, so the photos can only go
    // up once the ticket exists and has given one back.
    expect(repo.createdHelpdeskTickets.single.urgency, 1);
    expect(repo.attachedHelpdeskImages[7], hasLength(2));
  });

  test('a complaint with no photos sends no upload', () async {
    final repo = FakeCommunityRepository();
    final vm = CommunityViewModel(CommunityUsecase(repo));

    await vm.createHelpdeskTicket(
      flatId: 5,
      category: 1,
      query: 'Tap is leaking.',
      categoryType: 'personal',
      urgent: false,
    );

    expect(repo.attachedHelpdeskImages, isEmpty);
  });
}
