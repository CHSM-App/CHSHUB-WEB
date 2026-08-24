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

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {}
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
  Future<RowList> getHelpdeskTickets({String? search}) async => sampleRows();

  @override
  Future<RowList> getHelpdeskStatuses() async => sampleRows();

  @override
  Future<Map<String, dynamic>> getHelpdeskTicket(int id) async => {
    'ticket': {'title': 'Leaking tap', 'status': 1},
    'comments': <dynamic>[],
  };

  @override
  Future<void> updateHelpdeskStatus(
    int id,
    HelpdeskStatusRequest request,
  ) async {}

  @override
  Future<void> addHelpdeskComment(
    int id,
    HelpdeskCommentRequest request,
  ) async {}

  @override
  Future<RowList> getVisitors({String? search}) async => sampleRows();

  @override
  Future<void> createVisitor(VisitorRequest request) async {}

  @override
  Future<void> checkoutVisitor(int id) async {}

  @override
  Future<void> deleteVisitor(int id) async {}

  @override
  Future<RowList> getNotices({String? search}) async => sampleRows();

  @override
  Future<RowList> getNoticeRecipients() async => sampleRows();

  @override
  Future<void> createNotice(NoticeRequest request) async {}

  @override
  Future<void> updateNotice(int id, NoticeRequest request) async {}

  @override
  Future<void> deleteNotice(int id) async {}

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
  Future<RowList> getPolls() async => sampleRows();

  @override
  Future<RowList> getSuggestions({String? search}) async => sampleRows();

  @override
  Future<RowList> getEvents({String? search}) async => sampleRows();

  @override
  Future<RowList> getMeetings({String? search}) async => sampleRows();

  @override
  Future<RowList> getDocuments({String? search}) async => sampleRows();

  @override
  Future<RowList> getNotifications() async => sampleRows();
}
