import '../models/bill_preview.dart';
import '../models/generate_bill_request.dart';
import '../models/paged_rows.dart';
import '../models/pdc_request.dart';
import '../models/receipt_request.dart';
import '../repository/billing_repo.dart';

class BillingUsecase {
  final BillingRepository repository;

  BillingUsecase(this.repository);

  // ===== BILLS =====

  /// Past bill runs, newest first.
  Future<RowList> getBillRuns({int? year, int? month}) =>
      repository.getBillRuns(year: year, month: month);

  /// Every flat's bill within one run.
  Future<Map<String, dynamic>> getBillDetail(int billId, {int? flatId}) =>
      repository.getBillDetail(billId, flatId: flatId);

  /// Add-on charge heads that a run has not yet billed.
  Future<RowList> getBillCharges() => repository.getBillCharges();

  /// Flats with dues past their due date.
  Future<RowList> getDefaulters() => repository.getDefaulters();

  /// The months behind one flat's dues — the `ownerDue` breakdown the legacy
  /// Defaulter page showed in its Payment Details modal.
  Future<RowList> getOwnerDues(int flatId) => repository.getOwnerDues(flatId);

  // ===== GENERATION =====

  /// What a run would raise. Always shown before generating.
  Future<BillPreview> getGenerationPreview() =>
      repository.getGenerationPreview();

  /// Raise this month's regular maintenance bills.
  Future<Map<String, dynamic>> generateRegularBills() =>
      repository.generateRegularBills(const GenerateBillRequest(confirm: true));

  /// Raise the pending add-on charges.
  Future<Map<String, dynamic>> generateAddonBills({
    int? duePeriodMonths,
    double? interestRate,
    bool allowDuplicate = false,
  }) {
    return repository.generateAddonBills(
      GenerateBillRequest(
        confirm: true,
        duePeriodMonths: duePeriodMonths,
        interestRate: interestRate,
        allowDuplicate: allowDuplicate,
      ),
    );
  }

  // ===== RECEIPTS =====

  /// Receipts recorded so far, with the total collected.
  Future<RowList> getReceipts() => repository.getReceipts();

  /// Flats to choose from on the receipt form.
  Future<RowList> getReceiptResidents() => repository.getReceiptResidents();

  /// Bills a payment from this flat can settle.
  Future<RowList> getOutstandingBills(int flatId) =>
      repository.getOutstandingBills(flatId);

  /// Credit already sitting on the flat.
  Future<RowList> getAdvanceBalance(int flatId) =>
      repository.getAdvanceBalance(flatId);

  /// Post-dated cheques this flat has lodged, to pay a receipt with.
  Future<RowList> getReceiptPdc(int flatId) => repository.getReceiptPdc(flatId);

  /// One receipt and the bills it settled, for the view sheet.
  Future<Map<String, dynamic>> getReceipt(int id) => repository.getReceipt(id);

  /// Record a maintenance payment against the selected bills.
  Future<Map<String, dynamic>> createReceipt(ReceiptRequest request) =>
      repository.createReceipt(request);

  /// Reverse a receipt that was recorded in error.
  Future<void> cancelReceipt(int id) => repository.cancelReceipt(id);

  // ===== PDC =====

  /// Post-dated cheques on file.
  Future<RowList> getPdcList({String? search}) =>
      repository.getPdcList(search: search);

  /// Residents to file a cheque against — the form's owner picker.
  Future<RowList> getPdcOwners() => repository.getPdcOwners();

  /// The chosen resident's contact block, unwrapped from the API's `{owner}`.
  Future<Map<String, dynamic>> getPdcOwnerDetails(int ownerId) async {
    final body = await repository.getPdcOwnerDetails(ownerId);
    final owner = body['owner'];
    return owner is Map ? Map<String, dynamic>.from(owner) : body;
  }

  /// Cheques already on file for that resident.
  Future<RowList> getPdcByOwner(int ownerId) =>
      repository.getPdcByOwner(ownerId);

  /// Cheques bankable between two dates — the clearing worklist.
  Future<RowList> getPdcClearing({String? from, String? to}) =>
      repository.getPdcClearing(from: from, to: to);

  /// Put a new cheque on file.
  Future<void> createPdc(PdcRequest request) => repository.createPdc(request);

  Future<void> updatePdc(int id, PdcRequest request) =>
      repository.updatePdc(id, request);

  /// Mark a cheque deposited, returned or cancelled. Depositing also raises a
  /// receipt, which is why the confirmation is explicit.
  Future<void> clearPdc(
    int id, {
    bool deposited = false,
    bool returned = false,
    bool cancelled = false,
  }) {
    return repository.clearPdc(
      id,
      PdcClearRequest(
        deposited: deposited,
        returned: returned,
        cancelled: cancelled,
        confirm: deposited,
      ),
    );
  }

  Future<void> deletePdc(int id) => repository.deletePdc(id);
}
