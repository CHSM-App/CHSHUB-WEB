import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pdf/bill_export.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/bill_sheet.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/bill_sheet_view.dart';

/// Every flat's bill within one run, drawn as the website prints them.
///
/// The charge columns are not fixed: sp_maintanance_cal pivots each society's
/// own charge heads into col1_name/col1_amount pairs, so the server sends a
/// `chargeColumns` list describing which pairs are present and the screen
/// renders those. Hardcoding a chart of charges here would be wrong for the
/// next society.
class BillDetailScreen extends ConsumerStatefulWidget {
  final int billId;
  final String period;

  const BillDetailScreen({
    super.key,
    required this.billId,
    required this.period,
  });

  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  Map<String, dynamic>? _detail;
  Object? _error;
  bool _loading = true;

  /// True while a PDF is being built.
  ///
  /// A notifier rather than a plain field because the per-flat sheet is its own
  /// route: setState here would not rebuild it, leaving its buttons inert-
  /// looking through the wait.
  final ValueNotifier<bool> _exporting = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _exporting.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ref
          .read(billingViewModelProvider.notifier)
          .billDetail(widget.billId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Every flat in the run, in the order the server sent them.
  List<BillSheetData> get _sheets {
    final columns = asRows(_detail?['chargeColumns']);
    return asRows(
      _detail?['items'],
    ).map((row) => BillSheetData.fromRow(row, columns)).toList();
  }

  Future<void> _export(
    List<BillSheetData> sheets, {
    bool print = false,
    bool share = false,
  }) async {
    if (_exporting.value) return;
    _exporting.value = true;
    try {
      if (print) {
        await BillExport.print(context, sheets, period: widget.period);
      } else if (share) {
        await BillExport.share(context, sheets, period: widget.period);
      } else {
        await BillExport.download(context, sheets, period: widget.period);
      }
    } finally {
      if (mounted) _exporting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheets = _sheets;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.period),
        // Only once there is something to export — three live-looking actions
        // over an empty or failed run would each do nothing when tapped.
        actions: sheets.isEmpty
            ? null
            : [
                ListenableBuilder(
                  listenable: _exporting,
                  builder: (_, _) => Row(
                    children: [
                      // Each action takes its own hue, so the three read apart
                      // at a glance instead of as one grey run of glyphs.
                      _AppBarAction(
                        icon: Icons.download_rounded,
                        tooltip: 'Download',
                        color: AppTheme.primary,
                        busy: _exporting.value,
                        onTap: () => _export(sheets),
                      ),
                      const SizedBox(width: 6),
                      _AppBarAction(
                        icon: Icons.print_rounded,
                        tooltip: 'Print',
                        color: AppTheme.violet,
                        busy: _exporting.value,
                        onTap: () => _export(sheets, print: true),
                      ),
                      const SizedBox(width: 6),
                      _AppBarAction(
                        icon: Icons.share_rounded,
                        tooltip: 'Share',
                        color: AppTheme.teal,
                        busy: _exporting.value,
                        onTap: () => _export(sheets, share: true),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _detail == null) {
      return StateMessage(
        icon: Icons.cloud_off_rounded,
        iconColor: AppTheme.error,
        title: 'Could not load the bill',
        message: errorText(_error!),
        actionLabel: 'Try again',
        onAction: _load,
      );
    }

    final sheets = _sheets;
    if (sheets.isEmpty) {
      return const StateMessage(
        icon: Icons.receipt_outlined,
        title: 'No bills in this run',
        message: 'The run exists but has no flat rows.',
      );
    }

    final total = sheets.fold<double>(0, (sum, s) => sum + s.grandTotal);

    return Column(
      children: [
        _summary(sheets, total),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: sheets.length,
              itemBuilder: (context, i) => _tappable(sheets[i]),
            ),
          ),
        ),
      ],
    );
  }

  /// The run's size and value.
  ///
  /// The export actions used to sit here; they moved to the app bar, where
  /// they stay reachable as the list scrolls rather than scrolling away with
  /// the first bill.
  Widget _summary(List<BillSheetData> sheets, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${sheets.length} flat(s)', style: AppTheme.caption),
            const TextSpan(text: '  ·  ', style: AppTheme.caption),
            // The run's money is the figure worth reading twice, so it is the
            // one thing here not in caption grey.
            TextSpan(
              text: money(total),
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.darkerText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tapping a sheet opens that flat alone, where Download and Print export
  /// the single bill — the sheet a secretary actually hands to one resident.
  Widget _tappable(BillSheetData bill) {
    return InkWell(
      onTap: () => _openOne(bill),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: BillSheetView(bill: bill),
    );
  }

  void _openOne(BillSheetData bill) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bill.label.isEmpty ? 'Bill' : bill.label,
                      style: AppTheme.title.copyWith(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
            // The sheet is its own route, so the busy flag on the screen's
            // State does not reach it — a plain read here would leave these
            // buttons showing no progress while the PDF built. This rebuilds
            // them from the same notifier the app bar uses.
            //
            // Share leads rather than Download: one flat is open because the
            // secretary means to send that resident their bill.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: ListenableBuilder(
                listenable: _exporting,
                builder: (_, _) => Row(
                  children: [
                    Expanded(
                      child: _ExportButton(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        busy: _exporting.value,
                        filled: true,
                        onTap: () => _export([bill], share: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ExportButton(
                        icon: Icons.download_rounded,
                        label: 'Save',
                        busy: _exporting.value,
                        filled: false,
                        onTap: () => _export([bill]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ExportButton(
                        icon: Icons.print_rounded,
                        label: 'Print',
                        busy: _exporting.value,
                        filled: false,
                        onTap: () => _export([bill], print: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [BillSheetView(bill: bill)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One export action.
///
/// [filled] draws the primary treatment — the app's gradient with its own
/// tinted glow, since a grey shadow under a blue button reads as dirt. The
/// unfilled variant is bordered and tinted, heavy enough to read as a button
/// without contesting the filled one beside it.
class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.busy,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm + 2);
    // Disabled while an export runs — a second tap mid-render would build the
    // document twice and hand over two share sheets.
    final enabled = !busy;
    final foreground = filled ? AppTheme.white : AppTheme.primary;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: filled ? AppTheme.primaryGradient : null,
          color: filled ? null : AppTheme.primarySurface,
          borderRadius: radius,
          border: filled
              ? null
              : Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
          boxShadow: filled && enabled
              ? AppTheme.primaryGlow(opacity: 0.22)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // The spinner replaces the icon rather than sitting beside
                  // it, so the button keeps its width and the row does not
                  // shift under the finger that just tapped it.
                  if (busy)
                    SizedBox(
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  else
                    Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTheme.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One export action in the app bar.
///
/// A plain IconButton would keep its icon while a PDF built, so three taps in
/// a row would look like three ignored taps. This swaps the icon for a spinner
/// at the same size, holding the bar's layout still.
class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
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
    final radius = BorderRadius.circular(AppTheme.radiusSm + 2);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: !busy,
        label: tooltip,
        child: Opacity(
          opacity: busy ? 0.55 : 1,
          child: Material(
            // The plate itself, in the action's own tint — the same treatment
            // the dashboard's quick actions use, so a tinted icon here reads
            // as part of the app rather than a one-off.
            color: AppTheme.surfaceFor(color),
            borderRadius: radius,
            child: InkWell(
              onTap: busy ? null : onTap,
              borderRadius: radius,
              child: SizedBox(
                height: 38,
                width: 38,
                child: Center(
                  // Sized to match the icon it replaces, so the plate holds
                  // still through the wait rather than resizing under the
                  // finger that just tapped it.
                  child: busy
                      ? SizedBox(
                          height: 17,
                          width: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(icon, size: 19, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
