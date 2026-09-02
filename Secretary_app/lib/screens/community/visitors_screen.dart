import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/visitor_request.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';
import '../../widgets/time_dialog.dart';

/// Which slice of the gate log is showing.
///
/// Left has its own tab rather than living only under All: checking someone
/// out moved them straight off the Inside tab the screen opens on, so the
/// entry looked like it had been deleted rather than closed, and the exit
/// stamp that had just been written was nowhere to be seen.
enum _VisitorTab {
  inside('Inside', Icons.meeting_room_rounded),
  expected('Expected', Icons.schedule_rounded),
  left('Left', Icons.logout_rounded),
  all('All', Icons.list_alt_rounded);

  const _VisitorTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Which slice of time the gate log is narrowed to.
///
/// A society's log runs to hundreds of entries within a couple of months, and
/// what is asked of it is nearly always dated — who came today, who came over
/// the weekend, who came the week the flat was burgled. The presets carry the
/// common ones without opening a calendar; [custom] is there for the rest.
enum _DateFilter {
  all('All time', Icons.all_inclusive_rounded),
  today('Today', Icons.today_rounded),
  week('7 days', Icons.date_range_rounded),
  month('30 days', Icons.calendar_month_rounded),
  custom('Custom', Icons.edit_calendar_rounded);

  const _DateFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The filter menu's "Between dates…" entry, which opens the calendar rather
/// than selecting a preset. A sentinel, as noc_certificate_screen uses, so the
/// menu can stay keyed by [_DateFilter] for everything else.
const _dateFilterKey = 'pick-dates';

/// Gate entries.
class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key});

  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  /*
   * Inside first, not All: the question the gate log is opened to answer is
   * who is in the society right now, and a list led by last month's entries
   * buries it.
   */
  _VisitorTab _tab = _VisitorTab.inside;

  /*
   * The date window narrows the log before the tabs slice it, so every count
   * on screen — the summary line, each tab — describes the same filtered set.
   * Filtering after the tabs would have let a tab read "12" over a list of
   * three.
   */
  _DateFilter _dateFilter = _DateFilter.all;

  /// The span [_DateFilter.custom] resolves to. Null until a range is picked.
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref
      .read(communityViewModelProvider.notifier)
      .loadVisitors(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _refresh);
  }

  /*
   * Arrival is judged on in_date alone, never in_time.
   *
   * sp_Visitor's insert writes `in_time` as getdate() for every visitor —
   * including one registered days ahead of their visit — so in_time says when
   * the row was created, not when anyone walked in. Counting it as an arrival
   * stamp put all 65 of a society's visitors under "Inside" or "Left" and left
   * "Expected" permanently empty. Only in_date is left NULL until they come.
   */

  /// Still inside — arrived, with no exit against them yet.
  static bool _hasArrived(Map<String, dynamic> row) =>
      pick(row, ['in_date']) != null;

  static bool _isInside(Map<String, dynamic> row) =>
      _hasArrived(row) && !_hasLeft(row);

  /*
   * Still expected only if they have not also been stamped out.
   *
   * Three rows in a real society have an exit but no in_date: checked out
   * through a path that writes out_date without ever setting in_date. Being
   * stamped out is proof enough that they came, so Left wins — otherwise the
   * same visitor is counted under both tabs and the totals overshoot the list.
   */
  static bool _isExpected(Map<String, dynamic> row) =>
      !_hasArrived(row) && !_hasLeft(row);

  /// Been and gone — stamped out.
  static bool _hasLeft(Map<String, dynamic> row) =>
      pick(row, ['out_time', 'out_date']) != null;

  // ── Filtering ──────────────────────────────────────────────────────────

  /// The window [_dateFilter] currently stands for, or null for all time.
  ///
  /// Both ends are whole days: a range picked as 25–26 Aug has to include an
  /// entry stamped 26 Aug 6pm, which an end of midnight would drop.
  DateTimeRange? get _activeRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (_dateFilter) {
      _DateFilter.all => null,
      _DateFilter.today => DateTimeRange(start: today, end: today),
      _DateFilter.week => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _DateFilter.month => DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      _DateFilter.custom => _customRange,
    };
  }

  /// The day an entry belongs to.
  ///
  /// in_date when they came, pre_date while they are still expected: an entry
  /// booked for next Tuesday is dated by the visit it is for, so narrowing to
  /// "Today" answers who is due today as well as who arrived. Falling back to
  /// out_date covers the rows checked out without an in_date ever being set.
  static DateTime? _rowDate(Map<String, dynamic> row) =>
      asDate(pick(row, ['in_date'])) ??
      asDate(pick(row, ['pre_date'])) ??
      asDate(pick(row, ['out_date']));

  /// Whether a row falls inside the date window.
  bool _matchesFilters(Map<String, dynamic> row) {
    final range = _activeRange;
    if (range == null) return true;

    final date = _rowDate(row);
    // An entry with no date at all cannot be placed in a window, so it is
    // hidden while one is set rather than shown under every range.
    if (date == null) return false;

    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// True when a date window is narrowing the list, so the UI can offer a
  /// way back to the whole log.
  bool get _hasFilters => _dateFilter != _DateFilter.all;

  void _clearFilters() => setState(() {
    _dateFilter = _DateFilter.all;
    _customRange = null;
  });

  /// "25 Aug, 12:43PM" — one half of the gate stamp.
  ///
  /// The view hands the two halves back separately and already formatted:
  /// the date as "25 Aug 2026" and the time as "12:43PM", the latter being a
  /// time of day with no date on it. So they are joined rather than parsed
  /// into one moment — asDate would read the time string as nothing.
  ///
  /// The date is dropped when it is the same day as the other stamp: a visitor
  /// who arrived and left within the hour reads better as "In 9:30AM · Out
  /// 10:40AM" than as the same date printed twice.
  static String _stamp(
    Map<String, dynamic> row,
    List<String> dateKeys,
    List<String> timeKeys, {
    bool withDate = true,
  }) {
    final date = prettyDate(pick(row, dateKeys));
    final time = pick(row, timeKeys);

    if (!withDate) return time ?? (date == '—' ? '—' : date);
    if (date == '—') return time ?? '—';
    return time == null ? date : '$date, $time';
  }

  /// Whether the visitor arrived and left on the same day.
  static bool _sameDay(Map<String, dynamic> row) {
    final inDate = pick(row, ['in_date']);
    final outDate = pick(row, ['out_date']);
    return inDate != null && inDate == outDate;
  }

  /// Stamp a visitor out, once the secretary confirms it.
  ///
  /// Asked first because the exit time is written from GETDATE() — stamping
  /// the wrong person out records them leaving at a moment they did not, and
  /// there is no undo on the list.
  Future<void> _confirmCheckout(int id, String? name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check out visitor'),
        content: Text(
          'Record ${name ?? 'this visitor'} leaving now? '
          'The exit date and time are stamped from the clock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Check out'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    await ref.read(communityViewModelProvider.notifier).checkoutVisitor(id);
  }

  /// Opens the register form as its own page.
  ///
  /// A page rather than a sheet: the form runs to a building, a flat and up to
  /// six more fields, which a sheet shows a third of at a time — and the flat
  /// picker sat below the fold on a phone, where the keyboard then covered
  /// what was left.
  Future<void> _openForm() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const VisitorFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.visitors);

    return Scaffold(
      // No clear-filters action up here: the summary line under the search box
      // carries one, next to the count that says a filter is on.
      appBar: AppBar(title: const Text('Visitors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add visitor'),
      ),
      body: SafeArea(
        child: RowsView(
          rows: rows,
          onRefresh: _refresh,
          emptyIcon: Icons.how_to_reg_outlined,
          emptyTitle: 'No visitors',
          emptyMessage: 'Register the first gate entry to get started.',
          emptyActionLabel: 'Add visitor',
          emptyAction: _openForm,
          builder: (items) => _buildLoaded(items),
        ),
      ),
    );
  }

  /// The whole list once rows have arrived: summary, search, tabs, entries.
  ///
  /// Built inside RowsView rather than around it so the counts come from the
  /// rows themselves — a header sitting above it would have to be told the
  /// list was still loading and show figures for an empty one meanwhile.
  Widget _buildLoaded(List<Map<String, dynamic>> items) {
    // The date window and type are applied first, so the header figures and
    // every tab count describe the same slice the cards below come from.
    final scoped = items.where(_matchesFilters).toList(growable: false);

    final inside = scoped.where(_isInside).toList(growable: false);
    final expected = scoped.where(_isExpected).toList(growable: false);
    final left = scoped.where(_hasLeft).toList(growable: false);

    final shown = switch (_tab) {
      _VisitorTab.inside => inside,
      _VisitorTab.expected => expected,
      _VisitorTab.left => left,
      _VisitorTab.all => scoped,
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 118),
      children: [
        // The filter lives beside the search box rather than as rows of chips
        // down the page: the two together are one act of narrowing the list,
        // and the chips cost two lines of every screen to say "All time, all
        // types" — which is the state the log is nearly always read in.
        SearchBarArea(
          controller: _searchController,
          onChanged: _onSearchChanged,
          hint: 'Search by name, flat or phone',
          trailing: _buildFilterMenu(),
        ),
        // Under the search box, not above it: the count describes the list
        // being searched, and moves with it.
        PageConstraints(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space3),
            child: _buildSummary(items.length, scoped.length, inside.length),
          ),
        ),
        PageConstraints(
          child: _buildTabs(scoped.length, inside, expected, left),
        ),
        const SizedBox(height: AppTheme.space2),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.space5),
            child: StateMessage(
              icon: _tab.icon,
              title: _hasFilters
                  ? 'Nothing in this range'
                  : 'No ${_tab.label.toLowerCase()} visitors',
              /*
               * Three different things can empty this list, and the way out
               * differs for each: an empty log needs an entry registering, a
               * filter that matches nothing needs clearing, and an empty tab
               * over a full log just needs another tab.
               */
              message: items.isEmpty
                  ? 'Register the first gate entry to get started.'
                  : _hasFilters
                  ? 'No ${_tab.label.toLowerCase()} visitors match the '
                        'filters you have set. Widen the date range or clear '
                        'them to see the rest of the log.'
                  : '${items.length} entr${items.length == 1 ? 'y' : 'ies'} '
                        'in the log, none of them here.',
              actionLabel: items.isEmpty
                  ? 'Add visitor'
                  : _hasFilters
                  ? 'Clear filters'
                  : 'Show all',
              onAction: items.isEmpty
                  ? _openForm
                  : _hasFilters
                  ? _clearFilters
                  : () => setState(() => _tab = _VisitorTab.all),
            ),
          )
        else
          PageConstraints(
            child: Column(
              children: [for (final row in shown) _buildVisitor(row)],
            ),
          ),
      ],
    );
  }

  /// One quiet line saying how the log stands, and what is hiding the rest.
  ///
  /// A gradient panel of figures was tried here and taken out: it repeated the
  /// two numbers the tabs below already carry, in a block taller than the
  /// cards it introduced. This states the total, and — when a filter is on —
  /// says how much of the log it is showing, which is the one thing the tabs
  /// cannot say for themselves.
  Widget _buildSummary(int total, int shown, int inside) {
    final filtered = _hasFilters && shown != total;

    return Row(
      children: [
        Icon(
          filtered ? Icons.filter_alt_rounded : Icons.meeting_room_rounded,
          size: 15,
          color: filtered ? AppTheme.primary : AppTheme.lightText,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            filtered
                ? '$shown of $total shown · $_dateLabel'
                : '$inside inside now · $total in the log',
            style: filtered
                ? AppTheme.caption.copyWith(color: AppTheme.primary)
                : AppTheme.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // The way back out of a filter, next to the line that says one is on.
        if (_hasFilters)
          InkWell(
            onTap: _clearFilters,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'Clear',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The date window in words, with a custom range spelled out.
  String get _dateLabel {
    if (_dateFilter == _DateFilter.custom && _customRange != null) {
      final r = _customRange!;
      return '${shortDate(r.start)} — ${shortDate(r.end)}';
    }
    return _dateFilter.label;
  }

  /// The date filter, as the menu beside the search box.
  ///
  /// Built to match noc_certificate_screen's filter exactly — a PopupMenuButton
  /// in a 46pt square that tints while a filter is on. A bottom sheet of chips
  /// was tried first and taken out: it was a second design for the same job,
  /// and the two screens sit one tap apart under Community.
  ///
  /// Date only. A visitor-type filter was built here too and dropped: the type
  /// is already on every card, and the search box finds "Delivery" as readily
  /// as it finds a name.
  Widget _buildFilterMenu() {
    return Material(
      color: _hasFilters
          ? AppTheme.surfaceFor(AppTheme.primary)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: PopupMenuButton<Object?>(
        tooltip: 'Filter',
        position: PopupMenuPosition.under,
        onSelected: (value) {
          if (value == _dateFilterKey) {
            _pickCustomRange();
            return;
          }
          setState(() => _dateFilter = value as _DateFilter);
        },
        itemBuilder: (context) => [
          for (final filter in _DateFilter.values)
            if (filter != _DateFilter.custom)
              PopupMenuItem(
                value: filter,
                child: Row(
                  children: [
                    Icon(
                      filter.icon,
                      size: 18,
                      // The one in force is ticked in the app's accent, so the
                      // window is readable without closing the menu again.
                      color: _dateFilter == filter
                          ? AppTheme.primary
                          : AppTheme.lightText,
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Text(filter.label),
                  ],
                ),
              ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _dateFilterKey,
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 18),
                const SizedBox(width: AppTheme.space2),
                Text(
                  _dateFilter == _DateFilter.custom && _customRange != null
                      ? _dateLabel
                      : 'Between dates…',
                ),
              ],
            ),
          ),
        ],
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _hasFilters ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Icon(
            _hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
            size: 20,
            color: _hasFilters ? AppTheme.primary : AppTheme.lightText,
          ),
        ),
      ),
    );
  }

  /// Opens the calendar for the custom window.
  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangeDialog(
      context: context,
      initial:
          _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    // Dismissed: the filter it had stays, rather than switching to Custom with
    // no range behind it.
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = picked;
      _dateFilter = _DateFilter.custom;
    });
  }

  /// Segmented tabs, each carrying its own count.
  Widget _buildTabs(
    int total,
    List<Map<String, dynamic>> inside,
    List<Map<String, dynamic>> expected,
    List<Map<String, dynamic>> left,
  ) {
    final counts = {
      _VisitorTab.inside: inside.length,
      _VisitorTab.expected: expected.length,
      _VisitorTab.left: left.length,
      _VisitorTab.all: total,
    };

    /*
     * Wrapped, so each pill is as wide as its own contents and the ones that
     * do not fit the line drop to the next.
     *
     * Splitting a phone's width four ways left about 110pt a pill, which an
     * icon, a label and a two-digit count do not fit into: a real society's
     * log came out as "Insi… 26" and "Exp… 11" — the two tabs read most were
     * the two that lost their names. Scrolling was tried instead and is worse
     * here: TabPillBar builds its scrollable form with a lazy ListView, so All
     * simply did not exist until it was swiped into view.
     */
    return Wrap(
      spacing: AppTheme.space2,
      runSpacing: AppTheme.space2,
      children: [
        for (final tab in _VisitorTab.values)
          _TabPill(
            label: tab.label,
            icon: tab.icon,
            count: counts[tab] ?? 0,
            selected: _tab == tab,
            onTap: () => setState(() => _tab = tab),
          ),
      ],
    );
  }

  Widget _buildVisitor(Map<String, dynamic> row) {
    final id = pickInt(row, ['visitor_id', 'id']);
    final name = pick(row, ['v_name', 'visitor_name', 'name']);
    final type = pick(row, ['type', 'visitor_type', 'entry_type']);
    final flat = pick(row, ['flat_no', 'unit_no', 'flat']);
    final contact = pick(row, ['contact_no', 'mobile_no', 'phone']);
    final building = pick(row, ['build_wing', 'build_name', 'building_name']);
    final unit = [building, flat].where((e) => e != null).join(' ');
    // The same three predicates the tabs slice on, so a card can never
    // disagree with the tab it is sitting under.
    final expected = _isExpected(row);
    final stillInside = _isInside(row);
    final color = _typeColor(type);

    // The stripe states the entry's standing at a glance — green while they
    // are in the society, amber while they are still due, grey once they have
    // gone — which the scan down a long log picks up before any of the text.
    final statusColour = expected
        ? AppTheme.warning
        : stillInside
        ? AppTheme.success
        : AppTheme.deactivatedText;

    return AppCard(
      // Tighter than the default, and closer to its neighbours: the gate log
      // is read by scrolling a long list, so a card that spends four points a
      // side on air costs a row of entries per screen.
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppTheme.space2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: statusColour),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space3),
                child: _buildVisitorBody(
                  row: row,
                  id: id,
                  name: name,
                  type: type,
                  contact: contact,
                  unit: unit,
                  color: color,
                  expected: expected,
                  stillInside: stillInside,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The card's contents, inside the stripe.
  Widget _buildVisitorBody({
    required Map<String, dynamic> row,
    required int? id,
    required String? name,
    required String? type,
    required String? contact,
    required String unit,
    required Color color,
    required bool expected,
    required bool stillInside,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconPlate(icon: _typeIcon(type), color: color),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? 'Visitor',
                    style: AppTheme.title.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.home_outlined,
                          size: 13,
                          color: AppTheme.lightText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            unit,
                            style: AppTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppTheme.space2),
            // Three states, not two: an expected visitor has not arrived, so
            // "Left" would be wrong and a check-out button meaningless.
            if (expected)
              const StatusChip(label: 'Expected', color: AppTheme.warning)
            else if (stillInside)
              const StatusChip(label: 'Inside', color: AppTheme.success)
            else
              const StatusChip(label: 'Left', color: AppTheme.deactivatedText),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        /*
           * The facts and the action share one line, wrapping when they will
           * not fit. Given a row of its own, the button added a third of a
           * card's height to every entry — and the gate log is read by
           * scrolling, so three cards to a screen is the cost of that.
           *
           * A Wrap rather than a Row: on a narrow phone the button drops to
           * its own line by itself, which is the same layout as before but
           * only when it is actually needed.
           */
        Wrap(
          spacing: AppTheme.space4,
          runSpacing: AppTheme.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (type != null) _MetaLine(icon: _typeIcon(type), text: type),
            if (contact != null)
              _MetaLine(icon: Icons.call_outlined, text: contact),
            if (expected)
              _MetaLine(
                icon: Icons.event_outlined,
                text: 'Due ${prettyDate(row['pre_date'])}',
              )
            else ...[
              _MetaLine(
                icon: Icons.login_rounded,
                text: 'In ${_stamp(row, const ['in_date'], const ['in_time'])}',
              ),
              // Shown once they have left, so the card says how long the
              // visit ran rather than only when it started.
              if (!stillInside)
                _MetaLine(
                  icon: Icons.logout_rounded,
                  color: AppTheme.error,
                  text:
                      'Out ${_stamp(row, const ['out_date'], const ['out_time'], withDate: !_sameDay(row))}',
                ),
            ],
            // Red: stamping someone out is the one irreversible thing on
            // this card, and it sits beside the person's own details.
            if (stillInside && !expected && id != null)
              _CheckOutButton(onPressed: () => _confirmCheckout(id, name)),
          ],
        ),
      ],
    );
  }
}

/// The glyph for a visitor type. Top-level so the form can label its own
/// section with the same icon the list draws on the card.
IconData _typeIcon(String? type) {
  switch (type?.toLowerCase()) {
    case 'cab':
      return Icons.local_taxi_outlined;
    case 'delivery':
      return Icons.local_shipping_outlined;
    case 'service':
      return Icons.handyman_outlined;
    default:
      return Icons.person_outline;
  }
}

Color _typeColor(String? type) {
  switch (type?.toLowerCase()) {
    case 'cab':
      return AppTheme.warning;
    case 'delivery':
      return AppTheme.info;
    case 'service':
      return AppTheme.primary;
    default:
      return AppTheme.success;
  }
}

/// One group of the form, in a card under its own heading.
///
/// The form asks about three separate things — who is coming, which flat they
/// are visiting, and when they arrived — and as one run of nine fields there
/// was nothing to say where one ended and the next began.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space4,
        AppTheme.space4,
      ),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.overline.copyWith(color: AppTheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          ...children,
        ],
      ),
    );
  }
}

/// A read-only field that opens a picker when tapped.
///
/// InputDecorator rather than a TextFormField: the value is chosen from a
/// dialog, never typed, so a real field would put a caret in a box that cannot
/// be edited. This borrows the same decoration so it lines up with the fields
/// above and below it.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
        child: Text(
          value,
          style: AppTheme.body2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// The check-out action, sized to sit inline with the facts beside it.
///
/// A hand-built pill rather than TextButton.icon: the button's own minimum
/// height is 48pt, which set the height of the whole row it shared and undid
/// the point of putting it there.
class _CheckOutButton extends StatelessWidget {
  const _CheckOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.errorSurface,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space3,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 14, color: AppTheme.error),
              const SizedBox(width: 5),
              Text(
                'Check out',
                style: AppTheme.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab of the gate log, sized to its own label.
///
/// Local rather than TabPillBar's: that one either splits the width evenly —
/// which truncates these four labels once the counts run to two digits — or
/// scrolls with a lazy ListView, which leaves the last tab unbuilt until it is
/// swiped to. This keeps the same look and the same `tabCountKey`, and wraps.
class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusPill);
    final foreground = selected ? AppTheme.white : AppTheme.grey;

    return Material(
      color: selected ? AppTheme.primary : AppTheme.cardBackground,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppTheme.white : AppTheme.lightText,
              ),
              const SizedBox(width: 6),
              // No Flexible and no ellipsis: the pill takes the width its
              // label needs, which is the whole point of it living here.
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppTheme.spacer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    '$count',
                    // Keyed as TabPillBar's is, so the tests that read a tab's
                    // count outright go on working.
                    key: tabCountKey(label),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon and a word, for the facts under a visitor's name.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;

  /// Tints the pair, for the one fact worth picking out of the row — the exit
  /// stamp, which is what distinguishes a finished visit from a running one.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    /*
     * The label is Flexible even though the Row is mainAxisSize.min: a Wrap
     * gives its children the full line width to measure against, so a long
     * value ("In 25 Aug 2026, 9:30 am") measured wider than the card and
     * overflowed rather than moving to the next line.
     */
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? AppTheme.lightText),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: color == null
                ? AppTheme.caption
                : AppTheme.caption.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// One of the inputs a visitor type asks for.
///
/// `controller` is a lookup rather than the controller itself because the set
/// is declared once, above the State that owns them.
class _TypeField {
  const _TypeField(this.label, this.icon, this.controller, {this.keyboard});

  final String label;
  final IconData icon;
  final TextEditingController Function(_VisitorFormState) controller;
  final TextInputType? keyboard;
}

/*
 * Which inputs each visitor type shows, and what they are called.
 *
 * Mirrors VISITOR_TYPES on the website's visitors page, which in turn follows
 * visitor_search.aspx: the legacy page swapped in a different panel per type,
 * but every panel wrote the same three columns — company, vehicle_no and
 * location. Only the labels differed, so the type drives wording and which
 * boxes appear rather than there being a form per type.
 *
 * The app previously showed a bare "Company" and "Vehicle number" on some
 * types and no location box at all, so a cab's pickup point and a guest's
 * address had nowhere to go even though the API and the model both carry them.
 */
List<_TypeField> _typeFields(String type) => switch (type) {
  'Cab' => [
    _TypeField(
      'Cab company',
      Icons.local_taxi_outlined,
      (s) => s._companyController,
    ),
    _TypeField(
      'Vehicle number',
      Icons.pin_outlined,
      (s) => s._vehicleController,
      // A plate is letters and digits both, so the layout keeps the digits
      // visible without giving up the letters: MH12AB1234 is typed on one
      // keyboard rather than switching twice.
      keyboard: TextInputType.visiblePassword,
    ),
    _TypeField(
      'Pickup / drop location',
      Icons.place_outlined,
      (s) => s._locationController,
    ),
  ],
  'Delivery' => [
    _TypeField(
      'Delivery company',
      Icons.local_shipping_outlined,
      (s) => s._companyController,
    ),
    _TypeField(
      'Vehicle number',
      Icons.pin_outlined,
      (s) => s._vehicleController,
      // A plate is letters and digits both, so the layout keeps the digits
      // visible without giving up the letters: MH12AB1234 is typed on one
      // keyboard rather than switching twice.
      keyboard: TextInputType.visiblePassword,
    ),
    _TypeField(
      'Package description',
      Icons.inventory_2_outlined,
      (s) => s._purposeController,
    ),
  ],
  'Service' => [
    _TypeField(
      'Service company',
      Icons.handyman_outlined,
      (s) => s._companyController,
    ),
    _TypeField(
      'Vehicle number',
      Icons.pin_outlined,
      (s) => s._vehicleController,
      // A plate is letters and digits both, so the layout keeps the digits
      // visible without giving up the letters: MH12AB1234 is typed on one
      // keyboard rather than switching twice.
      keyboard: TextInputType.visiblePassword,
    ),
    _TypeField(
      'Nature of work',
      Icons.build_outlined,
      (s) => s._purposeController,
    ),
  ],
  // Guest, and anything a future type falls back to.
  _ => [
    _TypeField('Address', Icons.place_outlined, (s) => s._locationController),
    _TypeField(
      'Purpose of visit',
      Icons.notes_outlined,
      (s) => s._purposeController,
    ),
  ],
};

/// Register a visitor.
///
/// One form for every type: the legacy page had four panels, but all four wrote
/// the same columns, so `type` only changes which optional fields are shown.
///
/// A page rather than a bottom sheet. The form is nine fields deep once a type
/// with a vehicle and a company is chosen, and a sheet showed three of them at
/// a time — with the keyboard up, the building and flat pickers were off screen
/// entirely, which is where a visitor's unit is chosen.
class VisitorFormScreen extends ConsumerStatefulWidget {
  const VisitorFormScreen({super.key});

  @override
  ConsumerState<VisitorFormScreen> createState() => _VisitorFormState();
}

class _VisitorFormState extends ConsumerState<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _companyController = TextEditingController();
  final _purposeController = TextEditingController();
  final _locationController = TextEditingController();

  String _type = 'Guest';
  String? _building;
  int? _flatId;

  /*
   * Defaulted to now, because the common case is a visitor standing at the
   * gate — but shown and editable, because the other case is the secretary
   * writing up an entry after the fact, and a silent "now" recorded them
   * arriving whenever the form happened to be filled in.
   */
  DateTime _inDate = DateTime.now();
  TimeOfDay _inTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    /*
     * The helpdesk lookups, not the booking ones: this form reads a `flats`
     * list, and the booking endpoint returns `facilities` and `residents` — it
     * has no flats key at all, so the unit picker never rendered. The helpdesk
     * endpoint returns sp_flat_master's Grid_Show rows, which carry the
     * building and wing each flat sits under.
     */
    Future.microtask(
      () => ref.read(communityViewModelProvider.notifier).loadHelpdeskLookups(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _vehicleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .createVisitor(
          VisitorRequest(
            name: _nameController.text.trim(),
            type: _type,
            contactNo: _value(_contactController),
            flatId: _flatId,
            vehicleNo: _value(_vehicleController),
            company: _value(_companyController),
            purpose: _value(_purposeController),
            location: _value(_locationController),
            inDate:
                '${_inDate.year.toString().padLeft(4, '0')}-'
                '${_inDate.month.toString().padLeft(2, '0')}-'
                '${_inDate.day.toString().padLeft(2, '0')}',
            inTime:
                '${_inTime.hour.toString().padLeft(2, '0')}:'
                '${_inTime.minute.toString().padLeft(2, '0')}',
          ),
        );

    if (ok && mounted) Navigator.pop(context);
  }

  String? _value(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  /// Switch the visitor type, dropping anything the new one does not ask for.
  ///
  /// The boxes are swapped by type but the controllers behind them outlive the
  /// swap. Without this, typing a cab company and then changing the type to
  /// Guest still saved that company — written from a field no longer on screen,
  /// so there was no way to see it, let alone clear it.
  void _changeType(String next) {
    final keep = _typeFields(next).map((f) => f.controller(this)).toSet();

    setState(() {
      _type = next;
      for (final c in [
        _vehicleController,
        _companyController,
        _purposeController,
        _locationController,
      ]) {
        if (!keep.contains(c)) c.clear();
      }
    });
  }

  /// The arrival date.
  ///
  /// Bounded to the past year and today: this records someone who has come to
  /// the gate, so a future date would be a typo rather than a booking — a
  /// visitor expected later is pre-registered from the resident app, which
  /// writes pre_date instead.
  Future<void> _pickInDate() async {
    final now = DateTime.now();
    // The app's own calendar, as every other date field opens — Flutter's
    // showDatePicker is a full-screen Material dialog that looks nothing like
    // the six other screens that pick a date.
    final picked = await showSingleDateDialog(
      context: context,
      initial: _inDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      title: 'Arrived on',
    );
    if (picked != null && mounted) setState(() => _inDate = picked);
  }

  Future<void> _pickInTime() async {
    final picked = await showTimeDialog(
      context: context,
      initial: _inTime,
      title: 'Arrived at',
    );
    if (picked != null && mounted) setState(() => _inTime = picked);
  }

  /// The distinct buildings the society's flats sit in, by name.
  ///
  /// There is no building endpoint on the community API, so the list is derived
  /// from the flat rows themselves — Grid_Show returns `build_id` and `name` on
  /// every flat, which is all a picker needs.
  static List<String> _buildingsOf(List<Map<String, dynamic>> flats) {
    final names = <String>{};
    for (final f in flats) {
      final name = _buildingOf(f);
      if (name.isNotEmpty) names.add(name);
    }

    final rows = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return rows;
  }

  /// The building a flat sits in, however the row spelled it.
  ///
  /// Grouped by name rather than by `build_id`: the `flat` view does select
  /// build_id, but Grid_Show rows reach some callers carrying only the joined
  /// `build_wing` text, and a picker keyed on an id that is sometimes absent
  /// silently drops every flat. The name is present either way, and is what
  /// distinguishes one building from another to the person reading the list.
  ///
  /// `name` is preferred over `build_wing` because build_wing is the building
  /// and wing joined ("Ganesh Bhavan A"), which would split one building into
  /// one entry per wing.
  static String _buildingOf(Map<String, dynamic> flat) =>
      pick(flat, ['name', 'build_name', 'building_name', 'build_wing']) ?? '';

  /// Flats ordered so A-9 lands before A-101 rather than after it.
  ///
  /// Grid_Show returns them by flat_id descending — newest first, which reads as
  /// unordered to someone looking for a number.
  static List<Map<String, dynamic>> _sortedByFlatNo(
    List<Map<String, dynamic>> flats,
  ) {
    int? leadingNumber(String s) {
      final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
      return digits == null ? null : int.tryParse(digits);
    }

    final sorted = [...flats];
    sorted.sort((a, b) {
      final an = pick(a, ['flat_no', 'unit_no']) ?? '';
      final bn = pick(b, ['flat_no', 'unit_no']) ?? '';

      // Wing first, so a building's A-wing flats group together.
      final wing = (pick(a, ['w_name']) ?? '').compareTo(
        pick(b, ['w_name']) ?? '',
      );
      if (wing != 0) return wing;

      final ai = leadingNumber(an);
      final bi = leadingNumber(bn);
      if (ai != null && bi != null && ai != bi) return ai.compareTo(bi);
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final lookups = ref
        .read(communityViewModelProvider.notifier)
        .helpdeskLookups;
    final flats = lookups == null
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            (lookups['flats'] as List?)?.map(
                  (e) => Map<String, dynamic>.from(e as Map),
                ) ??
                const [],
          );

    final buildings = _buildingsOf(flats);
    // Every flat under the chosen building, in flat-number order.
    final flatsInBuilding = _building == null
        ? const <Map<String, dynamic>>[]
        : _sortedByFlatNo(
            flats.where((f) => _buildingOf(f) == _building).toList(),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Add visitor')),
      body: SafeArea(
        child: PageConstraints(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space5,
                AppTheme.space4,
                AppTheme.space5,
                AppTheme.space8,
              ),
              children: [
                GradientPanel(
                  gradient: AppTheme.heroGradient,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppTheme.white,
                        size: 26,
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New gate entry',
                              style: AppTheme.headline.copyWith(
                                fontSize: 18,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'The flat and the gate are both told once the '
                              'visitor is registered.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: AppTheme.onGradientMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
                /*
                 * Grouped into three cards — who is coming, where to, and
                 * when — rather than one run of nine fields. The form asks
                 * about three separate things, and a flat list gave no hint
                 * where one ended and the next began.
                 */
                _FormSection(
                  title: 'Visitor',
                  icon: Icons.person_outline,
                  children: [
                    AppDropdown<String>(
                      value: _type,
                      label: 'Type',
                      icon: Icons.badge_outlined,
                      isDense: false,
                      options: const [
                        AppOption('Guest', 'Guest', icon: Icons.person_outline),
                        AppOption(
                          'Cab',
                          'Cab',
                          icon: Icons.local_taxi_outlined,
                        ),
                        AppOption(
                          'Delivery',
                          'Delivery',
                          icon: Icons.local_shipping_outlined,
                        ),
                        AppOption(
                          'Service',
                          'Service',
                          icon: Icons.build_outlined,
                        ),
                      ],
                      onChanged: (v) => _changeType(v ?? 'Guest'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Visitor name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact number',
                        prefixIcon: Icon(Icons.call_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
                if (flats.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space3),
                  _FormSection(
                    title: 'Visiting',
                    icon: Icons.home_outlined,
                    children: [
                      AppDropdown<String>(
                        value: _building,
                        label: 'Building',
                        hint: 'Select a building',
                        icon: Icons.apartment_outlined,
                        isDense: false,
                        options: [for (final b in buildings) AppOption(b, b)],
                        // Changing the building drops a flat belonging to the
                        // old one, so the visitor can never be saved against a
                        // flat the building shown above it does not contain.
                        onChanged: (v) => setState(() {
                          _building = v;
                          _flatId = null;
                        }),
                      ),
                      const SizedBox(height: 14),
                      AppDropdown<int>(
                        value: _flatId,
                        label: 'Visiting flat',
                        hint: _building == null
                            ? 'Select a building first'
                            : 'Select a flat',
                        icon: Icons.meeting_room_outlined,
                        isDense: false,
                        helperText: _building == null
                            ? null
                            : '${flatsInBuilding.length} flat(s) in this '
                                  'building',
                        options: [
                          for (final f in flatsInBuilding)
                            if (pickInt(f, ['flat_id', 'flatId']) != null)
                              AppOption(
                                pickInt(f, ['flat_id', 'flatId'])!,
                                // Wing included: two wings of one building each
                                // run their own 101, so the number alone is
                                // ambiguous.
                                [
                                  pick(f, ['w_name']),
                                  pick(f, ['flat_no', 'unit_no']),
                                ].where((e) => e != null).join(' · '),
                              ),
                        ],
                        // Null while no building is picked, which AppDropdown
                        // renders as a disabled field showing the hint.
                        onChanged: _building == null
                            ? null
                            : (v) => setState(() => _flatId = v),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.space3),
                _FormSection(
                  // Named for the type, since that is what decides what is in
                  // it — "Cab details" reads as an answer to the type above.
                  title: '$_type details',
                  icon: _typeIcon(_type),
                  children: [
                    // The inputs this type calls for, labelled its way — see
                    // _typeFields.
                    for (final (i, field) in _typeFields(_type).indexed) ...[
                      if (i > 0) const SizedBox(height: 14),
                      TextFormField(
                        controller: field.controller(this),
                        keyboardType: field.keyboard,
                        // Plates are typed in capitals and the field that
                        // carries one asks for its own layout; everything else
                        // here is prose and takes title case.
                        textCapitalization: field.keyboard == null
                            ? TextCapitalization.words
                            : TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: field.label,
                          prefixIcon: Icon(field.icon, size: 20),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.space3),
                _FormSection(
                  title: 'Arrival',
                  icon: Icons.login_rounded,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PickerField(
                            label: 'In date',
                            icon: Icons.event_outlined,
                            value: prettyDate(_inDate),
                            onTap: _pickInDate,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space3),
                        Expanded(
                          child: _PickerField(
                            label: 'In time',
                            icon: Icons.schedule_outlined,
                            value: _inTime.format(context),
                            onTap: _pickInTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space6),
                BusyButton(
                  label: 'Register visitor',
                  icon: Icons.how_to_reg_rounded,
                  busy: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
