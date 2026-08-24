import '../../domain/models/expense_request.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/repository/accounts_repo.dart';
import '../api/api_service.dart';

class AccountsImpl implements AccountsRepository {
  final ApiService api;

  AccountsImpl(this.api);

  // ===== EXPENSES =====

  @override
  Future<RowList> getExpenses({String? search}) => api.getExpenses(search);

  @override
  Future<void> createExpense(ExpenseRequest request) =>
      api.createExpense(request);

  @override
  Future<void> updateExpense(int id, ExpenseRequest request) =>
      api.updateExpense(id, request);

  @override
  Future<void> deleteExpense(int id) => api.deleteExpense(id);

  // ===== BOOKS =====

  @override
  Future<RowList> getCashbook({String? from, String? to}) =>
      api.getCashbook(from, to);

  @override
  Future<RowList> getLedger({String? search}) => api.getLedger(search);

  @override
  Future<RowList> getSocietyReceipts({String? search}) =>
      api.getSocietyReceipts(search);

  @override
  Future<RowList> getOtherCredits({String? search}) =>
      api.getOtherCredits(search);

  @override
  Future<RowList> getShopMaintenance({String? search}) =>
      api.getShopMaintenance(search);

  // ===== VENDORS =====

  @override
  Future<RowList> getVendors({String? search}) => api.getVendors(search);

  @override
  Future<void> createVendor(Map<String, dynamic> body) =>
      api.createVendor(body);

  @override
  Future<void> updateVendor(int id, Map<String, dynamic> body) =>
      api.updateVendor(id, body);

  @override
  Future<void> deleteVendor(int id) => api.deleteVendor(id);

  // ===== VENDOR BILLS =====

  @override
  Future<RowList> getVendorBills({String? search}) =>
      api.getVendorBills(search);

  @override
  Future<Map<String, dynamic>> getVendorBillFormData() async {
    return asRow(await api.getVendorBillFormData());
  }

  @override
  Future<Map<String, dynamic>> getVendorBill(int id) async {
    return asRow(await api.getVendorBill(id));
  }

  @override
  Future<void> createVendorBill(Map<String, dynamic> body) =>
      api.createVendorBill(body);

  @override
  Future<void> deleteVendorBill(int id) => api.deleteVendorBill(id);

  @override
  Future<void> payVendorBill(int id, Map<String, dynamic> body) =>
      api.payVendorBill(id, body);

  @override
  Future<void> decideVendorBill(
    int billId,
    int approvalId,
    Map<String, dynamic> body,
  ) => api.decideVendorBill(billId, approvalId, body);
}
