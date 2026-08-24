import 'package:dio/dio.dart';

import '../../domain/models/bill_preview.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/models/pdc_request.dart';
import '../../domain/models/receipt_request.dart';
import '../../domain/usecase/billing_usecase.dart';
import 'list_state.dart';

/// Collection keys. Named constants rather than bare strings so a typo in a
/// screen is a compile error.
class BillingKeys {
  static const runs = 'runs';
  static const charges = 'charges';
  static const defaulters = 'defaulters';
  static const receipts = 'receipts';
  static const residents = 'residents';
  static const outstanding = 'outstanding';
  static const advance = 'advance';
  static const pdc = 'pdc';
  static const pdcClearing = 'pdcClearing';

  /// Residents the add-cheque form files a cheque against.
  static const pdcOwners = 'pdcOwners';

  /// One flat's post-dated cheques, on the receipt form. Kept apart from [pdc],
  /// which is the whole society's register — the two screens would otherwise
  /// overwrite each other's rows.
  static const flatPdc = 'flatPdc';
}

class BillingViewModel extends ListViewModel {
  final BillingUsecase usecase;

  /// Result of the last generation preview or run, for the confirm dialog.
  BillPreview? lastPreview;
  Map<String, dynamic>? lastGeneration;

  BillingViewModel(this.usecase);

  // ===== BILLS =====

  Future<void> loadBillRuns({int? year, int? month}) => load(
    BillingKeys.runs,
    () => usecase.getBillRuns(year: year, month: month),
  );

  Future<void> loadCharges() =>
      load(BillingKeys.charges, usecase.getBillCharges);

  Future<void> loadDefaulters() =>
      load(BillingKeys.defaulters, usecase.getDefaulters);

  Future<Map<String, dynamic>> billDetail(int billId, {int? flatId}) =>
      usecase.getBillDetail(billId, flatId: flatId);

  /// One receipt and the bills it settled.
  Future<Map<String, dynamic>> receiptDetail(int id) => usecase.getReceipt(id);

  /// The months behind one flat's dues, for the defaulter detail sheet.
  Future<RowList> ownerDues(int flatId) => usecase.getOwnerDues(flatId);

  // ===== GENERATION =====

  /// Fetch the preview shown before the secretary confirms a run.
  Future<bool> loadPreview() {
    return run(
      () async => lastPreview = await usecase.getGenerationPreview(),
      guard: 'preview',
    );
  }

  /// Raise this month's regular bills. Only call after showing the preview.
  Future<bool> generateRegular() {
    return run(
      () async => lastGeneration = await usecase.generateRegularBills(),
      guard: 'generate',
      // The server reports "nothing generated" as a successful response with a
      // message, so the message comes from the payload rather than being
      // assumed here.
      onSuccess: loadBillRuns,
    );
  }

  /// True when the last add-on run was refused as a same-day repeat.
  ///
  /// sp_new_maintenance has no duplicate guard of its own, so the API refuses
  /// a second run on a day that already has one and answers 409. That is a
  /// question for the secretary, not an error — two genuinely separate add-ons
  /// in a day is a real case — so the status is kept for the screen to act on.
  bool lastAddOnWasDuplicate = false;

  /// Raise the pending add-on charges.
  Future<bool> generateAddon({
    int? duePeriodMonths,
    double? interestRate,
    bool allowDuplicate = false,
  }) {
    lastAddOnWasDuplicate = false;

    return run(
      () async {
        try {
          lastGeneration = await usecase.generateAddonBills(
            duePeriodMonths: duePeriodMonths,
            interestRate: interestRate,
            allowDuplicate: allowDuplicate,
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 409) lastAddOnWasDuplicate = true;
          rethrow;
        }
      },
      guard: 'generate',
      onSuccess: () async {
        await loadBillRuns();
        await loadCharges();
      },
    );
  }

  String get generationMessage =>
      (lastGeneration?['message'] as String?) ?? 'Bill run complete.';

  // ===== RECEIPTS =====

  Future<void> loadReceipts() =>
      load(BillingKeys.receipts, usecase.getReceipts);

  Future<void> loadResidents() =>
      load(BillingKeys.residents, usecase.getReceiptResidents);

  /// The bills a payment from this flat can settle, the credit already on file,
  /// and any post-dated cheques it has lodged.
  ///
  /// The PDC lookup is allowed to fail on its own: a society that has never
  /// taken a post-dated cheque should still get the bill list, which is what
  /// the payment actually needs.
  Future<void> loadFlatDues(int flatId) => loadAll({
    BillingKeys.outstanding: () => usecase.getOutstandingBills(flatId),
    BillingKeys.advance: () => usecase.getAdvanceBalance(flatId),
    BillingKeys.flatPdc: () async {
      try {
        return await usecase.getReceiptPdc(flatId);
      } catch (_) {
        return const RowList();
      }
    },
  });

  Future<bool> createReceipt(ReceiptRequest request) {
    return run(
      () => usecase.createReceipt(request),
      guard: 'receipt',
      successMessage: 'Receipt recorded.',
      onSuccess: () async {
        await loadReceipts();
        await loadFlatDues(request.flatId);
      },
    );
  }

  Future<bool> cancelReceipt(int id) {
    return run(
      () => usecase.cancelReceipt(id),
      guard: 'receipt',
      successMessage: 'Receipt cancelled.',
      onSuccess: loadReceipts,
    );
  }

  // ===== PDC =====

  Future<void> loadPdc({String? search}) =>
      load(BillingKeys.pdc, () => usecase.getPdcList(search: search));

  Future<void> loadPdcClearing({String? from, String? to}) => load(
    BillingKeys.pdcClearing,
    () => usecase.getPdcClearing(from: from, to: to),
  );

  /// Residents the add-cheque form can file a cheque against.
  Future<void> loadPdcOwners() =>
      load(BillingKeys.pdcOwners, usecase.getPdcOwners);

  /// The chosen resident's contact block, for the form's read-only panel.
  Future<Map<String, dynamic>> pdcOwnerDetails(int ownerId) =>
      usecase.getPdcOwnerDetails(ownerId);

  /// Cheques already on file for that resident, shown while filing another.
  Future<RowList> pdcByOwner(int ownerId) => usecase.getPdcByOwner(ownerId);

  Future<bool> createPdc(PdcRequest request) {
    return run(
      () => usecase.createPdc(request),
      guard: 'pdc',
      successMessage: 'Cheque saved.',
      onSuccess: loadPdc,
    );
  }

  Future<bool> updatePdc(int id, PdcRequest request) {
    return run(
      () => usecase.updatePdc(id, request),
      guard: 'pdc',
      successMessage: 'Cheque updated.',
      onSuccess: loadPdc,
    );
  }

  /// Marking a cheque deposited raises a receipt for its amount — the
  /// confirmation is handled in the usecase, but the caller must have asked.
  /// [from] and [to] are the window the clearing list is showing. The reload
  /// needs them: the endpoint requires both, so refreshing without them would
  /// empty the list the cheque was just cleared from.
  Future<bool> clearPdc(
    int id, {
    bool deposited = false,
    bool returned = false,
    bool cancelled = false,
    String? from,
    String? to,
  }) {
    return run(
      () => usecase.clearPdc(
        id,
        deposited: deposited,
        returned: returned,
        cancelled: cancelled,
      ),
      guard: 'pdc',
      successMessage: deposited
          ? 'Cheque deposited and receipt raised.'
          : 'Cheque updated.',
      onSuccess: () async {
        await loadPdc();
        await loadPdcClearing(from: from, to: to);
      },
    );
  }

  Future<bool> deletePdc(int id) {
    return run(
      () => usecase.deletePdc(id),
      guard: 'pdc',
      successMessage: 'Cheque removed.',
      onSuccess: loadPdc,
    );
  }
}
