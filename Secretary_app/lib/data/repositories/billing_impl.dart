import '../../domain/models/bill_preview.dart';
import '../../domain/models/generate_bill_request.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/models/pdc_request.dart';
import '../../domain/models/receipt_request.dart';
import '../../domain/repository/billing_repo.dart';
import '../api/api_service.dart';

class BillingImpl implements BillingRepository {
  final ApiService api;

  BillingImpl(this.api);

  // ===== BILLS =====

  @override
  Future<RowList> getBillRuns({int? year, int? month}) =>
      api.getBillRuns(year, month);

  @override
  Future<Map<String, dynamic>> getBillDetail(int billId, {int? flatId}) async {
    return asRow(await api.getBillDetail(billId, flatId));
  }

  @override
  Future<RowList> getBillCharges() => api.getBillCharges();

  @override
  Future<RowList> getDefaulters() => api.getDefaulters();

  @override
  Future<RowList> getOwnerDues(int flatId) => api.getOwnerDues(flatId);

  // ===== GENERATION =====

  @override
  Future<BillPreview> getGenerationPreview() => api.getGenerationPreview();

  @override
  Future<Map<String, dynamic>> generateRegularBills(
    GenerateBillRequest request,
  ) async {
    return asRow(await api.generateRegularBills(request));
  }

  @override
  Future<Map<String, dynamic>> generateAddonBills(
    GenerateBillRequest request,
  ) async {
    return asRow(await api.generateAddonBills(request));
  }

  // ===== RECEIPTS =====

  @override
  Future<RowList> getReceipts() => api.getReceipts();

  @override
  Future<RowList> getReceiptResidents() => api.getReceiptResidents();

  @override
  Future<RowList> getOutstandingBills(int flatId) =>
      api.getOutstandingBills(flatId);

  @override
  Future<RowList> getAdvanceBalance(int flatId) =>
      api.getAdvanceBalance(flatId);

  @override
  Future<RowList> getReceiptPdc(int flatId) => api.getReceiptPdc(flatId);

  @override
  Future<Map<String, dynamic>> getReceipt(int id) async =>
      asRow(await api.getReceipt(id));

  @override
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) async {
    return asRow(await api.createReceipt(request));
  }

  @override
  Future<void> cancelReceipt(int id) => api.cancelReceipt(id);

  // ===== PDC =====

  @override
  Future<RowList> getPdcList({String? search}) => api.getPdcList(search);

  @override
  Future<RowList> getPdcOwners() => api.getOwners(null);

  @override
  Future<Map<String, dynamic>> getPdcOwnerDetails(int ownerId) async =>
      asRow(await api.getPdcOwnerDetails(ownerId));

  @override
  Future<RowList> getPdcByOwner(int ownerId) => api.getPdcByOwner(ownerId);

  @override
  Future<RowList> getPdcClearing({String? from, String? to}) =>
      api.getPdcClearing(from, to);

  @override
  Future<void> createPdc(PdcRequest request) => api.createPdc(request);

  @override
  Future<void> updatePdc(int id, PdcRequest request) =>
      api.updatePdc(id, request);

  @override
  Future<void> clearPdc(int id, PdcClearRequest request) =>
      api.clearPdc(id, request);

  @override
  Future<void> deletePdc(int id) => api.deletePdc(id);
}
