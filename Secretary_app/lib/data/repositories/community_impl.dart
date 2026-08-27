import 'dart:io';

import '../../domain/models/community_requests.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/models/visitor_request.dart';
import '../../domain/repository/community_repo.dart';
import '../api/api_service.dart';

class CommunityImpl implements CommunityRepository {
  final ApiService api;

  CommunityImpl(this.api);

  // ===== HELPDESK =====

  @override
  Future<RowList> getHelpdeskTickets() => api.getHelpdeskTickets();

  @override
  Future<RowList> getHelpdeskStatuses() => api.getHelpdeskStatuses();

  @override
  Future<Map<String, dynamic>> getHelpdeskLookups() async {
    return asRow(await api.getHelpdeskLookups());
  }

  @override
  Future<Map<String, dynamic>> getHelpdeskTicket(int id) async {
    return asRow(await api.getHelpdeskTicket(id));
  }

  @override
  Future<int?> createHelpdeskTicket(HelpdeskCreateRequest request) async {
    // The new id, so photos picked on the form can be attached to it. The
    // field is read straight rather than through pick(): this is our own
    // endpoint and it answers with `helpdesk_id` or nothing.
    final created = asRow(await api.createHelpdeskTicket(request));
    final id = created['helpdesk_id'];

    return id is int ? id : int.tryParse('$id');
  }

  @override
  Future<void> attachHelpdeskImages(int helpdeskId, List<File> files) async {
    if (files.isEmpty) return;

    // One multipart request for all of them — the uploader takes up to ten —
    // then one small record call per stored path.
    final stored = asRows(asRow(await api.uploadHelpdeskImages(files))['items']);

    for (final item in stored) {
      final path = item['path'];
      if (path is! String || path.isEmpty) continue;

      await api.recordHelpdeskImage(
        HelpdeskImageRequest(helpdeskId: helpdeskId, docPath: path),
      );
    }
  }

  @override
  Future<void> updateHelpdeskStatus(int id, HelpdeskStatusRequest request) =>
      api.updateHelpdeskStatus(id, request);

  @override
  Future<void> addHelpdeskComment(int id, HelpdeskCommentRequest request) =>
      api.addHelpdeskComment(id, request);

  // ===== VISITORS =====

  @override
  Future<RowList> getVisitors({String? search}) => api.getVisitors(search);

  @override
  Future<void> createVisitor(VisitorRequest request) =>
      api.createVisitor(request);

  @override
  Future<void> checkoutVisitor(int id) => api.checkoutVisitor(id);

  @override
  Future<void> deleteVisitor(int id) => api.deleteVisitor(id);

  // ===== NOTICES =====

  @override
  Future<RowList> getNotices({String? search}) => api.getNotices(search);

  @override
  Future<RowList> getNoticeRecipients() => api.getNoticeRecipients();

  @override
  Future<Map<String, dynamic>> createNotice(NoticeRequest request) async {
    final reply = await api.createNotice(request);
    // The route answers {notice_id, notified}; anything else means an older
    // build, and an empty map reads as "nothing to report" downstream.
    return reply is Map ? Map<String, dynamic>.from(reply) : {};
  }

  @override
  Future<void> updateNotice(int id, NoticeRequest request) =>
      api.updateNotice(id, request);

  @override
  Future<void> deleteNotice(int id) => api.deleteNotice(id);

  // ===== NOC CERTIFICATES =====

  @override
  Future<RowList> getNocCertificates({String? search}) =>
      api.getNocCertificates(search);

  @override
  Future<Map<String, dynamic>> createNocCertificate(NocRequest request) async {
    final reply = await api.createNocCertificate(request);
    // The route answers {noc_id, serial_no}; anything else means an older
    // build, and an empty map reads as "nothing to report" downstream.
    return reply is Map ? Map<String, dynamic>.from(reply) : {};
  }

  @override
  Future<void> updateNocCertificate(int id, NocRequest request) =>
      api.updateNocCertificate(id, request);

  @override
  Future<void> deleteNocCertificate(int id) => api.deleteNocCertificate(id);

  // ===== FACILITY BOOKINGS =====

  @override
  Future<RowList> getFacilities() => api.getFacilities();

  @override
  Future<RowList> getFacilityBookings({String? search}) =>
      api.getFacilityBookings(search);

  @override
  Future<Map<String, dynamic>> getFacilityBookingLookups() async {
    return asRow(await api.getFacilityBookingLookups());
  }

  @override
  Future<void> createFacilityBooking(FacilityBookingRequest request) =>
      api.createFacilityBooking(request);

  @override
  Future<void> deleteFacilityBooking(int id) => api.deleteFacilityBooking(id);

  // ===== THE REST =====

  @override
  Future<RowList> getMessages() => api.getMessages();

  @override
  Future<void> markMessageRead(int id) => api.markMessageRead(id);

  @override
  Future<RowList> getPolls() => api.getPolls();

  @override
  Future<RowList> getPollVotes(int id) => api.getPollVotes(id);

  @override
  Future<void> votePoll(int id, int optionId) =>
      api.votePoll(id, {'optionId': optionId});

  @override
  Future<Map<String, dynamic>> createPoll(PollRequest request) async {
    final reply = await api.createPoll(request);
    // The route answers {PollId, options, notified}; an empty map reads as
    // "nothing to report" downstream, as it does for a notice.
    return reply is Map ? Map<String, dynamic>.from(reply) : {};
  }

  @override
  Future<void> deletePoll(int id) => api.deletePoll(id);

  @override
  Future<RowList> getSuggestions({String? search}) =>
      api.getSuggestions(search);

  @override
  Future<void> createSuggestion(SuggestionRequest request) =>
      api.createSuggestion(request);

  @override
  Future<void> updateSuggestion(int id, SuggestionRequest request) =>
      api.updateSuggestion(id, request);

  @override
  Future<void> deleteSuggestion(int id) => api.deleteSuggestion(id);

  @override
  Future<RowList> getEvents({String? search}) => api.getEvents(search);

  @override
  Future<Map<String, dynamic>> createEvent(EventRequest request) async {
    final reply = await api.createEvent(request);
    // Same shape as a notice: {event_id, notified}, and an empty map when an
    // older build answers something else.
    return reply is Map ? Map<String, dynamic>.from(reply) : {};
  }

  @override
  Future<void> updateEvent(int id, EventRequest request) =>
      api.updateEvent(id, request);

  @override
  Future<void> deleteEvent(int id) => api.deleteEvent(id);

  @override
  Future<RowList> getMeetings({String? search}) => api.getMeetings(search);

  @override
  Future<Map<String, dynamic>> createMeeting(MeetingRequest request) async {
    final reply = await api.createMeeting(request);
    return reply is Map ? Map<String, dynamic>.from(reply) : {};
  }

  @override
  Future<void> updateMeeting(int id, MeetingRequest request) =>
      api.updateMeeting(id, request);

  @override
  Future<void> deleteMeeting(int id) => api.deleteMeeting(id);

  @override
  Future<RowList> getNotifications() => api.getNotifications();

  @override
  Future<void> markNotificationSeen(int id) => api.markNotificationSeen(id);
}
