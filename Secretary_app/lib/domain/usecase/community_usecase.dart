import 'dart:io';

import '../models/community_requests.dart';
import '../models/paged_rows.dart';
import '../models/visitor_request.dart';
import '../repository/community_repo.dart';

class CommunityUsecase {
  final CommunityRepository repository;

  CommunityUsecase(this.repository);

  // ===== HELPDESK =====

  /// Resident complaints, newest first.
  Future<RowList> getHelpdeskTickets() => repository.getHelpdeskTickets();

  /// The statuses a ticket can be moved to.
  Future<RowList> getHelpdeskStatuses() => repository.getHelpdeskStatuses();

  /// The categories and flats the raise-complaint form picks from.
  Future<Map<String, dynamic>> getHelpdeskLookups() =>
      repository.getHelpdeskLookups();

  /// One ticket with its comment thread and images.
  Future<Map<String, dynamic>> getHelpdeskTicket(int id) =>
      repository.getHelpdeskTicket(id);

  /// Raise a complaint on a resident's behalf, with any photos attached.
  ///
  /// The photos go up after the ticket exists, since each row in
  /// HelpdeskImages is keyed by its id. A ticket with no id back — which the
  /// SP should not do — keeps the complaint rather than failing the whole
  /// thing over its attachments.
  Future<void> createHelpdeskTicket({
    required int? flatId,
    required int category,
    required String query,
    required String categoryType,
    required bool urgent,
    List<File> images = const [],
  }) async {
    final id = await repository.createHelpdeskTicket(
      HelpdeskCreateRequest(
        flatId: flatId,
        category: category,
        query: query,
        categoryType: categoryType,
        urgency: urgent ? 1 : 0,
      ),
    );

    if (id != null && images.isNotEmpty) {
      await repository.attachHelpdeskImages(id, images);
    }
  }

  /// Move a ticket to another status.
  Future<void> updateHelpdeskStatus(int id, int status) => repository
      .updateHelpdeskStatus(id, HelpdeskStatusRequest(status: status));

  /// Reply on a ticket as the committee.
  Future<void> addHelpdeskComment(int id, String comment, {int? flatId}) {
    return repository.addHelpdeskComment(
      id,
      HelpdeskCommentRequest(comment: comment, flatId: flatId),
    );
  }

  // ===== VISITORS =====

  /// Visitor entries at the gate.
  Future<RowList> getVisitors({String? search}) =>
      repository.getVisitors(search: search);

  /// Register a visitor.
  Future<void> createVisitor(VisitorRequest request) =>
      repository.createVisitor(request);

  /// Stamp a visitor out.
  Future<void> checkoutVisitor(int id) => repository.checkoutVisitor(id);

  Future<void> deleteVisitor(int id) => repository.deleteVisitor(id);

  // ===== NOTICES =====

  /// Notices and announcements on the board.
  Future<RowList> getNotices({String? search}) =>
      repository.getNotices(search: search);

  /// Audience groups a notice can be sent to.
  Future<RowList> getNoticeRecipients() => repository.getNoticeRecipients();

  /// Publish a notice; the server pushes it to the chosen audience and
  /// reports how far that push got.
  Future<Map<String, dynamic>> createNotice(NoticeRequest request) =>
      repository.createNotice(request);

  Future<void> updateNotice(int id, NoticeRequest request) =>
      repository.updateNotice(id, request);

  Future<void> deleteNotice(int id) => repository.deleteNotice(id);

  // ===== NOC CERTIFICATES =====

  /// The no-objection certificates the society has issued.
  Future<RowList> getNocCertificates({String? search}) =>
      repository.getNocCertificates(search: search);

  /// Issue a certificate; the server allocates its number and returns it.
  Future<Map<String, dynamic>> createNocCertificate(NocRequest request) =>
      repository.createNocCertificate(request);

  Future<void> updateNocCertificate(int id, NocRequest request) =>
      repository.updateNocCertificate(id, request);

  Future<void> deleteNocCertificate(int id) =>
      repository.deleteNocCertificate(id);

  // ===== NOC REQUESTS =====

  /// Committee accounts that can be asked to decide on a request.
  Future<RowList> getNocApproverOptions() => repository.getNocApproverOptions();

  /// What members have asked for, need-an-answer first.
  Future<RowList> getNocRequests({String? search}) =>
      repository.getNocRequests(search: search);

  /// One request together with who was asked to decide on it.
  Future<Map<String, dynamic>> getNocRequest(int id) =>
      repository.getNocRequest(id);

  /// The wording, editable only while the request is still pending.
  Future<void> updateNocRequestDraft(int id, NocDraftRequest request) =>
      repository.updateNocRequestDraft(id, request);

  /// Name who must decide on a request.
  Future<Map<String, dynamic>> setNocRequestApprovers(
    int id,
    NocApproversRequest request,
  ) => repository.setNocRequestApprovers(id, request);

  /// Approve or reject. The reply carries the certificate's serial when this
  /// answer was the last one outstanding.
  Future<Map<String, dynamic>> decideNocRequest(
    int id,
    int approvalId,
    NocDecisionRequest request,
  ) => repository.decideNocRequest(id, approvalId, request);

  /// The letter is signed; give the member a collection appointment.
  Future<void> setNocRequestReady(int id, NocReadyRequest request) =>
      repository.setNocRequestReady(id, request);

  /// It was handed over.
  Future<void> setNocRequestCollected(int id, NocCollectedRequest request) =>
      repository.setNocRequestCollected(id, request);

  Future<void> deleteNocRequest(int id) => repository.deleteNocRequest(id);

  // ===== FACILITY BOOKINGS =====

  /// Bookable facilities.
  Future<RowList> getFacilities() => repository.getFacilities();

  /// Bookings on the calendar.
  Future<RowList> getFacilityBookings({String? search}) =>
      repository.getFacilityBookings(search: search);

  /// Facilities and flats for the booking form.
  Future<Map<String, dynamic>> getFacilityBookingLookups() =>
      repository.getFacilityBookingLookups();

  /// Book a facility for a resident.
  Future<void> createFacilityBooking(FacilityBookingRequest request) =>
      repository.createFacilityBooking(request);

  Future<void> deleteFacilityBooking(int id) =>
      repository.deleteFacilityBooking(id);

  // ===== THE REST =====

  /// Messages residents sent to the committee.
  Future<RowList> getMessages() => repository.getMessages();

  /// Mark one message read, so it stops counting against the unread badge.
  Future<void> markMessageRead(int id) => repository.markMessageRead(id);

  Future<RowList> getPolls() => repository.getPolls();

  /// The options on a poll, each with its vote count and whether this user
  /// picked it. Kept separate from [getPolls] because sp_polls answers the
  /// list and the options in two different modes.
  Future<RowList> getPollVotes(int id) => repository.getPollVotes(id);

  Future<void> votePoll(int id, int optionId) =>
      repository.votePoll(id, optionId);

  /// Start a poll; the server creates its options and notifies the audience.
  Future<Map<String, dynamic>> createPoll(PollRequest request) =>
      repository.createPoll(request);

  Future<void> deletePoll(int id) => repository.deletePoll(id);

  /// Suggestions and requests residents have put to the committee.
  Future<RowList> getSuggestions({String? search}) =>
      repository.getSuggestions(search: search);

  /// File a suggestion — the subject and details suggestion_request.aspx
  /// asked for. The society comes off the token, not the form.
  Future<void> createSuggestion(SuggestionRequest request) =>
      repository.createSuggestion(request);

  Future<void> updateSuggestion(int id, SuggestionRequest request) =>
      repository.updateSuggestion(id, request);

  Future<void> deleteSuggestion(int id) => repository.deleteSuggestion(id);

  /// Festivals and gatherings on the society calendar.
  Future<RowList> getEvents({String? search}) =>
      repository.getEvents(search: search);

  /// Schedule an event; the server pushes it to residents and reports how
  /// far that reached.
  Future<Map<String, dynamic>> createEvent(EventRequest request) =>
      repository.createEvent(request);

  Future<void> updateEvent(int id, EventRequest request) =>
      repository.updateEvent(id, request);

  Future<void> deleteEvent(int id) => repository.deleteEvent(id);

  /// Committee and general body meetings.
  Future<RowList> getMeetings({String? search}) =>
      repository.getMeetings(search: search);

  /// Call a meeting. The server notifies the whole society - there is no
  /// audience picker, as on the website.
  Future<Map<String, dynamic>> createMeeting(MeetingRequest request) =>
      repository.createMeeting(request);

  Future<void> updateMeeting(int id, MeetingRequest request) =>
      repository.updateMeeting(id, request);

  Future<void> deleteMeeting(int id) => repository.deleteMeeting(id);

  Future<RowList> getNotifications() => repository.getNotifications();

  /// Mark one notification read, so the bell stops counting it.
  Future<void> markNotificationSeen(int id) =>
      repository.markNotificationSeen(id);
}
