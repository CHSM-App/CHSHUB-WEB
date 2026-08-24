import '../models/bill_preview.dart';
import '../models/generate_bill_request.dart';
import '../models/paged_rows.dart';
import '../models/pdc_request.dart';
import '../models/receipt_request.dart';

abstract class BillingRepository {
  // ===== BILLS =====
  Future<RowList> getBillRuns({int? year, int? month});
  Future<Map<String, dynamic>> getBillDetail(int billId, {int? flatId});
  Future<RowList> getBillCharges();
  Future<RowList> getDefaulters();

  /// One flat's outstanding months, behind a defaulter row.
  Future<RowList> getOwnerDues(int flatId);

  // ===== GENERATION =====
  Future<BillPreview> getGenerationPreview();
  Future<Map<String, dynamic>> generateRegularBills(
    GenerateBillRequest request,
  );
  Future<Map<String, dynamic>> generateAddonBills(GenerateBillRequest request);

  // ===== RECEIPTS =====
  Future<RowList> getReceipts();
  Future<RowList> getReceiptResidents();
  Future<RowList> getOutstandingBills(int flatId);
  Future<RowList> getAdvanceBalance(int flatId);

  /// Post-dated cheques on file for one flat, to pay a receipt with.
  Future<RowList> getReceiptPdc(int flatId);

  /// One receipt, with the bill lines it settled.
  Future<Map<String, dynamic>> getReceipt(int id);

  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request);
  Future<void> cancelReceipt(int id);

  // ===== PDC =====
  Future<RowList> getPdcList({String? search});

  /// Residents to file a cheque against — the form's owner picker.
  Future<RowList> getPdcOwners();

  /// The chosen resident's contact block, shown read-only on the form.
  Future<Map<String, dynamic>> getPdcOwnerDetails(int ownerId);

  /// Cheques already on file for that resident, so a duplicate is visible
  /// before one more is added.
  Future<RowList> getPdcByOwner(int ownerId);

  Future<RowList> getPdcClearing({String? from, String? to});
  Future<void> createPdc(PdcRequest request);
  Future<void> updatePdc(int id, PdcRequest request);
  Future<void> clearPdc(int id, PdcClearRequest request);
  Future<void> deletePdc(int id);
}
