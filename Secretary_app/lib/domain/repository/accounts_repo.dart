import '../models/expense_request.dart';
import '../models/paged_rows.dart';

abstract class AccountsRepository {
  // ===== EXPENSES =====
  Future<RowList> getExpenses({String? search});
  Future<void> createExpense(ExpenseRequest request);
  Future<void> updateExpense(int id, ExpenseRequest request);
  Future<void> deleteExpense(int id);

  // ===== BOOKS =====
  Future<RowList> getCashbook({String? from, String? to});
  Future<RowList> getLedger({String? search});
  Future<RowList> getSocietyReceipts({String? search});
  Future<RowList> getOtherCredits({String? search});
  Future<RowList> getShopMaintenance({String? search});

  // ===== VENDORS =====
  Future<RowList> getVendors({String? search});
  Future<void> createVendor(Map<String, dynamic> body);
  Future<void> updateVendor(int id, Map<String, dynamic> body);
  Future<void> deleteVendor(int id);

  // ===== VENDOR BILLS =====
  Future<RowList> getVendorBills({String? search});
  Future<Map<String, dynamic>> getVendorBillFormData();

  /// One bill with its items, approvals and payments.
  Future<Map<String, dynamic>> getVendorBill(int id);
  Future<void> createVendorBill(Map<String, dynamic> body);
  Future<void> deleteVendorBill(int id);

  /// Record a payment against a bill — cheque, online or cash.
  Future<void> payVendorBill(int id, Map<String, dynamic> body);

  /// Approve or reject one approver's line on a bill.
  Future<void> decideVendorBill(
    int billId,
    int approvalId,
    Map<String, dynamic> body,
  );
}
