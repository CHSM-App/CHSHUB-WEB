import '../models/community_requests.dart';
import '../models/paged_rows.dart';
import '../models/visitor_request.dart';

abstract class CommunityRepository {
  // ===== HELPDESK =====
  Future<RowList> getHelpdeskTickets({String? search});
  Future<RowList> getHelpdeskStatuses();
  Future<Map<String, dynamic>> getHelpdeskTicket(int id);
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
  Future<void> createNotice(NoticeRequest request);
  Future<void> updateNotice(int id, NoticeRequest request);
  Future<void> deleteNotice(int id);

  // ===== FACILITY BOOKINGS =====
  Future<RowList> getFacilities();
  Future<RowList> getFacilityBookings({String? search});
  Future<Map<String, dynamic>> getFacilityBookingLookups();
  Future<void> createFacilityBooking(FacilityBookingRequest request);
  Future<void> deleteFacilityBooking(int id);

  // ===== THE REST =====
  Future<RowList> getMessages();
  Future<RowList> getPolls();
  Future<RowList> getSuggestions({String? search});
  Future<RowList> getEvents({String? search});
  Future<RowList> getMeetings({String? search});
  Future<RowList> getDocuments({String? search});
  Future<RowList> getNotifications();
}
