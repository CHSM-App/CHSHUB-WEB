import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/receipt_request.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/billing_viewmodel.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

/// Record a maintenance payment.
///
/// Pick a flat, tick the bills the money settles, enter the amount. The server
/// allocates it across the ticked bills (interest first, then principal) and
/// carries any surplus forward as advance.
class ReceiptEntryScreen extends ConsumerStatefulWidget {
  const ReceiptEntryScreen({super.key});

  @override
  ConsumerState<ReceiptEntryScreen> createState() => _ReceiptEntryScreenState();
}

class _ReceiptEntryScreenState extends ConsumerState<ReceiptEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _chequeNoController = TextEditingController();
  final _bankController = TextEditingController();
  final _remarksController = TextEditingController();

  int? _flatId;
  String _payMode = 'Cheque';
  DateTime _receiptDate = DateTime.now();
  DateTime? _chequeDate;
  final Set<String> _selectedBills = {};

  /// The post-dated cheque this receipt is being paid with, if any.
  ///
  /// A chosen cheque supplies its own number, date, bank and amount, and locks
  /// those fields — the cheque is already written, so the receipt has to match
  /// it rather than the other way round. This is what the website's PDC mode
  /// does, and what the legacy page's btnPDCMode_Click did before it.
  String? _pdcId;

  bool get _pdcLocked => _payMode == 'PDC' && _pdcId != null;

  /// receipt.bill_details is nvarchar(20) and the server joins the selected
  /// bill numbers with commas into it. Selecting more than fits is refused —
  /// checked here too so the secretary finds out before typing an amount.
  static const _billListLimit = 20;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(billingViewModelProvider.notifier).loadResidents(),
    );
    // The summary tracks what has been typed against what was ticked, so it
    // has to repaint on every keystroke rather than only on submit.
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _chequeNoController.dispose();
    _bankController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  String get _billList => _selectedBills.join(',');

  bool get _billListTooLong => _billList.length > _billListLimit;

  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  /// GetBills returns bill_type 1 = Regular, 0 = Add-On, and 2 = a carried
  /// charge shown for information but never settled directly — the website
  /// lists that one as a note and leaves it out of both the payable total and
  /// the bill list.
  static const _regular = 1;
  static const _noteOnly = 2;

  static int _billType(Map<String, dynamic> bill) => asIntOr(
    bill['BillType'] ?? bill['bill_type'] ?? bill['billType'],
    _regular,
  );

  static double _billAmount(Map<String, dynamic> bill) => asDoubleOr(
    bill['due_amount'] ??
        bill['balance'] ??
        bill['Amount'] ??
        bill['total_amount'],
  );

  /// The raw bill number.
  ///
  /// `bill_no`, not the formatted `BillNo` the website prints: the settlement
  /// proc matches on the raw value, so the selection has to be keyed on it.
  static String? _billNo(Map<String, dynamic> bill) =>
      pick(bill, ['bill_no', 'billNo', 'bill_id']);

  /// What the bill is called on screen — `BillNo` where the procedure formats
  /// one, falling back to the raw number.
  static String _billLabel(Map<String, dynamic> bill) =>
      pick(bill, ['BillNo']) ?? _billNo(bill) ?? '—';

  /// 'Regular' or 'Add-On', as the website labels each row.
  static String _billTypeLabel(Map<String, dynamic> bill) =>
      _billType(bill) == _regular ? 'Regular' : 'Add-On';

  static dynamic _billDue(Map<String, dynamic> bill) =>
      bill['DueDate'] ?? bill['due_date'] ?? bill['bill_date'];

  /// 'Overdue' / 'Pending', when the procedure says.
  static String? _billStatus(Map<String, dynamic> bill) =>
      pick(bill, ['Status', 'status']);

  /// The bills a payment can actually settle.
  List<Map<String, dynamic>> _payable(List<Map<String, dynamic>> outstanding) =>
      outstanding.where((b) => _billType(b) != _noteOnly).toList();

  /// Informational charges on the account, shown but never settled.
  double _noteOnlyTotal(List<Map<String, dynamic>> outstanding) => outstanding
      .where((b) => _billType(b) == _noteOnly)
      .fold(0.0, (sum, b) => sum + _billAmount(b));

  List<Map<String, dynamic>> _selectedRows(
    List<Map<String, dynamic>> outstanding,
  ) {
    return _payable(outstanding).where((b) {
      final no = _billNo(b);
      return no != null && _selectedBills.contains(no);
    }).toList();
  }

  /// What the ticked bills add up to.
  double _selectedDue(List<Map<String, dynamic>> outstanding) =>
      _selectedRows(outstanding).fold(0.0, (sum, b) => sum + _billAmount(b));

  /// How far the amount may be reduced.
  ///
  /// Mirrors the website, which mirrors _calculatePaymentDetails() in the CHS
  /// app: a Regular bill has to be cleared in full, so a selection of only
  /// Regular bills fixes the amount outright. Add-On bills may be part paid, so
  /// once one is ticked the floor drops to just the Regular portion.
  double _minimumAmount(List<Map<String, dynamic>> outstanding) {
    final rows = _selectedRows(outstanding);
    final hasRegular = rows.any((b) => _billType(b) == _regular);
    if (!hasRegular) return 0;
    return rows
        .where((b) => _billType(b) == _regular)
        .fold(0.0, (sum, b) => sum + _billAmount(b));
  }

  /// Regular bills settle before Add-On ones, matching the legacy screen — the
  /// settlement proc consumes the list in the order it is given.
  List<String> _orderedBillNos(List<Map<String, dynamic>> outstanding) {
    final rows = _selectedRows(outstanding)
      ..sort((a, b) => _billType(b).compareTo(_billType(a)));
    return rows.map(_billNo).whereType<String>().toList();
  }

  /// Ticking a bill proposes what it comes to.
  ///
  /// The secretary can still edit it down for a part payment, exactly as the
  /// website allows — this only fills the box, it does not lock it. Clearing
  /// the last tick empties the field rather than leaving a figure behind that
  /// no longer answers to anything on screen.
  void _proposeAmount() {
    final outstanding = ref
        .read(billingViewModelProvider)
        .items(BillingKeys.outstanding);

    final text = _selectedBills.isEmpty
        ? ''
        : _selectedDue(outstanding).toStringAsFixed(2);

    if (_amountController.text == text) return;
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _onFlatChanged(int? flatId) async {
    setState(() {
      _flatId = flatId;
      _selectedBills.clear();
      // The cheques belong to the old flat. Keeping the selection would pay
      // one flat's receipt with another flat's cheque.
      _pdcId = null;
      _chequeNoController.clear();
      _bankController.clear();
      _chequeDate = null;
      _amountController.clear();
    });
    if (flatId != null) {
      await ref.read(billingViewModelProvider.notifier).loadFlatDues(flatId);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final outstanding = ref
        .read(billingViewModelProvider)
        .items(BillingKeys.outstanding);

    if (_selectedBills.isEmpty) {
      _toast('Select at least one bill this payment settles.', isError: true);
      return;
    }
    if (_billListTooLong) {
      _toast(
        'Too many bills for one receipt. Record the payment across several.',
        isError: true,
      );
      return;
    }
    // The date picker is not a FormField, so it cannot carry its own
    // validator — but the website requires it, and a cheque with no date
    // cannot be reconciled against a bank statement.
    if (_chequeDate == null) {
      _toast('Enter the payment date.', isError: true);
      return;
    }
    // PDC mode with no cheque chosen.
    //
    // The picker carries a validator, but only when there are cheques to pick:
    // a flat with none renders a plain note instead, which has no validator at
    // all — so the form validated cleanly and the payment recorded itself
    // against a post-dated cheque that does not exist. Checked here because
    // this is the one place that sees the mode regardless of what was drawn.
    if (_payMode == 'PDC' && _pdcId == null) {
      _toast(
        'Select a post-dated cheque, or record this as a plain cheque.',
        isError: true,
      );
      return;
    }

    // A Regular bill has to be cleared in full. Without this a part payment
    // against one would be accepted here and then under-settle on the server.
    final minimum = _minimumAmount(outstanding);
    if (_enteredAmount + 0.005 < minimum) {
      // The website's wording, verbatim.
      _toast(
        'Amount entered is less than the minimum amount ${money(minimum)} — '
        'regular bills must be paid in full',
        isError: true,
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final ok = await ref
        .read(billingViewModelProvider.notifier)
        .createReceipt(
          ReceiptRequest(
            flatId: _flatId!,
            paidAmount: double.parse(_amountController.text.trim()),
            payMode: _payMode,
            // Regular before Add-On: the settlement proc consumes the list in
            // the order it is given, and a Set has no order to rely on.
            billNos: _orderedBillNos(outstanding),
            chequeNo: _text(_chequeNoController),
            chequeDate: _chequeDate == null ? null : _iso(_chequeDate!),
            bankName: _text(_bankController),
            remarks: _text(_remarksController),
            receiptDate: _iso(_receiptDate),
          ),
        );

    if (!mounted) return;
    if (ok) {
      // Back to the list, which the ViewModel has already refetched — so the
      // secretary lands on a list that carries the payment just recorded
      // rather than on an emptied form wondering whether it saved.
      //
      // Only when this screen was pushed onto something. Opened as the first
      // route it has nowhere to pop to, so it clears itself for the next
      // entry instead.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _selectedBills.clear();
        _amountController.clear();
        _chequeNoController.clear();
        _bankController.clear();
        _remarksController.clear();
      });
    }
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppTheme.error : AppTheme.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, billingViewModelProvider);

    final state = ref.watch(billingViewModelProvider);
    final residents = state.items(BillingKeys.residents);
    final outstanding = state.items(BillingKeys.outstanding);
    final advance = state.items(BillingKeys.advance);
    final pdcCheques = state.items(BillingKeys.flatPdc);
    final wide = !Breakpoints.isPhone(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Record a payment')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(
              top: AppTheme.space4,
              bottom: AppTheme.space8,
            ),
            children: [
              PageConstraints(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _flatCard(residents, advance),
                    if (_flatId != null) ...[
                      const SizedBox(height: AppTheme.space4),
                      // Side by side once there is room: the bills being
                      // settled and the money settling them are one decision,
                      // and a secretary on a laptop should not scroll between
                      // the two halves of it.
                      if (wide)
                        ResponsiveRow(
                          flex: const [5, 4],
                          children: [
                            _billsCard(outstanding),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _paymentCard(pdcCheques, outstanding),
                                const SizedBox(height: AppTheme.space4),
                                _summaryCard(outstanding),
                                const SizedBox(height: AppTheme.space4),
                                _submitButton(state.isLoading),
                              ],
                            ),
                          ],
                        )
                      else ...[
                        _billsCard(outstanding),
                        const SizedBox(height: AppTheme.space4),
                        _paymentCard(pdcCheques, outstanding),
                        const SizedBox(height: AppTheme.space4),
                        _summaryCard(outstanding),
                        const SizedBox(height: AppTheme.space5),
                        _submitButton(state.isLoading),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Flat ─────────────────────────────────────────────────────────────

  Widget _flatCard(
    List<Map<String, dynamic>> residents,
    List<Map<String, dynamic>> advance,
  ) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Who is paying',
            subtitle: 'Pick the flat this payment belongs to.',
          ),
          _buildFlatPicker(residents),
          if (_flatId != null) _buildAdvanceNote(advance),
        ],
      ),
    );
  }

  Widget _buildFlatPicker(List<Map<String, dynamic>> residents) {
    return AppDropdown<int>(
      value: _flatId,
      label: 'Flat',
      icon: Icons.home_outlined,
      isDense: false,
      options: [
        for (final r in residents)
          if (pickInt(r, ['flat_id', 'flatId']) != null)
            AppOption(
              pickInt(r, ['flat_id', 'flatId'])!,
              // `resident_name` is what the website shows, and the procedure
              // composes it — owner and flat already in one string. The parts
              // below are the fallback for a row that lacks it.
              pick(r, ['resident_name', 'residentName']) ??
                  [
                    pick(r, ['building_name', 'build_name', 'wing']),
                    pick(r, ['flat_no', 'unit_no', 'flat']),
                    pick(r, ['owner_name', 'name']),
                  ].where((e) => e != null).join(' · '),
            ),
      ],
      onChanged: _onFlatChanged,
      validator: (v) => v == null ? 'Choose a flat' : null,
    );
  }

  // ── Advance ──────────────────────────────────────────────────────────

  Widget _buildAdvanceNote(List<Map<String, dynamic>> advance) {
    final amount = advance.isEmpty
        ? 0.0
        : asDoubleOr(
            advance.first['advance'] ??
                advance.first['advance_amount'] ??
                advance.first['amount'],
          );

    if (amount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.space3),
      // The website's wording, and it matters: gen_bill subtracts this from
      // the next monthly bill before interest, so the credit is information
      // only. Collecting less here as well would credit the resident twice.
      child: _Note(
        icon: Icons.savings_outlined,
        color: AppTheme.info,
        text:
            'This flat holds ${money(amount)} in credit from an earlier '
            'overpayment. It comes off the next monthly bill automatically — '
            'collect the full amount shown below.',
      ),
    );
  }

  // ── Outstanding bills ────────────────────────────────────────────────

  Widget _billsCard(List<Map<String, dynamic>> outstanding) {
    final bills = ref
        .watch(billingViewModelProvider)
        .rows(BillingKeys.outstanding);

    // Still fetching. Drawing the empty state here would say "no outstanding
    // bills" about a flat whose bills have simply not arrived yet.
    if (bills.isLoading) {
      return const AppCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.space6),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // The fetch failed, and it must say so. Swallowing the error renders an
    // empty list indistinguishable from "this resident owes nothing", which
    // would invite recording a payment against bills that failed to load.
    if (bills.hasError) {
      return AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Bills this payment settles'),
            _Note(
              icon: Icons.cloud_off_rounded,
              color: AppTheme.error,
              text:
                  'Could not load this flat\'s bills — ${errorText(bills.error!)}. '
                  'Do not record a payment until they load.',
            ),
            const SizedBox(height: AppTheme.space3),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final id = _flatId;
                  if (id != null) {
                    ref
                        .read(billingViewModelProvider.notifier)
                        .loadFlatDues(id);
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      );
    }

    final payable = _payable(outstanding);
    final noteTotal = _noteOnlyTotal(outstanding);
    final minimum = _minimumAmount(outstanding);

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Bills this payment settles',
            subtitle: payable.isEmpty
                ? null
                : '${_selectedBills.length} of ${payable.length} selected',
          ),
          if (payable.isEmpty)
            const _Note(
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.success,
              text: 'This flat has no outstanding bills.',
            )
          else ...[
            // Select-all earns its place here: a flat clearing a year of
            // arrears would otherwise be twelve separate taps.
            if (payable.length > 1) _selectAllRow(payable),
            for (final bill in payable) _buildBillTile(bill),
            // The website closes its bill table with this row: how many are
            // ticked, what they come to, and the floor under the amount.
            Container(
              margin: const EdgeInsets.only(top: AppTheme.space2),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space3,
                vertical: AppTheme.space3,
              ),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm + 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected (${_selectedBills.length})',
                          style: AppTheme.body2.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (minimum > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Minimum amount is ${money(minimum)}',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    money(_selectedDue(outstanding)),
                    style: AppTheme.body2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkerText,
                    ),
                  ),
                ],
              ),
            ),
            if (_billListTooLong)
              const Padding(
                padding: EdgeInsets.only(top: AppTheme.space2),
                child: _Note(
                  icon: Icons.error_outline_rounded,
                  color: AppTheme.error,
                  text:
                      'Too many bills selected to fit on one receipt — record '
                      'the payment across several receipts.',
                ),
              ),
          ],
          // Carried charges the server will not settle against a receipt.
          // Shown because they are money owed, but never tickable — offering
          // them would build a receipt the settlement proc silently ignores.
          if (noteTotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.space2),
              child: _Note(
                icon: Icons.info_outline_rounded,
                color: AppTheme.warning,
                text:
                    'Note: an additional ${money(noteTotal)} is carried on '
                    'this account and is not settled by this receipt.',
              ),
            ),
        ],
      ),
    );
  }

  Widget _selectAllRow(List<Map<String, dynamic>> outstanding) {
    final all = outstanding.map(_billNo).whereType<String>().toSet();
    final allSelected = all.isNotEmpty && all.every(_selectedBills.contains);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              if (allSelected) {
                _selectedBills.removeAll(all);
              } else {
                _selectedBills.addAll(all);
              }
            });
            _proposeAmount();
          },
          icon: Icon(
            allSelected ? Icons.remove_done_rounded : Icons.done_all_rounded,
            size: 18,
          ),
          label: Text(allSelected ? 'Clear all' : 'Select all'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  /// One outstanding bill, as a tappable row rather than a bare checkbox —
  /// the whole row is the target, which matters most on a phone.
  Widget _buildBillTile(Map<String, dynamic> bill) {
    final billNo = _billNo(bill);
    if (billNo == null) return const SizedBox.shrink();

    final selected = _selectedBills.contains(billNo);
    // Only the outstanding amount. maintenance_cal.total_amount is a running
    // account total that rolls forward earlier arrears, not the value of this
    // charge, so showing it beside the bill would misread as its price.
    final due = _billAmount(bill);
    final date = _billDue(bill);
    final status = _billStatus(bill);
    final radius = BorderRadius.circular(AppTheme.radiusSm + 2);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space2),
      child: Material(
        color: selected ? AppTheme.primarySurface : AppTheme.background,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            setState(() {
              if (selected) {
                _selectedBills.remove(billNo);
              } else {
                _selectedBills.add(billNo);
              }
            });
            _proposeAmount();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space3,
              vertical: AppTheme.space3,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                // Ignoring its own taps: the row already handles them, and a
                // checkbox with its own handler double-fires on the edge
                // between the two.
                IgnorePointer(
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) {},
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: AppTheme.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Number and type on one line, as the website prints
                      // them — the type qualifies which bill this is, and a
                      // Regular and an Add-On otherwise read identically.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _billLabel(bill),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _billTypeLabel(bill),
                            style: AppTheme.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Due ${prettyDate(date)}',
                          style: AppTheme.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(due),
                      style: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.darkerText,
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(height: 4),
                      // Overdue reads red, anything else amber — the website's
                      // two-tone rule, which is the whole point of the column.
                      StatusChip(
                        label: status,
                        color: status.toLowerCase() == 'overdue'
                            ? AppTheme.error
                            : AppTheme.warning,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Payment ──────────────────────────────────────────────────────────

  Widget _paymentCard(
    List<Map<String, dynamic>> pdcCheques,
    List<Map<String, dynamic>> outstanding,
  ) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Payment'),
          _buildAmountField(outstanding),
          const SizedBox(height: AppTheme.space4),
          // Mode and date pair up above the phone breakpoint; on a phone they
          // stack, since two half-width fields there are too narrow to read.
          ResponsiveRow(
            spacing: AppTheme.space3,
            children: [_buildPayModePicker(), _buildDateField()],
          ),
          // Unconditional now that both modes are cheques: the number, bank
          // and date are required either way.
          const SizedBox(height: AppTheme.space4),
          _buildChequeFields(pdcCheques),
          const SizedBox(height: AppTheme.space4),
          TextFormField(
            controller: _remarksController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Remarks (optional)'),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(List<Map<String, dynamic>> outstanding) {
    final minimum = _minimumAmount(outstanding);
    // Add-On bills may be part paid, so one in the selection opens the box up.
    // A selection of only Regular bills fixes the amount outright.
    final editable = _selectedRows(
      outstanding,
    ).any((b) => _billType(b) != _regular);

    // The website's three hints, in its own words. Which one shows is the whole
    // explanation of why the field is or is not editable.
    final String hint;
    if (_pdcLocked) {
      hint = 'Set by the selected cheque';
    } else if (_selectedBills.isEmpty) {
      hint = 'Tick the bills this payment settles';
    } else if (!editable) {
      hint = 'Regular bills must be cleared in full';
    } else if (minimum > 0) {
      hint = 'Minimum ${money(minimum)} — only add-on bills may be part paid';
    } else {
      hint = 'Editable for a part payment';
    }

    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTheme.title.copyWith(fontSize: 20),
      // A PDC is written for a fixed sum, and a Regular bill has to clear in
      // full — in both cases the figure is decided elsewhere, so the field
      // follows it rather than the typist.
      enabled: !_pdcLocked && !(_selectedBills.isNotEmpty && !editable),
      decoration: InputDecoration(
        labelText: 'Amount received',
        prefixText: '₹ ',
        helperText: hint,
        helperMaxLines: 2,
      ),
      validator: (v) {
        final amount = double.tryParse((v ?? '').trim());
        if (amount == null) return 'Enter the amount';
        if (amount <= 0) return 'Amount must be more than zero';
        return null;
      },
    );
  }

  /// Cheque or PDC, as a segmented control.
  ///
  /// The website uses a ModeSwitch here, not a dropdown, and with only two
  /// options that is the better control: both are visible without opening
  /// anything, and the choice is one tap rather than two. Cash, Online, NEFT
  /// and UPI are absent on both — the form requires cheque number, bank and
  /// date, so a cash payment could only be saved by inventing them.
  Widget _buildPayModePicker() {
    const modes = <MapEntry<String, String>>[
      MapEntry('Cheque', 'Cheque'),
      MapEntry('PDC', 'PDC cheque'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment mode', style: AppTheme.caption),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm + 4),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              for (final mode in modes)
                Expanded(child: _modeButton(mode.key, mode.value)),
            ],
          ),
        ),
      ],
    );
  }

  /// One segment. The selected one is raised out of the track in white, which
  /// states selection more plainly than a tint at this size.
  Widget _modeButton(String value, String label) {
    final selected = _payMode == value;
    final radius = BorderRadius.circular(AppTheme.radiusSm);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppTheme.cardBackground : Colors.transparent,
        borderRadius: radius,
        elevation: selected ? 1 : 0,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: radius,
          onTap: selected ? null : () => _onPayModeChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.body2.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primary : AppTheme.darkText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Switching mode clears the cheque details, as the website does and as the
  /// legacy btnChequeMode_Click / btnPDCMode_Click handlers did.
  ///
  /// Leaving them behind would attach one cheque's number and bank to a
  /// payment made by another means entirely.
  void _onPayModeChanged(String? mode) {
    setState(() {
      _payMode = mode ?? 'Cheque';
      _pdcId = null;
      _chequeDate = null;
      _chequeNoController.clear();
      _bankController.clear();
    });
    // Back to the selection total, so an amount a PDC put there does not
    // survive the switch (legacy ClearChequeDetails cleared it).
    _proposeAmount();
  }

  Widget _buildChequeFields(List<Map<String, dynamic>> pdcCheques) {
    final isPdc = _payMode == 'PDC';

    // Required, as the website requires them. A cheque with no number cannot
    // be traced back to the payment it settled.
    String? required(String? v, String what) =>
        (v ?? '').trim().isEmpty ? 'Enter the $what' : null;

    return Column(
      children: [
        if (isPdc) ...[
          _pdcPicker(pdcCheques),
          const SizedBox(height: AppTheme.space4),
        ],
        ResponsiveRow(
          spacing: AppTheme.space3,
          children: [
            TextFormField(
              controller: _chequeNoController,
              // A chosen PDC fills these in and locks them: the cheque exists
              // already, so editing its number here would record a receipt
              // against a cheque nobody holds.
              enabled: !_pdcLocked,
              decoration: const InputDecoration(
                labelText: 'Transaction ID / cheque no.',
              ),
              validator: (v) => required(v, 'cheque number'),
            ),
            TextFormField(
              controller: _bankController,
              enabled: !_pdcLocked,
              decoration: const InputDecoration(labelText: 'Bank name'),
              validator: (v) => required(v, 'bank name'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        _dateField(
          label: 'Payment date',
          value: _chequeDate,
          placeholder: 'Not set',
          enabled: !_pdcLocked,
          onPicked: (d) => setState(() => _chequeDate = d),
        ),
      ],
    );
  }

  /// The post-dated cheques this flat has lodged.
  Widget _pdcPicker(List<Map<String, dynamic>> cheques) {
    if (cheques.isEmpty) {
      return const _Note(
        icon: Icons.info_outline_rounded,
        color: AppTheme.warning,
        text: 'No post-dated cheques on file for this flat.',
      );
    }

    return AppDropdown<String>(
      value: _pdcId,
      label: 'Post-dated cheque',
      icon: Icons.event_repeat_outlined,
      isDense: false,
      options: [
        for (final c in cheques)
          if (_pdcKey(c) != null)
            AppOption(
              _pdcKey(c)!,
              [
                pick(c, ['chqno', 'cheque_no']),
                money(c['che_amount'] ?? c['amount']),
                prettyDate(c['che_date']),
                pick(c, ['bank_name']),
              ].where((e) => e != null && e.isNotEmpty).join(' · '),
            ),
      ],
      onChanged: (v) => _onPdcChosen(v, cheques),
      validator: (v) =>
          _payMode == 'PDC' && v == null ? 'Select a post-dated cheque' : null,
    );
  }

  static String? _pdcKey(Map<String, dynamic> cheque) =>
      pick(cheque, ['pdc_rem_id', 'pdcRemId', 'pdc_id']);

  /// A picked cheque supplies the receipt's details.
  void _onPdcChosen(String? id, List<Map<String, dynamic>> cheques) {
    final cheque = cheques.firstWhere(
      (c) => _pdcKey(c) == id,
      orElse: () => const {},
    );

    setState(() {
      _pdcId = id;
      // These arrive from SQL as numbers as often as strings, so they are
      // normalised here rather than at every use.
      _chequeNoController.text = pick(cheque, ['chqno', 'cheque_no']) ?? '';
      _bankController.text = pick(cheque, ['bank_name']) ?? '';
      _chequeDate = asDate(cheque['che_date']);
    });

    // The cheque is written for what it is written for; the receipt takes its
    // amount rather than the bill selection's.
    final amount = asDouble(cheque['che_amount'] ?? cheque['amount']);
    if (amount != null) {
      final text = amount.toStringAsFixed(2);
      _amountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  Widget _buildDateField() => _dateField(
    label: 'Receipt date',
    value: _receiptDate,
    onPicked: (d) => setState(() => _receiptDate = d),
  );

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
    String placeholder = '',
    bool enabled = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm + 2),
      onTap: enabled
          ? () async {
              final picked = await showSingleDateDialog(
                context: context,
                initial: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onPicked(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? placeholder : prettyDate(value),
          style: AppTheme.body2.copyWith(
            color: enabled ? null : AppTheme.deactivatedText,
          ),
        ),
      ),
    );
  }

  // ── Summary ──────────────────────────────────────────────────────────

  /// What the entered amount does to the ticked bills.
  ///
  /// The server decides the real allocation — interest first, then principal,
  /// surplus to advance — so this does not try to reproduce it. It answers the
  /// one question the secretary can get wrong before submitting: does this
  /// money cover what was ticked, and if not, by how much.
  Widget _summaryCard(List<Map<String, dynamic>> outstanding) {
    final selected = _selectedDue(outstanding);
    final entered = _enteredAmount;

    if (_selectedBills.isEmpty && entered <= 0) {
      return const SizedBox.shrink();
    }

    final difference = entered - selected;
    // Half a paisa, so a total that lands on 1234.995 is not called short by
    // a rounding artefact the secretary cannot see or act on.
    final settles = difference.abs() < 0.005;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryRow('Selected bills', money(selected)),
          const Divider(height: AppTheme.space5),
          _summaryRow('Amount received', money(entered)),
          if (entered > 0 && _selectedBills.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space3),
            if (settles)
              const _Note(
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.success,
                text: 'Settles the selected bills exactly.',
              )
            else if (difference > 0)
              _Note(
                icon: Icons.savings_outlined,
                color: AppTheme.success,
                text:
                    '${money(difference)} over — the surplus carries forward '
                    'as advance.',
              )
            else
              _Note(
                icon: Icons.info_outline_rounded,
                color: AppTheme.warning,
                text:
                    '${money(-difference)} short — the balance stays '
                    'outstanding.',
              ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTheme.caption)),
        Text(
          value,
          style: AppTheme.body2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkerText,
          ),
        ),
      ],
    );
  }

  Widget _submitButton(bool loading) {
    return BusyButton(
      label: 'Record payment',
      busy: loading,
      icon: Icons.check_rounded,
      onPressed: loading ? null : _submit,
    );
  }
}

/// A tinted line of guidance — the advance note, the shortfall warning, the
/// nothing-outstanding message. One shape for all of them, so the screen does
/// not grow a slightly different banner each time it needs to say something.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(color),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm + 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppTheme.space2 + 2),
          Expanded(
            child: Text(
              text,
              style: AppTheme.caption.copyWith(color: AppTheme.darkText),
            ),
          ),
        ],
      ),
    );
  }
}
