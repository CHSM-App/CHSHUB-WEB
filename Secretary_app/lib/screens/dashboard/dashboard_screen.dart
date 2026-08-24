import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/dashboard.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/billing_viewmodel.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/charts.dart';
import '../../widgets/secretary_app_bar.dart';
import '../../widgets/stat_card.dart';
import '../billing/defaulters_screen.dart';
import '../billing/generate_bills_screen.dart';
import '../billing/receipt_entry_screen.dart';
import '../billing/receipts_screen.dart';
import '../community/helpdesk_screen.dart';
import '../community/notices_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Never call ref.read(...).method() synchronously in initState — the
    // provider may still be building.
    Future.microtask(() {
      ref.read(dashboardViewModelProvider.notifier).load();
      ref.read(authViewModelProvider.notifier).loadMe();
      ref.read(communityViewModelProvider.notifier).loadNotifications();
      // Backs the defaulters preview further down the page.
      ref.read(billingViewModelProvider.notifier).loadDefaulters();
    });
  }

  Future<void> _refresh() async {
    await ref.read(dashboardViewModelProvider.notifier).load();
    await ref.read(communityViewModelProvider.notifier).loadNotifications();
    await ref.read(billingViewModelProvider.notifier).loadDefaulters();
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final summary = state.summary.value;

    final unread = ref
        .watch(communityViewModelProvider)
        .items(CommunityKeys.notifications)
        .length;

    return Scaffold(
      appBar: SecretaryAppBar(
        // "Hello, Pallavi (Secretary)". The role comes from the token's
        // user_type — falling back to "Secretary" only when the API did not
        // send one, which is also the app's own name.
        greeting:
            'Hello, ${user?.name ?? 'there'} '
            '(${user?.userType ?? 'Secretary'})',
        avatarName: user?.name,
        subtitle: user?.societyName ?? 'Society',
        notificationCount: unread,
        onNotifications: () => _open(const HelpdeskScreen()),
        onAvatar: () => _open(const SettingsScreen()),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        child: _buildBody(state.summary, summary),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<DashboardSummary> async,
    DashboardSummary? summary,
  ) {
    if (async.isLoading && summary == null) return const _DashboardSkeleton();

    if (async.hasError && summary == null) {
      return StateMessage(
        icon: Icons.cloud_off_rounded,
        iconColor: AppTheme.error,
        title: 'Could not load the dashboard',
        message: errorText(async.error!),
        actionLabel: 'Try again',
        onAction: _refresh,
      );
    }

    final data = summary ?? const DashboardSummary();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        PageConstraints(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.space4),
              _buildHero(data),
              const SizedBox(height: AppTheme.space4),
              _buildQuickActions(),
              const SizedBox(height: AppTheme.space5),
              _buildStats(data),
              const SizedBox(height: AppTheme.space6),
              _buildCharts(data),
              const SizedBox(height: AppTheme.space6),
              _buildDefaulters(),
              const SizedBox(height: AppTheme.space6),
              _buildActivity(data),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────

  Widget _buildHero(DashboardSummary data) {
    final collected = _figureFor(data, 'collection');
    final due = _figureFor(data, 'due');
    final billed = collected + due;

    // The share already collected. Guarded because a society with no bills
    // raised yet would divide by zero.
    final progress = billed > 0 ? (collected / billed).clamp(0.0, 1.0) : 0.0;
    final owed = data.defaulters.totalDue > 0;

    // A white card rather than a coloured one. The two figures inside carry
    // the colour instead — green for money in, red for money owed — which is
    // the distinction worth seeing first; a coloured ground behind them just
    // competed with it.
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Flexible, not a bare Text + Spacer: on a narrow phone the
              // label and the chip together are wider than the card.
              Flexible(
                child: Text(
                  owed ? 'TOTAL OUTSTANDING' : 'ALL COLLECTED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Darker than the default overline grey: this label names
                  // the headline figure directly under it, so it carries more
                  // weight than an ordinary section caption.
                  style: AppTheme.overline.copyWith(
                    fontSize: 11,
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (data.defaulters.count > 0) ...[
                const SizedBox(width: AppTheme.space2),
                StatusChip(
                  label: '${data.defaulters.count} defaulters',
                  color: AppTheme.error,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUpText(
              value: data.defaulters.totalDue,
              formatter: moneyFlat,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                height: 1.1,
                color: AppTheme.darkerText,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text(
            owed
                ? 'still to be collected from residents'
                : 'every flat is up to date',
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.space4),
          _buildProgress(progress),
          const SizedBox(height: AppTheme.space4),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Collected',
                  value: compactMoney(collected),
                  icon: Icons.trending_up_rounded,
                  gradient: AppTheme.collectedGradient,
                  onTap: () => _open(const ReceiptsScreen()),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: StatCard(
                  label: 'Due',
                  value: compactMoney(due),
                  icon: Icons.schedule_rounded,
                  gradient: AppTheme.duesGradient,
                  onTap: () => _open(const DefaultersScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A slim bar showing how much of what was billed has come in.
  Widget _buildProgress(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Expanded so the percentage stays pinned to the right edge while
            // the label absorbs whatever width is left.
            Expanded(
              child: Text(
                'Collection progress',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption.copyWith(fontSize: 11.5),
              ),
            ),
            const SizedBox(width: AppTheme.space2),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 7,
              // The track is what has *not* been collected, so it takes the
              // same red as the Due card below.
              backgroundColor: AppTheme.errorSurface,
              valueColor: const AlwaysStoppedAnimation(AppTheme.success),
            ),
          ),
        ),
      ],
    );
  }

  /// Pulls a named slice out of the income split, which sp_dashboard returns
  /// as `{category, amount}` rows rather than named fields.
  double _figureFor(DashboardSummary data, String category) {
    for (final row in data.incomeSplit) {
      final label = pick(row, ['category', 'name', 'label'])?.toLowerCase();
      if (label != null && label.contains(category)) {
        return (row['amount'] as num?)?.toDouble() ??
            double.tryParse('${row['amount']}') ??
            0;
      }
    }
    return 0;
  }

  // ── Quick actions ────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          QuickAction(
            icon: Icons.playlist_add_check_circle_outlined,
            label: 'Generate\nbills',
            color: AppTheme.primary,
            onTap: () => _open(const GenerateBillsScreen()),
          ),
          QuickAction(
            icon: Icons.point_of_sale_outlined,
            label: 'Record\npayment',
            color: AppTheme.success,
            onTap: () => _open(const ReceiptEntryScreen()),
          ),
          QuickAction(
            icon: Icons.campaign_outlined,
            label: 'Post\nnotice',
            color: AppTheme.violet,
            onTap: () => _open(const NoticesScreen()),
          ),
          QuickAction(
            icon: Icons.support_agent_outlined,
            label: 'Open\ncomplaints',
            color: AppTheme.warning,
            onTap: () => _open(const HelpdeskScreen()),
          ),
        ],
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────

  Widget _buildStats(DashboardSummary data) {
    final open = _openTickets(data.tickets);

    return ResponsiveGrid(
      minTileWidth: 168,
      aspectRatio: 1.28,
      children: [
        StatTile(
          label: 'Residents',
          value: '${data.residentCount}',
          icon: Icons.people_alt_outlined,
          color: AppTheme.info,
        ),
        StatTile(
          label: 'Defaulters',
          value: '${data.defaulters.count}',
          icon: Icons.report_gmailerrorred_outlined,
          color: AppTheme.error,
          trend: data.defaulters.count > 0 ? 'Needs chasing' : 'All clear',
          onTap: () => _open(const DefaultersScreen()),
        ),
        StatTile(
          label: 'Open complaints',
          value: '$open',
          icon: Icons.support_agent_outlined,
          color: AppTheme.warning,
          trend: '${data.tickets.closed} resolved',
          onTap: () => _open(const HelpdeskScreen()),
        ),
        StatTile(
          label: 'Collected',
          value: compactMoney(_figureFor(data, 'collection')),
          icon: Icons.savings_outlined,
          color: AppTheme.success,
          onTap: () => _open(const ReceiptsScreen()),
        ),
      ],
    );
  }

  /// sp_dashboard 'Get_Ticket' is not consistent about which counts it
  /// returns, so prefer the explicit open count and fall back to
  /// total-minus-closed only when open is absent.
  int _openTickets(TicketCounts t) {
    if (t.open > 0) return t.open;
    if (t.pending > 0) return t.pending;
    final derived = t.total - t.closed;
    return derived > 0 ? derived : 0;
  }

  // ── Charts ───────────────────────────────────────────────────────────

  Widget _buildCharts(DashboardSummary data) {
    final income = chartData(
      data.incomeSplit,
      labelKeys: const ['category', 'name', 'label'],
      valueKeys: const ['amount', 'total', 'value'],
    );

    final monthly = chartData(
      data.monthlyDues,
      labelKeys: const ['month_name', 'month', 'name'],
      valueKeys: const ['amount', 'total_amount', 'due'],
      limit: 8,
    );

    // Only the trend line for the monthly figures. A bar chart of the same
    // series sat beside it, which said nothing the line did not — and two
    // charts of one dataset read as a mistake.
    return ResponsiveRow(
      flex: const [3, 2],
      children: [
        ChartCard(
          title: 'Billing trend',
          subtitle: 'Raised per period',
          child: TrendChart(data: monthly),
        ),
        ChartCard(
          title: 'Income tracker',
          subtitle: 'Collected against what is still due',
          child: DonutChart(data: income, centerLabel: 'BILLED'),
        ),
      ],
    );
  }

  // ── Defaulters preview ───────────────────────────────────────────────

  Widget _buildDefaulters() {
    final rows = ref
        .watch(billingViewModelProvider)
        .items(BillingKeys.defaulters);

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Needs chasing',
          subtitle: 'The largest outstanding balances',
          actionLabel: 'See all',
          onAction: () => _open(const DefaultersScreen()),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.take(4).length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 68),
                _defaulterRow(rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _defaulterRow(Map<String, dynamic> row) {
    final owner = pick(row, ['owner_name', 'name', 'resident_name']);
    final flat = pick(row, ['Unit', 'flat_no', 'unit_no', 'flat']);
    final contact = pick(row, ['pre_mob', 'contact_no', 'mobile_no', 'phone']);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          InitialsAvatar(name: owner, size: 36),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner ?? 'Resident',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
                ),
                if (flat != null)
                  Text(
                    flat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Text(
            money(row['due'] ?? row['due_amount'] ?? row['total_due']),
            style: AppTheme.numeralSm.copyWith(
              fontSize: 14,
              color: AppTheme.error,
            ),
          ),
          if (contact != null) ...[
            const SizedBox(width: AppTheme.space1),
            IconButton(
              icon: const Icon(Icons.phone_outlined, size: 18),
              color: AppTheme.success,
              visualDensity: VisualDensity.compact,
              tooltip: 'Call $owner',
              onPressed: () => _call(contact),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _call(String number) async {
    // Strip spaces and dashes — tel: does not accept them, and these numbers
    // come out of free-text columns.
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);

    if (!await launchUrl(uri)) {
      if (!mounted) return;
      showAppSnack(context, 'Could not start a call.', success: false);
    }
  }

  // ── Activity ─────────────────────────────────────────────────────────

  Widget _buildActivity(DashboardSummary data) {
    final rows = data.recentActivity;

    // An empty feed is a real answer — the society simply had no receipts or
    // bill runs in the window — so say so rather than dropping the section,
    // which read as the card having failed to load.
    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SectionHeader(
            title: 'Recent activity',
            subtitle: 'Latest movements across the society',
          ),
          AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.space4),
              child: Text(
                'Nothing recorded in the last 15 days.',
                textAlign: TextAlign.center,
                style: AppTheme.caption,
              ),
            ),
          ),
        ],
      );
    }

    final shown = rows.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Recent activity',
          subtitle: 'Latest movements across the society',
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _activityRow(shown[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// One row of `recent_activity_vw` — the union of receipts and generated
  /// maintenance bills, ordered newest first by sp_dashboard 'RecentActivity'.
  ///
  /// Its columns are `particular`, `date`, `timestamp` (a relative label the
  /// view builds with GetRelativeTime), `paid_amount` and `type`. The key list
  /// here previously asked for `activity`/`description`/`details`, none of
  /// which that view returns, so every row rendered the literal word
  /// "Activity" against a dash for the date.
  Widget _activityRow(Map<String, dynamic> row) {
    final title = pick(row, [
      'particular',
      'activity',
      'description',
      'details',
      'title',
    ]);

    final when = row['date'] ?? row['m_date'] ?? row['created_at'];
    final amount = asDoubleOr(row['paid_amount'] ?? row['amount']);

    // A receipt brings money in; a bill run does not. dashboard.aspx keyed its
    // tick/tools icon off exactly this test, so the two stay in step.
    final isPayment = amount != 0;
    final tone = isPayment ? AppTheme.success : AppTheme.info;

    // The view already computed a relative label server-side. Prefer it, and
    // fall back to formatting the raw date only when that column is empty.
    final ago = pick(row, ['timestamp']) ?? relativeDate(when);
    final exact = asDate(when);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: AppTheme.surfaceFor(tone),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPayment ? Icons.check_rounded : Icons.receipt_long_outlined,
              size: 15,
              color: tone,
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? 'Activity',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body2,
                ),
                const SizedBox(height: 2),
                Text(
                  // "2 days ago · 14 Aug" — the relative half answers "is this
                  // recent?", the date answers "when exactly?" without having
                  // to open anything.
                  exact == null ? ago : '$ago · ${_activityDate.format(exact)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          if (isPayment)
            Text(
              money(amount),
              style: AppTheme.numeralSm.copyWith(fontSize: 14, color: tone),
            ),
        ],
      ),
    );
  }
}

final _activityDate = DateFormat('d MMM');

/// Placeholder matching the real layout, so the page does not jump when the
/// figures arrive.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        PageConstraints(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SizedBox(height: AppTheme.space4),
              Skeleton(height: 250, radius: AppTheme.radiusLg),
              SizedBox(height: AppTheme.space4),
              Skeleton(height: 96, radius: AppTheme.radiusMd),
              SizedBox(height: AppTheme.space5),
              Row(
                children: [
                  Expanded(
                    child: Skeleton(height: 118, radius: AppTheme.radiusMd),
                  ),
                  SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: Skeleton(height: 118, radius: AppTheme.radiusMd),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.space3),
              Row(
                children: [
                  Expanded(
                    child: Skeleton(height: 118, radius: AppTheme.radiusMd),
                  ),
                  SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: Skeleton(height: 118, radius: AppTheme.radiusMd),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.space6),
              Skeleton(height: 250, radius: AppTheme.radiusMd),
            ],
          ),
        ),
      ],
    );
  }
}
