import '../../domain/models/expense_request.dart';
import '../../domain/usecase/accounts_usecase.dart';
import 'list_state.dart';

class AccountsKeys {
  static const expenses = 'expenses';
  static const cashbook = 'cashbook';
  static const ledger = 'ledger';
  static const societyReceipts = 'societyReceipts';
  static const otherCredits = 'otherCredits';
  static const shopMaintenance = 'shopMaintenance';
  static const vendors = 'vendors';
  static const vendorBills = 'vendorBills';
}

class AccountsViewModel extends ListViewModel {
  final AccountsUsecase usecase;

  /// Vendors, approvers and expense heads for the vendor-bill form.
  Map<String, dynamic>? vendorFormData;

  AccountsViewModel(this.usecase);

  // ===== EXPENSES =====

  Future<void> loadExpenses({String? search}) =>
      load(AccountsKeys.expenses, () => usecase.getExpenses(search: search));

  Future<bool> createExpense(ExpenseRequest request) {
    return run(
      () => usecase.createExpense(request),
      guard: 'expense',
      successMessage: 'Expense saved.',
      onSuccess: loadExpenses,
    );
  }

  Future<bool> updateExpense(int id, ExpenseRequest request) {
    return run(
      () => usecase.updateExpense(id, request),
      guard: 'expense',
      successMessage: 'Expense updated.',
      onSuccess: loadExpenses,
    );
  }

  Future<bool> deleteExpense(int id) {
    return run(
      () => usecase.deleteExpense(id),
      guard: 'expense',
      successMessage: 'Expense deleted.',
      onSuccess: loadExpenses,
    );
  }

  // ===== BOOKS =====

  Future<void> loadCashbook({String? from, String? to}) => load(
    AccountsKeys.cashbook,
    () => usecase.getCashbook(from: from, to: to),
  );

  Future<void> loadLedger({String? search}) =>
      load(AccountsKeys.ledger, () => usecase.getLedger(search: search));

  Future<void> loadSocietyReceipts({String? search}) => load(
    AccountsKeys.societyReceipts,
    () => usecase.getSocietyReceipts(search: search),
  );

  Future<void> loadOtherCredits({String? search}) => load(
    AccountsKeys.otherCredits,
    () => usecase.getOtherCredits(search: search),
  );

  Future<void> loadShopMaintenance({String? search}) => load(
    AccountsKeys.shopMaintenance,
    () => usecase.getShopMaintenance(search: search),
  );

  /// The three read-only books, which the Ledger screen shows as tabs.
  ///
  /// [loadAll] rather than three [load] calls behind a `Future.wait`: each
  /// `load` marks its own key by spreading the state map it read *before*
  /// awaiting, so three of them starting together all spread the same original
  /// map and only the last one's mark survived — the other tabs were left
  /// showing a spinner over rows that had in fact arrived. Batching also means
  /// one refresh of an expired access token covers all three rather than
  /// several 401s racing to rotate the same refresh token.
  Future<void> loadBooks({String? search}) => loadAll({
    AccountsKeys.ledger: () => usecase.getLedger(search: search),
    AccountsKeys.otherCredits: () => usecase.getOtherCredits(search: search),
    AccountsKeys.shopMaintenance: () =>
        usecase.getShopMaintenance(search: search),
  });

  // ===== VENDORS =====

  Future<void> loadVendors({String? search}) =>
      load(AccountsKeys.vendors, () => usecase.getVendors(search: search));

  Future<void> loadVendorBills({String? search}) => load(
    AccountsKeys.vendorBills,
    () => usecase.getVendorBills(search: search),
  );

  Future<bool> loadVendorFormData() {
    return run(
      () async => vendorFormData = await usecase.getVendorBillFormData(),
      guard: 'vendorForm',
    );
  }

  /// Register a vendor, then refresh both the vendor list and the form data —
  /// the new vendor has to appear in the bill form's dropdown straight away,
  /// which reads from [vendorFormData] rather than the list.
  Future<bool> createVendor(Map<String, dynamic> body) {
    return run(
      () => usecase.createVendor(body),
      guard: 'vendor',
      successMessage: 'Vendor added.',
      onSuccess: () async {
        await loadVendors();
        vendorFormData = await usecase.getVendorBillFormData();
      },
    );
  }

  Future<bool> updateVendor(int id, Map<String, dynamic> body) {
    return run(
      () => usecase.updateVendor(id, body),
      guard: 'vendor',
      successMessage: 'Vendor updated.',
      onSuccess: () async {
        await loadVendors();
        vendorFormData = await usecase.getVendorBillFormData();
      },
    );
  }

  Future<bool> deleteVendor(int id) {
    return run(
      () => usecase.deleteVendor(id),
      guard: 'vendor',
      successMessage: 'Vendor deleted.',
      onSuccess: loadVendors,
    );
  }

  /// One bill with its items, approvals and payments.
  ///
  /// Returned rather than pushed into state: only the detail sheet wants it,
  /// and parking it in a collection would leave the last-opened bill behind
  /// for the next one to flash before its own load lands.
  Future<Map<String, dynamic>?> loadVendorBill(int id) async {
    try {
      return await usecase.getVendorBill(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createVendorBill(Map<String, dynamic> body) {
    return run(
      () => usecase.createVendorBill(body),
      guard: 'vendorBill',
      successMessage: 'Vendor bill saved.',
      onSuccess: loadVendorBills,
    );
  }

  Future<bool> deleteVendorBill(int id) {
    return run(
      () => usecase.deleteVendorBill(id),
      guard: 'vendorBill',
      successMessage: 'Vendor bill deleted.',
      onSuccess: loadVendorBills,
    );
  }

  /// Money leaving the society account, so the list is refetched to show the
  /// bill's new paid and outstanding figures.
  Future<bool> payVendorBill(int id, Map<String, dynamic> body) {
    return run(
      () => usecase.payVendorBill(id, body),
      guard: 'vendorPayment',
      successMessage: 'Payment recorded against the bill.',
      onSuccess: loadVendorBills,
    );
  }

  Future<bool> decideVendorBill(
    int billId,
    int approvalId,
    Map<String, dynamic> body,
  ) {
    return run(
      () => usecase.decideVendorBill(billId, approvalId, body),
      guard: 'vendorApproval',
      successMessage: body['decision'] == 'reject'
          ? 'Bill rejected.'
          : 'Bill approved.',
      onSuccess: loadVendorBills,
    );
  }
}
