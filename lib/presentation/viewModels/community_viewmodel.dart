import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/community_requests.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/models/visitor_request.dart';
import '../../domain/usecase/community_usecase.dart';
import 'list_state.dart';

class CommunityKeys {
  static const helpdesk = 'helpdesk';
  static const helpdeskStatuses = 'helpdeskStatuses';
  static const visitors = 'visitors';
  static const notices = 'notices';
  static const noticeRecipients = 'noticeRecipients';
  static const facilities = 'facilities';
  static const bookings = 'bookings';
  static const messages = 'messages';
  static const polls = 'polls';

  /// Each poll's options live in their own collection, so one card loading or
  /// failing to load its options does not disturb the others.
  static String pollOptions(int pollId) => 'pollOptions:$pollId';
  static const suggestions = 'suggestions';
  static const events = 'events';
  static const meetings = 'meetings';
  static const notifications = 'notifications';
  static const nocCertificates = 'nocCertificates';
  static const nocRequests = 'nocRequests';
}

class CommunityViewModel extends ListViewModel {
  final CommunityUsecase usecase;

  /// The ticket currently open, with its comment thread.
  Map<String, dynamic>? openTicket;

  /// Facilities and flats for the booking form.
  Map<String, dynamic>? bookingLookups;

  CommunityViewModel(this.usecase);

  // ===== HELPDESK =====

  /// The list and the statuses it can be moved to - the detail page needs
  /// both, so they load together.
  ///
  /// Fetches the whole list: `GET /helpdesk` runs sp_helpdesk's GetTickets
  /// branch, which takes no search term. The screen filters what it has, as
  /// the website's grid does.
  Future<void> loadHelpdesk() => loadAll({
    CommunityKeys.helpdesk: () => usecase.getHelpdeskTickets(),
    CommunityKeys.helpdeskStatuses: usecase.getHelpdeskStatuses,
  });

  /// The categories and flats the raise-complaint form picks from.
  Map<String, dynamic>? helpdeskLookups;

  Future<bool> loadHelpdeskLookups() {
    return run(
      () async => helpdeskLookups = await usecase.getHelpdeskLookups(),
      guard: 'helpdeskLookups',
    );
  }

  Future<bool> createHelpdeskTicket({
    required int? flatId,
    required int category,
    required String query,
    required String categoryType,
    required bool urgent,
    List<File> images = const [],
  }) {
    return run(
      () => usecase.createHelpdeskTicket(
        flatId: flatId,
        category: category,
        query: query,
        categoryType: categoryType,
        urgent: urgent,
        images: images,
      ),
      guard: 'helpdeskCreate',
      successMessage: 'Complaint raised.',
      onSuccess: loadHelpdesk,
    );
  }

  Future<bool> openHelpdeskTicket(int id) {
    return run(_fetchHelpdeskTicket(id), guard: 'ticket');
  }

  /// Re-reads the open ticket's thread.
  ///
  /// Unguarded, and so safe to await from inside another `run` holding the
  /// 'ticket' guard. Calling [openHelpdeskTicket] there instead returns false
  /// the moment it sees the guard already held, and the thread is never
  /// refetched — which is why a new reply did not appear until the page was
  /// closed and opened again.
  Future<void> Function() _fetchHelpdeskTicket(int id) =>
      () async => openTicket = await usecase.getHelpdeskTicket(id);

  /// Moves a ticket to [status].
  ///
  /// [refreshDetail] re-reads the ticket's thread afterwards, which is what
  /// the open sheet needs to redraw itself. The list does not: it has no
  /// thread on screen, and refetching there would replace [openTicket] with a
  /// ticket the secretary has not opened.
  Future<bool> updateHelpdeskStatus(
    int id,
    int status, {
    bool refreshDetail = true,
  }) {
    return run(
      () => usecase.updateHelpdeskStatus(id, status),
      guard: 'ticket',
      successMessage: 'Status updated.',
      onSuccess: () async {
        await loadHelpdesk();
        if (refreshDetail) await _fetchHelpdeskTicket(id)();
      },
    );
  }

  Future<bool> addHelpdeskComment(int id, String comment, {int? flatId}) {
    return run(
      () => usecase.addHelpdeskComment(id, comment, flatId: flatId),
      guard: 'ticket',
      successMessage: 'Reply posted.',
      onSuccess: _fetchHelpdeskTicket(id),
    );
  }

  // ===== VISITORS =====

  Future<void> loadVisitors({String? search}) =>
      load(CommunityKeys.visitors, () => usecase.getVisitors(search: search));

  Future<bool> createVisitor(VisitorRequest request) {
    return run(
      () => usecase.createVisitor(request),
      guard: 'visitor',
      successMessage: 'Visitor registered.',
      onSuccess: loadVisitors,
    );
  }

  Future<bool> checkoutVisitor(int id) {
    return run(
      () => usecase.checkoutVisitor(id),
      guard: 'visitor',
      successMessage: 'Visitor checked out.',
      onSuccess: loadVisitors,
    );
  }

  Future<bool> deleteVisitor(int id) {
    return run(
      () => usecase.deleteVisitor(id),
      guard: 'visitor',
      successMessage: 'Visitor removed.',
      onSuccess: loadVisitors,
    );
  }

  // ===== NOTICES =====

  Future<void> loadNotices({String? search}) => loadAll({
    CommunityKeys.notices: () => usecase.getNotices(search: search),
    CommunityKeys.noticeRecipients: usecase.getNoticeRecipients,
  });

  /// Publish a notice, and say how far the notification actually reached.
  ///
  /// The push runs on the server after the save and never fails the request,
  /// so "Notice published." alone would read the same whether it reached the
  /// whole society or nobody at all. The count comes back in the reply, so it
  /// is reported instead of assumed.
  Future<bool> createNotice(NoticeRequest request) {
    Map<String, dynamic>? reply;

    return run(
      () async => reply = await usecase.createNotice(request),
      guard: 'notice',
      onSuccess: loadNotices,
    ).then((ok) {
      if (ok) {
        state = state.copyWith(message: _publishMessage(reply));
      }
      return ok;
    });
  }

  /// The confirmation for a published item, given the server's `notified`
  /// summary — `{sent, failed, recipients, pushable}`.
  ///
  /// `recipients` counts everyone the notice was filed for, `pushable` those
  /// with a device token and `sent` the pushes that landed. Residents without
  /// a token still see it in the app when they next open it, so a zero push
  /// is not a failure worth alarming anyone about — it just must not be
  /// reported as a delivery.
  static String _publishMessage(
    Map<String, dynamic>? reply, {
    String noun = 'Notice',
    String verb = 'published',
  }) {
    final notified = reply?['notified'];
    if (notified is! Map) return '$noun $verb.';

    int count(String key) => (notified[key] as num?)?.toInt() ?? 0;

    final sent = count('sent');
    final recipients = count('recipients');

    if (recipients == 0) return '$noun $verb. No one in that group yet.';
    if (sent == 0) {
      return '$noun $verb to $recipients '
          '${recipients == 1 ? 'resident' : 'residents'} — '
          'they will see it in the app.';
    }
    return '$noun $verb. $sent '
        '${sent == 1 ? 'resident' : 'residents'} notified.';
  }

  Future<bool> updateNotice(int id, NoticeRequest request) {
    return run(
      () => usecase.updateNotice(id, request),
      guard: 'notice',
      successMessage: 'Notice updated.',
      onSuccess: loadNotices,
    );
  }

  Future<bool> deleteNotice(int id) {
    return run(
      () => usecase.deleteNotice(id),
      guard: 'notice',
      successMessage: 'Notice deleted.',
      onSuccess: loadNotices,
    );
  }

  // ===== NOC CERTIFICATES =====

  /// The certificate the server most recently issued — `{noc_id, serial_no}`.
  ///
  /// Held so the screen can open the letter it just created with the number
  /// the server allocated, which the form could not know in advance.
  Map<String, dynamic>? issuedNoc;

  Future<void> loadNocCertificates({String? search}) => load(
    CommunityKeys.nocCertificates,
    () => usecase.getNocCertificates(search: search),
  );

  Future<bool> createNocCertificate(NocRequest request) {
    issuedNoc = null;

    return run(
      () async => issuedNoc = await usecase.createNocCertificate(request),
      guard: 'noc',
      successMessage: 'Certificate issued.',
      onSuccess: loadNocCertificates,
    );
  }

  Future<bool> updateNocCertificate(int id, NocRequest request) {
    return run(
      () => usecase.updateNocCertificate(id, request),
      guard: 'noc',
      successMessage: 'Certificate updated.',
      onSuccess: loadNocCertificates,
    );
  }

  Future<bool> deleteNocCertificate(int id) {
    return run(
      () => usecase.deleteNocCertificate(id),
      guard: 'noc',
      successMessage: 'Certificate deleted.',
      onSuccess: loadNocCertificates,
    );
  }

  // ===== NOC REQUESTS =====

  /// The certificate the last approval issued — `{noc_id, serial_no}`, or
  /// null when that decision did not settle the request.
  ///
  /// Held so the screen can open the letter the committee has just approved
  /// with the number the server allocated, which the client cannot know in
  /// advance.
  Map<String, dynamic>? decidedNoc;

  /// Committee accounts that can be asked to decide, for the approver picker.
  Future<RowList> getNocApproverOptions() => usecase.getNocApproverOptions();

  Future<void> loadNocRequests({String? search}) => load(
    CommunityKeys.nocRequests,
    () => usecase.getNocRequests(search: search),
  );

  /// One request with its approvals, for the review screen.
  Future<Map<String, dynamic>> getNocRequest(int id) =>
      usecase.getNocRequest(id);

  Future<bool> updateNocRequestDraft(int id, NocDraftRequest request) {
    return run(
      () => usecase.updateNocRequestDraft(id, request),
      guard: 'nocRequest',
      successMessage: 'Draft saved.',
      onSuccess: loadNocRequests,
    );
  }

  Future<bool> setNocRequestApprovers(int id, NocApproversRequest request) {
    return run(
      () => usecase.setNocRequestApprovers(id, request),
      guard: 'nocRequest',
      successMessage: 'Sent for approval.',
      onSuccess: loadNocRequests,
    );
  }

  /// Record this approver's answer.
  ///
  /// [decidedNoc] is set only when the answer settled the request and a
  /// certificate was issued, so the screen can tell "approved, and here is the
  /// certificate" from "approved, still waiting on others".
  Future<bool> decideNocRequest(
    int id,
    int approvalId,
    NocDecisionRequest request,
  ) {
    decidedNoc = null;

    return run(
      () async {
        final reply = await usecase.decideNocRequest(id, approvalId, request);
        if (reply['noc_id'] != null) decidedNoc = reply;
      },
      guard: 'nocRequest',
      successMessage: request.decision == 'approve'
          ? 'Approved.'
          : 'Rejected.',
      onSuccess: loadNocRequests,
    );
  }

  Future<bool> setNocRequestReady(int id, NocReadyRequest request) {
    return run(
      () => usecase.setNocRequestReady(id, request),
      guard: 'nocRequest',
      successMessage: 'The member has been told when to collect it.',
      onSuccess: loadNocRequests,
    );
  }

  Future<bool> setNocRequestCollected(int id, NocCollectedRequest request) {
    return run(
      () => usecase.setNocRequestCollected(id, request),
      guard: 'nocRequest',
      successMessage: 'Marked as collected.',
      onSuccess: loadNocRequests,
    );
  }

  Future<bool> deleteNocRequest(int id) {
    return run(
      () => usecase.deleteNocRequest(id),
      guard: 'nocRequest',
      successMessage: 'Request deleted.',
      onSuccess: loadNocRequests,
    );
  }

  // ===== EVENTS =====

  Future<void> loadEvents({String? search}) =>
      load(CommunityKeys.events, () => usecase.getEvents(search: search));

  /// Schedule an event, and say how far the notification actually reached —
  /// the same reporting a published notice gets, for the same reason.
  Future<bool> createEvent(EventRequest request) {
    Map<String, dynamic>? reply;

    return run(
      () async => reply = await usecase.createEvent(request),
      guard: 'event',
      onSuccess: loadEvents,
    ).then((ok) {
      if (ok) {
        state = state.copyWith(
          message: _publishMessage(reply, noun: 'Event', verb: 'scheduled'),
        );
      }
      return ok;
    });
  }

  Future<bool> updateEvent(int id, EventRequest request) {
    return run(
      () => usecase.updateEvent(id, request),
      guard: 'event',
      successMessage: 'Event updated.',
      onSuccess: loadEvents,
    );
  }

  Future<bool> deleteEvent(int id) {
    return run(
      () => usecase.deleteEvent(id),
      guard: 'event',
      successMessage: 'Event deleted.',
      onSuccess: loadEvents,
    );
  }

  // ===== MEETINGS =====

  Future<void> loadMeetings({String? search}) =>
      load(CommunityKeys.meetings, () => usecase.getMeetings(search: search));

  /// Call a meeting. The server notifies the whole society rather than a
  /// chosen group, so the count reported here covers everyone.
  Future<bool> createMeeting(MeetingRequest request) {
    Map<String, dynamic>? reply;

    return run(
      () async => reply = await usecase.createMeeting(request),
      guard: 'meeting',
      onSuccess: loadMeetings,
    ).then((ok) {
      if (ok) {
        state = state.copyWith(
          message: _publishMessage(reply, noun: 'Meeting', verb: 'called'),
        );
      }
      return ok;
    });
  }

  Future<bool> updateMeeting(int id, MeetingRequest request) {
    return run(
      () => usecase.updateMeeting(id, request),
      guard: 'meeting',
      successMessage: 'Meeting updated.',
      onSuccess: loadMeetings,
    );
  }

  Future<bool> deleteMeeting(int id) {
    return run(
      () => usecase.deleteMeeting(id),
      guard: 'meeting',
      successMessage: 'Meeting cancelled.',
      onSuccess: loadMeetings,
    );
  }

  // ===== FACILITY BOOKINGS =====

  Future<void> loadBookings({String? search}) => loadAll({
    CommunityKeys.bookings: () => usecase.getFacilityBookings(search: search),
    CommunityKeys.facilities: usecase.getFacilities,
  });

  Future<bool> loadBookingLookups() {
    return run(
      () async => bookingLookups = await usecase.getFacilityBookingLookups(),
      guard: 'bookingLookups',
    );
  }

  Future<bool> createBooking(FacilityBookingRequest request) {
    return run(
      () => usecase.createFacilityBooking(request),
      guard: 'booking',
      successMessage: 'Facility booked.',
      onSuccess: loadBookings,
    );
  }

  Future<bool> deleteBooking(int id) {
    return run(
      () => usecase.deleteFacilityBooking(id),
      guard: 'booking',
      successMessage: 'Booking cancelled.',
      onSuccess: loadBookings,
    );
  }

  // ===== THE REST =====

  Future<void> loadMessages() =>
      load(CommunityKeys.messages, usecase.getMessages);

  /// Mark one message read, clearing its "New" mark where it sits.
  ///
  /// Unlike a notification, a read message stays on the list — GetMessages
  /// returns every message, read or not — so the row is rewritten in place
  /// rather than dropped. It is done before the call rather than after: the
  /// user opened the message, so it *has* been read, and waiting for the
  /// round trip leaves the badge sitting under the sheet that just showed it.
  ///
  /// A failure is swallowed for the same reason it is on the bell: the true
  /// value comes back on the next load, and there is nothing the user could
  /// usefully do about it here.
  Future<void> markMessageRead(int id) async {
    final rows = state.items(CommunityKeys.messages);

    state = state.withCollection(
      CommunityKeys.messages,
      AsyncValue.data(
        RowList(
          items: [
            for (final r in rows)
              if (asInt(r['r_id'] ?? r['id']) == id)
                {...r, 'view_status': 1}
              else
                r,
          ],
          count: rows.length,
        ),
      ),
    );

    try {
      await usecase.markMessageRead(id);
    } catch (_) {
      // Best effort: the next load says what the server actually holds.
    }
  }

  /// The polls, and then the options of each one.
  ///
  /// The options are part of this rather than left to the screen: every path
  /// that reloads the list — starting a poll, deleting one, casting a vote —
  /// should leave every card able to draw its bars, and a poll that arrived
  /// after the screen first loaded would otherwise sit on its placeholders.
  Future<void> loadPolls() async {
    await load(CommunityKeys.polls, usecase.getPolls);

    final ids = <int>{
      for (final row in state.items(CommunityKeys.polls))
        ?asInt(row['PollId'] ?? row['poll_id'] ?? row['pollId'] ?? row['id']),
    };

    await Future.wait([for (final id in ids) loadPollOptions(id)]);
  }

  /// The options on one poll, with their vote counts.
  Future<void> loadPollOptions(int pollId) => load(
    CommunityKeys.pollOptions(pollId),
    () => usecase.getPollVotes(pollId),
  );

  /// Cast a vote, then re-read that poll's options so the bars move.
  ///
  /// Every rule — one vote per flat, whether a second vote is allowed — is
  /// enforced by sp_PollVoting, which answers a refusal as a 400. This sends
  /// the tap and lets `run` surface whatever the server says, rather than
  /// trying to pre-judge it from the row.
  ///
  /// The poll list is refetched too: its vote total is a column on the poll
  /// row, so it would otherwise still show the count from before the vote.
  Future<bool> votePoll(int pollId, int optionId) {
    return run(
      () => usecase.votePoll(pollId, optionId),
      guard: 'poll-vote',
      successMessage: 'Your vote has been recorded.',
      // loadPolls refetches every poll's options as well, so the bars and the
      // tally under them both move.
      onSuccess: loadPolls,
    );
  }

  /// Start a poll, and say how many residents the alert reached.
  ///
  /// POST /community/polls answers `notified` as a plain count rather than the
  /// `{sent, recipients, …}` summary a notice returns — the legacy page pushed
  /// best-effort and reported only a total — so this counts rather than
  /// reusing [_publishMessage].
  Future<bool> createPoll(PollRequest request) {
    Map<String, dynamic>? reply;

    return run(
      () async => reply = await usecase.createPoll(request),
      guard: 'poll',
      onSuccess: loadPolls,
    ).then((ok) {
      if (ok) {
        final sent = (reply?['notified'] as num?)?.toInt() ?? 0;
        state = state.copyWith(
          message: sent == 0
              ? 'Poll started. Residents will see it in the app.'
              : 'Poll started. $sent '
                    '${sent == 1 ? 'resident' : 'residents'} notified.',
        );
      }
      return ok;
    });
  }

  Future<bool> deletePoll(int id) {
    return run(
      () => usecase.deletePoll(id),
      guard: 'poll',
      successMessage: 'Poll deleted.',
      onSuccess: loadPolls,
    );
  }

  Future<void> loadSuggestions({String? search}) => load(
    CommunityKeys.suggestions,
    () => usecase.getSuggestions(search: search),
  );

  /// File a suggestion, then re-read the list so the new one is on it.
  ///
  /// The guard is shared with the edit and the delete: all three write the
  /// same list, and a second tap while one is still in flight would reorder
  /// what the reload lands on.
  Future<bool> createSuggestion(SuggestionRequest request) {
    return run(
      () => usecase.createSuggestion(request),
      guard: 'suggestion',
      successMessage: 'Suggestion added.',
      onSuccess: loadSuggestions,
    );
  }

  Future<bool> updateSuggestion(int id, SuggestionRequest request) {
    return run(
      () => usecase.updateSuggestion(id, request),
      guard: 'suggestion',
      successMessage: 'Suggestion updated.',
      onSuccess: loadSuggestions,
    );
  }

  Future<bool> deleteSuggestion(int id) {
    return run(
      () => usecase.deleteSuggestion(id),
      guard: 'suggestion',
      successMessage: 'Suggestion deleted.',
      onSuccess: loadSuggestions,
    );
  }

  Future<void> loadNotifications() =>
      load(CommunityKeys.notifications, usecase.getNotifications);

  /// Marks one read and drops it from the list.
  ///
  /// The row goes immediately rather than after a refetch: the server only
  /// returns unseen rows, so a reload would drop it anyway, and waiting for
  /// the round trip leaves the item sitting under the tap that dismissed it.
  Future<void> markNotificationSeen(int id) async {
    final rows = state.items(CommunityKeys.notifications);

    state = state.withCollection(
      CommunityKeys.notifications,
      AsyncValue.data(
        RowList(
          items: [
            for (final r in rows)
              // The bell's own key. Read straight rather than through pick():
              // this is our endpoint and it always names the column.
              if (asInt(r['notify_status_id'] ?? r['id']) != id) r,
          ],
          count: rows.length - 1,
        ),
      ),
    );

    try {
      await usecase.markNotificationSeen(id);
    } catch (_) {
      // Best effort: it reappears on the next load if the call failed.
    }
  }
}
