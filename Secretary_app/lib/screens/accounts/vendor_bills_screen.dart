import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pdf/vendor_bill_export.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/accounts_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

// ── The four service types, as VendorBill.aspx ordered them ──────────────
//
// The value is what the SP stores in service_type, so these are the numbers
// the API is sent — not display indexes.
class _Service {
  static const staff = 0;
  static const daily = 1;
  static const inventory = 2;
  static const service = 3;
}

const _serviceTypes = <AppOption<int>>[
  AppOption(_Service.staff, 'Staff Payment', icon: Icons.badge_outlined),
  AppOption(_Service.daily, 'Daily Expense', icon: Icons.receipt_long_outlined),
  AppOption(
    _Service.inventory,
    'Vendor-Inventory Payment',
    icon: Icons.inventory_2_outlined,
  ),
  AppOption(
    _Service.service,
    'Vendor-Service Payment',
    icon: Icons.handyman_outlined,
  ),
];

/// Bill-number prefix per service type, so each kind is told apart at a glance.
const _billPrefix = {
  _Service.staff: 'STAFF',
  _Service.daily: 'EXP',
  _Service.inventory: 'INV',
  _Service.service: 'SRV',
};

const _payModes = <AppOption<String>>[
  AppOption('Cheque', 'Cheque', icon: Icons.receipt_long_rounded),
  AppOption('Online', 'Online', icon: Icons.account_balance_rounded),
  AppOption('Cash', 'Cash', icon: Icons.payments_rounded),
];

/// A colour per payment mode, so the three are told apart by more than their
/// label — the icon plate carries it whether or not the mode is selected.
const _payModeColors = {
  'Cheque': AppTheme.info,
  'Online': AppTheme.primary,
  'Cash': AppTheme.success,
};

/// A bill number for a service type: PREFIX-YYYYMM-HHMMSS.
///
/// Month comes from the bill date and the time from now, which is what made
/// repeated numbers unlikely on the legacy page.
String _generateBillNumber(int serviceType, DateTime billDate) {
  final prefix = _billPrefix[serviceType];
  if (prefix == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  final now = DateTime.now();
  return '$prefix-${billDate.year}${two(billDate.month)}'
      '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
}

/// True when a bill number looks like one this screen stamped.
///
/// A number typed in, or one off a supplier's invoice, is left alone when the
/// service type changes — only a generated one is re-stamped.
bool _isGeneratedBillNumber(String value) {
  final prefixes = _billPrefix.values.join('|');
  return RegExp('^($prefixes)-\\d{6}-\\d{6}\$').hasMatch(value.trim());
}

/// Approval status codes, as UPDATE_STATUS writes them.
String _approvalLabel(dynamic v) {
  final n = asIntOr(v);
  if (n == 2) return 'Approved';
  if (n == 4) return 'Rejected';
  return 'Pending';
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// One inventory line on the bill form.
class _BillItem {
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unit = TextEditingController();
  final purchaseCost = TextEditingController();
  final tax = TextEditingController();
  final warrantyMonths = TextEditingController();

  /// quantity × unit price, plus this line's tax — the same expression the
  /// legacy items grid evaluated per row.
  double get total {
    final base =
        (double.tryParse(quantity.text.trim()) ?? 0) *
        (double.tryParse(purchaseCost.text.trim()) ?? 0);
    return base + base * (double.tryParse(tax.text.trim()) ?? 0) / 100;
  }

  Map<String, dynamic> toJson() => {
    'name': name.text.trim(),
    'quantity': int.tryParse(quantity.text.trim()) ?? 0,
    'unit': unit.text.trim(),
    'purchaseCost': double.tryParse(purchaseCost.text.trim()) ?? 0,
    'tax': double.tryParse(tax.text.trim()) ?? 0,
    'warrantyMonths': int.tryParse(warrantyMonths.text.trim()) ?? 0,
    'totalAmount': total,
  };

  void dispose() {
    for (final c in [name, quantity, unit, purchaseCost, tax, warrantyMonths]) {
      c.dispose();
    }
  }
}

/// What a payment carries, in whichever mode it is being made.
class _Payment {
  String? mode;
  final transactionRef = TextEditingController();
  final chequeNo = TextEditingController();
  final bankName = TextEditingController();
  final amount = TextEditingController();
  final remarks = TextEditingController();
  DateTime? chequeDate;

  /// Same rule as IsPaymentDataFilled(): a mode picked, with a positive amount.
  bool get isFilled =>
      mode != null && (double.tryParse(amount.text.trim()) ?? 0) > 0;

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'amount': double.tryParse(amount.text.trim()) ?? 0,
    if (mode == 'Online') 'transactionRef': transactionRef.text.trim(),
    if (mode == 'Cheque') ...{
      'chequeNo': chequeNo.text.trim(),
      'bankName': bankName.text.trim(),
      if (chequeDate != null) 'chequeDate': _isoDate(chequeDate!),
    },
    if (remarks.text.trim().isNotEmpty) 'remarks': remarks.text.trim(),
  };

  void dispose() {
    for (final c in [transactionRef, chequeNo, bankName, amount, remarks]) {
      c.dispose();
    }
  }
}

/// What the bill list is narrowed to.
///
/// Payment state and approval state in one list of choices: they are what a
/// secretary actually looks for — what still needs paying, what is waiting on
/// the committee — and splitting them across two menus would mean two taps to
/// answer one question.
enum _BillFilter {
  all('All bills', Icons.list_alt_rounded),
  unpaid('Unpaid', Icons.error_outline_rounded),
  // Worded as the SP words it — Grid_Show returns 'Partially Paid' as the
  // payment_status, and that is what the chip on each card reads. A filter
  // called something else would look like it narrowed by a different thing.
  partial('Partially Paid', Icons.timelapse_rounded),
  paid('Fully paid', Icons.check_circle_outline_rounded),
  pending('Awaiting approval', Icons.hourglass_empty_rounded),
  rejected('Rejected', Icons.block_outlined);

  const _BillFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  /// True when [row] belongs in this view.
  bool matches(Map<String, dynamic> row) {
    final status = asIntOr(row['status']);
    final outstanding = asDoubleOr(row['remaining_amount']);
    final paid = asDoubleOr(row['paid_amount']);

    return switch (this) {
      _BillFilter.all => true,
      // A rejected bill is not "unpaid" in any useful sense — nobody is going
      // to pay it — so it is kept out of the payment filters entirely.
      _BillFilter.unpaid => status != 4 && paid <= 0 && outstanding > 0,
      _BillFilter.partial => status != 4 && paid > 0 && outstanding > 0,
      _BillFilter.paid => status != 4 && outstanding <= 0,
      _BillFilter.pending => status == 1,
      _BillFilter.rejected => status == 4,
    };
  }
}

/// Vendor bills and the vendors behind them.
///
/// Full parity with the website's VendorBillsPage, which in turn mirrors
/// Society2024/VendorBill.aspx. That page combined four workflows behind one
/// screen and they are kept together here for the same reason:
///   1. raise a bill, with the sub-form switching on service type
///   2. quick-add a vendor without leaving the screen
///   3. pick approvers, then approve/reject
///   4. record a payment in one of three modes
class VendorBillsScreen extends ConsumerStatefulWidget {
  const VendorBillsScreen({super.key});

  @override
  ConsumerState<VendorBillsScreen> createState() => _VendorBillsScreenState();
}

class _VendorBillsScreenState extends ConsumerState<VendorBillsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// Which bills to show. Applied here rather than sent to the API — the
  /// grid returns every bill for the society in one call, and narrowing a
  /// list already in hand should not cost a round trip.
  _BillFilter _filter = _BillFilter.all;

  @override
  void initState() {
    super.initState();
    // The pills read the controller's index, so a swipe of the TabBarView has
    // to repaint them too — otherwise the highlighted pill and the list on
    // screen disagree the moment the page is swiped rather than tapped.
    _tabs.addListener(_onTabChanged);

    Future.microtask(() {
      final vm = ref.read(accountsViewModelProvider.notifier);
      vm.loadVendorBills();
      vm.loadVendors();
      // Vendors, staff, roles and approvers for the bill form — fetched up
      // front so the form opens ready rather than with empty dropdowns.
      vm.loadVendorFormData();
    });
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final search = query.trim().isEmpty ? null : query.trim();
      final vm = ref.read(accountsViewModelProvider.notifier);
      // Search whichever list is in front.
      if (_tabs.index == 0) {
        vm.loadVendorBills(search: search);
      } else {
        vm.loadVendors(search: search);
      }
    });
  }

  // These four open as pages rather than bottom sheets. A bill carries a
  // service type, a sub-form, approvers and a payment section, which is more
  // than a sheet can show without the keyboard burying half of it — and the
  // form is filled in one pass, so it wants a screen of its own.
  Future<void> _openBillForm() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const _BillFormPage()));
  }

  Future<void> _openVendorForm({Map<String, dynamic>? vendor}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _VendorFormPage(vendor: vendor)),
    );
  }

  Future<void> _openBillDetail(int id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _BillDetailPage(billId: id)),
    );
  }

  Future<void> _openPayForm(Map<String, dynamic> row) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => _PayFormPage(bill: row)));
  }

  Future<void> _confirmDeleteBill(int id, String? number) async {
    final ok = await confirmAction(
      context,
      title: 'Delete bill',
      message: number == null
          ? 'This bill will be removed from the books.'
          : 'Bill $number will be removed from the books.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(accountsViewModelProvider.notifier).deleteVendorBill(id);
  }

  Future<void> _confirmDeleteVendor(int id, String? name) async {
    final ok = await confirmAction(
      context,
      title: 'Delete vendor',
      message: '${name ?? 'This vendor'} will be removed from the register.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(accountsViewModelProvider.notifier).deleteVendor(id);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, accountsViewModelProvider);

    final state = ref.watch(accountsViewModelProvider);
    final vm = ref.read(accountsViewModelProvider.notifier);
    final onBills = _tabs.index == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Vendors & bills')),
      // The action follows the tab in front: a bill on Bills, a vendor on
      // Vendors — so the button always adds the thing being looked at.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onBills ? _openBillForm : () => _openVendorForm(),
        icon: const Icon(Icons.add),
        label: Text(onBills ? 'Add bill' : 'Add vendor'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // A pill switcher rather than Material's underline tabs: it sits
            // on the page instead of clinging to the app bar, states the
            // selection with a filled plate, and has room to carry how many
            // rows are behind each side.
            _PillTabs(
              index: _tabs.index,
              onChanged: (i) => setState(() => _tabs.index = i),
              tabs: [
                (
                  label: 'Bills',
                  icon: Icons.receipt_long_rounded,
                  count: state.items(AccountsKeys.vendorBills).length,
                ),
                (
                  label: 'Vendors',
                  icon: Icons.storefront_rounded,
                  count: state.items(AccountsKeys.vendors).length,
                ),
              ],
            ),
            // Search and totals are shared chrome above the tabs: both lists
            // are searched the same way, and swapping tab should not reshuffle
            // the box being typed into.
            SearchBarArea(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: onBills ? 'Search bills' : 'Search vendors',
              // Bills only: a vendor has no state worth narrowing by, and an
              // icon that did nothing on one tab would be worse than none.
              trailing: onBills ? _buildFilterButton() : null,
            ),
            if (onBills) _buildTotals(state.items(AccountsKeys.vendorBills)),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  RowsView(
                    rows: state.rows(AccountsKeys.vendorBills),
                    onRefresh: () => vm.loadVendorBills(),
                    emptyIcon: Icons.receipt_long_outlined,
                    emptyTitle: 'No vendor bills',
                    emptyMessage: 'Raise the first bill to get started.',
                    emptyActionLabel: 'Add bill',
                    emptyAction: _openBillForm,
                    builder: (items) {
                      final shown = items
                          .where(_filter.matches)
                          .toList(growable: false);

                      // A filter that matches nothing needs its own message:
                      // RowsView's empty state speaks for the whole list, and
                      // "raise the first bill" is wrong when there are twenty
                      // of them and none is rejected.
                      if (shown.isEmpty) {
                        return StateMessage(
                          icon: _filter.icon,
                          title: 'No ${_filter.label.toLowerCase()}',
                          message:
                              '${items.length} bill(s) here, none of them '
                              'matching this filter.',
                          actionLabel: 'Show all bills',
                          onAction: () =>
                              setState(() => _filter = _BillFilter.all),
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
                        itemCount: shown.length,
                        itemBuilder: (context, i) => _buildBill(shown[i]),
                      );
                    },
                  ),
                  RowsView(
                    rows: state.rows(AccountsKeys.vendors),
                    onRefresh: () => vm.loadVendors(),
                    emptyIcon: Icons.storefront_outlined,
                    emptyTitle: 'No vendors',
                    emptyMessage: 'Register a vendor to bill against.',
                    emptyActionLabel: 'Add vendor',
                    emptyAction: () => _openVendorForm(),
                    builder: (items) => ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _buildVendor(items[i]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The filter menu, beside the search box.
  ///
  /// Tinted while a filter is on, so a list showing three of twenty bills
  /// says why rather than looking like the other seventeen went missing.
  Widget _buildFilterButton() {
    final active = _filter != _BillFilter.all;

    return Container(
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
      ),
      child: PopupMenuButton<_BillFilter>(
        tooltip: 'Filter bills',
        initialValue: _filter,
        position: PopupMenuPosition.under,
        color: AppTheme.white,
        onSelected: (value) => setState(() => _filter = value),
        itemBuilder: (context) => [
          for (final option in _BillFilter.values)
            PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: option == _filter
                        ? AppTheme.primary
                        : AppTheme.lightText,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    option.label,
                    style: AppTheme.body2.copyWith(
                      color: option == _filter
                          ? AppTheme.primary
                          : AppTheme.darkText,
                      fontWeight: option == _filter
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Icon(
            active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            size: 20,
            color: active ? AppTheme.white : AppTheme.lightText,
          ),
        ),
      ),
    );
  }

  /// Billed, paid and outstanding across every bill on screen — the three
  /// stat cards the website heads its page with.
  Widget _buildTotals(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();

    double sum(String key) =>
        rows.fold<double>(0, (s, r) => s + asDoubleOr(r[key]));
    final due = sum('remaining_amount');

    return PageConstraints(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space2),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Billed',
                  value: compactMoney(sum('total_amount')),
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Paid',
                  value: compactMoney(sum('paid_amount')),
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Outstanding',
                  value: compactMoney(due),
                  icon: Icons.schedule_rounded,
                  color: due > 0 ? AppTheme.error : AppTheme.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBill(Map<String, dynamic> row) {
    final id = pickInt(row, ['bill_id', 'vendor_bill_id', 'id']);
    final vendor = pick(row, ['vendor_name', 'name', 'vendor']);
    final number = pick(row, ['bill_number', 'bill_no']);
    final status = pick(row, ['bill_status', 'status', 'status_name']);
    final paymentStatus = pick(row, ['payment_status']);
    final outstanding = asDoubleOr(row['remaining_amount']);

    final total = asDoubleOr(row['total_amount'] ?? row['amount']);
    final paid = asDoubleOr(row['paid_amount']);
    // A rejected bill (status 4) is not payable — the society decided not to
    // spend this money, so there is nothing left to settle.
    final rejected = asIntOr(row['status']) == 4;
    // Settled bills are marked green, part-paid amber, untouched red — the
    // spine carries it so the state is readable before anything is read.
    final spine = rejected
        ? AppTheme.deactivatedText
        : outstanding <= 0 && total > 0
        ? AppTheme.success
        : (paid > 0 ? AppTheme.warning : AppTheme.error);

    return AppCard(
      accent: spine,
      // Tighter than the default, and less on the right where the row ends in
      // icon buttons that carry their own padding.
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
      margin: const EdgeInsets.only(bottom: 10),
      // No whole-card tap: the row carries Pay and Delete, and a card that
      // also opened on a stray tap made those easy to trigger by accident.
      // Viewing is its own button in the action row instead.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(name: vendor, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor ?? 'Vendor bill',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.title.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (number != null) number,
                        prettyDate(row['bill_date'] ?? row['date']),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(total),
                    style: AppTheme.title.copyWith(fontSize: 14),
                  ),
                  if (paymentStatus != null) ...[
                    const SizedBox(height: 2),
                    StatusChip(
                      label: paymentStatus,
                      color: statusColor(paymentStatus),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // What is still owed, on one line with the bill's own status.
          //
          // This replaced a progress bar with a paid/due line under it. The
          // bar spanned the card and then ran on past the buttons below it,
          // reading as a half-finished thing rather than a figure — and it
          // cost three rows of height to say what one line says.
          const SizedBox(height: 10),
          Row(
            children: [
              if (status != null) ...[
                StatusChip(label: status, color: statusColor(status)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  rejected
                      ? 'Not payable'
                      : outstanding > 0
                      ? '${money(outstanding)} due'
                      : 'Fully paid',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption.copyWith(
                    color: rejected
                        ? AppTheme.deactivatedText
                        : outstanding > 0
                        ? AppTheme.error
                        : AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Pay only while something is owed — and never on a bill the
              // society rejected, which the API refuses outright.
              if (outstanding > 0 && !rejected)
                IconButton(
                  tooltip: 'Pay bill',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _openPayForm(row),
                  icon: const Icon(
                    Icons.payments_outlined,
                    size: 19,
                    color: AppTheme.success,
                  ),
                ),
              IconButton(
                tooltip: 'View bill',
                visualDensity: VisualDensity.compact,
                onPressed: id == null ? null : () => _openBillDetail(id),
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 19,
                  color: AppTheme.primary,
                ),
              ),
              IconButton(
                tooltip: 'Delete bill',
                visualDensity: VisualDensity.compact,
                onPressed: id == null
                    ? null
                    : () => _confirmDeleteBill(id, number),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 19,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVendor(Map<String, dynamic> row) {
    final id = pickInt(row, ['vendor_id', 'id']);
    final name = pick(row, ['vendor_name', 'name']);
    final contact = pick(row, [
      'contact_no',
      'contactNo',
      'phone',
      'mobile_no',
    ]);
    final person = pick(row, ['contact_person', 'contactPerson']);
    final service = pick(row, ['service_type', 'serviceType']);

    return AppCard(
      // Edit is a button of its own, as viewing is on a bill — a card that
      // opened a form on any tap sat too close to the delete beside it.
      child: Row(
        children: [
          // The initials tint from the name, so a register of vendors is a
          // run of distinguishable plates rather than one repeated icon.
          InitialsAvatar(name: name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Vendor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.title.copyWith(fontSize: 15),
                ),
                if (person != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    person,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ],
                if (contact != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.call_outlined,
                        size: 13,
                        color: AppTheme.lightText,
                      ),
                      const SizedBox(width: 4),
                      Text(contact, style: AppTheme.caption),
                    ],
                  ),
                ],
                if (service != null) ...[
                  const SizedBox(height: 6),
                  StatusChip(label: service, color: AppTheme.warning),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit vendor',
            visualDensity: VisualDensity.compact,
            onPressed: () => _openVendorForm(vendor: row),
            icon: const Icon(
              Icons.edit_outlined,
              size: 19,
              color: AppTheme.primary,
            ),
          ),
          IconButton(
            tooltip: 'Delete vendor',
            visualDensity: VisualDensity.compact,
            onPressed: id == null ? null : () => _confirmDeleteVendor(id, name),
            icon: const Icon(
              Icons.delete_outline,
              size: 19,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// A form page: a title bar, a scrolling body and the same padding the
/// sheets used, so the forms read identically now they are full screens.
///
/// The scroll padding leaves room under the last field for the keyboard,
/// which on a page has to be accounted for here rather than by the sheet.
class _FormPage extends StatelessWidget {
  const _FormPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Buttons on the title bar — download, print and share on a bill detail.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: actions,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // The app bar sits on the light background, so a white
                // subtitle was invisible against it — only its descenders
                // showed under the title.
                style: AppTheme.caption.copyWith(fontSize: 12),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.space5,
            AppTheme.space5,
            AppTheme.space5,
            AppTheme.space8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: children,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── add / edit vendor

/// The quick-add vendor form.
///
/// Same fields and same rules as the website's dialog: only the name is
/// mandatory, the contact number takes ten digits and nothing else, and the
/// e-mail is checked for shape rather than saved as any text.
class _VendorFormPage extends ConsumerStatefulWidget {
  const _VendorFormPage({this.vendor});

  /// The row being edited, or null when registering a new vendor.
  final Map<String, dynamic>? vendor;

  @override
  ConsumerState<_VendorFormPage> createState() => _VendorFormPageState();
}

class _VendorFormPageState extends ConsumerState<_VendorFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: pick(widget.vendor ?? {}, ['vendor_name', 'name']) ?? '',
  );
  late final _contactPerson = TextEditingController(
    text: pick(widget.vendor ?? {}, ['contact_person', 'contactPerson']) ?? '',
  );
  late final _contactNo = TextEditingController(
    text: pick(widget.vendor ?? {}, ['contact_no', 'contactNo']) ?? '',
  );
  late final _email = TextEditingController(
    text: pick(widget.vendor ?? {}, ['email']) ?? '',
  );
  late final _gstNo = TextEditingController(
    text: pick(widget.vendor ?? {}, ['gst_no', 'gstNo']) ?? '',
  );
  late final _serviceType = TextEditingController(
    text: pick(widget.vendor ?? {}, ['service_type', 'serviceType']) ?? '',
  );
  late final _address = TextEditingController(
    text: pick(widget.vendor ?? {}, ['address']) ?? '',
  );

  bool get _isEdit => widget.vendor != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _contactPerson,
      _contactNo,
      _email,
      _gstNo,
      _serviceType,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _orNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'contactPerson': _orNull(_contactPerson),
      'contactNo': _orNull(_contactNo),
      'email': _orNull(_email),
      'gstNo': _orNull(_gstNo),
      'serviceType': _orNull(_serviceType),
      'address': _orNull(_address),
    };

    final vm = ref.read(accountsViewModelProvider.notifier);
    final id = pickInt(widget.vendor ?? {}, ['vendor_id', 'id']);
    final ok = _isEdit && id != null
        ? await vm.updateVendor(id, body)
        : await vm.createVendor(body);

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsViewModelProvider).isLoading;

    return Form(
      key: _formKey,
      child: _FormPage(
        title: _isEdit ? 'Edit vendor' : 'Add vendor',
        subtitle: 'Only the vendor name is required.',
        children: [
          _VendorFields(
            name: _name,
            contactPerson: _contactPerson,
            contactNo: _contactNo,
            email: _email,
            gstNo: _gstNo,
            serviceType: _serviceType,
            address: _address,
          ),
          const SizedBox(height: 22),
          BusyButton(
            label: _isEdit ? 'Save vendor' : 'Add vendor',
            busy: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// The vendor boxes, shared by the vendor page and the quick-add dialog.
///
/// Written once so the two cannot drift apart: the register form and the
/// detour taken mid-bill have to ask for the same things, with the same rules.
class _VendorFields extends StatelessWidget {
  const _VendorFields({
    required this.name,
    required this.contactPerson,
    required this.contactNo,
    required this.email,
    required this.gstNo,
    required this.serviceType,
    required this.address,
  });

  final TextEditingController name;
  final TextEditingController contactPerson;
  final TextEditingController contactNo;
  final TextEditingController email;
  final TextEditingController gstNo;
  final TextEditingController serviceType;
  final TextEditingController address;

  @override
  Widget build(BuildContext context) {
    // Two fields to a row once there is width for it. On a phone they stack;
    // on a tablet or the desktop build a seven-box form is otherwise a very
    // long column of half-empty lines.
    final wide = MediaQuery.sizeOf(context).width >= 600;

    Widget pair(Widget first, Widget second) {
      if (!wide) {
        return Column(children: [first, const SizedBox(height: 14), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormCard(
          title: 'Who the vendor is',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Vendor name',
                  prefixIcon: Icon(Icons.storefront_outlined, size: 19),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the vendor name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: serviceType,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Service type (optional)',
                  hintText: 'Housekeeping, Plumbing, Security…',
                  prefixIcon: Icon(Icons.handyman_outlined, size: 19),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        _FormCard(
          title: 'How to reach them',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: contactPerson,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Contact person (optional)',
                  prefixIcon: Icon(Icons.person_outline, size: 19),
                ),
              ),
              const SizedBox(height: 14),
              pair(
                TextFormField(
                  controller: contactNo,
                  keyboardType: TextInputType.phone,
                  // Digits only, capped at ten — the same rule the website's
                  // `digits` field applies as the user types.
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Contact number (optional)',
                    prefixIcon: Icon(Icons.call_outlined, size: 19),
                  ),
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return null;
                    return text.length == 10 ? null : 'Enter a 10-digit number';
                  },
                ),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.mail_outline, size: 19),
                  ),
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return null;
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                        ? null
                        : 'Enter a valid email';
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: address,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        _FormCard(
          title: 'Tax',
          subtitle: 'Shown beside the vendor when raising a bill',
          child: TextFormField(
            controller: gstNo,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'GST number (optional)',
              prefixIcon: Icon(Icons.receipt_outlined, size: 19),
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick-add a vendor from inside the bill form.
///
/// Pops the new vendor's id so the bill can select it straight away — the
/// vendor was added *for* this bill, so making it the picked one saves the
/// user going back to the dropdown to find what they just typed.
class _VendorDialog extends ConsumerStatefulWidget {
  const _VendorDialog();

  @override
  ConsumerState<_VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends ConsumerState<_VendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contactPerson = TextEditingController();
  final _contactNo = TextEditingController();
  final _email = TextEditingController();
  final _gstNo = TextEditingController();
  final _serviceType = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _name,
      _contactPerson,
      _contactNo,
      _email,
      _gstNo,
      _serviceType,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _orNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = ref.read(accountsViewModelProvider.notifier);
    final name = _name.text.trim();
    final ok = await vm.createVendor({
      'name': name,
      'contactPerson': _orNull(_contactPerson),
      'contactNo': _orNull(_contactNo),
      'email': _orNull(_email),
      'gstNo': _orNull(_gstNo),
      'serviceType': _orNull(_serviceType),
      'address': _orNull(_address),
    });
    if (!ok || !mounted) return;

    // createVendor refetches the lookups, so the new row is already there —
    // matched by name, which is what the user just typed and what the SP
    // rejects duplicates of.
    final created = asRows(vm.vendorFormData?['vendors']).firstWhere(
      (v) => (pick(v, ['vendor_name', 'name']) ?? '') == name,
      orElse: () => const {},
    );
    if (!mounted) return;
    Navigator.pop(
      context,
      created.isEmpty ? null : asIntOr(created['vendor_id']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsViewModelProvider).isLoading;

    return AlertDialog(
      title: const Text('Add vendor'),
      // The dialog's own scroll area: seven boxes are taller than a phone
      // once the keyboard is up, and an AlertDialog does not scroll its
      // content on its own.
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: _VendorFields(
              name: _name,
              contactPerson: _contactPerson,
              contactNo: _contactNo,
              email: _email,
              gstNo: _gstNo,
              serviceType: _serviceType,
              address: _address,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.white,
                  ),
                )
              : const Text('Save vendor'),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────── add bill

/// The add-bill form.
///
/// The service type decides what the rest of the form is, exactly as
/// ddlSevice_SelectedIndexChanged did:
///   0 Staff     — staff list + payment (payment mandatory)
///   1 Daily     — vendor + items + approvers + payment
///   2 Inventory — same as Daily
///   3 Service   — vendor + description + cost + payment
class _BillFormPage extends ConsumerStatefulWidget {
  const _BillFormPage();

  @override
  ConsumerState<_BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends ConsumerState<_BillFormPage> {
  final _formKey = GlobalKey<FormState>();

  int? _serviceType;
  final _billNumber = TextEditingController();
  DateTime _billDate = DateTime.now();
  int? _vendorId;
  final _description = TextEditingController();
  final _serviceCost = TextEditingController();
  final _tax = TextEditingController();
  final _notes = TextEditingController();

  /// staff_id -> the salary being paid, which stays editable per head.
  final Map<int, TextEditingController> _selectedStaff = {};
  int? _staffRoleFilter;

  final List<_BillItem> _items = [];
  final _payment = _Payment();
  final List<int> _approverIds = [];

  @override
  void initState() {
    super.initState();
    // Totals are derived as the secretary types, so every box that feeds them
    // has to rebuild the summary.
    for (final c in [_serviceCost, _tax]) {
      c.addListener(_onTotalsChanged);
    }
  }

  void _onTotalsChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_serviceCost, _tax]) {
      c.removeListener(_onTotalsChanged);
    }
    for (final c in [_billNumber, _description, _serviceCost, _tax, _notes]) {
      c.dispose();
    }
    for (final c in _selectedStaff.values) {
      c.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    _payment.dispose();
    super.dispose();
  }

  // ── What the picked service type turns on ──────────────────────────────

  bool get _isStaff => _serviceType == _Service.staff;
  bool get _hasItems =>
      _serviceType == _Service.daily || _serviceType == _Service.inventory;
  bool get _needsVendor =>
      _serviceType == _Service.daily ||
      _serviceType == _Service.inventory ||
      _serviceType == _Service.service;
  bool get _hasApprovers =>
      _serviceType == _Service.daily || _serviceType == _Service.inventory;
  bool get _hasServiceCost =>
      _serviceType == _Service.daily || _serviceType == _Service.service;

  List<Map<String, dynamic>> _lookup(String key) =>
      asRows(ref.read(accountsViewModelProvider.notifier).vendorFormData?[key]);

  /// Subtotal, tax and grand total, recomputed exactly as the legacy page did.
  ({double subtotal, double tax, double total}) get _computed {
    double subtotal;
    if (_isStaff) {
      subtotal = _selectedStaff.values.fold<double>(
        0,
        (s, c) => s + (double.tryParse(c.text.trim()) ?? 0),
      );
    } else if (_hasItems) {
      subtotal = _items.fold<double>(0, (s, it) => s + it.total);
    } else {
      subtotal = double.tryParse(_serviceCost.text.trim()) ?? 0;
    }
    final tax = double.tryParse(_tax.text.trim()) ?? 0;
    return (subtotal: subtotal, tax: tax, total: subtotal + tax);
  }

  /// Switching service type re-stamps the bill number for the new type, but
  /// only when the current one is a number this screen generated.
  void _changeServiceType(int? value) {
    if (value == null) return;
    setState(() {
      _serviceType = value;
      final current = _billNumber.text.trim();
      if (current.isEmpty || _isGeneratedBillNumber(current)) {
        _billNumber.text = _generateBillNumber(value, _billDate);
      }
      // The sub-forms do not carry over: staff picked for a salary run mean
      // nothing on an inventory bill, and vice versa.
      for (final c in _selectedStaff.values) {
        c.dispose();
      }
      _selectedStaff.clear();
      _staffRoleFilter = null;
      if (!_hasItems) {
        for (final item in _items) {
          item.dispose();
        }
        _items.clear();
      }
      if (!_needsVendor) _vendorId = null;
      if (!_hasApprovers) _approverIds.clear();
    });
  }

  void _toggleStaff(int staffId, dynamic salary) {
    setState(() {
      final existing = _selectedStaff.remove(staffId);
      if (existing != null) {
        existing.dispose();
        return;
      }
      final controller = TextEditingController(
        text: asDoubleOr(salary) == 0 ? '' : asDoubleOr(salary).toString(),
      );
      controller.addListener(_onTotalsChanged);
      _selectedStaff[staffId] = controller;
    });
  }

  void _addItem() {
    final item = _BillItem();
    for (final c in [item.quantity, item.purchaseCost, item.tax]) {
      c.addListener(_onTotalsChanged);
    }
    setState(() => _items.add(item));
  }

  void _removeItem(int index) {
    final item = _items[index];
    setState(() => _items.removeAt(index));
    item.dispose();
  }

  /// The cross-field rules, checked after the per-field validators pass.
  String? _crossFieldError() {
    if (_isStaff && _selectedStaff.isEmpty) {
      return 'Select at least one staff member';
    }
    if (_isStaff && !_payment.isFilled) {
      return 'Payment is mandatory for a staff payment — '
          'pick a mode and enter an amount';
    }
    // An amount with no mode would be dropped rather than saved, so it is
    // caught here instead of silently going nowhere.
    if (_payment.mode == null &&
        (double.tryParse(_payment.amount.text.trim()) ?? 0) > 0) {
      return 'Pick a payment mode for the amount entered';
    }
    if (_hasItems && _items.isEmpty) return 'Add at least one item';
    if (_computed.total <= 0) {
      return 'The bill total must be greater than zero';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final message = _crossFieldError();
    if (message != null) {
      showAppSnack(context, message, success: false);
      return;
    }

    final computed = _computed;
    // vendor_id holds a comma-separated list: staff ids for a salary run,
    // otherwise the single vendor. Matches how the SP parses it.
    final vendorIds = _isStaff
        ? _selectedStaff.keys.map((e) => e.toString()).toList()
        : [_vendorId.toString()];

    final ok = await ref
        .read(accountsViewModelProvider.notifier)
        .createVendorBill({
          'serviceType': _serviceType,
          'billNumber': _billNumber.text.trim(),
          'billDate': _isoDate(_billDate),
          'vendorIds': vendorIds,
          'subtotal': computed.subtotal,
          'taxAmount': computed.tax,
          'totalAmount': computed.total,
          if (_description.text.trim().isNotEmpty)
            'description': _description.text.trim(),
          if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
          'items': _hasItems
              ? _items.map((it) => it.toJson()).toList()
              : const [],
          'approverIds': _approverIds,
          if (_payment.isFilled) 'payment': _payment.toJson(),
        });

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsViewModelProvider).isLoading;
    final computed = _computed;

    return Form(
      key: _formKey,
      child: _FormPage(
        title: 'New vendor bill',
        subtitle: _serviceType == null
            ? 'Pick what this bill is for — the rest follows.'
            : null,
        children: [
          _FormCard(
            title: 'What is this bill for?',
            child: AppDropdown<int>(
              label: 'Service type',
              value: _serviceType,
              options: _serviceTypes,
              isDense: false,
              onChanged: _changeServiceType,
              validator: (v) => v == null ? 'Pick a service type' : null,
            ),
          ),

          // Nothing else can be filled in until the service type is known —
          // it decides which sub-form the bill even has.
          if (_serviceType != null) ...[
            const SizedBox(height: 14),
            _FormCard(
              title: 'Bill details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _billNumber,
                    decoration: InputDecoration(
                      labelText: 'Bill number',
                      suffixIcon: IconButton(
                        tooltip: 'Generate bill number',
                        icon: const Icon(Icons.autorenew, size: 19),
                        onPressed: () => setState(() {
                          _billNumber.text = _generateBillNumber(
                            _serviceType!,
                            _billDate,
                          );
                        }),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter or generate a bill number'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _DateField(
                    label: 'Bill date',
                    value: _billDate,
                    onChanged: (picked) => setState(() => _billDate = picked),
                  ),
                  if (_needsVendor) ...[
                    const SizedBox(height: 14),
                    _buildVendorPicker(),
                  ],
                ],
              ),
            ),

            if (_isStaff) ...[
              const SizedBox(height: 14),
              _FormCard(
                title: 'Staff',
                subtitle:
                    '${_selectedStaff.length} selected · '
                    '${money(computed.subtotal)}',
                child: _buildStaffPicker(),
              ),
            ],

            if (_hasItems) ...[
              const SizedBox(height: 14),
              _FormCard(
                title: 'Items',
                subtitle: 'Each becomes an inventory record',
                action: TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Add item'),
                ),
                child: _buildItems(),
              ),
            ],

            if (_hasServiceCost) ...[
              const SizedBox(height: 14),
              _FormCard(
                title: 'Service',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Service description',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _serviceCost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Service cost',
                        prefixText: '₹ ',
                      ),
                      validator: (v) {
                        final amount = double.tryParse((v ?? '').trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter the service cost';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            _FormCard(
              title: 'Totals',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTotals(computed),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                ],
              ),
            ),

            if (_hasApprovers) ...[
              const SizedBox(height: 14),
              _FormCard(child: _buildApprovers()),
            ],

            const SizedBox(height: 14),
            _FormCard(
              title: 'Payment',
              subtitle: _isStaff
                  ? 'Required for a staff payment'
                  : 'Optional — can be paid later',
              child: _PaymentFields(
                payment: _payment,
                amountRequired: _isStaff,
                amountHint: _isStaff
                    ? 'Mandatory for a staff payment'
                    : 'Leave blank to pay this bill later',
                onChanged: () => setState(() {}),
              ),
            ),

            const SizedBox(height: 22),
            BusyButton(label: 'Save bill', busy: isLoading, onPressed: _submit),
          ],
        ],
      ),
    );
  }

  Widget _buildVendorPicker() {
    final vendors = _lookup('vendors');
    // GST comes from the chosen vendor and is shown rather than typed, as on
    // the legacy page.
    final selected = vendors.firstWhere(
      (v) => asIntOr(v['vendor_id']) == _vendorId,
      orElse: () => const {},
    );
    final gst = pick(selected, ['gst_no', 'gstNo']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor and its GST sit side by side, as they did on the legacy row:
        // the GST is the one thing checked against the vendor just picked, so
        // it belongs beside the name rather than under it.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppDropdown<int>(
                label: 'Vendor name',
                value: _vendorId,
                isDense: false,
                options: [
                  for (final v in vendors)
                    AppOption(
                      asIntOr(v['vendor_id']),
                      pick(v, ['vendor_name', 'name']) ?? 'Vendor',
                    ),
                ],
                onChanged: (v) => setState(() => _vendorId = v),
                validator: (v) => v == null ? 'Select a vendor' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              // Read-only and filled from the vendor, never typed.
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'GST number',
                  isDense: false,
                ),
                child: Text(
                  gst ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body2.copyWith(
                    color: gst == null
                        ? AppTheme.deactivatedText
                        : AppTheme.darkText,
                  ),
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openAddVendorDialog,
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Add vendor'),
          ),
        ),
      ],
    );
  }

  /// Register a vendor without leaving the bill.
  ///
  /// A dialog rather than a page: it is a five-box detour in the middle of
  /// filling a bill in, and pushing a route would hide the half-typed form
  /// behind it. Saving refreshes the lookups, so the new vendor is in the
  /// dropdown — and selected — by the time the dialog closes.
  Future<void> _openAddVendorDialog() async {
    final created = await showDialog<int>(
      context: context,
      builder: (_) => const _VendorDialog(),
    );
    if (!mounted) return;
    setState(() {
      if (created != null) _vendorId = created;
    });
  }

  Widget _buildStaffPicker() {
    final all = _lookup('staff');
    final roles = _lookup('staffRoles');
    // Filtered by the role dropdown, as ddlStaffType did.
    final staff = _staffRoleFilter == null
        ? all
        : all.where((s) => asIntOr(s['role_id']) == _staffRoleFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (roles.isNotEmpty)
          AppDropdown<int?>(
            label: 'Filter by role',
            value: _staffRoleFilter,
            options: [
              const AppOption<int?>(null, 'All roles'),
              for (final r in roles)
                AppOption<int?>(
                  asIntOr(r['role_id']),
                  pick(r, ['role', 'role_name']) ?? 'Role',
                ),
            ],
            onChanged: (v) => setState(() => _staffRoleFilter = v),
          ),
        const SizedBox(height: 8),
        if (staff.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No staff found for this role.',
              style: AppTheme.caption,
            ),
          )
        else
          ...staff.map((s) {
            final staffId = asIntOr(s['staff_id']);
            final controller = _selectedStaff[staffId];
            final picked = controller != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: picked ? AppTheme.primary : AppTheme.border,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: picked,
                    onChanged: (_) => _toggleStaff(staffId, s['salary']),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pick(s, ['name', 'staff_name']) ?? 'Staff',
                          style: AppTheme.body2,
                        ),
                        if (pick(s, ['role', 'role_name']) != null)
                          Text(
                            pick(s, ['role', 'role_name'])!,
                            style: AppTheme.caption,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      controller: controller,
                      enabled: picked,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: '₹ ',
                        hintText: picked ? null : money(s['salary']),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        Text(
          'A salary already raised for the same month will be rejected.',
          style: AppTheme.caption.copyWith(color: AppTheme.warning),
        ),
      ],
    );
  }

  /// One line per item, laid out across a row as the website's items grid is:
  /// description, qty, unit, unit price, tax %, warranty, amount.
  ///
  /// The row scrolls sideways rather than wrapping. Seven controls will not
  /// fit across a phone at a readable width, and stacking them turned a
  /// five-item bill into a page of its own — scrolling keeps one item on one
  /// line, which is what makes a list of them comparable at a glance.
  Widget _buildItems() {
    if (_items.isEmpty) {
      return Text(
        'Add the items received. Each becomes an inventory record.',
        style: AppTheme.caption,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A header strip per item: which line this is, what it comes to
              // and how to drop it. It is what separates one item from the
              // next once several are stacked up.
              Container(
                color: AppTheme.background,
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                child: Row(
                  children: [
                    Container(
                      height: 22,
                      width: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // qty × price + tax, as the legacy grid computed it.
                        money(item.total),
                        style: AppTheme.body2.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // The seven boxes do not fit across a phone, so the row
                    // below scrolls — which nothing would otherwise announce.
                    Text('Swipe', style: AppTheme.caption),
                    const Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      size: 15,
                      color: AppTheme.lightText,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Remove item ${i + 1}',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removeItem(i),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 19,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description takes the slack; the rest are sized to
                      // their content, as the website's flex row does.
                      _ItemField(
                        label: 'Description',
                        width: 170,
                        child: TextFormField(
                          controller: item.name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Item name',
                            isDense: true,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ItemField(
                        label: 'Qty',
                        width: 64,
                        child: TextFormField(
                          controller: item.quantity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ItemField(
                        label: 'Unit',
                        width: 74,
                        child: TextFormField(
                          controller: item.unit,
                          decoration: const InputDecoration(
                            hintText: 'kg, box',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ItemField(
                        label: 'Unit price',
                        width: 104,
                        child: TextFormField(
                          controller: item.purchaseCost,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ItemField(
                        label: 'Tax %',
                        width: 70,
                        child: TextFormField(
                          controller: item.tax,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ItemField(
                        label: 'Warranty',
                        width: 96,
                        child: TextFormField(
                          controller: item.warrantyMonths,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: 'mo',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// The chosen approvers, with the full roster behind a picker.
  ///
  /// VendorBill.aspx put an "Add Approver" button here and listed the chosen
  /// approvers beneath it rather than showing the whole roster on the form —
  /// a society with twenty committee members would otherwise bury the rest of
  /// the bill under a wall of checkboxes.
  Widget _buildApprovers() {
    final approvers = _lookup('approvers');

    /// The roster row for an id, so a chosen approver can be named.
    Map<String, dynamic> rowFor(int id) => approvers.firstWhere(
      (a) => asIntOr(a['user_id']) == id,
      orElse: () => const {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Approvers',
          subtitle: _approverIds.isEmpty
              ? 'Optional'
              : '${_approverIds.length} selected',
        ),
        if (approvers.isEmpty)
          Text(
            'No approvers available. Add committee members first.',
            style: AppTheme.caption,
          )
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openApproverPicker(approvers),
              icon: const Icon(Icons.person_add_alt, size: 17),
              label: const Text('Add approver'),
            ),
          ),
          if (_approverIds.isEmpty)
            Text('No approvers added yet.', style: AppTheme.caption)
          else
            ..._approverIds.map((id) {
              final row = rowFor(id);
              final name = pick(row, ['name', 'user_name']) ?? 'User $id';

              return AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                elevated: false,
                // Tapping the approver opens their details, so a name picked
                // by mistake can be checked before the bill is saved.
                onTap: () => _openApproverDetail(row, id),
                child: Row(
                  children: [
                    InitialsAvatar(name: name, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTheme.body2),
                          if (pick(row, ['role', 'designation']) != null)
                            Text(
                              pick(row, ['role', 'designation'])!,
                              style: AppTheme.caption,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove approver',
                      onPressed: () => setState(() => _approverIds.remove(id)),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }

  /// The roster, with the already-chosen ones ticked.
  Future<void> _openApproverPicker(List<Map<String, dynamic>> approvers) async {
    final picked = await showDialog<List<int>>(
      context: context,
      builder: (context) => _ApproverPickerDialog(
        approvers: approvers,
        selected: List<int>.from(_approverIds),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _approverIds
        ..clear()
        ..addAll(picked);
    });
  }

  /// One approver's details, with the option to drop them from the bill.
  Future<void> _openApproverDetail(Map<String, dynamic> row, int id) async {
    final name = pick(row, ['name', 'user_name']) ?? 'User $id';
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final field in [
              ('Role', pick(row, ['role', 'designation'])),
              ('Email', pick(row, ['email'])),
              ('Contact', pick(row, ['contact_no', 'mobile_no', 'phone'])),
            ])
              if (field.$2 != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 74,
                        child: Text(field.$1, style: AppTheme.caption),
                      ),
                      Expanded(child: Text(field.$2!, style: AppTheme.body2)),
                    ],
                  ),
                ),
            Text(
              'This approver will be asked to approve the bill once it '
              'is saved.',
              style: AppTheme.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (remove == true && mounted) {
      setState(() => _approverIds.remove(id));
    }
  }

  Widget _buildTotals(({double subtotal, double tax, double total}) computed) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: money(computed.subtotal)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Tax', style: AppTheme.body2)),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _tax,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixText: '₹ ',
                    hintText: '0.00',
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          _SummaryRow(
            label: 'Grand total',
            value: money(computed.total),
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

/// A figure and its label on one line, with a small tinted glyph.
///
/// StatTile stacks its icon above the number and is sized for a dashboard
/// grid; three of them across a list header took a third of the screen before
/// a single bill was visible. This says the same thing in about half the
/// height by putting the icon beside the figure rather than over it.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceFor(color),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 7),
          // The figure has to survive a narrow third of a phone, so it scales
          // down rather than overflowing — an overflow here would abort
          // layout for the whole header.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppTheme.title.copyWith(fontSize: 14),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill switcher — one filled plate per view, with its count.
///
/// Material's TabBar wants to live under an app bar and states the selection
/// with a hairline underline, which on this page was invisible against the
/// light background. This sits on the page as a control in its own right: the
/// picked side is a filled plate, and each side carries how many rows are
/// behind it so the choice is informed before it is made.
class _PillTabs extends StatelessWidget {
  const _PillTabs({
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<({String label, IconData icon, int count})> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PageConstraints(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, AppTheme.space3, 0, 0),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppTheme.spacer,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            children: [
              for (final (i, tab) in tabs.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    child: Material(
                      color: i == index ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      elevation: i == index ? 2 : 0,
                      shadowColor: AppTheme.primary.withValues(alpha: 0.35),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                        onTap: () => onChanged(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tab.icon,
                                size: 17,
                                color: i == index
                                    ? AppTheme.white
                                    : AppTheme.lightText,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  tab.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.body2.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: i == index
                                        ? AppTheme.white
                                        : AppTheme.lightText,
                                  ),
                                ),
                              ),
                              // Hidden while a list is still empty, so a
                              // loading tab does not claim it holds nothing.
                              if (tab.count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i == index
                                        ? AppTheme.white.withValues(alpha: 0.24)
                                        : AppTheme.border,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    '${tab.count}',
                                    style: AppTheme.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: i == index
                                          ? AppTheme.white
                                          : AppTheme.lightText,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One column of the item row: a heading above a fixed-width box.
///
/// The heading sits outside the field rather than floating in its border.
/// A dense field in a row aligned to the top has no spare height above it for
/// a floating label to rise into, so the label was cut in half the moment the
/// box took focus — and a column header is what an items grid wants anyway:
/// it stays readable while the box is being typed into.
class _ItemField extends StatelessWidget {
  const _ItemField({
    required this.label,
    required this.width,
    required this.child,
  });

  final String label;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A segmented control — one button per choice, with its icon.
///
/// This is the website's ModeSwitch: three payment modes are few enough, and
/// consequential enough, to be worth showing all at once. A dropdown hid them
/// behind a tap and gave no clue that cheque, online and cash each ask for
/// different details until one was already chosen.
///
/// The track is sunken and the picked option raised out of it, which states
/// the selection more plainly than a tint on its own.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final List<AppOption<String>> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTheme.caption),
          const SizedBox(height: 6),
        ],
        // One row, but each mode is its own card with a gap between them —
        // a shared track ran the three together, and these are three
        // different things to choose rather than positions on a slider.
        Row(
          children: [
            for (final (index, option) in options.indexed) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final selected = option.value == value;
                    final tint =
                        _payModeColors[option.value] ?? AppTheme.primary;

                    return Semantics(
                      button: true,
                      selected: selected,
                      child: Material(
                        color: selected
                            ? tint.withValues(alpha: 0.08)
                            : AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          onTap: () => onChanged(option.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              // The picked card is ringed in its own colour;
                              // the others keep the plain field border.
                              border: Border.all(
                                color: selected ? tint : AppTheme.border,
                                width: selected ? 1.6 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // The plate fills with the mode's own colour
                                // once picked, and holds a tint of it while
                                // not — so the three read as three things at
                                // a glance.
                                Container(
                                  height: 34,
                                  width: 34,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? tint
                                        : tint.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm,
                                    ),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    size: 18,
                                    color: selected ? AppTheme.white : tint,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  option.label,
                                  style: AppTheme.caption.copyWith(
                                    color: selected ? tint : AppTheme.lightText,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// One titled block of the bill form, on its own card.
///
/// The form asks for four or five unrelated things at once — the bill, the
/// items, the approvers, the payment — and as a flat run of inputs there was
/// nothing to say where one ended and the next began. A card per section is
/// what makes a long form skimmable.
class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.child,
    this.title,
    this.subtitle,
    this.action,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// A button on the header row — "Add item" and the like.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: AppTheme.title.copyWith(fontSize: 15),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTheme.caption),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// The approver roster, ticked. Returns the chosen ids, or null on cancel.
///
/// Its own widget so the ticks are local: choosing is not the same as having
/// chosen, and a picker that wrote straight through to the bill would leave
/// no way to back out of a half-made selection.
class _ApproverPickerDialog extends StatefulWidget {
  const _ApproverPickerDialog({
    required this.approvers,
    required this.selected,
  });

  final List<Map<String, dynamic>> approvers;
  final List<int> selected;

  @override
  State<_ApproverPickerDialog> createState() => _ApproverPickerDialogState();
}

class _ApproverPickerDialogState extends State<_ApproverPickerDialog> {
  late final List<int> _picked = List<int>.from(widget.selected);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add approver'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in widget.approvers)
                Builder(
                  builder: (context) {
                    final id = asIntOr(a['user_id']);
                    final name = pick(a, ['name', 'user_name']) ?? 'User $id';
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _picked.contains(id),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _picked.add(id);
                        } else {
                          _picked.remove(id);
                        }
                      }),
                      title: Text(name, style: AppTheme.body2),
                      subtitle: pick(a, ['role', 'designation']) == null
                          ? null
                          : Text(
                              pick(a, ['role', 'designation'])!,
                              style: AppTheme.caption,
                            ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _picked),
          child: Text(_picked.isEmpty ? 'Done' : 'Add ${_picked.length}'),
        ),
      ],
    );
  }
}

/// The three ways a bill leaves the app.
enum _ExportAction { download, print, share }

/// One vendor bill, drawn as the website prints it.
///
/// The layout is the printed document's, not a phone card's — the same shape
/// BillSheetView gives a maintenance bill: a bordered sheet, a particulars
/// grid two to a row, and bordered tables that stay tables. A bill is a
/// record, and what is on screen should match what comes out of the printer.
class _VendorBillSheet extends StatelessWidget {
  const _VendorBillSheet({
    required this.bill,
    required this.items,
    required this.approvals,
    required this.payments,
  });

  final Map<String, dynamic> bill;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> approvals;
  final List<Map<String, dynamic>> payments;

  static const _line = Color(0xFFCBD5E1);
  static const _head = Color(0xFFF1F5F9);
  static const _grandFill = Color(0xFFFDF1F1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'VENDOR BILL',
            textAlign: TextAlign.center,
            style: AppTheme.title.copyWith(fontSize: 15, letterSpacing: 0.6),
          ),
          const SizedBox(height: 14),
          _particulars(),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionLabel('Items'),
            _itemsTable(),
          ],
          const SizedBox(height: 12),
          _totals(),
          if (approvals.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionLabel('Approvals'),
            _approvalsTable(),
          ],
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionLabel('Payments'),
            _paymentsTable(),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTheme.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.darkerText,
      ),
    ),
  );

  static Widget _cell(
    Widget child, {
    Color? fill,
    Alignment align = Alignment.centerLeft,
  }) => Container(
    color: fill,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    alignment: align,
    child: child,
  );

  Widget _head_(String text, {Alignment align = Alignment.centerLeft}) => _cell(
    Text(
      text,
      style: AppTheme.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.darkerText,
      ),
    ),
    fill: _head,
    align: align,
  );

  Widget _body(String text, {Alignment align = Alignment.centerLeft}) =>
      _cell(Text(text, style: AppTheme.caption), align: align);

  /// Bill number, date, vendor and the rest — two to a row, as the
  /// maintenance bill lays its particulars out.
  Widget _particulars() {
    final cells = <(String, String)>[
      ('Bill No', pick(bill, ['bill_number', 'bill_no']) ?? '—'),
      ('Bill Date', prettyDate(bill['bill_date'])),
      ('Vendor', pick(bill, ['vendor_name', 'name']) ?? '—'),
      ('GST No', pick(bill, ['gst_no', 'gstNo']) ?? '—'),
      ('Status', pick(bill, ['bill_status']) ?? '—'),
      ('Payment', pick(bill, ['payment_status']) ?? '—'),
    ];

    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      children: [
        for (var i = 0; i < cells.length; i += 2)
          TableRow(
            children: [
              for (final cell in cells.skip(i).take(2))
                _cell(
                  Text(
                    '${cell.$1}: ${cell.$2}',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkerText,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _itemsTable() {
    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      // The amount column is fixed rather than intrinsic: sized to its
      // content it would stretch for a long item name and leave the figures
      // adrift from the totals block below.
      columnWidths: const {
        0: FixedColumnWidth(38),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(44),
        3: FixedColumnWidth(96),
      },
      children: [
        TableRow(
          children: [
            _head_('Sr'),
            _head_('Particulars'),
            _head_('Qty', align: Alignment.centerRight),
            _head_('Amount', align: Alignment.centerRight),
          ],
        ),
        for (var i = 0; i < items.length; i++)
          TableRow(
            children: [
              _body('${i + 1}'),
              _body(pick(items[i], ['item_name', 'name']) ?? '—'),
              _body(
                '${items[i]['quantity'] ?? 0}',
                align: Alignment.centerRight,
              ),
              _body(
                money(items[i]['total_amount']),
                align: Alignment.centerRight,
              ),
            ],
          ),
      ],
    );
  }

  /// What the bill comes to, and what is left on it.
  Widget _totals() {
    TableRow row(
      String label,
      String value, {
      bool bold = false,
      Color? fill,
    }) => TableRow(
      decoration: fill == null ? null : BoxDecoration(color: fill),
      children: [
        _cell(
          Text(
            label,
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.darkerText,
            ),
          ),
        ),
        _cell(
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.caption.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AppTheme.darkerText : null,
            ),
          ),
          align: Alignment.centerRight,
        ),
      ],
    );

    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {0: FlexColumnWidth(), 1: FixedColumnWidth(130)},
      children: [
        row('Subtotal', money(bill['subtotal'])),
        row('Tax', money(bill['tax_amount'])),
        row(
          'Grand Total',
          money(bill['total_amount']),
          bold: true,
          fill: _grandFill,
        ),
        row('Paid', money(bill['paid_amount'])),
        row('Outstanding', money(bill['remaining_amount']), bold: true),
      ],
    );
  }

  Widget _approvalsTable() {
    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FixedColumnWidth(72),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          children: [_head_('Approver'), _head_('Status'), _head_('Reason')],
        ),
        for (final a in approvals)
          TableRow(
            children: [
              _body(pick(a, ['name', 'user_name']) ?? '—'),
              _body(_approvalLabel(a['approval_status'])),
              // The API insists on a reason before it records a rejection,
              // so the printed copy carries it too.
              _body(pick(a, ['remarks']) ?? '—'),
            ],
          ),
      ],
    );
  }

  /// What each payment was, and what identifies it.
  ///
  /// The reference is the point of the row: a cheque is traced by its number
  /// and the date it carries, an online transfer by its transaction ref.
  /// Without them a payment cannot be matched to a bank statement at all, and
  /// they were being stored and then never shown.
  Widget _paymentsTable() {
    /// The identifying detail for a payment, by mode. Cash has none — it is
    /// handed over, and the receipt number is the only record of it.
    String reference(Map<String, dynamic> p) {
      final cheque = pick(p, ['cheque_no']);
      if (cheque != null) {
        final date = p['cheque_date'];
        final bank = pick(p, ['bank_name']);
        return [
          'Cheque $cheque',
          if (date != null) prettyDate(date),
          if (bank != null) bank,
        ].join(' · ');
      }

      final txn = pick(p, ['transaction_ref']);
      if (txn != null) return 'Ref $txn';

      return '—';
    }

    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: FixedColumnWidth(64),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(96),
      },
      children: [
        TableRow(
          children: [
            _head_('Mode'),
            _head_('Receipt & reference'),
            _head_('Amount', align: Alignment.centerRight),
          ],
        ),
        for (final p in payments)
          TableRow(
            children: [
              _body(pick(p, ['pay_mode']) ?? '—'),
              _cell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        pick(p, ['payment_no']) ?? 'Payment',
                        prettyDate(p['payment_date']),
                      ].join(' · '),
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reference(p),
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.darkerText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (pick(p, ['remarks']) != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        pick(p, ['remarks'])!,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.lightText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _body(money(p['paid_amount']), align: Alignment.centerRight),
            ],
          ),
      ],
    );
  }
}

/// One title-bar action on the bill detail, on a plate in its own tint.
///
/// The same treatment the maintenance bill's actions use, so a tinted icon
/// here reads as part of the app rather than a one-off.
class _BillAction extends StatelessWidget {
  const _BillAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: !busy,
        label: tooltip,
        child: Opacity(
          opacity: busy ? 0.55 : 1,
          child: Material(
            color: AppTheme.surfaceFor(color),
            borderRadius: radius,
            child: InkWell(
              onTap: busy ? null : onTap,
              borderRadius: radius,
              child: SizedBox(
                height: 34,
                width: 34,
                child: Center(
                  // Sized to match the icon it replaces, so the plate holds
                  // still through the wait rather than resizing under the
                  // finger that just tapped it.
                  child: busy
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(icon, size: 18, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A label and a figure, for the totals block.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasis
              ? AppTheme.title.copyWith(fontSize: 15)
              : AppTheme.body2,
        ),
        Text(
          value,
          style: emphasis
              ? AppTheme.title.copyWith(fontSize: 16, color: AppTheme.primary)
              : AppTheme.body2,
        ),
      ],
    );
  }
}

/// A tappable date box, matching the app's other inputs.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showSingleDateDialog(
          context: context,
          initial: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? 'Not set' : prettyDate(value),
          style: AppTheme.body2,
        ),
      ),
    );
  }
}

/// Cheque / online / cash inputs, shared by the bill form's payment section
/// and the Pay sheet — the same three panels the legacy page used in both.
class _PaymentFields extends StatelessWidget {
  const _PaymentFields({
    required this.payment,
    required this.amountRequired,
    required this.onChanged,
    this.amountHint,
    this.maxAmount,
  });

  final _Payment payment;
  final bool amountRequired;
  final VoidCallback onChanged;
  final String? amountHint;

  /// The outstanding balance, when paying an existing bill — more than this
  /// cannot be paid.
  final double? maxAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeSwitch(
          label: 'Payment mode',
          options: _payModes,
          value: payment.mode,
          onChanged: (mode) {
            payment.mode = mode;
            onChanged();
          },
        ),

        if (payment.mode == null) ...[
          const SizedBox(height: 8),
          Text(
            'Pick a payment mode to enter the details.',
            style: AppTheme.caption,
          ),
        ],

        // Each mode carries its own reference: a cheque with no number cannot
        // be matched to a bank statement, and a transfer with no reference
        // cannot be found at all. Cash needs neither.
        if (payment.mode == 'Online') ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: payment.transactionRef,
            decoration: const InputDecoration(
              labelText: 'Transaction reference',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter the transaction reference'
                : null,
          ),
        ],

        // A cheque's four boxes pair up two to a row: the number with the date
        // it carries, then the bank with the amount drawn on it.
        if (payment.mode == 'Cheque') ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: payment.chequeNo,
                  decoration: const InputDecoration(labelText: 'Cheque number'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the cheque number'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'Cheque date',
                  value: payment.chequeDate,
                  onChanged: (picked) {
                    payment.chequeDate = picked;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: payment.bankName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Bank name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the bank name'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _amountField()),
            ],
          ),
        ],

        // Cash and online have no reference boxes to pair with, so the amount
        // takes a row of its own.
        if (payment.mode != null && payment.mode != 'Cheque') ...[
          const SizedBox(height: 14),
          _amountField(),
        ],

        if (payment.mode != null) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: payment.remarks,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Remarks (optional)'),
          ),
        ],
      ],
    );
  }

  /// What is being paid. Shared, so the cheque row and the plainer modes ask
  /// for it the same way and check it against the same balance.
  Widget _amountField() {
    return TextFormField(
      controller: payment.amount,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixText: '₹ ',
        helperText: amountHint,
      ),
      validator: (v) {
        final text = (v ?? '').trim();
        final amount = double.tryParse(text);
        if (text.isEmpty && !amountRequired) return null;
        if (amount == null || amount <= 0) {
          return 'Enter the amount being paid';
        }
        if (maxAmount != null && amount > maxAmount!) {
          return 'That is more than the ${money(maxAmount)} outstanding';
        }
        return null;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────── pay a bill

/// The website's Pay action — settle what is outstanding on an existing bill.
class _PayFormPage extends ConsumerStatefulWidget {
  const _PayFormPage({required this.bill});

  final Map<String, dynamic> bill;

  @override
  ConsumerState<_PayFormPage> createState() => _PayFormPageState();
}

class _PayFormPageState extends ConsumerState<_PayFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _payment = _Payment();

  double get _outstanding => asDoubleOr(widget.bill['remaining_amount']);

  @override
  void initState() {
    super.initState();
    // The legacy modal opened with the balance already filled in, which is
    // what is being paid in nearly every case.
    _payment.amount.text = _outstanding <= 0
        ? ''
        : _outstanding.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _payment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // The mode is picked on a segmented control rather than a form field, so
    // it is checked here — nothing below it is even rendered until a mode is
    // chosen, and a submit without one would post a null mode.
    if (_payment.mode == null) {
      showAppSnack(context, 'Pick a payment mode', success: false);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final id = pickInt(widget.bill, ['bill_id', 'vendor_bill_id', 'id']);
    if (id == null) return;

    final ok = await ref
        .read(accountsViewModelProvider.notifier)
        .payVendorBill(id, _payment.toJson());

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsViewModelProvider).isLoading;
    final number = pick(widget.bill, ['bill_number', 'bill_no']);

    return Form(
      key: _formKey,
      child: _FormPage(
        title: 'Record payment',
        subtitle: number == null
            ? '${money(_outstanding)} outstanding'
            : 'Bill $number · ${money(_outstanding)} outstanding',
        children: [
          _PaymentFields(
            payment: _payment,
            amountRequired: true,
            maxAmount: _outstanding,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 22),
          BusyButton(
            label: 'Save payment',
            busy: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── bill detail

/// One bill in full: its figures, items, approvals and payments.
class _BillDetailPage extends ConsumerStatefulWidget {
  const _BillDetailPage({required this.billId});

  final int billId;

  @override
  ConsumerState<_BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends ConsumerState<_BillDetailPage> {
  Map<String, dynamic>? _detail;
  bool _loading = true;

  /// True while a PDF is being built. All three actions share it — the
  /// document is the same either way, so a second tap during the first is
  /// work thrown away.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  /// Build the bill's PDF and hand it to the OS.
  Future<void> _export(_ExportAction action) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    final bill = asRow(_detail?['bill']);
    // The screen's own formatters go with it, so a printed bill reads exactly
    // as the page it was printed from.
    final args = (
      bill: bill,
      items: asRows(_detail?['items']),
      approvals: asRows(_detail?['approvals']),
      payments: asRows(_detail?['payments']),
      money: money,
      date: prettyDate,
    );

    try {
      switch (action) {
        case _ExportAction.download:
          await VendorBillExport.download(
            context,
            bill: args.bill,
            items: args.items,
            approvals: args.approvals,
            payments: args.payments,
            money: args.money,
            date: args.date,
          );
        case _ExportAction.print:
          await VendorBillExport.print(
            context,
            bill: args.bill,
            items: args.items,
            approvals: args.approvals,
            payments: args.payments,
            money: args.money,
            date: args.date,
          );
        case _ExportAction.share:
          await VendorBillExport.share(
            context,
            bill: args.bill,
            items: args.items,
            approvals: args.approvals,
            payments: args.payments,
            money: args.money,
            date: args.date,
          );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ref
        .read(accountsViewModelProvider.notifier)
        .loadVendorBill(widget.billId);
    if (!mounted) return;
    setState(() {
      _detail = data;
      _loading = false;
    });
  }

  /// Approve, or reject with a remark — the API requires one on a rejection.
  Future<void> _decide(int approvalId, String decision) async {
    String? remarks;
    if (decision == 'reject') {
      remarks = await _askRemarks();
      if (remarks == null) return;
    }

    final ok = await ref
        .read(accountsViewModelProvider.notifier)
        .decideVendorBill(widget.billId, approvalId, {
          'decision': decision,
          if (remarks != null) 'remarks': remarks,
        });

    if (ok) await _load();
  }

  Future<String?> _askRemarks() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject bill'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why is this bill being rejected?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _FormPage(
        title: 'Bill',
        children: [
          SizedBox(height: 40),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 40),
        ],
      );
    }

    final bill = asRow(_detail?['bill']);
    final items = asRows(_detail?['items']);
    final approvals = asRows(_detail?['approvals']);
    final payments = asRows(_detail?['payments']);

    if (bill.isEmpty) {
      return _FormPage(
        title: 'Bill',
        children: [
          const SizedBox(height: 20),
          StateMessage(
            icon: Icons.error_outline,
            title: 'This bill could not be loaded',
            message: 'Pull the list to refresh and try again.',
          ),
        ],
      );
    }

    final outstanding = asDoubleOr(bill['remaining_amount']);
    final rejected = asIntOr(bill['status']) == 4;

    return _FormPage(
      title: 'Bill ${pick(bill, ['bill_number', 'bill_no']) ?? ''}'.trim(),
      subtitle: pick(bill, ['vendor_name', 'name']),
      // Each action takes its own hue, so the three read apart at a glance
      // instead of as one grey run of glyphs.
      actions: [
        _BillAction(
          icon: Icons.download_rounded,
          tooltip: 'Download',
          color: AppTheme.primary,
          busy: _exporting,
          onTap: () => _export(_ExportAction.download),
        ),
        const SizedBox(width: 6),
        // The same three hues the receipt and maintenance bill use, so the
        // export actions look the same wherever they appear.
        _BillAction(
          icon: Icons.print_rounded,
          tooltip: 'Print',
          color: AppTheme.violet,
          busy: _exporting,
          onTap: () => _export(_ExportAction.print),
        ),
        const SizedBox(width: 6),
        _BillAction(
          icon: Icons.share_rounded,
          tooltip: 'Share',
          color: AppTheme.teal,
          busy: _exporting,
          onTap: () => _export(_ExportAction.share),
        ),
        const SizedBox(width: 12),
      ],
      children: [
        // Drawn as the document it is, the way BillSheetView draws a
        // maintenance bill: a bordered sheet with the same particulars grid
        // and the same bordered tables. A bill is a record, and the thing on
        // screen should match the thing that prints.
        _VendorBillSheet(
          bill: bill,
          items: items,
          approvals: approvals,
          payments: payments,
        ),

        // The approval decisions stay interactive below the sheet — the
        // printed copy records them, but approving is done here.
        if (approvals.isNotEmpty) ...[
          const SizedBox(height: 14),
          _FormCard(
            title: 'Approvals',
            subtitle: _approvalSummary(approvals),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: approvals.map(_buildApproval).toList(),
            ),
          ),
        ],

        // Paying from here saves going back to the list to find the bill
        // that is already open.
        if (outstanding > 0 && !rejected) ...[
          const SizedBox(height: 20),
          BusyButton(
            label: 'Record payment',
            icon: Icons.payments_outlined,
            busy: ref.watch(accountsViewModelProvider).isLoading,
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => _PayFormPage(bill: bill)),
              );
              // The payment changes what is outstanding, so the sheet behind
              // it is reloaded rather than left showing the old figures.
              await _load();
            },
          ),
        ],
      ],
    );
  }

  /// "2 of 3 approved" — where the bill stands without reading every row.
  String _approvalSummary(List<Map<String, dynamic>> approvals) {
    final approved = approvals
        .where((a) => asIntOr(a['approval_status']) == 2)
        .length;
    final rejected = approvals
        .where((a) => asIntOr(a['approval_status']) == 4)
        .length;

    if (rejected > 0) return 'Rejected by $rejected of ${approvals.length}';
    return '$approved of ${approvals.length} approved';
  }

  Widget _buildApproval(Map<String, dynamic> approval) {
    final approvalId = asIntOr(approval['approval_id']);
    final status = _approvalLabel(approval['approval_status']);
    final pending = asIntOr(approval['approval_status']) == 1;
    final rejected = asIntOr(approval['approval_status']) == 4;
    final remarks = pick(approval, ['remarks', 'notes']);

    // An approval may only be answered by the approver it was asked of. The
    // API refuses anyone else, so showing the buttons to everyone offered
    // something that would fail on tap.
    final signedInUserId = ref.watch(authViewModelProvider).user?.userId;
    final isMine =
        signedInUserId != null &&
        asIntOr(approval['user_id']) == signedInUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(
                name: pick(approval, ['name', 'user_name']),
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pick(approval, ['name', 'user_name']) ?? 'Approver',
                      style: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (approval['approval_date'] != null)
                      Text(
                        prettyDate(approval['approval_date']),
                        style: AppTheme.caption,
                      ),
                  ],
                ),
              ),
              StatusChip(label: status, color: statusColor(status)),
            ],
          ),

          // Why it was turned down. The API insists on a reason before it
          // records a rejection, and it was being stored and then never
          // shown — leaving the bill marked Rejected with nothing saying why.
          if (remarks != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceFor(statusColor(status)),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    rejected ? Icons.block_outlined : Icons.chat_bubble_outline,
                    size: 15,
                    color: statusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remarks,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Only a line still waiting, and only the approver's own.
          if (pending && approvalId > 0)
            if (isMine) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _decide(approvalId, 'approve'),
                    icon: const Icon(Icons.check, size: 17),
                    label: const Text('Approve'),
                  ),
                  TextButton.icon(
                    onPressed: () => _decide(approvalId, 'reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                    ),
                    icon: const Icon(Icons.close, size: 17),
                    label: const Text('Reject'),
                  ),
                ],
              ),
            ] else ...[
              // Someone else's line: say what it is waiting on rather than
              // leaving the row looking inert.
              const SizedBox(height: 6),
              Text('Waiting on them to decide.', style: AppTheme.caption),
            ],
        ],
      ),
    );
  }
}
