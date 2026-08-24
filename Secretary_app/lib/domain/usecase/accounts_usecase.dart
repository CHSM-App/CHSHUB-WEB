import '../models/expense_request.dart';
import '../models/paged_rows.dart';
import '../repository/accounts_repo.dart';

class AccountsUsecase {
  final AccountsRepository repository;

  AccountsUsecase(this.repository);

  /// Society expenses, optionally filtered.
  Future<RowList> getExpenses({String? search}) =>
      repository.getExpenses(search: search);

  /// Record a society expense.
  Future<void> createExpense(ExpenseRequest request) =>
      repository.createExpense(request);

  Future<void> updateExpense(int id, ExpenseRequest request) =>
      repository.updateExpense(id, request);

  Future<void> deleteExpense(int id) => repository.deleteExpense(id);

  /// Cash in and out over a date range.
  Future<RowList> getCashbook({String? from, String? to}) =>
      repository.getCashbook(from: from, to: to);

  /// The society ledger.
  Future<RowList> getLedger({String? search}) =>
      repository.getLedger(search: search);

  /// Receipts raised by the society itself, as opposed to maintenance.
  Future<RowList> getSocietyReceipts({String? search}) =>
      repository.getSocietyReceipts(search: search);

  /// Income that is not maintenance — interest, rent, donations.
  Future<RowList> getOtherCredits({String? search}) =>
      repository.getOtherCredits(search: search);

  /// Maintenance billed to commercial units.
  Future<RowList> getShopMaintenance({String? search}) =>
      repository.getShopMaintenance(search: search);

  /// Registered vendors.
  Future<RowList> getVendors({String? search}) =>
      repository.getVendors(search: search);

  /// Register a vendor.
  Future<void> createVendor(Map<String, dynamic> body) =>
      repository.createVendor(body);

  Future<void> updateVendor(int id, Map<String, dynamic> body) =>
      repository.updateVendor(id, body);

  Future<void> deleteVendor(int id) => repository.deleteVendor(id);

  /// Vendor bills awaiting approval or payment.
  Future<RowList> getVendorBills({String? search}) =>
      repository.getVendorBills(search: search);

  /// Vendors, approvers and expense heads for the vendor-bill form.
  Future<Map<String, dynamic>> getVendorBillFormData() =>
      repository.getVendorBillFormData();

  /// One bill with its items, approvals and payments.
  Future<Map<String, dynamic>> getVendorBill(int id) =>
      repository.getVendorBill(id);

  Future<void> createVendorBill(Map<String, dynamic> body) =>
      repository.createVendorBill(body);

  Future<void> deleteVendorBill(int id) => repository.deleteVendorBill(id);

  /// Record a payment against a bill — cheque, online or cash.
  Future<void> payVendorBill(int id, Map<String, dynamic> body) =>
      repository.payVendorBill(id, body);

  /// Approve or reject one approver's line on a bill.
  Future<void> decideVendorBill(
    int billId,
    int approvalId,
    Map<String, dynamic> body,
  ) => repository.decideVendorBill(billId, approvalId, body);
}
