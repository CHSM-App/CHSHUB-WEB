import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pdf/cashbook_export.dart';
import '../../core/pdf/cashbook_pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/accounts_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

/// A single cashbook line, normalised out of the `sp_cashbook` row.
///
/// The procedure returns opening balance, transactions and closing balance in
/// one result set, told apart by `seq` (1, 2, 3) — the same contract the web
/// Cashbook page reads. Column names come back in the procedure's own casing
/// (`Date`, `Particular`, `Debit`, `Credit`), so they are picked case-
/// insensitively rather than indexed directly.
class _Entry {
  _Entry({
    required this.seq,
    required this.particular,
    required this.date,
    required this.debit,
    required this.credit,
  });

  factory _Entry.fromRow(Map<String, dynamic> row) {
    return _Entry(
      seq: asIntOr(pick(row, ['seq', 'Seq', 'SEQ']), 2),
      particular:
          pick(row, [
            'Particular',
            'particular',
            'particulars',
            'description',
            'details',
            'narration',
            'name',
          ]) ??
          'Entry',
      date: asDate(pick(row, ['Date', 'date', 'entry_date', 'EntryDate'])),
      debit: asDoubleOr(pick(row, ['Debit', 'debit', 'dr', 'payment'])),
      credit: asDoubleOr(pick(row, ['Credit', 'credit', 'cr', 'receipt'])),
    );
  }

  final int seq;
  final String particular;
  final DateTime? date;
  final double debit;
  final double credit;

  /// Money in. The cashbook is kept from the society's side, so a credit is a
  /// receipt and a debit is a payment. The procedure fills one side and leaves
  /// the other null, so a row counts as a receipt only when the credit side
  /// actually carries an amount.
  bool get isCredit => credit > 0;

  double get amount => isCredit ? credit : debit;
}

/// Cash in and out over a date range.
class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  late DateTimeRange _range;

  /// True while a PDF is being built. All three actions share it — the
  /// document is the same either way, so a second tap during the first is
  /// work thrown away.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    // Year-to-date, matching the web Cashbook's default range so the same
    // society shows the same rows on both.
    _range = _presetRange(_RangePreset.thisYear);
    Future.microtask(_refresh);
  }

  Future<void> _refresh() => ref
      .read(accountsViewModelProvider.notifier)
      .loadCashbook(from: _iso(_range.start), to: _iso(_range.end));

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTimeRange _presetRange(_RangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case _RangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today,
        );
      case _RangePreset.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        // Day 0 of this month is the last day of the previous one.
        return DateTimeRange(
          start: start,
          end: DateTime(now.year, now.month, 0),
        );
      case _RangePreset.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
    }
  }

  /// Marks a preset as selected only when the range matches it exactly, so a
  /// hand-picked range leaves every chip unselected rather than lying.
  bool _isPreset(_RangePreset preset) {
    final r = _presetRange(preset);
    return _sameDay(r.start, _range.start) && _sameDay(r.end, _range.end);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _applyPreset(_RangePreset preset) async {
    setState(() => _range = _presetRange(preset));
    await _refresh();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangeDialog(
      context: context,
      initial: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref
        .watch(accountsViewModelProvider)
        .rows(AccountsKeys.cashbook);
    final entries = (rows.value?.items ?? const <Map<String, dynamic>>[])
        .map(_Entry.fromRow)
        .toList();

    final opening = entries.where((e) => e.seq == 1).toList();
    final closing = entries.where((e) => e.seq == 3).toList();
    final transactions = entries.where((e) => e.seq == 2).toList();

    // Totalled over the transactions only — folding the opening and closing
    // balances in would count the period twice.
    var credit = 0.0;
    var debit = 0.0;
    for (final e in transactions) {
      credit += e.credit;
      debit += e.debit;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Cashbook'),
        // Download, print and share sit on the title bar, as they do on a
        // bill detail — the same three actions in the same place throughout
        // the app. They go inert while there is nothing to export.
        actions: [
          _AppBarAction(
            icon: Icons.download_rounded,
            tooltip: 'Download',
            color: AppTheme.primary,
            busy: _exporting,
            onTap: entries.isEmpty
                ? null
                : () => _export(
                    _ExportAction.download,
                    opening: opening,
                    closing: closing,
                    transactions: transactions,
                    debit: debit,
                    credit: credit,
                  ),
          ),
          _AppBarAction(
            icon: Icons.print_rounded,
            tooltip: 'Print',
            color: AppTheme.violet,
            busy: _exporting,
            onTap: entries.isEmpty
                ? null
                : () => _export(
                    _ExportAction.print,
                    opening: opening,
                    closing: closing,
                    transactions: transactions,
                    debit: debit,
                    credit: credit,
                  ),
          ),
          _AppBarAction(
            icon: Icons.share_rounded,
            tooltip: 'Share',
            color: AppTheme.teal,
            busy: _exporting,
            onTap: entries.isEmpty
                ? null
                : () => _export(
                    _ExportAction.share,
                    opening: opening,
                    closing: closing,
                    transactions: transactions,
                    debit: debit,
                    credit: credit,
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RowsView(
          rows: rows,
          onRefresh: _refresh,
          emptyIcon: Icons.menu_book_outlined,
          emptyTitle: 'No entries',
          emptyMessage: 'Nothing was recorded in this period.',
          builder: (_) => _buildBody(
            opening: opening,
            closing: closing,
            transactions: transactions,
            credit: credit,
            debit: debit,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<_Entry> opening,
    required List<_Entry> closing,
    required List<_Entry> transactions,
    required double credit,
    required double debit,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space4,
        AppTheme.space8,
      ),
      children: [
        _buildSummary(credit: credit, debit: debit),
        const SizedBox(height: AppTheme.space3),
        _buildRangeBar(),
        const SizedBox(height: AppTheme.space4),
        _CashbookTable(
          // Opening and closing balances frame the period, so they stay at the
          // top and bottom of the grid rather than sorting into the entries.
          opening: opening,
          closing: closing,
          transactions: transactions,
          debit: debit,
          credit: credit,
        ),
      ],
    );
  }

  /// The period at a glance, on one line.
  ///
  /// Kept to a strip rather than a full gradient panel: the table below is
  /// what the page is for, and a hero tall enough to push it off the fold
  /// makes the reader scroll past the summary to reach the thing they came
  /// for. In, Out and Net sit side by side in the height a single figure used
  /// to take.
  Widget _buildSummary({required double credit, required double debit}) {
    final net = credit - debit;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          _SummaryFigure(
            label: 'In',
            value: money(credit),
            icon: Icons.south_west_rounded,
          ),
          _SummaryFigure(
            label: 'Out',
            value: money(debit),
            icon: Icons.north_east_rounded,
          ),
          _SummaryFigure(label: 'Net', value: money(net)),
        ],
      ),
    );
  }

  /// Build the cashbook's PDF and hand it to the OS.
  Future<void> _export(
    _ExportAction action, {
    required List<_Entry> opening,
    required List<_Entry> closing,
    required List<_Entry> transactions,
    required double debit,
    required double credit,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    // The screen's own formatters go with it, so the printed cashbook reads
    // exactly as the page it was printed from — including the blank cell a
    // zero side gets rather than a printed 0.00.
    CashbookLine line(_Entry e) => CashbookLine(
      date: e.date == null ? '' : shortDate(e.date),
      particular: e.particular,
      debit: e.debit == 0 ? '' : money(e.debit),
      credit: e.credit == 0 ? '' : money(e.credit),
    );

    final data = CashbookExportData(
      opening: opening.map(line).toList(),
      closing: closing.map(line).toList(),
      entries: transactions.map(line).toList(),
      debitTotal: money(debit),
      creditTotal: money(credit),
      period: '${prettyDate(_range.start)} — ${prettyDate(_range.end)}',
      fileStamp: '${_iso(_range.start)}-to-${_iso(_range.end)}',
    );

    try {
      switch (action) {
        case _ExportAction.download:
          await CashbookExport.download(context, data);
        case _ExportAction.print:
          await CashbookExport.print(context, data);
        case _ExportAction.share:
          await CashbookExport.share(context, data);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Presets for the ranges asked for most, with the picker for the rest.
  Widget _buildRangeBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final preset in _RangePreset.values) ...[
            _RangeChip(
              label: preset.label,
              selected: _isPreset(preset),
              onTap: () => _applyPreset(preset),
            ),
            const SizedBox(width: AppTheme.space2),
          ],
          _RangeChip(
            label: 'Custom',
            icon: Icons.tune_rounded,
            // A hand-picked range matches no preset, so the custom chip is
            // what stays lit.
            selected: !_RangePreset.values.any(_isPreset),
            onTap: _pickRange,
          ),
        ],
      ),
    );
  }
}

enum _RangePreset {
  thisMonth('This month'),
  lastMonth('Last month'),
  thisYear('This year');

  const _RangePreset(this.label);
  final String label;
}

enum _ExportAction { download, print, share }

/// One figure in the summary strip.
class _SummaryFigure extends StatelessWidget {
  const _SummaryFigure({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: AppTheme.onGradientMuted),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onGradientMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppTheme.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An export action on the title bar, drawn as a tinted plate.
///
/// Each takes its own hue — the same three the bill and receipt exports use —
/// so the actions read apart at a glance instead of as one grey run of
/// glyphs. The plate keeps a fixed footprint, so swapping the glyph for a
/// spinner mid-export does not shift the bar.
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

  /// Null while there is nothing to export, which greys the plate out.
  final VoidCallback? onTap;

  static const double _size = 34;

  @override
  Widget build(BuildContext context) {
    // With nothing to export the plate drops to a flat grey rather than
    // keeping a hue it can no longer act on.
    final enabled = onTap != null && !busy;
    final tint = enabled ? color : AppTheme.deactivatedText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: tint.withValues(alpha: enabled ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Container(
              height: _size,
              width: _size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: tint.withValues(alpha: 0.28)),
              ),
              child: Center(
                child: busy
                    ? SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(tint),
                        ),
                      )
                    : Icon(icon, size: 17, color: tint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pieces ───────────────────────────────────────────────────────────────

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primary : AppTheme.lightText;

    return Material(
      color: selected ? AppTheme.primarySurface : AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space2 + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTheme.body2.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The cashbook grid: Date, Particular, Debit and Credit — the same four
/// columns, in the same order, as the web Cashbook page.
///
/// A phone is too narrow for four columns of readable money, so the grid
/// scrolls sideways under a fixed minimum width rather than letting the
/// columns collapse into each other. The header scrolls with the cells so it
/// cannot drift out of line with them.
class _CashbookTable extends StatefulWidget {
  const _CashbookTable({
    required this.opening,
    required this.closing,
    required this.transactions,
    required this.debit,
    required this.credit,
  });

  final List<_Entry> opening;
  final List<_Entry> closing;
  final List<_Entry> transactions;
  final double debit;
  final double credit;

  /// Widths the four columns are laid out on. Particular takes the slack, so
  /// only the fixed ones are named here.
  static const double _dateWidth = 88;
  static const double _amountWidth = 100;
  static const double _particularWidth = 160;

  static const double _minWidth =
      _dateWidth + _particularWidth + _amountWidth * 2;

  @override
  State<_CashbookTable> createState() => _CashbookTableState();
}

class _CashbookTableState extends State<_CashbookTable> {
  final _controller = ScrollController();

  /// Whether there is anything left to scroll to on the right. Drives the
  /// hint and the fade, both of which must disappear once the user reaches
  /// the end — a cue that never resolves reads as a rendering fault.
  bool _more = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
    // The extent is not known until the first layout has run.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    if (!_controller.hasClients) return;
    // A pixel of slack: the extent rarely lands exactly on the offset.
    final more = _controller.position.maxScrollExtent - _controller.offset > 1;
    if (more != _more && mounted) setState(() => _more = more);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Says outright that the grid slides, rather than leaving the reader
        // to discover it. Only shown while there is somewhere to slide to.
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.topCenter,
          child: _more
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Swipe the table sideways for Debit and Credit',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.swipe_left_rounded,
                        size: 14,
                        color: AppTheme.lightText,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSm,
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On a wide window the table fills it; on a phone it holds its
              // minimum and scrolls sideways instead.
              final width = constraints.maxWidth > _CashbookTable._minWidth
                  ? constraints.maxWidth
                  : _CashbookTable._minWidth;

              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _TableHeader(),
                          for (final e in widget.opening)
                            _TableRow(entry: e, isBalance: true),
                          if (widget.transactions.isEmpty)
                            const _EmptyRow()
                          else
                            for (final e in widget.transactions)
                              _TableRow(entry: e),
                          _TableFooter(
                            debit: widget.debit,
                            credit: widget.credit,
                          ),
                          for (final e in widget.closing)
                            _TableRow(entry: e, isBalance: true),
                        ],
                      ),
                    ),
                  ),

                  // A column cut clean at the edge looks like the table ends
                  // there; fading it shows the content continues.
                  if (_more)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.cardBackground.withValues(alpha: 0),
                                AppTheme.cardBackground,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Shared cell geometry, so the header, body and footer stay in one grid.
class _Cells extends StatelessWidget {
  const _Cells({
    required this.date,
    required this.particular,
    required this.debit,
    required this.credit,
  });

  final Widget date;
  final Widget particular;
  final Widget debit;
  final Widget credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          SizedBox(width: _CashbookTable._dateWidth, child: date),
          // Particular absorbs whatever width is left over.
          Expanded(child: particular),
          SizedBox(
            width: _CashbookTable._amountWidth,
            child: Align(alignment: Alignment.centerRight, child: debit),
          ),
          SizedBox(
            width: _CashbookTable._amountWidth,
            child: Align(alignment: Alignment.centerRight, child: credit),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.overline.copyWith(color: AppTheme.lightText);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.notWhite,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: _Cells(
        date: Text('Date', style: style),
        particular: Text('Particular', style: style),
        debit: Text('Debit', style: style),
        credit: Text('Credit', style: style),
      ),
    );
  }
}

/// One line of the grid. Balance rows are shaded and set in medium, the way
/// the web page marks seq 1 and 3 apart from the entries between them.
class _TableRow extends StatelessWidget {
  const _TableRow({required this.entry, this.isBalance = false});

  final _Entry entry;
  final bool isBalance;

  @override
  Widget build(BuildContext context) {
    final weight = isBalance ? FontWeight.w600 : FontWeight.w400;
    final amount = AppTheme.numeralSm.copyWith(
      fontSize: 13,
      fontWeight: weight,
    );

    return Container(
      decoration: BoxDecoration(
        color: isBalance ? AppTheme.primarySurface : null,
        border: const Border(bottom: BorderSide(color: AppTheme.spacer)),
      ),
      child: _Cells(
        date: Text(
          entry.date == null ? '' : shortDate(entry.date),
          style: AppTheme.caption.copyWith(fontWeight: weight),
        ),
        particular: Text(
          entry.particular,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body2.copyWith(fontWeight: weight),
        ),
        // A zero side stays blank rather than printing 0.00 — the web grid
        // leaves it empty, and a column of zeroes is harder to scan.
        debit: Text(
          entry.debit == 0 ? '' : money(entry.debit),
          style: amount.copyWith(color: AppTheme.error),
        ),
        credit: Text(
          entry.credit == 0 ? '' : money(entry.credit),
          style: amount.copyWith(color: AppTheme.success),
        ),
      ),
    );
  }
}

/// The totals row that closes the web page's grid. Debit and credit are kept
/// apart rather than netted, because reconciling against a bank statement
/// needs both sides.
class _TableFooter extends StatelessWidget {
  const _TableFooter({required this.debit, required this.credit});

  final double debit;
  final double credit;

  @override
  Widget build(BuildContext context) {
    final amount = AppTheme.numeralSm.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.chipBackground,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      child: _Cells(
        date: const SizedBox.shrink(),
        particular: Text(
          'Total',
          style: AppTheme.body2.copyWith(fontWeight: FontWeight.w700),
        ),
        debit: Text(
          money(debit),
          style: amount.copyWith(color: AppTheme.error),
        ),
        credit: Text(
          money(credit),
          style: amount.copyWith(color: AppTheme.success),
        ),
      ),
    );
  }
}

/// Shown when the period has balances but nothing moved between them.
class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.spacer)),
      ),
      child: Text('No cash moved in this period', style: AppTheme.caption),
    );
  }
}
