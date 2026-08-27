import 'dart:io';

import '../models/community_requests.dart';
import '../models/paged_rows.dart';
import '../models/visitor_request.dart';

abstract class CommunityRepository {
  // ===== HELPDESK =====
  Future<RowList> getHelpdeskTickets();
  Future<RowList> getHelpdeskStatuses();
  Future<Map<String, dynamic>> getHelpdeskLookups();
  Future<Map<String, dynamic>> getHelpdeskTicket(int id);
  Future<int?> createHelpdeskTicket(HelpdeskCreateRequest request);

  /// Stores [files] and attaches each to [helpdeskId].
  Future<void> attachHelpdeskImages(int helpdeskId, List<File> files);
  Future<void> updateHelpdeskStatus(int id, HelpdeskStatusRequest request);
  Future<void> addHelpdeskComment(int id, HelpdeskCommentRequest request);

  // ===== VISITORS =====
  Future<RowList> getVisitors({String? search});
  Future<void> createVisitor(VisitorRequest request);
  Future<void> checkoutVisitor(int id);
  Future<void> deleteVisitor(int id);

  // ===== NOTICES =====
  Future<RowList> getNotices({String? search});
  Future<RowList> getNoticeRecipients();

  /// Returns the server's reply: the new notice_id, and a `notified` summary
  /// of how far the push actually got. The notice is saved either way — the
  /// push runs after the save — so the summary is worth showing rather than
  /// letting a notice that reached nobody read as one that reached everyone.
  Future<Map<String, dynamic>> createNotice(NoticeRequest request);
  Future<void> updateNotice(int id, NoticeRequest request);
  Future<void> deleteNotice(int id);

  // ===== NOC CERTIFICATES =====

  Future<RowList> getNocCertificates({String? search});

  /// Returns the server's reply: the new noc_id and the serial it allocated.
  /// The serial is issued server-side so two secretaries certifying at the
  /// same moment cannot land on one certificate number.
  Future<Map<String, dynamic>> createNocCertificate(NocRequest request);
  Future<void> updateNocCertificate(int id, NocRequest request);
  Future<void> deleteNocCertificate(int id);

  // ===== FACILITY BOOKINGS =====
  Future<RowList> getFacilities();
  Future<RowList> getFacilityBookings({String? search});
  Future<Map<String, dynamic>> getFacilityBookingLookups();
  Future<void> createFacilityBooking(FacilityBookingRequest request);
  Future<void> deleteFacilityBooking(int id);

  // ===== EVENTS =====
  Future<RowList> getEvents({String? search});
  Future<Map<String, dynamic>> createEvent(EventRequest request);
  Future<void> updateEvent(int id, EventRequest request);
  Future<void> deleteEvent(int id);

  // ===== MEETINGS =====
  Future<RowList> getMeetings({String? search});
  Future<Map<String, dynamic>> createMeeting(MeetingRequest request);
  Future<void> updateMeeting(int id, MeetingRequest request);
  Future<void> deleteMeeting(int id);

  // ===== THE REST =====
  Future<RowList> getMessages();
  Future<void> markMessageRead(int id);
  Future<RowList> getPolls();
  Future<RowList> getPollVotes(int id);
  Future<Map<String, dynamic>> createPoll(PollRequest request);
  Future<void> votePoll(int id, int optionId);
  Future<void> deletePoll(int id);
  Future<RowList> getSuggestions({String? search});
  Future<void> createSuggestion(SuggestionRequest request);
  Future<void> updateSuggestion(int id, SuggestionRequest request);
  Future<void> deleteSuggestion(int id);
  Future<RowList> getNotifications();
  Future<void> markNotificationSeen(int id);
}
