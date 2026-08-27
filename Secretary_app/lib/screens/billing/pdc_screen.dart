import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/models/pdc_request.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/billing_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

/// Post-dated cheques: everything on file, and the ones due to be banked.
class PdcScreen extends ConsumerStatefulWidget {
  const PdcScreen({super.key});

  @override
  ConsumerState<PdcScreen> createState() => _PdcScreenState();
}

class _PdcScreenState extends ConsumerState<PdcScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// The clearing worklist is a date window, as pdc_clearing.aspx was: the
  /// endpoint requires from and to, so it cannot be loaded without one.
  late DateTimeRange _range;

  /// True until the window has been sized from the cheques actually on file.
  ///
  /// A guessed window is the wrong default here: any fixed span either misses
  /// cheques dated beyond it or opens on a stretch with nothing in it, and
  /// either way the screen reads as broken rather than as empty.
  bool _rangeIsProvisional = true;

  /// True while the window is the fitted one — every cheque on file — rather
  /// than a narrower span the operator picked.
  bool _rangeCoversEverything = false;

  @override
  void initState() {
    super.initState();
    // Stands in only until the register comes back and _fitRange replaces it.
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 3, now.day),
    );
    // The Add button belongs to the reminder tab only, and the segmented
    // control is drawn from the index, so both a swipe and a tap have to
    // rebuild — TabController does not do that on its own. Unguarded on
    // purpose: skipping while indexIsChanging left the pill behind the tap
    // for the length of the animation.
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    Future.microtask(() async {
      final vm = ref.read(billingViewModelProvider.notifier);
      // The register first: its rows are what the window is measured from.
      await vm.loadPdc();
      _fitRangeToCheques();
      await _loadClearing();
    });
  }

  /// Opens the window on the cheques the society actually holds.
  ///
  /// The register carries every cheque and its date, so the span between the
  /// earliest and the latest is the one window guaranteed to show all of them.
  /// The operator narrows it from there; a default that showed nothing gave
  /// them nothing to narrow.
  void _fitRangeToCheques() {
    if (!mounted || !_rangeIsProvisional) return;

    final rows = ref
        .read(billingViewModelProvider)
        .rows(BillingKeys.pdc)
        .value
        ?.items;

    final dates = [
      for (final r in rows ?? const <Map<String, dynamic>>[])
        if (asDate(r['che_date'] ?? r['cheque_date']) case final d?) d,
    ]..sort();

    // Nothing on file: leave the provisional window and try again once rows
    // arrive, rather than collapsing it to a single day.
    if (dates.isEmpty) return;

    setState(() {
      _rangeIsProvisional = false;
      _rangeCoversEverything = true;
      _range = DateTimeRange(start: dates.first, end: dates.last);
    });
  }

  Future<void> _loadClearing() => ref
      .read(billingViewModelProvider.notifier)
      .loadPdcClearing(from: _iso(_range.start), to: _iso(_range.end));

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final picked = await showDateRangeDialog(
      context: context,
      initial: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        // A window they chose is never overwritten by the fitted one.
        _rangeIsProvisional = false;
        _rangeCoversEverything = false;
      });
      await _loadClearing();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(billingViewModelProvider.notifier)
          .loadPdc(search: query.trim().isEmpty ? null : query.trim());
    });
  }

  /// Files a new cheque, or reopens one already on file to correct it.
  ///
  /// The reminder tab does exactly what pdc_reminder_search.aspx does: add,
  /// edit, delete. Banking a cheque is the clearing tab's job.
  Future<void> _openForm([Map<String, dynamic>? row]) async {
    // A page rather than a sheet: with the resident's details and their
    // cheques already on file below the fields, this outgrew the height a
    // bottom sheet can give it without becoming a scroll inside a scroll.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => _PdcFormPage(existing: row)),
    );
  }

  /// Removes a cheque from the register.
  ///
  /// Edit and Delete sit on the row itself, as the website's two buttons do —
  /// nothing here opens a menu first. Clearing is not offered from this tab at
  /// all: it belongs to the dated worklist next door.
  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final id = pickInt(row, ['pdc_rem_id', 'id']);
    if (id == null) return;

    final chequeNo = pick(row, ['chqno', 'cheque_no', 'che_no', 'chequeNo']);
    final confirmed = await _confirm(
      title: 'Remove this cheque?',
      message: chequeNo == null
          ? 'It will no longer appear on the PDC list.'
          : 'Cheque $chequeNo will no longer appear on the PDC list.',
      actionLabel: 'Remove',
    );

    if (!confirmed || !mounted) return;
    await ref.read(billingViewModelProvider.notifier).deletePdc(id);
  }

  /// Records the outcome, carrying the window the clearing list is showing so
  /// the reload comes back with the same rows.
  Future<void> _clear(
    BillingViewModel vm,
    int id, {
    bool deposited = false,
    bool returned = false,
    bool cancelled = false,
  }) => vm.clearPdc(
    id,
    deposited: deposited,
    returned: returned,
    cancelled: cancelled,
    from: _iso(_range.start),
    to: _iso(_range.end),
  );

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, billingViewModelProvider);

    final state = ref.watch(billingViewModelProvider);
    final vm = ref.read(billingViewModelProvider.notifier);

    return Scaffold(
      // Only on the reminder tab: the clearing list is a dated worklist of
      // cheques already on file, so filing a new one there would drop it
      // outside the window it was just added to.
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: const Text('Add cheque'),
            )
          : null,
      appBar: AppBar(
        title: const Text('Post-dated cheques'),
        // A segmented control rather than underlined tabs: two options read
        // as a switch between two lists, which is what they are, and the
        // filled pill survives the light app bar that made white labels
        // invisible.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(SegmentedTabBar.height),
          child: SegmentedTabBar(
            // Named as the two website pages are — pdc_reminder_search.aspx
            // and pdc_clearing.aspx — so the same words mean the same thing
            // in both.
            tabs: const [
              SegmentTab(label: 'Reminder', icon: Icons.event_note_outlined),
              SegmentTab(
                label: 'Clearing',
                icon: Icons.event_available_outlined,
              ),
            ],
            selectedIndex: _tabs.index,
            onSelected: _tabs.animateTo,
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    hint: 'Search by resident or cheque number',
                  ),
                ),
                Expanded(
                  child: RowsView(
                    rows: state.rows(BillingKeys.pdc),
                    onRefresh: () => vm.loadPdc(),
                    emptyIcon: Icons.event_note_outlined,
                    emptyTitle: 'No cheques on file',
                    builder: (items) => _buildList(items),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                _buildRangeBar(),
                Expanded(
                  child: RowsView(
                    rows: state.rows(BillingKeys.pdcClearing),
                    onRefresh: _loadClearing,
                    emptyIcon: Icons.event_available_outlined,
                    emptyTitle: 'Nothing due',
                    emptyMessage: 'No cheques fall due in this period.',
                    builder: (items) => _buildList(items, clearing: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The window the clearing list covers, and the way to change it — the
  /// From/To pair the legacy page carried above its grid.
  Widget _buildRangeBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: _pickRange,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.date_range_outlined,
                size: 17,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Says where the window came from, so a list that opens
                    // on everything does not look like an arbitrary filter.
                    _rangeCoversEverything
                        ? 'Showing every cheque on file'
                        : 'Cheques due between',
                    style: AppTheme.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prettyDate(_iso(_range.start))} — '
                    '${prettyDate(_iso(_range.end))}',
                    style: AppTheme.title.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Change',
              style: AppTheme.caption.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {bool clearing = false}) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // Deep enough at the foot that the Add button does not sit on the last
      // card's outcome buttons.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildCheque(items[i], clearing: clearing),
    );
  }

  Widget _buildCheque(Map<String, dynamic> row, {bool clearing = false}) {
    final owner = pick(row, ['owner_name', 'name', 'resident_name']);
    final flat = pick(row, ['flat_no', 'unit_no', 'flat']);
    final chequeNo = pick(row, ['chqno', 'cheque_no', 'che_no', 'chequeNo']);
    final bank = pick(row, ['bank_name', 'bank']);
    final status = _statusOf(row);

    final tint = statusColor(status);

    return AppCard(
      // Nothing on either tab opens a menu: the reminder rows carry Edit and
      // Delete, the clearing rows carry the three outcomes.
      onTap: null,
      // A coloured spine carries the outcome, so the state of a long list is
      // readable at a glance rather than one chip at a time.
      accent: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A cheque leads with its number — that is what an operator
              // matches against the paper in their hand.
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceFor(tint),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(Icons.payments_outlined, size: 19, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner ?? 'Resident',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.title.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (flat != null) flat,
                        if (chequeNo != null) 'Cheque $chequeNo',
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(row['amount'] ?? row['che_amount']),
                    style: AppTheme.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  StatusChip(label: status, color: tint),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 13,
                color: AppTheme.lightText,
              ),
              const SizedBox(width: 5),
              Text(
                // Said in words, because "the date" on this screen is the day
                // the cheque may be banked, not the day it was written.
                'Due ${prettyDate(row['che_date'] ?? row['cheque_date'])}',
                style: AppTheme.caption,
              ),
              if (bank != null) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.account_balance_outlined,
                  size: 13,
                  color: AppTheme.lightText,
                ),
                const SizedBox(width: 5),
                // Flexible, not Expanded: with the actions to its right the
                // bank name gives up its space rather than pushing them off.
                Flexible(
                  child: Text(
                    bank,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ),
              ],
              // Edit and Delete ride on the date line rather than taking a
              // row of their own — a card per cheque is short enough that a
              // separate button bar doubled its height for two verbs.
              if (!clearing) ...[
                const Spacer(),
                _RowAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppTheme.primary,
                  onTap: () => _openForm(row),
                ),
                const SizedBox(width: 4),
                _RowAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppTheme.error,
                  onTap: () => _confirmDelete(row),
                ),
              ],
            ],
          ),
          if (clearing) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 10),
            Text(
              // Without a label the three pills read as filters rather than
              // as the action they are.
              'Mark this cheque as',
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            _buildOutcomes(row, status),
          ],
        ],
      ),
    );
  }

  /// The three outcomes, on the row itself — the website's radio buttons.
  ///
  /// Exactly one applies at a time, so picking one replaces the others rather
  /// than adding to them, and the one already recorded reads as selected.
  Widget _buildOutcomes(Map<String, dynamic> row, String status) {
    final id = pickInt(row, ['pdc_rem_id', 'id']);

    return Row(
      children: [
        for (final outcome in const [
          ('Deposited', 'deposit', AppTheme.success),
          ('Returned', 'return', AppTheme.error),
          ('Bounced', 'cancel', AppTheme.warning),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _OutcomeButton(
                label: outcome.$1,
                color: outcome.$3,
                selected: status == outcome.$1,
                onTap: id == null ? null : () => _pickOutcome(id, outcome.$2),
              ),
            ),
          ),
      ],
    );
  }

  /// Records the outcome tapped on the row. Depositing still asks first — it
  /// raises a receipt, which the website confirms too.
  Future<void> _pickOutcome(int id, String action) async {
    final vm = ref.read(billingViewModelProvider.notifier);

    if (action == 'deposit') {
      final confirmed = await _confirm(
        title: 'Mark cheque deposited?',
        message:
            'This also raises a receipt for the cheque amount against the '
            'resident. It cannot be undone from the app.',
        actionLabel: 'Deposit',
      );
      if (!confirmed) return;
      await _clear(vm, id, deposited: true);
      return;
    }

    await _clear(
      vm,
      id,
      returned: action == 'return',
      cancelled: action == 'cancel',
    );
  }

  /// sp_pdc_reminder tracks the outcome as three separate bit columns rather
  /// than one status, so the label is derived. Order matters: a cheque that
  /// was deposited and then returned is a return.
  String _statusOf(Map<String, dynamic> row) {
    final text = pick(row, ['status', 'status_name']);
    if (text != null) return text;

    bool flag(List<String> keys) => keys.any((k) => asBoolish(row[k]));

    if (flag(['che_can', 'cancelled'])) return 'Bounced';
    if (flag(['che_ret', 'returned'])) return 'Returned';
    if (flag(['che_dep', 'deposited'])) return 'Deposited';
    return 'Pending';
  }

  static bool asBoolish(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }
}

/// One of the three clearing outcomes, as a tappable pill.
///
/// Rendered as a radio rather than a checkbox: the outcomes are mutually
/// exclusive, which is what the website's radio group says and what
/// sp_pdc_reminder records — one flag set, the other two cleared.
class _OutcomeButton extends StatelessWidget {
  const _OutcomeButton({
    required this.label,
    required this.color,
    required this.selected,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm);

    return Material(
      color: selected ? AppTheme.surfaceFor(color) : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? color : AppTheme.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 15,
                color: selected ? color : AppTheme.lightText,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption.copyWith(
                    color: selected ? color : AppTheme.lightText,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

/// Records a cheque as soon as it is handed over.
///
/// The website's form fills the resident's wing, mobile and address from the
/// chosen owner and leaves them read-only; none of that is written back, so
/// the app asks only for what POST /billing/pdc actually stores.
class _PdcFormPage extends ConsumerStatefulWidget {
  const _PdcFormPage({this.existing});

  /// The row being corrected, or null when filing a new cheque.
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_PdcFormPage> createState() => _PdcFormPageState();
}

class _PdcFormPageState extends ConsumerState<_PdcFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _chequeNoController = TextEditingController();
  final _amountController = TextEditingController();

  int? _ownerId;

  /// Defaults to a month out. A cheque handed over today is post-dated by
  /// definition, so today would be the one date it cannot be.
  DateTime _chequeDate = DateTime.now().add(const Duration(days: 30));

  /// The chosen resident's contact block, and the cheques already on file for
  /// them — both read-only, exactly as the website's form shows them.
  Map<String, dynamic>? _ownerDetails;
  List<Map<String, dynamic>> _ownerCheques = const [];
  bool _loadingOwner = false;

  int? get _editingId => widget.existing == null
      ? null
      : pickInt(widget.existing!, ['pdc_rem_id', 'id']);

  /// Fills the read-only panel from the picked resident.
  ///
  /// Neither lookup is allowed to break the form: a resident with no contact
  /// record, or with no cheques yet, must still be able to have one filed.
  Future<void> _loadOwner(int ownerId) async {
    setState(() {
      _loadingOwner = true;
      _ownerDetails = null;
      _ownerCheques = const [];
    });

    final vm = ref.read(billingViewModelProvider.notifier);
    Map<String, dynamic> details;
    RowList cheques;
    try {
      details = await vm.pdcOwnerDetails(ownerId);
    } catch (_) {
      details = const {};
    }
    try {
      cheques = await vm.pdcByOwner(ownerId);
    } catch (_) {
      cheques = const RowList();
    }

    // A second pick while the first was in flight wins.
    if (!mounted || _ownerId != ownerId) return;
    setState(() {
      _ownerDetails = details.isEmpty ? null : details;
      // The cheque being edited is not "already on file" from its own form.
      _ownerCheques = cheques.items
          .where((c) => pickInt(c, ['pdc_rem_id', 'id']) != _editingId)
          .toList();
      _loadingOwner = false;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(billingViewModelProvider.notifier).loadPdcOwners(),
    );

    final row = widget.existing;
    if (row == null) return;

    _ownerId = pickInt(row, ['owner_id', 'ownerId']);
    _chequeNoController.text =
        pick(row, ['chqno', 'cheque_no', 'che_no']) ?? '';
    _amountController.text =
        (row['che_amount'] ?? row['amount'])?.toString() ?? '';

    final date = asDate(row['che_date'] ?? row['cheque_date']);
    if (date != null) _chequeDate = date;

    // An edit opens with a resident already chosen, so its panel has to be
    // filled without waiting for a pick that will not come.
    if (_ownerId case final id?) Future.microtask(() => _loadOwner(id));
  }

  @override
  void dispose() {
    _chequeNoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// The resident's details and their cheques already on file.
  ///
  /// Read-only throughout, as the website's panel is: none of it is written
  /// back, and the outcome flags are the clearing tab's to change.
  Widget _buildOwnerPanel() {
    if (_loadingOwner) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final d = _ownerDetails;
    final contact = <String, String>{
      if (d != null) ...{
        if ([
              pick(d, ['build_name']),
              pick(d, ['w_name']),
            ].whereType<String>().join(' — ')
            case final where when where.isNotEmpty)
          'Building — wing': where,
        if (pick(d, ['pre_mob']) case final m?) 'Mobile': m,
        if (pick(d, ['alter_mob']) case final m?) 'Alternate mobile': m,
        if (pick(d, ['email']) case final e?) 'E-mail': e,
        if (pick(d, ['pre_addr1']) case final a?) 'Address': a,
        if (pick(d, ['pre_add2']) case final a?) 'Address 2': a,
      },
    };

    if (contact.isEmpty && _ownerCheques.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in contact.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: Text(entry.key, style: AppTheme.caption),
                  ),
                  Expanded(child: Text(entry.value, style: AppTheme.body2)),
                ],
              ),
            ),
          if (_ownerCheques.isNotEmpty) ...[
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 10),
            ],
            Text(
              // So a duplicate is visible before one more is added — this is
              // GridView2 on the legacy modal.
              'Cheques already on file',
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            for (final c in _ownerCheques)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pick(c, ['chqno', 'cheque_no']) ?? '—',
                        style: AppTheme.body2,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        prettyDate(c['che_date']),
                        style: AppTheme.caption,
                      ),
                    ),
                    Text(
                      money(c['che_amount']),
                      style: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final row = widget.existing;
    final request = PdcRequest(
      ownerId: _ownerId,
      // The wing travels with the resident, as it does on the website's form.
      // Left out, the API defaults it to 0 and the cheque is filed against no
      // wing at all — sp_pdc_reminder has no row to match that against.
      wingId:
          pickInt(_ownerDetails ?? const {}, ['wing_id']) ??
          pickInt(widget.existing ?? const {}, ['wing_id']),
      chequeNo: _chequeNoController.text.trim(),
      chequeDate: _PdcScreenState._iso(_chequeDate),
      amount: double.tryParse(_amountController.text.trim()),
      // Carried through an edit. The API defaults each of these to 0 when it
      // is absent, so correcting an amount would otherwise quietly un-bank a
      // cheque that had already been deposited.
      deposited: row == null ? null : _PdcScreenState.asBoolish(row['che_dep']),
      returned: row == null ? null : _PdcScreenState.asBoolish(row['che_ret']),
      cancelled: row == null ? null : _PdcScreenState.asBoolish(row['che_can']),
    );

    final vm = ref.read(billingViewModelProvider.notifier);
    final id = _editingId;
    final saved = id == null
        ? await vm.createPdc(request)
        : await vm.updatePdc(id, request);

    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingViewModelProvider);
    final owners = state.rows(BillingKeys.pdcOwners).value?.items ?? const [];

    // The page outlives a failed save, so the message has to land here — on a
    // sheet the list screen behind it was still mounted to catch one.
    listenForFeedback(ref, context, billingViewModelProvider);

    final isEditing = _editingId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit cheque' : 'Add cheque')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              Text(
                'It appears on the clearing list on the date it may be banked.',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 20),
              AppDropdown<int>(
                value: _ownerId,
                label: 'Resident',
                hint: owners.isEmpty ? 'Loading residents…' : 'Select resident',
                icon: Icons.person_outline,
                isDense: false,
                options: [
                  for (final o in owners)
                    if (pickInt(o, ['owner_id', 'id']) case final id?)
                      AppOption(
                        id,
                        [
                          pick(o, ['name', 'owner_name']) ?? 'Resident',
                          if (pick(o, ['Unit', 'unit', 'flat_no'])
                              case final unit?)
                            unit,
                        ].join(' — '),
                      ),
                ],
                onChanged: (v) {
                  setState(() => _ownerId = v);
                  if (v != null) _loadOwner(v);
                },
                validator: (v) => v == null ? 'Choose a resident' : null,
              ),
              if (_ownerId != null) ...[
                const SizedBox(height: 12),
                _buildOwnerPanel(),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _chequeNoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cheque number',
                  prefixIcon: Icon(Icons.tag, size: 18),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the cheque number'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  final amount = double.tryParse(v?.trim() ?? '');
                  if (amount == null) return 'Enter the amount';
                  if (amount <= 0) return 'Amount must be more than zero';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showSingleDateDialog(
                    context: context,
                    initial: _chequeDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _chequeDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Cheque date',
                    helperText: 'The date it may be banked',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(prettyDate(_chequeDate), style: AppTheme.body2),
                ),
              ),
              // No bank field: sp_pdc_reminder's Update branch takes no such
              // parameter, so anything typed here was accepted by the form and
              // then silently dropped. The website's form does not ask either.
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : Text(_editingId == null ? 'Save cheque' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact row action — icon and word, sized to sit inline on a text line.
///
/// TextButton.icon carries Material's 48px minimum tap target and its own
/// padding, which pushed these onto a line of their own; this keeps the touch
/// area honest at 40px while letting the label sit beside a date.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
