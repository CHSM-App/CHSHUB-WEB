import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'event_form_screen.dart';
import 'meeting_form_screen.dart';
import 'notices_screen.dart';

/// Everything the committee announces, in one place.
///
/// Notices, meetings and events are three different tables behind three
/// stored procedures, but to a secretary they are one job — telling residents
/// something is happening. They used to be three separate destinations: the
/// notice board had its own screen, while meetings and events were tabs four
/// and three inside Community › More, which meant reaching them took three
/// taps and knowing which tab held what.
///
/// The tab a secretary lands on carries a count, so "is there anything on the
/// board" is answered without opening it, and each tab adds its own kind
/// directly rather than routing through a chooser.
enum AnnouncementKind {
  notice('Notice', 'Notices', Icons.campaign_rounded, AppTheme.primary),
  meeting('Meeting', 'Meetings', Icons.groups_rounded, AppTheme.info),
  event('Event', 'Events', Icons.celebration_rounded, AppTheme.warning);

  const AnnouncementKind(this.singular, this.plural, this.icon, this.color);

  /// 'Notice' — used in buttons and confirmations.
  final String singular;

  /// 'Notices' — used as the tab label.
  final String plural;

  final IconData icon;
  final Color color;
}

/// Which slice of a list is on screen.
///
/// All three kinds carry a date, so all three split the same way: what is
/// still ahead, what has passed, and everything.
enum _When {
  upcoming('Upcoming', Icons.upcoming_rounded),
  past('Past', Icons.history_rounded),
  all('All', Icons.list_alt_rounded);

  const _When(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key, this.initialKind});

  /// Which tab opens first. Null starts on notices, which is what the
  /// dashboard's quick action wants.
  final AnnouncementKind? initialKind;

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late AnnouncementKind _kind = widget.initialKind ?? AnnouncementKind.notice;
  // Opens on what is still ahead, as the notice board opened on Active: a
  // secretary reaching for Announcements is almost always dealing with what
  // is current, and the filter says so on the button when it is not.
  _When _when = _When.upcoming;

  late final TabController _tabs = TabController(
    length: AnnouncementKind.values.length,
    vsync: this,
    initialIndex: _kind.index,
  );

  @override
  void initState() {
    super.initState();

    // The pill bar, the FAB's label and the search hint all follow the page
    // that is showing, so the controller is what they read — including when a
    // swipe moves it rather than a tap.
    _tabs.addListener(() {
      final kind = AnnouncementKind.values[_tabs.index];
      if (kind != _kind) setState(() => _kind = kind);
    });

    // All three load at once rather than per tab: the tab bar shows counts for
    // the tabs not yet opened, and a badge that fills in only after its tab is
    // visited would be blank exactly when it is most useful.
    Future.microtask(_refreshAll);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String? get _search {
    final text = _searchController.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Loads all three lists, one after another.
  ///
  /// Sequential rather than a `Future.wait`: the view model writes each result
  /// into its own key by spreading the whole collections map, and that spread
  /// reads `state` before the await suspends — so three loaders in flight at
  /// once each save a copy taken before the others landed, and the last to
  /// finish erases the other two. Awaiting in turn is the difference between
  /// three populated tabs and one.
  Future<void> _refreshAll() async {
    final notifier = ref.read(communityViewModelProvider.notifier);
    await notifier.loadNotices(search: _search);
    await notifier.loadMeetings(search: _search);
    await notifier.loadEvents(search: _search);
  }

  /// Reloads only the tab on screen — what pull-to-refresh and a save mean.
  Future<void> _refreshCurrent() {
    final notifier = ref.read(communityViewModelProvider.notifier);
    return switch (_kind) {
      AnnouncementKind.notice => notifier.loadNotices(search: _search),
      AnnouncementKind.meeting => notifier.loadMeetings(search: _search),
      AnnouncementKind.event => notifier.loadEvents(search: _search),
    };
  }

  /// Searching re-runs every list, not just the visible one, so the counts on
  /// the other tabs describe the same search the user typed.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _refreshAll);
  }

  /// Where a kind's rows sit in the view model's collections.
  static String _keyFor(AnnouncementKind kind) => switch (kind) {
    AnnouncementKind.notice => CommunityKeys.notices,
    AnnouncementKind.meeting => CommunityKeys.meetings,
    AnnouncementKind.event => CommunityKeys.events,
  };

  /// How many rows a tab holds, or null while it is still loading — TabPill
  /// leaves the badge off rather than showing a zero it may have to correct.
  int? _countFor(AnnouncementKind kind) {
    final rows = ref.watch(communityViewModelProvider).rows(_keyFor(kind));
    return rows.hasValue ? rows.requireValue.items.length : null;
  }

  /// The date a row is filtered and sorted by.
  ///
  /// A notice is judged by when it stops showing, a meeting and an event by
  /// when they happen — so "upcoming" means the same thing on all three tabs
  /// even though the columns behind it differ.
  static DateTime? _dateOf(AnnouncementKind kind, Map<String, dynamic> row) {
    final raw = switch (kind) {
      AnnouncementKind.notice => row['valid_to'] ?? row['validTo'],
      AnnouncementKind.meeting =>
        row['meeting_date'] ?? row['meetingDate'] ?? row['date'],
      AnnouncementKind.event =>
        row['to_date'] ?? row['toDate'] ?? row['from_date'] ?? row['fromDate'],
    };
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  /// Whether [row] has already passed.
  ///
  /// Compared by day rather than by instant: something dated today is still
  /// upcoming for the whole of today. A row with no date never passes — that
  /// is what a notice with a blank "valid until" means on the website.
  static bool _isPast(AnnouncementKind kind, Map<String, dynamic> row) {
    final date = _dateOf(kind, row);
    if (date == null) return false;
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  /// The rows a tab shows, after the search box and the time filter.
  ///
  /// Notices and meetings are searched by the server, which is why the term is
  /// sent with their requests. sp_event_master has no Search branch — the
  /// website sets `searchable={false}` on its events page for exactly that
  /// reason — so events are matched here instead, rather than leaving the box
  /// looking broken on one tab out of three.
  List<Map<String, dynamic>> _visible(
    AnnouncementKind kind,
    List<Map<String, dynamic>> items,
  ) {
    var rows = items;
    final term = _search?.toLowerCase();

    if (term != null && kind == AnnouncementKind.event) {
      rows = rows.where((row) {
        final name = pick(row, ['event_name', 'name', 'title']) ?? '';
        final body = pick(row, ['description', 'details', 'venue']) ?? '';
        return name.toLowerCase().contains(term) ||
            body.toLowerCase().contains(term);
      }).toList();
    }

    rows = switch (_when) {
      _When.upcoming => rows.where((r) => !_isPast(kind, r)).toList(),
      _When.past => rows.where((r) => _isPast(kind, r)).toList(),
      _When.all => rows,
    };

    return rows;
  }

  /// Opens the add form for the tab on screen, or edits [existing].
  ///
  /// This is the whole point of the screen: the tab already says which kind is
  /// being added, so the button opens that form rather than asking again.
  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final screen = switch (_kind) {
      AnnouncementKind.notice => NoticeFormScreen(existing: existing),
      AnnouncementKind.meeting => MeetingFormScreen(existing: existing),
      AnnouncementKind.event => EventFormScreen(existing: existing),
    };

    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmDelete(int id, String title) async {
    final kind = _kind;
    final confirmed = await confirmAction(
      context,
      title: 'Delete this ${kind.singular.toLowerCase()}?',
      message: '"$title" will no longer be shown to residents.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    final notifier = ref.read(communityViewModelProvider.notifier);
    switch (kind) {
      case AnnouncementKind.notice:
        await notifier.deleteNotice(id);
      case AnnouncementKind.meeting:
        await notifier.deleteMeeting(id);
      case AnnouncementKind.event:
        await notifier.deleteEvent(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        // The segmented control the post-dated cheques screen uses, rather
        // than a row of pills in the body: it belongs to the app bar the way
        // a page's own tabs do, and it leaves the body to the search box and
        // the list.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(SegmentedTabBar.height),
          child: SegmentedTabBar(
            tabs: [
              for (final kind in AnnouncementKind.values)
                SegmentTab(
                  label: kind.plural,
                  icon: kind.icon,
                  count: _countFor(kind),
                ),
            ],
            selectedIndex: _kind.index,
            // Drives the controller rather than setState: the page view
            // animates across and its listener is what moves `_kind`, so a
            // tap and a swipe end in the same place.
            onSelected: _tabs.animateTo,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text('New ${_kind.singular.toLowerCase()}'),
        backgroundColor: _kind.color,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SearchBarArea(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: 'Search ${_kind.plural.toLowerCase()}',
              // Beside the search box rather than a second row of pills: the
              // kind tabs already take a band of the screen, and two stacked
              // rows push the first card below the fold on a small phone.
              trailing: _WhenFilterButton(
                current: _when,
                onSelected: (when) => setState(() => _when = when),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (final kind in AnnouncementKind.values)
                    _buildTabBody(kind),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One tab's list.
  ///
  /// Takes its kind as an argument rather than reading `_kind`: all three are
  /// built at once inside the TabBarView, and the two off-screen ones must
  /// render their own rows rather than three copies of the visible tab's.
  Widget _buildTabBody(AnnouncementKind kind) {
    final rows = ref.watch(communityViewModelProvider).rows(_keyFor(kind));

    return RowsView(
      rows: rows,
      onRefresh: _refreshCurrent,
      emptyIcon: kind.icon,
      emptyTitle: 'No ${kind.plural.toLowerCase()}',
      emptyMessage: switch (kind) {
        AnnouncementKind.notice => 'Publish one to tell residents something.',
        AnnouncementKind.meeting => 'Call one and every resident is told.',
        AnnouncementKind.event =>
          'Schedule one and it goes on the society calendar.',
      },
      emptyActionLabel: 'New ${kind.singular.toLowerCase()}',
      emptyAction: _openForm,
      builder: (items) => _buildList(kind, items),
    );
  }

  Widget _buildList(
    AnnouncementKind kind,
    List<Map<String, dynamic>> items,
  ) {
    final shown = _visible(kind, items);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 118),
      children: [
        PageConstraints(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space2),
            child: _buildSummary(kind, items.length, shown.length),
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.space6),
            child: StateMessage(
              icon: _when.icon,
              // RowsView's own empty state speaks for a tab with nothing in
              // it; this one has to say the tab is fine and only this filter
              // or search is empty.
              title: 'Nothing to show',
              message: _search != null
                  ? 'No ${_kind.plural.toLowerCase()} match "${_search!}".'
                  : '${items.length} '
                        '${items.length == 1 ? _kind.singular.toLowerCase() : _kind.plural.toLowerCase()} '
                        'in all, none of them ${_when.label.toLowerCase()}.',
              actionLabel: 'Show all',
              onAction: () => setState(() => _when = _When.all),
            ),
          )
        else
          PageConstraints(
            child: Column(
              children: [for (final row in shown) _buildCard(kind, row)],
            ),
          ),
      ],
    );
  }

  /// One quiet line saying how the tab stands, and which filter is on.
  Widget _buildSummary(AnnouncementKind kind, int total, int shown) {
    final noun = total == 1
        ? kind.singular.toLowerCase()
        : kind.plural.toLowerCase();
    final label = _when == _When.all && _search == null
        ? '$total $noun'
        : '$shown of $total $noun';

    return Row(
      children: [
        Icon(kind.icon, size: 15, color: AppTheme.lightText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTheme.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// One row, read through whichever column names its stored procedure used.
  ///
  /// The three procedures name the same ideas differently — a notice has a
  /// `name`, a meeting a `subject`, an event an `event_name` — so each kind
  /// lists the spellings it may arrive under rather than sharing one guess.
  Widget _buildCard(AnnouncementKind kind, Map<String, dynamic> row) {
    final (id, title, body, date) = switch (kind) {
      AnnouncementKind.notice => (
        pickInt(row, ['notice_id', 'id']),
        pick(row, ['name', 'title', 'notice_name']),
        pick(row, ['description', 'details']),
        row['valid_to'] ?? row['validTo'] ?? row['date'],
      ),
      AnnouncementKind.meeting => (
        pickInt(row, ['meet_id', 'meeting_id', 'id']),
        pick(row, ['subject', 'meeting_name', 'name', 'title']),
        pick(row, ['details', 'description', 'venue']),
        row['meeting_date'] ?? row['date'] ?? row['created_at'],
      ),
      AnnouncementKind.event => (
        pickInt(row, ['event_id', 'id']),
        pick(row, ['event_name', 'name', 'title']),
        pick(row, ['description', 'details', 'venue']),
        row['from_date'] ?? row['event_date'] ?? row['date'],
      ),
    };

    final past = _isPast(kind, row);
    // A past row is stated in grey rather than in its kind's colour: the tint
    // is what makes a card read as live, and three ended events in full
    // colour look like three things still to come.
    final accent = past ? AppTheme.lightText : kind.color;
    final time = kind == AnnouncementKind.meeting
        ? _clockOf(row['meeting_time'] ?? row['meetingTime'])
        : null;

    return AppCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space4,
      ),
      onTap: id == null ? null : () => _openForm(existing: row),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconPlate(icon: kind.icon, color: accent),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title ?? kind.singular,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.title.copyWith(
                          fontSize: 15,
                          height: 1.25,
                          color: past ? AppTheme.grey : AppTheme.darkerText,
                        ),
                      ),
                    ),
                    if (id != null) ...[
                      const SizedBox(width: AppTheme.space2),
                      // Spelled out rather than left to a tap on the card:
                      // tapping opens the form either way, but nothing on
                      // screen would say so. Boxed to 30pt so neither crowds a
                      // long title into an extra line.
                      _CardAction(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit',
                        color: AppTheme.primary,
                        onPressed: () => _openForm(existing: row),
                      ),
                      _CardAction(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete',
                        color: AppTheme.error,
                        onPressed: () =>
                            _confirmDelete(id, title ?? kind.singular),
                      ),
                    ],
                  ],
                ),
                if (body != null && body.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body2.copyWith(
                      height: 1.4,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
                if (date != null) ...[
                  const SizedBox(height: AppTheme.space3),
                  // The date and the state on one line: the chip says whether
                  // this still matters, the date says when — together they are
                  // the two things worth reading after the title.
                  Wrap(
                    spacing: AppTheme.space2,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusChip(
                        label: past ? 'Ended' : _liveLabel(kind),
                        color: past ? AppTheme.lightText : AppTheme.success,
                      ),
                      _DateLine(
                        icon: kind == AnnouncementKind.meeting
                            ? Icons.schedule_rounded
                            : Icons.event_outlined,
                        label: [
                          _datePrefix(kind, past),
                          prettyDate(date),
                          if (time != null) '· $time',
                        ].join(' '),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// What a row that has not passed is called, in its own terms.
  static String _liveLabel(AnnouncementKind kind) => switch (kind) {
    AnnouncementKind.notice => 'Showing',
    AnnouncementKind.meeting => 'Scheduled',
    AnnouncementKind.event => 'Upcoming',
  };

  /// How the date reads for each kind — a notice runs until, a meeting happens
  /// on, an event runs from.
  static String _datePrefix(AnnouncementKind kind, bool past) =>
      switch (kind) {
        AnnouncementKind.notice => past ? 'Ended' : 'Until',
        AnnouncementKind.meeting => past ? 'Was' : 'On',
        AnnouncementKind.event => past ? 'Was' : 'From',
      };

  /// A meeting's stored time as a short clock string, or null when it has none.
  ///
  /// sp_meeting_master keeps it in a datetime column, so it arrives either as a
  /// whole timestamp whose date half is meaningless or as plain HH:mm.
  static String? _clockOf(dynamic raw) {
    if (raw == null) return null;

    TimeOfDay? parsed;
    if (raw is DateTime) {
      parsed = TimeOfDay.fromDateTime(raw);
    } else {
      final text = raw.toString().trim();
      if (text.isEmpty) return null;
      final asDate = DateTime.tryParse(text);
      if (asDate != null) {
        parsed = TimeOfDay.fromDateTime(asDate);
      } else {
        final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
        if (match == null) return null;
        final hour = int.tryParse(match.group(1)!);
        final minute = int.tryParse(match.group(2)!);
        if (hour == null || minute == null || hour > 23 || minute > 59) {
          return null;
        }
        parsed = TimeOfDay(hour: hour, minute: minute);
      }
    }

    final hour = parsed.hourOfPeriod == 0 ? 12 : parsed.hourOfPeriod;
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${parsed.period == DayPeriod.am ? 'am' : 'pm'}';
  }
}

/// The Upcoming / Past / All filter, beside the search box.
///
/// A menu rather than a row of chips: the three options are exclusive and only
/// the chosen one matters once it is set, so it costs one button of width
/// instead of a second band across the screen. It is tinted while a filter
/// other than the default is on, so a short list is never mistaken for an
/// empty tab.
class _WhenFilterButton extends StatelessWidget {
  const _WhenFilterButton({required this.current, required this.onSelected});

  final _When current;
  final ValueChanged<_When> onSelected;

  @override
  Widget build(BuildContext context) {
    final filtered = current != _When.all;
    final color = filtered ? AppTheme.primary : AppTheme.lightText;

    return PopupMenuButton<_When>(
      onSelected: onSelected,
      tooltip: 'Filter by date',
      position: PopupMenuPosition.under,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      itemBuilder: (context) => [
        for (final when in _When.values)
          PopupMenuItem(
            value: when,
            child: Row(
              children: [
                Icon(
                  when.icon,
                  size: 18,
                  color: when == current
                      ? AppTheme.primary
                      : AppTheme.lightText,
                ),
                const SizedBox(width: AppTheme.space3),
                Text(
                  when.label,
                  style: AppTheme.body2.copyWith(
                    color: when == current
                        ? AppTheme.primary
                        : AppTheme.darkText,
                    fontWeight: when == current
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
        decoration: BoxDecoration(
          color: filtered ? AppTheme.surfaceFor(AppTheme.primary) : null,
          border: Border.all(color: filtered ? AppTheme.primary : AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(current.icon, size: 17, color: color),
            const SizedBox(width: 5),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

/// A compact icon button on a card — Edit and Delete.
///
/// Boxed to a fixed 30pt square so a row of them keeps its height whatever
/// the title does, and so neither pushes a long title onto an extra line.
class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: 30,
      child: IconButton(
        icon: Icon(icon, size: 17),
        color: color,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

/// The when-line under a card's text: a small icon and a date.
class _DateLine extends StatelessWidget {
  const _DateLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.lightText),
        const SizedBox(width: 5),
        // Flexible inside a Wrap run: the chip beside it takes its share
        // first, and a meeting's date-and-time line is long enough to
        // overrun what is left on a small phone.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
