import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/billing_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'bill_detail_screen.dart';

/// Past bill runs. Tapping one opens the flat-wise detail.
class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  int? _year;
  int? _month;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() => ref
      .read(billingViewModelProvider.notifier)
      .loadBillRuns(year: _year, month: _month);

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(billingViewModelProvider).rows(BillingKeys.runs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance bills'),
        actions: [
          if (_year != null || _month != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Clear filter',
              onPressed: () {
                setState(() {
                  _year = null;
                  _month = null;
                });
                _refresh();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: RowsView(
                rows: rows,
                onRefresh: _refresh,
                emptyIcon: Icons.receipt_long_outlined,
                emptyTitle: 'No bill runs',
                emptyMessage: _year != null || _month != null
                    ? 'Nothing matches this filter.'
                    : 'Generate a bill run to see it here.',
                builder: (items) => ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _buildRun(items[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────

  Widget _buildFilters() {
    final now = DateTime.now();
    final years = [for (var y = now.year; y >= now.year - 4; y--) y];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: AppDropdown<int?>(
              value: _year,
              label: 'Year',
              // The field keeps its share of the row; only the dropped list
              // narrows. Five four-digit years do not need the field's width.
              menuWidth: 190,
              options: [
                const AppOption(null, 'All years'),
                for (final y in years) AppOption(y, '$y'),
              ],
              onChanged: (v) {
                setState(() => _year = v);
                _refresh();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppDropdown<int?>(
              value: _month,
              label: 'Month',
              // Wide enough for "September" and the check beside it.
              menuWidth: 210,
              options: [
                const AppOption(null, 'All months'),
                for (var m = 1; m <= 12; m++) AppOption(m, _monthName(m)),
              ],
              onChanged: (v) {
                setState(() => _month = v);
                _refresh();
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m - 1];

  // ── Rows ─────────────────────────────────────────────────────────────

  /// 'Regular' or 'Add-on', or null when the server did not say.
  ///
  /// sp_maintanance_cal 'Grid_Show' does not select the type, so the bills
  /// route joins it on from `maintenance_cal.bill_type` — 1 for gen_bill's
  /// monthly run, 0 for sp_new_maintenance's add-on — and sends both the raw
  /// int as `bill_type` and the string as `bill_type_label`. The label is
  /// preferred; a row too old to carry either shows no chip rather than
  /// guessing a type.
  String? _billType(Map<String, dynamic> row) {
    final label = pick(row, ['bill_type_label', 'billTypeLabel']);
    if (label != null) return label;

    final raw = row['bill_type'] ?? row['billType'];
    if (raw == null) return null;

    if (raw is String) {
      final text = raw.trim();
      return text.isEmpty ? null : text;
    }

    final n = asInt(raw);
    if (n == null) return null;
    return n == 1 ? 'Regular' : 'Add-on';
  }

  /// Matched loosely — the route writes 'Add-on', but the raw-column fallback
  /// above and any older spelling ('Addon', 'add on') should tint the same.
  bool _isAddOn(String type) {
    final t = type.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return t.contains('addon');
  }

  Widget _buildRun(Map<String, dynamic> row) {
    final billId = pickInt(row, ['bill_id', 'billId']);
    final month = asInt(row['month']);
    final year = asInt(row['year']);
    final type = _billType(row);

    final period = (month != null && year != null)
        ? '${_monthName(month)} $year'
        : (pick(row, ['period', 'bill_period']) ?? 'Bill run');

    return AppCard(
      onTap: billId == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BillDetailScreen(billId: billId, period: period),
              ),
            ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The type sits beside the period because it qualifies *which*
                // run this is — a regular run and an add-on can share a month
                // and otherwise read identically.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        period,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.title.copyWith(fontSize: 15),
                      ),
                    ),
                    if (type != null) ...[
                      const SizedBox(width: 8),
                      StatusChip(
                        label: type,
                        color: _isAddOn(type)
                            ? AppTheme.violet
                            : AppTheme.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Generated ${prettyDate(row['gen_date'] ?? row['created_at'] ?? row['bill_date'])}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
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
