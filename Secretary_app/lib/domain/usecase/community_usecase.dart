import '../models/community_requests.dart';
import '../models/paged_rows.dart';
import '../models/visitor_request.dart';
import '../repository/community_repo.dart';

class CommunityUsecase {
  final CommunityRepository repository;

  CommunityUsecase(this.repository);

  // ===== HELPDESK =====

  /// Resident complaints, newest first.
  Future<RowList> getHelpdeskTickets({String? search}) =>
      repository.getHelpdeskTickets(search: search);

  /// The statuses a ticket can be moved to.
  Future<RowList> getHelpdeskStatuses() => repository.getHelpdeskStatuses();

  /// One ticket with its comment thread and images.
  Future<Map<String, dynamic>> getHelpdeskTicket(int id) =>
      repository.getHelpdeskTicket(id);

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

  /// Publish a notice; the server pushes it to the chosen audience.
  Future<void> createNotice(NoticeRequest request) =>
      repository.createNotice(request);

  Future<void> updateNotice(int id, NoticeRequest request) =>
      repository.updateNotice(id, request);

  Future<void> deleteNotice(int id) => repository.deleteNotice(id);

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

  Future<RowList> getPolls() => repository.getPolls();

  Future<RowList> getSuggestions({String? search}) =>
      repository.getSuggestions(search: search);

  Future<RowList> getEvents({String? search}) =>
      repository.getEvents(search: search);

  Future<RowList> getMeetings({String? search}) =>
      repository.getMeetings(search: search);

  Future<RowList> getDocuments({String? search}) =>
      repository.getDocuments(search: search);

  Future<RowList> getNotifications() => repository.getNotifications();
}
