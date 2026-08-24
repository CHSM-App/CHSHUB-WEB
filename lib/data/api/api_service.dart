import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../core/constant.dart';
import '../../domain/models/auth_requests.dart';
import '../../domain/models/bill_preview.dart';
import '../../domain/models/community_requests.dart';
import '../../domain/models/dashboard.dart';
import '../../domain/models/expense_request.dart';
import '../../domain/models/generate_bill_request.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/models/pdc_request.dart';
import '../../domain/models/receipt_request.dart';
import '../../domain/models/token_response.dart';
import '../../domain/models/visitor_request.dart';

part 'api_service.g.dart';

/// The only HTTP surface in the app.
///
/// Every path is relative to `<baseUrl>/api/web` — the website API in
/// `backend/web`, which is separate from the mobile API in `backend/routes` and
/// uses a different token scope. The {ok, data} envelope those routes return
/// is stripped by EnvelopeInterceptor before Retrofit deserialises, so the
/// return types below describe the payload, not the envelope.
///
/// The society is never a parameter: backend/web/middleware/authenticate.js
/// takes it from the access token and rejects a request that claims a
/// different one.
@RestApi(baseUrl: '$baseUrl$webApiPrefix/')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // =========================================================================
  // AUTH
  // =========================================================================

  @POST('auth/login')
  Future<TokenResponse> login(@Body() TokenResponse credentials);

  @POST('auth/refresh')
  Future<TokenResponse> refreshAccessToken(@Body() TokenResponse refreshToken);

  @POST('auth/logout')
  Future<TokenResponse> logout(@Body() TokenResponse refreshToken);

  /// Answers `{ user: {...} }`, unlike /auth/login which returns the user
  /// alongside the tokens. Unwrapped in AuthImpl rather than typed here.
  @GET('auth/me')
  Future<dynamic> me();

  /// Password reset. Lives under /onboarding, not /auth — that is where the
  /// backend put it, and it is the only unauthenticated password route.
  @POST('onboarding/forgot-password')
  Future<dynamic> forgotPassword(@Body() ForgotPasswordRequest request);

  @POST('onboarding/change-password')
  Future<dynamic> changePassword(@Body() ChangePasswordRequest request);

  // =========================================================================
  // DASHBOARD & REPORTS
  // =========================================================================

  @GET('reports/dashboard')
  Future<DashboardSummary> getDashboard();

  /// `to` is ISO yyyy-MM-dd; the period always starts at the first bill.
  @GET('reports/income-split')
  Future<RowList> getIncomeSplit(@Query('to') String? to);

  /// `type` 2 means every bill type.
  @GET('reports/expense-chart')
  Future<RowList> getExpenseChart(@Query('type') int? type);

  @GET('reports/activity')
  Future<RowList> getRecentActivity();

  @GET('reports/owner-ledger')
  Future<RowList> getOwnerLedger(@Query('ownerId') int ownerId);

  // =========================================================================
  // BILLING - BILLS
  // =========================================================================

  /// Add-on charge heads awaiting a run, with the per-flat share.
  @GET('billing/bills/charges')
  Future<RowList> getBillCharges();

  @GET('billing/bills')
  Future<RowList> getBillRuns(
    @Query('year') int? year,
    @Query('month') int? month,
  );

  /// One row per flat in the run. The charge columns are built dynamically per
  /// society, so the payload is returned raw rather than typed.
  @GET('billing/bills/{billId}')
  Future<dynamic> getBillDetail(
    @Path('billId') int billId,
    @Query('flatId') int? flatId,
  );

  @GET('billing/bills/{billId}/flat/{flatId}')
  Future<dynamic> getFlatBill(
    @Path('billId') int billId,
    @Path('flatId') int flatId,
  );

  @GET('billing/bills/reports/defaulters')
  Future<RowList> getDefaulters();

  // =========================================================================
  // BILLING - GENERATION
  // =========================================================================

  /// Always shown before generating: what the run would raise, and why it
  /// might raise nothing.
  @GET('billing/generate/preview')
  Future<BillPreview> getGenerationPreview();

  @POST('billing/generate/regular')
  Future<dynamic> generateRegularBills(@Body() GenerateBillRequest request);

  @POST('billing/generate/addon')
  Future<dynamic> generateAddonBills(@Body() GenerateBillRequest request);

  // =========================================================================
  // BILLING - RECEIPTS
  // =========================================================================

  @GET('billing/receipts')
  Future<RowList> getReceipts();

  /// Flats to choose from on the receipt form.
  @GET('billing/receipts/residents')
  Future<RowList> getReceiptResidents();

  /// Unpaid and partly-paid bills for a flat - what a payment can settle.
  @GET('billing/receipts/outstanding')
  Future<RowList> getOutstandingBills(@Query('flatId') int flatId);

  @GET('billing/receipts/advance')
  Future<RowList> getAdvanceBalance(@Query('flatId') int flatId);

  @GET('billing/receipts/pdc')
  Future<RowList> getReceiptPdc(@Query('flatId') int? flatId);

  @GET('billing/receipts/{id}')
  Future<dynamic> getReceipt(@Path('id') int id);

  @POST('billing/receipts')
  Future<dynamic> createReceipt(@Body() ReceiptRequest request);

  @POST('billing/receipts/{id}/cancel')
  Future<dynamic> cancelReceipt(@Path('id') int id);

  // =========================================================================
  // BILLING - PDC
  // =========================================================================

  @GET('billing/pdc')
  Future<RowList> getPdcList(@Query('search') String? search);

  /// Cheques bankable in a date range - the clearing worklist.
  @GET('billing/pdc/clearing')
  Future<RowList> getPdcClearing(
    @Query('from') String? from,
    @Query('to') String? to,
  );

  @GET('billing/pdc/owner/{ownerId}/details')
  Future<dynamic> getPdcOwnerDetails(@Path('ownerId') int ownerId);

  @GET('billing/pdc/owner/{ownerId}')
  Future<RowList> getPdcByOwner(@Path('ownerId') int ownerId);

  @POST('billing/pdc')
  Future<dynamic> createPdc(@Body() PdcRequest request);

  @PUT('billing/pdc/{id}')
  Future<dynamic> updatePdc(@Path('id') int id, @Body() PdcRequest request);

  /// Marking a cheque deposited also raises a receipt, so the body must carry
  /// confirm: true.
  @POST('billing/pdc/{id}/clear')
  Future<dynamic> clearPdc(@Path('id') int id, @Body() PdcClearRequest request);

  @DELETE('billing/pdc/{id}')
  Future<dynamic> deletePdc(@Path('id') int id);

  // =========================================================================
  // ACCOUNTS
  // =========================================================================

  @GET('accounts/expenses')
  Future<RowList> getExpenses(@Query('search') String? search);

  @GET('accounts/expenses/{id}')
  Future<dynamic> getExpense(@Path('id') int id);

  @POST('accounts/expenses')
  Future<dynamic> createExpense(@Body() ExpenseRequest request);

  @PUT('accounts/expenses/{id}')
  Future<dynamic> updateExpense(
    @Path('id') int id,
    @Body() ExpenseRequest request,
  );

  @DELETE('accounts/expenses/{id}')
  Future<dynamic> deleteExpense(@Path('id') int id);

  @GET('accounts/ledger')
  Future<RowList> getLedger(@Query('search') String? search);

  @GET('accounts/cashbook')
  Future<RowList> getCashbook(
    @Query('from') String? from,
    @Query('to') String? to,
  );

  @GET('accounts/other-credits')
  Future<RowList> getOtherCredits(@Query('search') String? search);

  @GET('accounts/society-receipts')
  Future<RowList> getSocietyReceipts(@Query('search') String? search);

  @GET('accounts/shop-maintenance')
  Future<RowList> getShopMaintenance(@Query('search') String? search);

  // ===== VENDORS =====

  @GET('accounts/vendors')
  Future<RowList> getVendors(@Query('search') String? search);

  @POST('accounts/vendors')
  Future<dynamic> createVendor(@Body() Map<String, dynamic> body);

  @PUT('accounts/vendors/{id}')
  Future<dynamic> updateVendor(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('accounts/vendors/{id}')
  Future<dynamic> deleteVendor(@Path('id') int id);

  // ===== VENDOR BILLS =====

  @GET('accounts/vendor-bills')
  Future<RowList> getVendorBills(@Query('search') String? search);

  /// Vendors, approvers and expense heads for the vendor-bill form.
  @GET('accounts/vendor-bills/form-data')
  Future<dynamic> getVendorBillFormData();

  @GET('accounts/vendor-bills/service-types')
  Future<RowList> getVendorServiceTypes();

  @GET('accounts/vendor-bills/{id}')
  Future<dynamic> getVendorBill(@Path('id') int id);

  @POST('accounts/vendor-bills')
  Future<dynamic> createVendorBill(@Body() Map<String, dynamic> body);

  @PUT('accounts/vendor-bills/{id}')
  Future<dynamic> updateVendorBill(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('accounts/vendor-bills/{id}')
  Future<dynamic> deleteVendorBill(@Path('id') int id);

  /// Record a payment against a bill — cheque, online or cash.
  @POST('accounts/vendor-bills/{id}/payments')
  Future<dynamic> payVendorBill(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  /// Approve or reject one approver's line on a bill.
  ///
  /// The bill is in the path so the API can check the approval belongs to the
  /// caller — only the approver it was asked of may answer it.
  @POST('accounts/vendor-bills/{id}/approvals/{approvalId}')
  Future<dynamic> decideVendorBill(
    @Path('id') int id,
    @Path('approvalId') int approvalId,
    @Body() Map<String, dynamic> body,
  );

  // =========================================================================
  // COMMUNITY - HELPDESK
  // =========================================================================

  @GET('community/helpdesk')
  Future<RowList> getHelpdeskTickets(@Query('search') String? search);

  @GET('community/helpdesk/statuses')
  Future<RowList> getHelpdeskStatuses();

  @GET('community/helpdesk/{id}')
  Future<dynamic> getHelpdeskTicket(@Path('id') int id);

  @PUT('community/helpdesk/{id}/status')
  Future<dynamic> updateHelpdeskStatus(
    @Path('id') int id,
    @Body() HelpdeskStatusRequest request,
  );

  @POST('community/helpdesk/{id}/comments')
  Future<dynamic> addHelpdeskComment(
    @Path('id') int id,
    @Body() HelpdeskCommentRequest request,
  );

  // =========================================================================
  // COMMUNITY - VISITORS
  // =========================================================================

  @GET('community/visitors')
  Future<RowList> getVisitors(@Query('search') String? search);

  @GET('community/visitors/{id}')
  Future<dynamic> getVisitor(@Path('id') int id);

  @POST('community/visitors')
  Future<dynamic> createVisitor(@Body() VisitorRequest request);

  @PUT('community/visitors/{id}')
  Future<dynamic> updateVisitor(
    @Path('id') int id,
    @Body() VisitorRequest request,
  );

  @POST('community/visitors/{id}/checkout')
  Future<dynamic> checkoutVisitor(@Path('id') int id);

  @DELETE('community/visitors/{id}')
  Future<dynamic> deleteVisitor(@Path('id') int id);

  // =========================================================================
  // COMMUNITY - NOTICES
  // =========================================================================

  @GET('community/notices')
  Future<RowList> getNotices(@Query('search') String? search);

  /// The audience groups a notice can be addressed to.
  @GET('community/notices/recipients')
  Future<RowList> getNoticeRecipients();

  @POST('community/notices')
  Future<dynamic> createNotice(@Body() NoticeRequest request);

  @PUT('community/notices/{id}')
  Future<dynamic> updateNotice(
    @Path('id') int id,
    @Body() NoticeRequest request,
  );

  @DELETE('community/notices/{id}')
  Future<dynamic> deleteNotice(@Path('id') int id);

  // =========================================================================
  // COMMUNITY - FACILITY BOOKINGS
  // =========================================================================

  @GET('community/facilities')
  Future<RowList> getFacilities();

  @GET('community/facility-bookings')
  Future<RowList> getFacilityBookings(@Query('search') String? search);

  /// Facilities and flats for the booking form.
  @GET('community/facility-bookings/lookups')
  Future<dynamic> getFacilityBookingLookups();

  @GET('community/facility-bookings/charge')
  Future<dynamic> getFacilityCharge(@Query('facilityId') int facilityId);

  @POST('community/facility-bookings')
  Future<dynamic> createFacilityBooking(@Body() FacilityBookingRequest request);

  @DELETE('community/facility-bookings/{id}')
  Future<dynamic> deleteFacilityBooking(@Path('id') int id);

  // =========================================================================
  // COMMUNITY - MESSAGES, POLLS, SUGGESTIONS, EVENTS, MEETINGS, DOCUMENTS
  // =========================================================================

  @GET('community/messages')
  Future<RowList> getMessages();

  @GET('community/messages/count')
  Future<dynamic> getUnreadMessageCount();

  @PUT('community/messages/{id}/read')
  Future<dynamic> markMessageRead(@Path('id') int id);

  @GET('community/polls')
  Future<RowList> getPolls();

  @GET('community/polls/{id}/votes')
  Future<RowList> getPollVotes(@Path('id') int id);

  @POST('community/polls')
  Future<dynamic> createPoll(@Body() Map<String, dynamic> body);

  @DELETE('community/polls/{id}')
  Future<dynamic> deletePoll(@Path('id') int id);

  @GET('community/suggestions')
  Future<RowList> getSuggestions(@Query('search') String? search);

  @GET('community/suggestions/{id}')
  Future<dynamic> getSuggestion(@Path('id') int id);

  @POST('community/suggestions')
  Future<dynamic> createSuggestion(@Body() Map<String, dynamic> body);

  @PUT('community/suggestions/{id}')
  Future<dynamic> updateSuggestion(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('community/suggestions/{id}')
  Future<dynamic> deleteSuggestion(@Path('id') int id);

  @GET('community/events')
  Future<RowList> getEvents(@Query('search') String? search);

  @POST('community/events')
  Future<dynamic> createEvent(@Body() Map<String, dynamic> body);

  @PUT('community/events/{id}')
  Future<dynamic> updateEvent(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('community/events/{id}')
  Future<dynamic> deleteEvent(@Path('id') int id);

  @GET('community/meetings')
  Future<RowList> getMeetings(@Query('search') String? search);

  @POST('community/meetings')
  Future<dynamic> createMeeting(@Body() Map<String, dynamic> body);

  @PUT('community/meetings/{id}')
  Future<dynamic> updateMeeting(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('community/meetings/{id}')
  Future<dynamic> deleteMeeting(@Path('id') int id);

  @GET('community/documents')
  Future<RowList> getDocuments(@Query('search') String? search);

  @DELETE('community/documents/{id}')
  Future<dynamic> deleteDocument(@Path('id') int id);

  // ===== NOTIFICATIONS =====

  @GET('community/notifications')
  Future<RowList> getNotifications();

  @PUT('community/notifications/{id}/seen')
  Future<dynamic> markNotificationSeen(@Path('id') int id);

  // =========================================================================
  // MASTERS - lookups the screens above need
  // =========================================================================

  @GET('masters/flats')
  Future<RowList> getFlats(@Query('search') String? search);

  @GET('masters/owners')
  Future<RowList> getOwners(@Query('search') String? search);

  @GET('masters/buildings')
  Future<RowList> getBuildings();

  @GET('masters/society')
  Future<dynamic> getSocietyProfile();

  /// One flat's outstanding months — the `ownerDue` breakdown behind the
  /// defaulters list.
  @GET('masters/owner-extras/dues')
  Future<RowList> getOwnerDues(@Query('flatId') int flatId);
}
