import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/bill_preview.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/stat_card.dart';

/// Raise a bill run.
///
/// Follows GenerateBillsPage.jsx on the website: the same three headline
/// figures (flats, regular total, add-on total), the same table of charge
/// heads with a per-flat column, the same warnings panel, and the run button
/// last.
///
/// Generation writes charges against every flat and no stored procedure here
/// reverses it, so the preview is not optional — the screen loads it first and
/// the server refuses a request without `confirm: true`.
class GenerateBillsScreen extends ConsumerStatefulWidget {
  const GenerateBillsScreen({super.key});

  @override
  ConsumerState<GenerateBillsScreen> createState() =>
      _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends ConsumerState<GenerateBillsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() =>
      ref.read(billingViewModelProvider.notifier).loadPreview();

  /// The regular run. Add-on charges go through [_openAddOnForm] instead,
  /// because they carry their own bill period.
  Future<void> _confirmAndRunRegular() async {
    final vm = ref.read(billingViewModelProvider.notifier);
    final preview = vm.lastPreview;

    final total = preview?.regular.totalAmount ?? 0;
    final flats = preview?.flatCount ?? 0;

    final confirmed = await confirmAction(
      context,
      title: 'Generate bills?',
      message:
          'This inserts $flats ${flats == 1 ? 'bill' : 'bills'} totalling '
          '${money(total)}. It cannot be undone from this app.',
      confirmLabel: 'Generate',
      destructive: true,
    );

    if (!confirmed) return;

    final ok = await vm.generateRegular();
    if (!mounted) return;

    // The server reports "nothing was generated" as a *success* with an
    // explanation — a run already exists this month, or no eligible flats —
    // so the message comes from the payload rather than being assumed.
    showAppSnack(
      context,
      ok
          ? vm.generationMessage
          : (ref.read(billingViewModelProvider).error ??
                'Could not generate bills.'),
      success: ok,
    );

    if (ok) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingViewModelProvider);
    final preview = ref.read(billingViewModelProvider.notifier).lastPreview;

    return Scaffold(
      appBar: AppBar(title: const Text('Generate bills')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.primary,
          child: preview == null
              ? _buildPlaceholder(state.isLoading)
              : _buildPreview(preview, state.isLoading),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isLoading) {
    if (isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Breakpoints.pagePadding(context),
        children: const [
          SizedBox(height: AppTheme.space4),
          Skeleton(height: 110, radius: AppTheme.radiusMd),
          SizedBox(height: AppTheme.space4),
          Skeleton(height: 220, radius: AppTheme.radiusMd),
        ],
      );
    }

    return StateMessage(
      icon: Icons.cloud_off_rounded,
      iconColor: AppTheme.error,
      title: 'Could not load the preview',
      message:
          ref.read(billingViewModelProvider).error ?? 'Pull down to try again.',
      actionLabel: 'Try again',
      onAction: _refresh,
    );
  }

  Widget _buildPreview(BillPreview preview, bool isLoading) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        PageConstraints(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.space4),
              Text(
                'Preview of what the next bill run would charge. Nothing is '
                'written until you run it.',
                style: AppTheme.body2.copyWith(color: AppTheme.lightText),
              ),
              const SizedBox(height: AppTheme.space5),
              if (preview.warnings.isNotEmpty) ...[
                _buildWarnings(preview.warnings),
                const SizedBox(height: AppTheme.space5),
              ],
              _buildTotals(preview),
              const SizedBox(height: AppTheme.space6),
              if (preview.regular.charges.isNotEmpty) ...[
                _buildChargeTable(
                  title: 'Regular charge heads',
                  subtitle: 'Raised every month by the bill run',
                  group: preview.regular,
                  accent: AppTheme.primary,
                ),
                const SizedBox(height: AppTheme.space5),
              ],
              if (preview.addOn.charges.isNotEmpty) ...[
                _buildChargeTable(
                  title: 'Add-on charge heads',
                  subtitle: 'One-off charges, billed separately',
                  group: preview.addOn,
                  accent: AppTheme.warning,
                ),
                const SizedBox(height: AppTheme.space5),
              ],
              if (!preview.hasAnythingToBill) ...[
                const AppCard(
                  child: Text(
                    'No charge heads are configured, so a run would raise '
                    'nothing.',
                    style: AppTheme.caption,
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
              ],
              _buildSettings(preview.settings),
              const SizedBox(height: AppTheme.space6),
              _buildRunPanel(preview, isLoading),
            ],
          ),
        ),
      ],
    );
  }

  // ── Warnings ─────────────────────────────────────────────────────────

  Widget _buildWarnings(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.warningSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppTheme.warning,
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before generating',
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkerText,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                // Shown verbatim: the server words these, and they explain
                // exactly why a run might do nothing.
                for (final warning in warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: AppTheme.caption),
                        Expanded(child: Text(warning, style: AppTheme.caption)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Totals ───────────────────────────────────────────────────────────

  Widget _buildTotals(BillPreview preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppTheme.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'THIS RUN WOULD RAISE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.overline.copyWith(
                        fontSize: 11,
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  StatusChip(
                    label: '${preview.flatCount} flats',
                    color: AppTheme.info,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CountUpText(
                  value: preview.grandTotal,
                  formatter: moneyFlat,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    height: 1.1,
                    color: AppTheme.darkerText,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space1),
              Text(
                '${money(preview.perFlatTotal)} per flat',
                style: AppTheme.caption,
              ),
              const SizedBox(height: AppTheme.space4),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Regular',
                      value: compactMoney(preview.regular.totalAmount),
                      icon: Icons.autorenew_rounded,
                      gradient: AppTheme.primaryGradient,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: StatCard(
                      label: 'Add-on',
                      value: compactMoney(preview.addOn.totalAmount),
                      icon: Icons.add_card_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB45309), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Charge heads ─────────────────────────────────────────────────────

  /// The website's table, as a card list.
  ///
  /// Rows rather than a real table: three columns of figures do not fit a
  /// phone, and the website's own table collapses to stacked rows at the same
  /// width via `stacked-table`.
  Widget _buildChargeTable({
    required String title,
    required String subtitle,
    required ChargeGroup group,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        AppCard(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _buildTableHeader(),
              for (final charge in group.charges) ...[
                const Divider(height: 1),
                _buildChargeRow(charge, accent),
              ],
              const Divider(height: 1),
              _buildTableTotal(group),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      color: AppTheme.background,
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('CHARGE', style: AppTheme.overline)),
          Expanded(
            flex: 3,
            child: Text(
              'TOTAL',
              textAlign: TextAlign.right,
              style: AppTheme.overline,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'PER FLAT',
              textAlign: TextAlign.right,
              style: AppTheme.overline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeRow(ChargeHead charge, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppTheme.space2),
                Expanded(
                  child: Text(
                    charge.name ?? 'Charge',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body2.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkerText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              money(charge.amount),
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTheme.numeralSm.copyWith(fontSize: 13.5),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              money(charge.perFlat),
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTheme.caption.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableTotal(ChargeGroup group) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      color: AppTheme.background,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Total',
              style: AppTheme.body2.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              money(group.totalAmount),
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTheme.numeralSm.copyWith(
                fontSize: 13.5,
                color: AppTheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              money(group.perFlatTotal),
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTheme.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings ─────────────────────────────────────────────────────────

  Widget _buildSettings(BillSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Billing settings',
          subtitle: 'What the run will apply',
        ),
        AppCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _settingRow('Rate per sq ft', money(settings.ratePerSqFt)),
              _settingRow(
                'Two-wheeler parking',
                money(settings.twoWheelerRate),
              ),
              _settingRow(
                'Four-wheeler parking',
                money(settings.fourWheelerRate),
              ),
              _settingRow('Interest on arrears', '${settings.interestRate}%'),
              _settingRow('Due period', '${settings.billDuePeriodDays} days'),
              _settingRow(
                'Automatic billing',
                settings.autoBillGeneration
                    ? 'On · day ${settings.billGenerationDay}'
                    : 'Off · manual only',
                accent: settings.autoBillGeneration
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingRow(String label, String value, {Color? accent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.caption)),
          const SizedBox(width: AppTheme.space3),
          Text(
            value,
            style: AppTheme.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: accent ?? AppTheme.darkerText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Run ──────────────────────────────────────────────────────────────

  /// Explains where this society's bills normally come from.
  ///
  /// Auto on: the nightly cron raises them on `billGenerationDay`, so a manual
  /// run is only bringing that forward. Auto off: nothing raises them at all
  /// unless someone presses the button, which is worth saying plainly.
  Widget _buildAutoNote(bool auto, int day) {
    final color = auto ? AppTheme.success : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(color),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            auto ? Icons.schedule_rounded : Icons.pan_tool_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Text(
              auto
                  ? 'Automatic billing is on — these bills would be raised on '
                        'day $day of the month anyway. Running now just brings '
                        'that forward.'
                  : 'Automatic billing is off for this society, so bills are '
                        'only raised when someone runs them here.',
              style: AppTheme.caption.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Stands in for a button that would do nothing.
  ///
  /// Shown rather than a disabled button: a greyed-out control reads as
  /// "temporarily unavailable", when what is true is that the work is already
  /// done for this period.
  Widget _buildDoneNote(String message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.successSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm + 2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 19,
            color: AppTheme.success,
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              message,
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkerText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunPanel(BillPreview preview, bool isLoading) {
    final blocked = preview.alreadyGeneratedThisMonth;
    final auto = preview.settings.autoBillGeneration;
    final hasAddOn = preview.addOn.charges.isNotEmpty;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Run generation', style: AppTheme.title.copyWith(fontSize: 16)),
          const SizedBox(height: AppTheme.space2),
          Text(
            auto
                ? 'This society bills itself, so regular bills are raised for '
                      'you. Add-on charges are never automatic and still need '
                      'to be run here.'
                : blocked
                ? 'A run already exists for this month, so regular billing '
                      'will be skipped. Add-on charges can still be raised.'
                : 'This inserts ${preview.flatCount} '
                      '${preview.flatCount == 1 ? 'bill' : 'bills'} '
                      'totalling ${money(preview.regular.totalAmount)}. It '
                      'cannot be undone from this app.',
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.space3),
          _buildAutoNote(auto, preview.settings.billGenerationDay),
          const SizedBox(height: AppTheme.space4),

          // The regular run is offered only when it would actually do
          // something. Two things take it away:
          //
          //  * auto on — the nightly gen_bill raises these anyway, so a second
          //    trigger invites raising bills that were already coming;
          //  * already run this month — gen_bill skips a society that has a
          //    run for the current month, so the button would be a no-op that
          //    still reads as "something happened".
          //
          // The add-on button survives both: sp_new_maintenance is a separate
          // procedure the automatic run never calls, and its charges are not
          // covered by the monthly guard. Hiding it would strand them.
          if (!auto) ...[
            if (blocked)
              _buildDoneNote(
                'This month’s regular bills have already been generated.',
              )
            else
              BusyButton(
                label: 'Generate regular bills',
                busy: isLoading,
                icon: Icons.playlist_add_check_rounded,
                onPressed: _confirmAndRunRegular,
              ),
          ],

          if (hasAddOn) ...[
            if (!auto) const SizedBox(height: AppTheme.space3),
            // Primary whenever it is the only thing left to run.
            if (auto || blocked)
              BusyButton(
                label:
                    'Raise add-on charges '
                    '(${money(preview.addOn.totalAmount)})',
                busy: isLoading,
                icon: Icons.add_card_outlined,
                onPressed: _openAddOnForm,
              )
            else
              OutlinedButton.icon(
                onPressed: isLoading ? null : _openAddOnForm,
                icon: const Icon(Icons.add_card_outlined, size: 19),
                label: Text(
                  'Raise add-on charges '
                  '(${money(preview.addOn.totalAmount)})',
                ),
              ),
          ],

          if ((auto || blocked) && !hasAddOn)
            Text(
              'Nothing to run by hand right now.',
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
        ],
      ),
    );
  }

  /// The add-on form, as BillsPage.jsx presents it.
  ///
  /// Add-on charges carry their own bill period rather than the society's
  /// default, which is why this asks instead of running straight away — the
  /// legacy form did the same, and showed the resulting due date as the number
  /// was typed.
  Future<void> _openAddOnForm() async {
    final preview = ref.read(billingViewModelProvider.notifier).lastPreview;
    if (preview == null) return;

    final months = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddOnSheet(preview: preview),
    );

    if (months == null || !mounted) return;
    await _runAddOn(months: months);
  }

  /// Runs the add-on generation, handling the duplicate case.
  ///
  /// sp_new_maintenance has no duplicate guard of its own — every call raises
  /// another set of charges — so the API refuses a second run on a day that
  /// already has one and answers 409. That is worth asking about rather than
  /// swallowing: two genuinely separate add-ons in a day is a real case.
  Future<void> _runAddOn({
    required int months,
    bool allowDuplicate = false,
  }) async {
    final vm = ref.read(billingViewModelProvider.notifier);

    if (!allowDuplicate) {
      final preview = vm.lastPreview;
      final confirmed = await confirmAction(
        context,
        title: 'Raise add-on charges?',
        message:
            'This charges ${money(preview?.addOn.totalAmount ?? 0)} '
            'across ${preview?.flatCount ?? 0} flats, due in '
            '$months ${months == 1 ? 'month' : 'months'}. It cannot be undone '
            'from this app.',
        confirmLabel: 'Raise charges',
        destructive: true,
      );
      if (!confirmed) return;
    }

    final ok = await vm.generateAddon(
      duePeriodMonths: months,
      allowDuplicate: allowDuplicate,
    );

    if (!mounted) return;

    // A 409 is not a failure here — it opens the duplicate question.
    if (!ok && !allowDuplicate && vm.lastAddOnWasDuplicate) {
      final again = await confirmAction(
        context,
        title: 'Already raised today',
        message:
            'An add-on run has already gone out today. Raising another '
            'charges every flat a second time. Continue only if this is a '
            'genuinely separate add-on.',
        confirmLabel: 'Raise anyway',
        destructive: true,
      );
      if (again && mounted) {
        await _runAddOn(months: months, allowDuplicate: true);
      }
      return;
    }

    showAppSnack(
      context,
      ok
          ? vm.generationMessage
          : (ref.read(billingViewModelProvider).error ??
                'Could not raise add-on charges.'),
      success: ok,
    );

    if (ok) await _refresh();
  }
}

/// The add-on run's own form.
///
/// Add-on charges do not use the society's default bill period — the legacy
/// page asked for it each time, and worked the due date out as the number was
/// typed so the effect is visible before the run happens. Returns the number
/// of months, or null if the secretary backed out.
class _AddOnSheet extends StatefulWidget {
  const _AddOnSheet({required this.preview});

  final BillPreview preview;

  @override
  State<_AddOnSheet> createState() => _AddOnSheetState();
}

class _AddOnSheetState extends State<_AddOnSheet> {
  final _controller = TextEditingController(text: '1');
  final _today = DateTime.now();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _months {
    final value = int.tryParse(_controller.text.trim());
    return (value != null && value >= 1) ? value : null;
  }

  /// Today plus the bill period, month-end clamped — 31 Jan plus one month is
  /// 28 Feb, not 3 March. Same arithmetic as the website's addOnDueDate.
  String get _dueDate {
    final months = _months;
    if (months == null) return 'Enter a period in months.';

    final target = DateTime(_today.year, _today.month + months, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final due = DateTime(
      target.year,
      target.month,
      _today.day < lastDay ? _today.day : lastDay,
    );
    return 'Due date: ${prettyDate(due)}';
  }

  @override
  Widget build(BuildContext context) {
    final addOn = widget.preview.addOn;

    return AppBottomSheet(
      title: 'Raise add-on charges',
      subtitle: 'One-off charges, on top of the monthly bill.',
      initialSize: 0.75,
      children: [
        Row(
          children: [
            Expanded(
              child: _readOnlyField(
                label: 'Date',
                value: prettyDate(_today),
                hint: 'The day this run is raised.',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          // Rebuilds so the due date below tracks what is typed.
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Bill period (months)',
            hintText: 'Enter in months',
            helperText: _dueDate,
            prefixIcon: const Icon(Icons.event_outlined, size: 20),
          ),
        ),
        const SizedBox(height: AppTheme.space5),
        Text('Nature of charges', style: AppTheme.title.copyWith(fontSize: 15)),
        const SizedBox(height: AppTheme.space2),
        AppCard(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < addOn.charges.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _chargeRow(addOn.charges[i]),
              ],
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space4,
                  vertical: AppTheme.space3,
                ),
                color: AppTheme.background,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total',
                        style: AppTheme.body2.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      money(addOn.totalAmount),
                      style: AppTheme.numeralSm.copyWith(
                        fontSize: 13.5,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        ElevatedButton.icon(
          // Disabled until the period is valid: the server defaults a missing
          // value to 1, which would silently bill a different due date than
          // the one shown above.
          onPressed: _months == null
              ? null
              : () => Navigator.pop(context, _months),
          icon: const Icon(Icons.add_card_outlined, size: 19),
          label: const Text('Raise charges'),
        ),
        const SizedBox(height: AppTheme.space3),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required String hint,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        filled: true,
        fillColor: AppTheme.background,
      ),
      child: Text(value, style: AppTheme.body2),
    );
  }

  Widget _chargeRow(ChargeHead charge) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              charge.name ?? 'Charge',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body2,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              money(charge.amount),
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTheme.numeralSm.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${money(charge.perFlat)} / flat',
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTheme.caption.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
