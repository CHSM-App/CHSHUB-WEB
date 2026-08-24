import '../../domain/models/community_requests.dart';
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
  static const suggestions = 'suggestions';
  static const events = 'events';
  static const meetings = 'meetings';
  static const documents = 'documents';
  static const notifications = 'notifications';
}

class CommunityViewModel extends ListViewModel {
  final CommunityUsecase usecase;

  /// The ticket currently open, with its comment thread.
  Map<String, dynamic>? openTicket;

  /// Facilities and flats for the booking form.
  Map<String, dynamic>? bookingLookups;

  CommunityViewModel(this.usecase);

  // ===== HELPDESK =====

  /// The list and the statuses it can be moved to - the detail sheet needs
  /// both, so they load together.
  Future<void> loadHelpdesk({String? search}) => loadAll({
    CommunityKeys.helpdesk: () => usecase.getHelpdeskTickets(search: search),
    CommunityKeys.helpdeskStatuses: usecase.getHelpdeskStatuses,
  });

  Future<bool> openHelpdeskTicket(int id) {
    return run(
      () async => openTicket = await usecase.getHelpdeskTicket(id),
      guard: 'ticket',
    );
  }

  Future<bool> updateHelpdeskStatus(int id, int status) {
    return run(
      () => usecase.updateHelpdeskStatus(id, status),
      guard: 'ticket',
      successMessage: 'Status updated.',
      onSuccess: () async {
        await loadHelpdesk();
        await openHelpdeskTicket(id);
      },
    );
  }

  Future<bool> addHelpdeskComment(int id, String comment, {int? flatId}) {
    return run(
      () => usecase.addHelpdeskComment(id, comment, flatId: flatId),
      guard: 'ticket',
      successMessage: 'Reply posted.',
      onSuccess: () => openHelpdeskTicket(id),
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

  Future<bool> createNotice(NoticeRequest request) {
    return run(
      () => usecase.createNotice(request),
      guard: 'notice',
      successMessage: 'Notice published.',
      onSuccess: loadNotices,
    );
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

  Future<void> loadPolls() => load(CommunityKeys.polls, usecase.getPolls);

  Future<void> loadSuggestions({String? search}) => load(
    CommunityKeys.suggestions,
    () => usecase.getSuggestions(search: search),
  );

  Future<void> loadEvents({String? search}) =>
      load(CommunityKeys.events, () => usecase.getEvents(search: search));

  Future<void> loadMeetings({String? search}) =>
      load(CommunityKeys.meetings, () => usecase.getMeetings(search: search));

  Future<void> loadDocuments({String? search}) =>
      load(CommunityKeys.documents, () => usecase.getDocuments(search: search));

  Future<void> loadNotifications() =>
      load(CommunityKeys.notifications, usecase.getNotifications);
}
