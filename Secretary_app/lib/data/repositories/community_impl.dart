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
  Future<RowList> getHelpdeskTickets({String? search}) =>
      api.getHelpdeskTickets(search);

  @override
  Future<RowList> getHelpdeskStatuses() => api.getHelpdeskStatuses();

  @override
  Future<Map<String, dynamic>> getHelpdeskTicket(int id) async {
    return asRow(await api.getHelpdeskTicket(id));
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
  Future<void> createNotice(NoticeRequest request) => api.createNotice(request);

  @override
  Future<void> updateNotice(int id, NoticeRequest request) =>
      api.updateNotice(id, request);

  @override
  Future<void> deleteNotice(int id) => api.deleteNotice(id);

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
  Future<RowList> getPolls() => api.getPolls();

  @override
  Future<RowList> getSuggestions({String? search}) =>
      api.getSuggestions(search);

  @override
  Future<RowList> getEvents({String? search}) => api.getEvents(search);

  @override
  Future<RowList> getMeetings({String? search}) => api.getMeetings(search);

  @override
  Future<RowList> getDocuments({String? search}) => api.getDocuments(search);

  @override
  Future<RowList> getNotifications() => api.getNotifications();
}
