import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:secretary_app/domain/models/auth_requests.dart';
import 'package:secretary_app/domain/models/bill_preview.dart';
import 'package:secretary_app/domain/models/community_requests.dart';
import 'package:secretary_app/domain/models/dashboard.dart';
import 'package:secretary_app/domain/models/expense_request.dart';
import 'package:secretary_app/domain/models/generate_bill_request.dart';
import 'package:secretary_app/domain/models/paged_rows.dart';
import 'package:secretary_app/domain/models/pdc_request.dart';
import 'package:secretary_app/domain/models/receipt_request.dart';
import 'package:secretary_app/domain/models/token_response.dart';
import 'package:secretary_app/domain/models/user.dart';
import 'package:secretary_app/domain/models/visitor_request.dart';
import 'package:secretary_app/domain/repository/accounts_repo.dart';
import 'package:secretary_app/domain/repository/auth_repo.dart';
import 'package:secretary_app/domain/repository/billing_repo.dart';
import 'package:secretary_app/domain/repository/community_repo.dart';
import 'package:secretary_app/domain/repository/dashboard_repo.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';

/// Repository fakes for widget tests.
///
/// Hand-written rather than generated: the contracts are small, and a fake
/// that returns realistic rows is what makes these tests catch layout faults.
/// The payloads mirror what the live Gokuldham society actually returns,
/// including the column spellings the stored procedures use.

List<Override> fakeOverrides() => [
  authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
  billingRepositoryProvider.overrideWithValue(FakeBillingRepository()),
  accountsRepositoryProvider.overrideWithValue(FakeAccountsRepository()),
  communityRepositoryProvider.overrideWithValue(FakeCommunityRepository()),
];

// ── Sample payloads ──────────────────────────────────────────────────────

DashboardSummary sampleDashboard() => DashboardSummary.fromJson({
  // `opened` / `resolved`, not open/closed — this is what sp_dashboard
  // 'Get_Ticket' really returns.
  'tickets': {'opened': 12, 'resolved': 8},
  'residentCount': 10,
  'incomeSplit': [
    {'category': 'Due', 'amount': 88117.14},
    {'category': 'Collection', 'amount': 235291.57},
  ],
  'monthlyDues': [
    {'month_name': 'January', 'amount': 9165.35},
    {'month_name': 'February', 'amount': 6176.9},
    {'month_name': 'March', 'amount': 10311.5},
  ],
  'recentActivity': [
    {'activity': 'Receipt recorded', 'date': '2026-08-19T00:00:00.000Z'},
  ],
  'weeklyUpdates': [
    {'title': 'New complaints', 'count': 3},
  ],
  'defaulters': {'count': 4, 'totalDue': 88117.14},
});

RowList sampleDefaulters() => RowList.fromJson({
  'items': [
    {
      'owner_name': 'Aniket',
      'bed': '2 BED',
      'Unit': 'W-1 302',
      'flat_no': '302',
      'flat_id': 2,
      'pre_mob': '8263829478',
      'due': 6830.76,
    },
    {
      'owner_name': 'Archana Kudalkar',
      'bed': '3 BED',
      'Unit': 'T-2 203',
      'flat_no': '203',
      'flat_id': 11,
      'due': 4120.0,
    },
  ],
  'count': 2,
  'totalDue': 10950.76,
});

/// The bill-generation preview, copied from what the live Gokuldham society
/// returns — including the warning that a run already exists this month.
BillPreview samplePreview({
  bool autoBillGeneration = false,
  bool alreadyGeneratedThisMonth = true,
}) => BillPreview.fromJson({
  'flatCount': 26,
  'settings': {
    'ratePerSqFt': 5,
    'twoWheelerRate': 50,
    'fourWheelerRate': 100,
    'interestRate': 0,
    'billGenerationDay': 2,
    'billDuePeriodDays': 15,
    'autoBillGeneration': autoBillGeneration,
  },
  'regular': {
    'charges': [
      {
        'charge_id': 27,
        'name': 'gardening',
        'amount': 20000,
        'perFlat': 769.23,
      },
      {
        'charge_id': 8,
        'name': 'service charges',
        'amount': 1800,
        'perFlat': 69.23,
      },
      {'charge_id': 5, 'name': 'sinking', 'amount': 3000, 'perFlat': 115.38},
    ],
    'totalAmount': 25900,
    'perFlatTotal': 996.15,
  },
  'addOn': {
    'charges': [
      {'charge_id': 31, 'name': 'test', 'amount': 4000, 'perFlat': 153.85},
    ],
    'totalAmount': 4000,
    'perFlatTotal': 153.85,
  },
  'existingRuns': 11,
  'alreadyGeneratedThisMonth': alreadyGeneratedThisMonth,
  'warnings': [
    if (alreadyGeneratedThisMonth)
      'A bill run already exists for the current month; gen_bill will skip '
          'regular billing.',
  ],
});

RowList sampleRows() => RowList.fromJson({
  'items': [
    {
      'name': 'Sample row',
      'title': 'Sample row',
      'owner_name': 'Aniket',
      'flat_no': '302',
      'status': 'Pending',
      'amount': 1250.0,
      'date': '2026-08-18T00:00:00.000Z',
    },
  ],
  'count': 1,
});

RowList emptyRows() => const RowList();

/// Gate entries in all three states the visitors screen splits on.
///
/// sp_Visitor stamps `in_date`/`in_time` on arrival and `out_time` on the way
/// out, so the three are told apart by which of those are set: expected has
/// neither, inside has the first pair only, left has both.
///
/// The dates are strings, not ISO timestamps, because that is what arrives:
/// the `visitor` view selects CONVERT(varchar, in_date, 106) — "25 Aug 2026" —
/// and the time as CONVERT(varchar(15), CAST(in_time AS TIME), 100), a time of
/// day with no date on it. Held as ISO here, the tests would pass against a
/// shape the app never actually sees.
RowList visitorRows() => RowList.fromJson({
  'items': [
    {
      'visitor_id': 1,
      'v_name': 'Ramesh Pawar',
      'type': 'Guest',
      'contact_no': '9876500011',
      'flat_no': '101',
      'build_wing': 'Ganesh Bhavan A',
      'in_date': '25 Aug 2026',
      'in_time': '9:30AM',
    },
    {
      'visitor_id': 2,
      'v_name': 'Swiggy Delivery',
      'type': 'Delivery',
      'contact_no': '9876500022',
      'flat_no': '204',
      'build_wing': 'Ganesh Bhavan B',
      'in_date': '25 Aug 2026',
      'in_time': '10:15AM',
      // Stamped out, so this one has left.
      'out_date': '25 Aug 2026',
      'out_time': '10:40AM',
    },
    {
      'visitor_id': 3,
      'v_name': 'Anita Deshmukh',
      'type': 'Guest',
      'contact_no': '9876500033',
      'flat_no': '9',
      'build_wing': 'Shiv Kunj A',
      // No in_date: registered ahead of arrival, still expected.
      //
      // in_time is set even so — sp_Visitor's insert writes it as getdate()
      // for every visitor, so it records when the row was made rather than
      // when anyone arrived. Only in_date stays null until they turn up.
      'in_time': '11:00AM',
      'pre_date': '26 Aug 2026',
    },
    {
      'visitor_id': 4,
      'v_name': 'Prakash Jadhav',
      'type': 'Service',
      'contact_no': '9876500044',
      'flat_no': '101',
      'build_wing': 'Ganesh Bhavan A',
      // Stamped out but never stamped in — three real rows look like this.
      // Being checked out proves they came, so Left has to win over Expected
      // or the same visitor is counted twice.
      'in_time': '2:00PM',
      'out_date': '25 Aug 2026',
      'out_time': '4:20PM',
    },
  ],
  'count': 4,
});

/// Notices in the states the board splits on: still showing, ended, and one
/// with no end date at all.
///
/// The valid_to dates are relative to today rather than fixed, because the
/// screen decides Active from DateTime.now(): a hardcoded 2026 date would
/// pass this year and silently flip to Expired later, turning the test into
/// one that reports on the calendar rather than the code.
/// Certificates in the two states the list chips on: one still valid and one
/// whose end date has passed. Dated relative to today for the same reason the
/// notices are — a fixed date would flip the test's meaning next year.
RowList nocCertificateRows() {
  final today = DateTime.now();
  String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  return RowList.fromJson({
    'items': [
      {
        'noc_id': 1,
        'serial_no': 'NOC/2026/00001',
        'noc_type': 'SaleTransfer',
        'clause':
            'to the sale and transfer of the said flat by the member, and '
            'holds no claim, charge or lien over the said flat.',
        'member_name': 'Rahul Sharma',
        'flat_no': 'A-1203',
        'building_name': 'Building A',
        'purpose': 'Visa Application',
        'issued_on': iso(today.subtract(const Duration(days: 3))),
        'valid_till': iso(today.add(const Duration(days: 300))),
      },
      {
        'noc_id': 2,
        'serial_no': 'NOC/2026/00002',
        'noc_type': 'Other',
        'custom_title': 'Pet ownership NOC',
        'clause': 'to the member keeping a pet in the said flat.',
        'member_name': 'Meera Joshi',
        'flat_no': 'B-402',
        'building_name': 'Building B',
        // Lapsed last week.
        'issued_on': iso(today.subtract(const Duration(days: 400))),
        'valid_till': iso(today.subtract(const Duration(days: 7))),
      },
    ],
    'count': 2,
  });
}

RowList noticeRows() {
  final today = DateTime.now();
  String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  return RowList.fromJson({
    'items': [
      {
        'notice_id': 1,
        'name': 'Water tank cleaning',
        'description': 'Supply is off on Sunday from 9am to 2pm.',
        'date': iso(today.subtract(const Duration(days: 2))),
        'valid_to': iso(today.add(const Duration(days: 5))),
        'recipients_id': 3,
      },
      {
        'notice_id': 2,
        'name': 'Diwali lighting',
        'description': 'Committee will put the lights up on Saturday.',
        'date': iso(today.subtract(const Duration(days: 40))),
        // Ended last week.
        'valid_to': iso(today.subtract(const Duration(days: 7))),
        'recipients_id': 1,
      },
      {
        'notice_id': 3,
        'name': 'Society office hours',
        'description': 'Open 10am to 6pm on weekdays.',
        'date': iso(today.subtract(const Duration(days: 90))),
        // No valid_to: a standing notice that never expires, which is what
        // the website's blank "Valid until" writes.
        'recipients_id': 5,
      },
    ],
    'count': 3,
  });
}

/// The audience groups, as sp_notice_master/GetAllRecipients returns them.
RowList noticeRecipientRows() => RowList.fromJson({
  'items': [
    {'recipients_id': 1, 'recipients': 'Owners'},
    {'recipients_id': 2, 'recipients': 'Tenants'},
    {'recipients_id': 3, 'recipients': 'Owners and Tenants'},
    {'recipients_id': 4, 'recipients': 'Members'},
  ],
  'count': 4,
});

// ── Fakes ────────────────────────────────────────────────────────────────

class FakeAuthRepository implements AuthRepository {
  @override
  Future<TokenResponse> login(String username, String password) async =>
      const TokenResponse(accessToken: 'a', refreshToken: 'r');

  @override
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken) async =>
      const TokenResponse(accessToken: 'a', refreshToken: 'r');

  @override
  Future<void> logout(String refreshToken) async {}

  @override
  Future<User> me() async => User.fromJson(const {
    'user_id': 98,
    'name': 'Test Secretary',
    'username': 'testsec',
    'user_type_id': 2,
    'user_type': 'Secretary',
    'society_id': 'C10001',
    'society_name': 'Gokuldham',
    'tenant_type': 'Society',
    'email': 'testsec@example.com',
    'contact_no': '9999900001',
  });

  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) async {}

  /// Mirrors the route: the change revokes the account's other sessions and
  /// hands this device a replacement pair.
  @override
  Future<TokenResponse?> changePassword(ChangePasswordRequest request) async =>
      request.refreshToken == null
      ? null
      : const TokenResponse(
          accessToken: 'access-after-change',
          refreshToken: 'refresh-after-change',
        );

  /// Answers a path shaped like the uploader's, without touching the disk.
  @override
  Future<String> uploadProfilePhoto(File file) async =>
      'profile-photos/test-photo.png';

  /// Echoes the edit back the way the real repository does — it re-reads
  /// /auth/me after saving, so the caller receives the stored user rather than
  /// the request it sent.
  @override
  Future<User> updateProfile(UpdateProfileRequest request) async {
    final base = await me();
    return User.fromJson({
      ...base.toJson(),
      // '' means "removed" on this endpoint, so it maps to a null photo rather
      // than to an empty path.
      if (request.photoPath != null)
        'photo_path': request.photoPath!.isEmpty ? null : request.photoPath,
      'name': [
        request.firstName,
        if (request.lastName != null) request.lastName,
      ].join(' ').trim(),
      'username': request.username,
      'email': request.email,
      'contact_no': request.contactNo,
    });
  }
}

class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getDashboard() async => sampleDashboard();

  @override
  Future<RowList> getIncomeSplit({String? to}) async => sampleRows();

  @override
  Future<RowList> getExpenseChart({int? type}) async => sampleRows();

  @override
  Future<RowList> getRecentActivity() async => sampleRows();
}

class FakeBillingRepository implements BillingRepository {
  FakeBillingRepository({
    this.autoBillGeneration = false,
    this.alreadyGeneratedThisMonth = true,
  });

  /// Drives the preview's `settings.autoBillGeneration`, which decides what
  /// the generate screen says a manual run is actually doing.
  final bool autoBillGeneration;

  /// Drives whether a regular run has already gone out this month, which
  /// decides if the generate screen offers the regular button at all.
  final bool alreadyGeneratedThisMonth;

  @override
  Future<RowList> getBillRuns({int? year, int? month}) async => sampleRows();

  @override
  Future<Map<String, dynamic>> getBillDetail(int billId, {int? flatId}) async =>
      {'items': <Map<String, dynamic>>[], 'chargeColumns': <dynamic>[]};

  @override
  Future<RowList> getBillCharges() async => emptyRows();

  @override
  Future<RowList> getDefaulters() async => sampleDefaulters();

  @override
  Future<RowList> getOwnerDues(int flatId) async => emptyRows();

  @override
  Future<BillPreview> getGenerationPreview() async => samplePreview(
    autoBillGeneration: autoBillGeneration,
    alreadyGeneratedThisMonth: alreadyGeneratedThisMonth,
  );

  @override
  Future<Map<String, dynamic>> generateRegularBills(
    GenerateBillRequest request,
  ) async => {'generated': true, 'message': 'Bill run created.'};

  @override
  Future<Map<String, dynamic>> generateAddonBills(
    GenerateBillRequest request,
  ) async => {'generated': true, 'message': 'Add-on charges raised.'};

  @override
  Future<RowList> getReceipts() async => sampleRows();

  @override
  Future<RowList> getReceiptResidents() async => sampleRows();

  @override
  Future<RowList> getOutstandingBills(int flatId) async => sampleRows();

  @override
  Future<RowList> getAdvanceBalance(int flatId) async => emptyRows();

  @override
  Future<RowList> getReceiptPdc(int flatId) async => emptyRows();

  @override
  Future<Map<String, dynamic>> getReceipt(int id) async => {
    'receipt': {'receipt_no': 'R-$id'},
    'lines': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) async => {
    'receipt_id': 1,
  };

  @override
  Future<void> cancelReceipt(int id) async {}

  @override
  Future<RowList> getPdcList({String? search}) async => sampleRows();

  @override
  Future<RowList> getPdcOwners() async => sampleRows();

  @override
  Future<Map<String, dynamic>> getPdcOwnerDetails(int ownerId) async =>
      const {};

  @override
  Future<RowList> getPdcByOwner(int ownerId) async => const RowList();

  @override
  Future<RowList> getPdcClearing({String? from, String? to}) async =>
      sampleRows();

  @override
  Future<void> createPdc(PdcRequest request) async {}

  @override
  Future<void> updatePdc(int id, PdcRequest request) async {}

  @override
  Future<void> clearPdc(int id, PdcClearRequest request) async {}

  @override
  Future<void> deletePdc(int id) async {}
}

class FakeAccountsRepository implements AccountsRepository {
  @override
  Future<RowList> getExpenses({String? search}) async => sampleRows();

  @override
  Future<void> createExpense(ExpenseRequest request) async {}

  @override
  Future<void> updateExpense(int id, ExpenseRequest request) async {}

  @override
  Future<void> deleteExpense(int id) async {}

  @override
  Future<RowList> getCashbook({String? from, String? to}) async => sampleRows();

  @override
  Future<RowList> getLedger({String? search}) async => sampleRows();

  @override
  Future<RowList> getSocietyReceipts({String? search}) async => sampleRows();

  @override
  Future<RowList> getOtherCredits({String? search}) async => sampleRows();

  @override
  Future<RowList> getShopMaintenance({String? search}) async => sampleRows();

  @override
  Future<RowList> getVendors({String? search}) async => sampleRows();

  @override
  Future<void> createVendor(Map<String, dynamic> body) async {}

  @override
  Future<void> updateVendor(int id, Map<String, dynamic> body) async {}

  @override
  Future<void> deleteVendor(int id) async {}

  @override
  Future<RowList> getVendorBills({String? search}) async => sampleRows();

  @override
  Future<Map<String, dynamic>> getVendorBillFormData() async => {};

  @override
  Future<Map<String, dynamic>> getVendorBill(int id) async => {
    'bill': {'bill_number': 'INV-202608-101500', 'total_amount': 1200},
    'items': <dynamic>[],
    'approvals': <dynamic>[],
    'payments': <dynamic>[],
  };

  @override
  Future<void> createVendorBill(Map<String, dynamic> body) async {}

  @override
  Future<void> deleteVendorBill(int id) async {}

  @override
  Future<void> payVendorBill(int id, Map<String, dynamic> body) async {}

  @override
  Future<void> decideVendorBill(
    int billId,
    int approvalId,
    Map<String, dynamic> body,
  ) async {}
}

class FakeCommunityRepository implements CommunityRepository {
  @override
  Future<RowList> getHelpdeskTickets() async => sampleRows();

  @override
  Future<Map<String, dynamic>> getHelpdeskLookups() async => {
    // As sp_usefull_contact's ComplaintType branch names them — including the
    // guidance column, which the database spells `decription`.
    'categories': [
      {
        'c_type_id': 1,
        'c_type_name': 'Maintenance Issues',
        'decription':
            'Water leakage, plumbing problems, electrical faults, lift '
            'malfunction, etc.',
      },
      {
        'c_type_id': 2,
        'c_type_name': 'Cleanliness and Sanitation',
        'decription':
            'Unclean common areas, irregular garbage collection, pest '
            'control issues.',
      },
      // The branch returns a trailing all-null row, which the picker drops
      // rather than offering as a blank choice.
      {'c_type_id': null, 'c_type_name': null, 'decription': null},
    ],
    // As sp_flat_master's Grid_Show branch names them — the `flat` view, which
    // returns the building as `name`, the wing as `w_name`, and the two joined
    // as `build_wing`. All three are carried here because the pickers group by
    // the building and label by the wing, and a row missing either falls back
    // silently rather than failing.
    //
    // Deliberately out of order, spanning two buildings, and with two wings in
    // one of them, so a test can tell the picker groups, filters and sorts.
    'flats': [
      {
        'flat_id': 7,
        'flat_no': '10',
        'name': 'Ganesh Bhavan',
        'w_name': 'A',
        'build_wing': 'Ganesh Bhavan A',
      },
      {
        'flat_id': 8,
        'flat_no': '2',
        'name': 'Shiv Kunj',
        'w_name': 'A',
        'build_wing': 'Shiv Kunj A',
      },
      {
        'flat_id': 5,
        'flat_no': '9',
        'name': 'Ganesh Bhavan',
        'w_name': 'A',
        'build_wing': 'Ganesh Bhavan A',
      },
      // A second wing of the first building, running its own flat 9 — the case
      // that makes a bare flat number ambiguous.
      {
        'flat_id': 9,
        'flat_no': '9',
        'name': 'Ganesh Bhavan',
        'w_name': 'B',
        'build_wing': 'Ganesh Bhavan B',
      },
    ],
  };

  /// The tickets raised through the form, so a test can assert one was sent.
  final List<HelpdeskCreateRequest> createdHelpdeskTickets = [];

  /// The photos attached, keyed by the ticket they went to.
  final Map<int, List<File>> attachedHelpdeskImages = {};

  @override
  Future<int?> createHelpdeskTicket(HelpdeskCreateRequest request) async {
    createdHelpdeskTickets.add(request);
    return 7;
  }

  @override
  Future<void> attachHelpdeskImages(int helpdeskId, List<File> files) async {
    attachedHelpdeskImages.putIfAbsent(helpdeskId, () => []).addAll(files);
  }

  @override
  Future<RowList> getHelpdeskStatuses() async => sampleRows();

  /// The thread the server would hold, so a fetch after a post returns the
  /// posted reply — which is what makes a missing refetch visible to a test.
  final List<Map<String, dynamic>> helpdeskComments = [];

  /// Counts fetches of the detail, so a test can assert one happened.
  int helpdeskTicketFetches = 0;

  @override
  Future<Map<String, dynamic>> getHelpdeskTicket(int id) async {
    helpdeskTicketFetches++;
    return {
      'ticket': {'title': 'Leaking tap', 'status': helpdeskStatus},
      'comments': [...helpdeskComments],
    };
  }

  /// The status last written, echoed back by the detail fetch.
  int helpdeskStatus = 1;

  @override
  Future<void> updateHelpdeskStatus(
    int id,
    HelpdeskStatusRequest request,
  ) async {
    helpdeskStatus = request.status;
  }

  @override
  Future<void> addHelpdeskComment(
    int id,
    HelpdeskCommentRequest request,
  ) async {
    helpdeskComments.add({'description': request.comment, 'type': 'admin'});
  }

  @override
  Future<RowList> getVisitors({String? search}) async => visitorRows();

  @override
  Future<void> createVisitor(VisitorRequest request) async {}

  @override
  Future<void> checkoutVisitor(int id) async {}

  @override
  Future<void> deleteVisitor(int id) async {}

  @override
  Future<RowList> getNotices({String? search}) async => noticeRows();

  @override
  Future<RowList> getNoticeRecipients() async => noticeRecipientRows();

  @override
  Future<Map<String, dynamic>> createNotice(NoticeRequest request) async =>
      createNoticeReply;

  /// What POST /community/notices answered. Overridden per test to stand in
  /// for a push that reached everyone, nobody, or a group with no one in it.
  Map<String, dynamic> createNoticeReply = const {
    'notice_id': 9,
    'notified': {'sent': 12, 'failed': 0, 'recipients': 12, 'pushable': 12},
  };

  @override
  Future<void> updateNotice(int id, NoticeRequest request) async {}

  @override
  Future<void> deleteNotice(int id) async {}

  @override
  Future<RowList> getNocCertificates({String? search}) async => nocRows;

  /// What GET /community/noc answered.
  RowList nocRows = nocCertificateRows();

  @override
  Future<Map<String, dynamic>> createNocCertificate(NocRequest request) async =>
      createNocReply;

  /// What POST /community/noc answered — the id and the serial the server
  /// allocated, which the form could not know in advance.
  Map<String, dynamic> createNocReply = const {
    'noc_id': 7,
    'serial_no': 'NOC/2026/00007',
  };

  @override
  Future<void> updateNocCertificate(int id, NocRequest request) async {}

  @override
  Future<void> deleteNocCertificate(int id) async {}

  @override
  Future<RowList> getFacilities() async => sampleRows();

  @override
  Future<RowList> getFacilityBookings({String? search}) async => sampleRows();

  @override
  Future<Map<String, dynamic>> getFacilityBookingLookups() async => {
    'facilities': <dynamic>[],
    'flats': <dynamic>[],
  };

  @override
  Future<void> createFacilityBooking(FacilityBookingRequest request) async {}

  @override
  Future<void> deleteFacilityBooking(int id) async {}

  @override
  Future<RowList> getMessages() async => sampleRows();

  @override
  Future<void> markMessageRead(int id) async {}

  @override
  Future<RowList> getPolls() async => pollRows();

  @override
  Future<RowList> getPollVotes(int id) async => pollOptionRows();

  /// Votes cast through the fake, as (pollId, optionId) pairs.
  final List<({int pollId, int optionId})> votesCast = [];

  /// Set to make the next vote fail, as sp_PollVoting's refusals do.
  String? voteError;

  @override
  Future<void> votePoll(int id, int optionId) async {
    if (voteError != null) throw Exception(voteError);
    votesCast.add((pollId: id, optionId: optionId));
  }

  @override
  Future<Map<String, dynamic>> createPoll(PollRequest request) async =>
      createPollReply;

  /// What POST /community/polls answered. `notified` is a plain count here,
  /// not the `{sent, recipients, …}` summary a notice returns — the route
  /// pushes best-effort and reports only a total.
  Map<String, dynamic> createPollReply = const {
    'PollId': 4,
    'options': ['Yes', 'No'],
    'notified': 12,
  };

  @override
  Future<void> deletePoll(int id) async {}

  @override
  Future<RowList> getSuggestions({String? search}) async => sampleRows();

  @override
  Future<void> createSuggestion(SuggestionRequest request) async {}

  @override
  Future<void> updateSuggestion(int id, SuggestionRequest request) async {}

  @override
  Future<void> deleteSuggestion(int id) async {}

  @override
  Future<RowList> getEvents({String? search}) async => eventRows();

  @override
  Future<Map<String, dynamic>> createEvent(EventRequest request) async =>
      createEventReply;

  /// What POST /community/events answered, in the same shape a notice
  /// returns — tests override it to stand in for a wider or emptier push.
  Map<String, dynamic> createEventReply = const {
    'event_id': 7,
    'notified': {'sent': 12, 'failed': 0, 'recipients': 12, 'pushable': 12},
  };

  @override
  Future<void> updateEvent(int id, EventRequest request) async {}

  @override
  Future<void> deleteEvent(int id) async {}

  @override
  Future<RowList> getMeetings({String? search}) async => meetingRows();

  @override
  Future<Map<String, dynamic>> createMeeting(MeetingRequest request) async =>
      createMeetingReply;

  Map<String, dynamic> createMeetingReply = const {
    'meet_id': 5,
    'notified': {'sent': 12, 'failed': 0, 'recipients': 12, 'pushable': 12},
  };

  @override
  Future<void> updateMeeting(int id, MeetingRequest request) async {}

  @override
  Future<void> deleteMeeting(int id) async {}

  @override
  /// Two unseen alerts, shaped as sp_dashboard's Notification branch sends
  /// them — `notify_status_id` is the key the bell marks read.
  @override
  Future<RowList> getNotifications() async => const RowList(
    items: [
      {
        'notify_status_id': 501,
        'notification_type': 'Helpdesk',
        'title': 'New community complaint',
        'body': 'The lift is out.',
        'timestamp': '2 hours ago',
      },
      {
        'notify_status_id': 502,
        'notification_type': 'Notice',
        'title': 'Water supply',
        'body': 'Tanker arriving at 4pm.',
        'timestamp': 'yesterday',
      },
    ],
    count: 2,
  );

  /// The alerts marked read, so a test can assert the bell cleared one.
  final List<int> seenNotifications = [];

  @override
  Future<void> markNotificationSeen(int id) async {
    seenNotifications.add(id);
  }
}

/// Meetings either side of today, so the Upcoming/Past filter has both.
///
/// Dates are relative for the same reason the notices' are: the screen decides
/// past from DateTime.now(), and a fixed date would flip the test's meaning
/// once the calendar caught up with it.
RowList meetingRows() {
  final today = DateTime.now();
  return RowList.fromJson({
    'items': [
      {
        'meet_id': 1,
        'subject': 'Monthly committee meeting',
        'details': 'Accounts review and the lift quotation.',
        'meeting_date': _iso(today.add(const Duration(days: 6))),
        'meeting_time': '18:30',
      },
      {
        'meet_id': 2,
        'subject': 'Annual general body',
        'details': 'Budget approval for the coming year.',
        'meeting_date': _iso(today.subtract(const Duration(days: 21))),
        'meeting_time': '11:00',
      },
    ],
    'count': 2,
  });
}

/// Events either side of today, matching sp_event_master's column names.
RowList eventRows() {
  final today = DateTime.now();
  return RowList.fromJson({
    'items': [
      {
        'event_id': 1,
        'event_name': 'Ganesh Utsav',
        'description': 'Ten days in the society hall.',
        'from_date': _iso(today.add(const Duration(days: 12))),
        'to_date': _iso(today.add(const Duration(days: 22))),
      },
      {
        'event_id': 2,
        'event_name': 'Summer clean-up drive',
        'description': 'Terrace and parking, volunteers welcome.',
        'from_date': _iso(today.subtract(const Duration(days: 60))),
        'to_date': _iso(today.subtract(const Duration(days: 60))),
      },
    ],
    'count': 2,
  });
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Polls either side of their closing date, so open and closed both render.
///
/// Column names are sp_polls/GetPolls's own — PascalCase, unlike the snake_case
/// the community procedures use.
RowList pollRows() {
  final today = DateTime.now();
  return RowList.fromJson({
    'items': [
      {
        'PollId': 1,
        'Topic': 'Paint the building this year?',
        'Description': 'Quotes are in from three contractors.',
        'ExpiryDate': _iso(today.add(const Duration(days: 9))),
        'TotalVotes': 14,
      },
      {
        'PollId': 2,
        'Topic': 'Gym equipment for the clubhouse',
        'Description': 'Voting closed last month.',
        'ExpiryDate': _iso(today.subtract(const Duration(days: 30))),
        'TotalVotes': 22,
      },
    ],
    'count': 2,
  });
}

/// The options on a poll, as GET /community/polls/:id/votes answers them.
///
/// `isSelected` marks the option this user voted for, and the counts do not
/// divide evenly — 7 of 12 is 58%, which catches a card that rounds or sums
/// wrongly better than a tidy half would.
RowList pollOptionRows() => RowList.fromJson({
  'items': [
    {'OptionId': 1, 'text': 'Yes, go ahead', 'votes': 7, 'isSelected': true},
    {'OptionId': 2, 'text': 'No, wait a year', 'votes': 5, 'isSelected': false},
  ],
  'count': 2,
});
