import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/billing_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'receipt_detail_screen.dart';
import 'receipt_entry_screen.dart';

/// Payments collected, with the running total.
///
/// One page, as the website has it: the list is the screen, recording a
/// payment opens over it, and each row opens the receipt it stands for.
class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(billingViewModelProvider.notifier).loadReceipts();

  /// Rows matching the search box.
  ///
  /// Filtered here rather than on the server: the receipts route returns the
  /// society's list in one call, so a round trip per keystroke would be slower
  /// than the match itself. Name, flat and receipt number all match, because a
  /// secretary looking for a payment knows one of the three.
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> rows) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return rows;

    return rows.where((row) {
      final haystack = [
        pick(row, ['owner', 'owner_name', 'name', 'resident_name']),
        pick(row, ['flat_no', 'unit_no', 'flat']),
        pick(row, ['building_name', 'build_name', 'wing']),
        pick(row, ['receipt_no', 'voucher_no']),
        pick(row, ['transaction_ref', 'cheque_no']),
        pick(row, ['pay_mode', 'payment_mode', 'mode']),
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(q);
    }).toList();
  }

  /// The entry form, as a page.
  ///
  /// Not a sheet: the form runs long — bills to tick, an amount, a payment
  /// mode, cheque details — and a sheet gave it a cramped height with no app
  /// bar of its own.
  ///
  /// The refetch on return is a safety net, not the main path. Recording a
  /// payment already refreshes the list through the ViewModel, but a form
  /// abandoned after a failed save can leave the list stale, and a receipt
  /// that does not appear reads as a payment that was not recorded.
  Future<void> _recordPayment() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptEntryScreen()),
    );
    if (!mounted) return;
    await _refresh();
  }

  /// The receipt, as a page of its own.
  ///
  /// Not a bottom sheet: a receipt is a document, and a document wants a full
  /// screen with its own app bar to carry Download, Print and Share — a sheet
  /// gives it neither the height nor the header for that.
  Future<void> _viewReceipt(int receiptId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptDetailScreen(receiptId: receiptId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, billingViewModelProvider);

    final state = ref.watch(billingViewModelProvider);
    final rows = state.rows(BillingKeys.receipts);
    final total = rows.valueOrNull?.totalCollected;

    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordPayment,
        icon: const Icon(Icons.add),
        label: const Text('Record payment'),
      ),
      body: SafeArea(
        child: PageConstraints(
          padded: false,
          child: Column(
            children: [
              if (total != null) _collectedBanner(total),
              _searchBar(),
              Expanded(
                child: RowsView(
                  rows: rows,
                  onRefresh: _refresh,
                  emptyIcon: Icons.request_quote_outlined,
                  emptyTitle: 'No receipts yet',
                  emptyMessage: 'Record a payment to see it here.',
                  builder: (items) {
                    final matches = _filter(items);

                    // A search that matches nothing is not an empty list; it
                    // is a search that needs changing, and saying so keeps the
                    // secretary from thinking the receipts have gone.
                    if (matches.isEmpty) {
                      return StateMessage(
                        icon: Icons.search_off_rounded,
                        title: 'No receipts match',
                        message: 'Nothing here matches "${_query.trim()}".',
                        actionLabel: 'Clear search',
                        onAction: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppTheme.space4,
                        AppTheme.space3,
                        AppTheme.space4,
                        118,
                      ),
                      itemCount: matches.length,
                      itemBuilder: (context, i) => _buildReceipt(matches[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collectedBanner(dynamic total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.primaryGlow(opacity: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collected',
            style: AppTheme.caption.copyWith(color: AppTheme.border),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(total),
              style: AppTheme.headline.copyWith(color: AppTheme.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search name, flat or receipt no.',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppTheme.cardBackground,
        ),
      ),
    );
  }

  /// One receipt, compact.
  ///
  /// Name and amount lead the card, with the receipt number, date and
  /// reference on one line under them — the columns the website's grid shows,
  /// in the order a secretary scans them. The View button is gone: the whole
  /// card opens the receipt, and a button repeating that only cost height on
  /// every row.
  Widget _buildReceipt(Map<String, dynamic> row) {
    final receiptId = pickInt(row, ['receipt_id', 'id']);
    final flat = pick(row, ['flat_no', 'unit_no', 'flat']);
    final building = pick(row, ['building_name', 'build_name', 'wing']);
    // `owner` is what Grid_Show returns, and what the website's grid reads.
    // Without it the name was blank on every card.
    final owner = pick(row, ['owner', 'owner_name', 'name', 'resident_name']);
    final mode = pick(row, ['pay_mode', 'payment_mode', 'mode']);
    final status = pick(row, ['bill_status', 'status_name', 'status']);
    final receiptNo = pick(row, ['receipt_no', 'voucher_no']);
    final reference = pick(row, ['transaction_ref', 'cheque_no']);

    // A reversed payment must not read as money collected.
    final cancelled = status?.toLowerCase().contains('cancel') ?? false;
    final unit = [building, flat].where((e) => e != null).join(' · ');
    final title = owner ?? (unit.isEmpty ? 'Receipt' : unit);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.space2),
      onTap: receiptId == null ? null : () => _viewReceipt(receiptId),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.title.copyWith(fontSize: 15),
                      ),
                    ),
                    if (owner != null && unit.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(unit, style: AppTheme.caption),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                // Receipt number, date and reference on one line. Wrapped
                // rather than in a Row: three values and a long reference
                // would otherwise overflow a narrow phone.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    if (receiptNo != null)
                      Text(
                        receiptNo,
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      prettyDate(row['receipt_date'] ?? row['date']),
                      style: AppTheme.caption,
                    ),
                    if (reference != null)
                      Text('Ref $reference', style: AppTheme.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(row['paid_amount'] ?? row['amount']),
                style: AppTheme.title.copyWith(
                  fontSize: 15,
                  color: cancelled
                      ? AppTheme.deactivatedText
                      : AppTheme.success,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 4),
              // The mode is the everyday label; a cancelled receipt overrides
              // it, because that is the fact worth reading first.
              if (cancelled)
                StatusChip(label: status!, color: AppTheme.error)
              else if (mode != null)
                StatusChip(label: mode, color: AppTheme.info),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppTheme.deactivatedText,
          ),
        ],
      ),
    );
  }
}
