import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constant.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'raise_complaint_screen.dart';

/// The resolved state, as HelpdeskStatus numbers it. The web page keys its
/// Open/Resolved split off the same id.
const int _resolvedStatus = 4;

/// `urgency` is a flag, not a scale.
///
/// support_ticket.aspx renders it as `urgency == "0" ? "Minor" : "Urgent"` and
/// the column is written by the resident app's raise-complaint form, so any
/// non-zero value means urgent.
bool _isUrgent(Map<String, dynamic> row) =>
    (pickInt(row, ['urgency']) ?? 0) != 0;

/// Which tab of the list is showing.
enum _Filter { open, resolved, all }

/// Resident complaints. Tapping one opens its thread, where the secretary can
/// change the status and reply.
class HelpdeskScreen extends ConsumerStatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  ConsumerState<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends ConsumerState<HelpdeskScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  _Filter _filter = _Filter.open;

  /// The search text, lowercased, matched against the rows already fetched.
  String _search = '';

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

  Future<void> _refresh() =>
      ref.read(communityViewModelProvider.notifier).loadHelpdesk();

  /// Filters the rows already fetched.
  ///
  /// `GET /helpdesk` takes no search parameter — it runs sp_helpdesk's
  /// GetTickets branch, which has none — so passing one refetched the same
  /// full list on every keystroke and nothing appeared to happen. The website
  /// filters its grid client-side for the same reason, so the two now match.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 200),
      () => setState(() => _search = value.trim().toLowerCase()),
    );
  }

  /// True when [row] matches the current search.
  ///
  /// Covers the fields the card actually shows, so a search matches what the
  /// secretary can see rather than columns hidden in the payload.
  bool _matchesSearch(Map<String, dynamic> row) {
    if (_search.isEmpty) return true;

    return [
      pick(row, ['p_type_name', 'title', 'subject', 'category_type']),
      pick(row, ['query', 'description', 'details']),
      pick(row, ['name', 'owner_name']),
      pick(row, ['building_name', 'building']),
      pick(row, ['flat_no', 'unit_no', 'Unit', 'flat']),
    ].any((field) => field != null && field.toLowerCase().contains(_search));
  }

  /// Raise a complaint on a resident's behalf.
  ///
  /// The list reloads on success from the viewmodel, so nothing is refetched
  /// here; the page only has to be dismissed.
  Future<void> _raiseComplaint() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const RaiseComplaintScreen()),
    );
  }

  /// Opens the ticket's thread as a page of its own.
  ///
  /// A page rather than a bottom sheet: the thread is the screen's real work —
  /// reading a complaint and replying to it — and a sheet gave it two thirds
  /// of the height with the list showing uselessly behind.
  Future<void> _openTicket(int id) async {
    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .openHelpdeskTicket(id);
    if (!ok || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _TicketPage(ticketId: id)),
    );

    // The thread is left behind once the page closes, so a later tap does not
    // flash the previous ticket while the new one loads.
    if (mounted) {
      ref.read(communityViewModelProvider.notifier).openTicket = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.helpdesk);

    // The counters summarise everything the search matched, not the visible
    // tab — a count that changed as you switched tabs would be telling you
    // what you already picked rather than what is outstanding.
    final all = (rows.value?.items ?? const <Map<String, dynamic>>[])
        .where(_matchesSearch)
        .toList();
    final open = all.where((r) => !_isResolved(r)).toList();
    final resolved = all.where(_isResolved).toList();
    final urgent = open.where(_isUrgent).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Helpdesk')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _raiseComplaint,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Raise'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            PageConstraints(
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.space3),
                  _buildSummary(
                    open.length,
                    resolved.length,
                    all.length,
                    urgent,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    hint: 'Search complaints',
                  ),
                  const SizedBox(height: AppTheme.space3),
                ],
              ),
            ),
            Expanded(
              child: RowsView(
                rows: rows,
                onRefresh: _refresh,
                emptyIcon: Icons.sentiment_satisfied_alt_outlined,
                emptyTitle: 'No complaints',
                emptyMessage: 'Nothing needs attention right now.',
                builder: (items) {
                  final visible = _visible(items);

                  // RowsView's own empty state covers "the server sent
                  // nothing"; this covers "the filter hid them all", which is
                  // a different thing to tell a secretary.
                  if (visible.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: AppTheme.space8),
                        StateMessage(
                          icon: _filter == _Filter.resolved
                              ? Icons.done_all_rounded
                              : Icons.task_alt_rounded,
                          title: _filter == _Filter.resolved
                              ? 'Nothing resolved yet'
                              : 'No open complaints',
                          message: _filter == _Filter.resolved
                              ? 'Complaints appear here once they are closed.'
                              : 'Every complaint has been dealt with.',
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: AppTheme.space1,
                      bottom: AppTheme.space8,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _buildTicket(visible[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isResolved(Map<String, dynamic> row) =>
      pickInt(row, ['status']) == _resolvedStatus;

  List<Map<String, dynamic>> _visible(List<Map<String, dynamic>> items) {
    // The search narrows every tab, so a term that only matches a resolved
    // ticket does not look like "no results" while sitting on Open.
    final matched = items.where(_matchesSearch);

    switch (_filter) {
      case _Filter.open:
        return matched.where((r) => !_isResolved(r)).toList();
      case _Filter.resolved:
        return matched.where(_isResolved).toList();
      case _Filter.all:
        return matched.toList();
    }
  }

  // ── Summary ──────────────────────────────────────────────────────────

  /// The three counters the web page carries above its grid.
  ///
  /// One short strip rather than a grid of [StatTile]s: at three tiles those
  /// wrapped to two rows on a phone and pushed the list itself off the screen,
  /// and the counts are a glance, not the subject of the page.
  Widget _buildSummary(int open, int resolved, int total, int urgent) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: 'Open',
              value: open,
              hint: urgent > 0 ? '$urgent urgent' : null,
              color: AppTheme.error,
              selected: _filter == _Filter.open,
              onTap: () => setState(() => _filter = _Filter.open),
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              label: 'Resolved',
              value: resolved,
              color: AppTheme.success,
              selected: _filter == _Filter.resolved,
              onTap: () => setState(() => _filter = _Filter.resolved),
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              label: 'Total',
              value: total,
              color: AppTheme.info,
              selected: _filter == _Filter.all,
              onTap: () => setState(() => _filter = _Filter.all),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rows ─────────────────────────────────────────────────────────────

  /// The wording for a status code, from the list the server sent.
  ///
  /// Returns null when the code is unknown or the list has not loaded, so the
  /// row simply carries no chip rather than an invented one.
  String? _statusLabel(int? code) {
    if (code == null) return null;

    final statuses = ref
        .read(communityViewModelProvider)
        .items(CommunityKeys.helpdeskStatuses);

    for (final row in statuses) {
      if (pickInt(row, ['id', 'status_id']) == code) {
        return pick(row, ['status', 'status_name', 'name']);
      }
    }
    return null;
  }

  /// The status dropdown for one row.
  ///
  /// Opens against [anchor] — the button that was tapped — so the menu appears
  /// over the row being changed, the way the web grid's select does, rather
  /// than sliding up from the bottom of the screen.
  Future<void> _pickStatus(int id, int? current, BuildContext anchor) async {
    final statuses = ref
        .read(communityViewModelProvider)
        .items(CommunityKeys.helpdeskStatuses);

    if (statuses.isEmpty) return;

    // Place the menu directly under the button. showMenu wants a rect in the
    // coordinate space of the overlay, not of the row.
    final box = anchor.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(anchor).overlay?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      origin.dx,
      origin.dy + box.size.height + 4,
      overlay.size.width - origin.dx - box.size.width,
      0,
    );

    final picked = await showMenu<int>(
      context: anchor,
      position: position,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.border),
      ),
      items: [
        for (final s in statuses)
          if (pickInt(s, ['status_id', 'id']) != null)
            PopupMenuItem<int>(
              value: pickInt(s, ['status_id', 'id']),
              height: 42,
              child: _StatusRow(
                label: pick(s, ['status_name', 'name', 'status']) ?? 'Status',
                selected: current == pickInt(s, ['status_id', 'id']),
              ),
            ),
      ],
    );

    if (picked == null || picked == current) return;

    await ref
        .read(communityViewModelProvider.notifier)
        // The list has no thread on screen, so there is nothing to refresh —
        // and refetching would replace the ticket the sheet may still hold.
        .updateHelpdeskStatus(id, picked, refreshDetail: false);
  }

  Widget _buildTicket(Map<String, dynamic> row) {
    final id = pickInt(row, ['helpdesk_id', 'id', 'ticket_id']);
    // sp_helpdesk names the complaint `query` and its category `p_type_name`.
    // The heading is the category — a short phrase like "Noise or
    // Disturbance" — with the resident's own words beneath it.
    final title = pick(row, [
      'p_type_name',
      'title',
      'subject',
      'category_type',
    ]);
    final description = pick(row, [
      'query',
      'description',
      'details',
      'complaint',
    ]);
    final flat = pick(row, ['Unit', 'flat_no', 'unit_no', 'flat']);
    final owner = pick(row, ['name', 'owner_name', 'resident_name']);
    final building = pick(row, ['build_name', 'building_name']);

    // `status` is an integer code (1 New, 2 In-Progress, …). Resolved against
    // the statuses the server sent rather than printing the number, and left
    // off entirely if that list has not arrived — a bare "1" tells a
    // secretary nothing.
    final code = pickInt(row, ['status']);
    final status = _statusLabel(code);
    final resolved = code == _resolvedStatus;
    final urgent = _isUrgent(row) && !resolved;

    // An urgent complaint carries a red spine down the card's edge, which is
    // the app's way of marking a row's state without spending a chip on it —
    // the web grid emphasises the same rows.
    // The card itself is not tappable: the row carries two controls of its own
    // (status, comments), and a whole-card tap that opened a third thing meant
    // a mis-aimed press on the status button landed somewhere unexpected.
    return AppCard(
      accent: urgent
          ? AppTheme.error
          : resolved
          ? AppTheme.success
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconPlate(
                icon: resolved
                    ? Icons.check_circle_outline_rounded
                    : Icons.support_agent_outlined,
                color: resolved
                    ? AppTheme.success
                    : urgent
                    ? AppTheme.error
                    : AppTheme.primary,
              ),
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
                            title ?? 'Complaint',
                            style: AppTheme.title.copyWith(fontSize: 15),
                          ),
                        ),
                        // The date takes the top-right corner, freeing the
                        // bottom line for the comments action. The ticket id
                        // is not shown: it is the database's name for the row,
                        // not anything a secretary refers to.
                        const SizedBox(width: AppTheme.space2),
                        Text(
                          prettyDate(row['created_at'] ?? row['date']),
                          style: AppTheme.caption.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          // Chips first, then the meta line — so the state of a complaint is
          // legible while scanning without reading the names.
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (urgent)
                const StatusChip(
                  label: 'Urgent',
                  color: AppTheme.error,
                  icon: Icons.priority_high_rounded,
                ),
              // The status is changed from the row itself, as the web grid's
              // save-on-change dropdown does — a secretary working down a list
              // should not have to open each ticket to close it. The word
              // "Status" sits outside the control: without it the button is
              // just a coloured word, and which word it is changes per row.
              if (id != null) ...[
                Text(
                  'Status',
                  style: AppTheme.overline.copyWith(fontSize: 10),
                ),
                _StatusButton(
                  label: status,
                  // The button hands back its own context so the menu can be
                  // anchored to it rather than to the whole row.
                  onTap: (anchor) => _pickStatus(id, code, anchor),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 13,
                color: AppTheme.lightText,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  [owner, building, flat].where((e) => e != null).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption,
                ),
              ),
              // Opening the thread is its own labelled action, as the web
              // grid's Comments column is — the row no longer opens it by
              // being tapped. It sits on the end of the meta line, where the
              // date used to be, rather than on a rule of its own.
              if (id != null) ...[
                const SizedBox(width: AppTheme.space2),
                TextButton.icon(
                  onPressed: () => _openTicket(id),
                  icon: const Icon(Icons.forum_outlined, size: 15),
                  label: const Text('View comments'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space2,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One count in the summary strip, which doubles as the list's filter — the
/// selected one is underlined in its own colour, so the strip says both what
/// the numbers are and which of them you are looking at.
class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
    this.hint,
  });

  final String label;
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// A short qualifier under the label — "2 urgent".
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.surfaceFor(color) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space2,
                vertical: AppTheme.space3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: AppTheme.numeral.copyWith(
                      fontSize: 20,
                      color: selected ? color : AppTheme.darkerText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    maxLines: 1,
                    style: AppTheme.caption.copyWith(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? color : AppTheme.lightText,
                    ),
                  ),
                  // Kept in the tree at all times so the three cells stay the
                  // same height whether or not anything is urgent — otherwise
                  // the strip changes height as tickets are worked.
                  SizedBox(
                    height: 13,
                    child: hint == null
                        ? null
                        : Text(
                            hint!,
                            maxLines: 1,
                            style: AppTheme.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 2.5, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

/// The hairline between two summary cells.
class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: AppTheme.border);
  }
}

/// The status control on a list row.
///
/// Deliberately not a [StatusChip]: a tinted pill is what the rest of the app
/// uses for read-only labels, and one used as a button was being read as one
/// too. This carries a solid outline, the word "Status", and a caret — so it
/// reads as something to press rather than something to skim.
class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.label, required this.onTap});

  /// Null while the status list has not loaded, or when the code is not in it.
  /// The button still works — picking from the menu is how it gets set.
  final String? label;

  /// Passed this widget's own context, which the menu is positioned against.
  final void Function(BuildContext anchor) onTap;

  @override
  Widget build(BuildContext context) {
    final color = label == null ? AppTheme.lightText : statusColor(label);
    final accent = color == AppTheme.lightText ? AppTheme.primary : color;

    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 6, 7, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A dot in the status's own colour, so the state is still
              // readable at a glance now that the plate behind it is white.
              Container(
                height: 7,
                width: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label ?? 'Set status',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: AppTheme.lightText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the status dropdown. The tap is owned by the [PopupMenuItem]
/// around it, so this is only the label.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(label);
    final accent = color == AppTheme.lightText ? AppTheme.primary : color;

    return Row(
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.space3),
        Expanded(
          child: Text(
            label,
            style: AppTheme.body2.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? accent : AppTheme.darkText,
            ),
          ),
        ),
        if (selected) Icon(Icons.check_rounded, size: 18, color: accent),
      ],
    );
  }
}

/// The ticket thread: details, comments, status change and reply box.
class _TicketPage extends ConsumerStatefulWidget {
  final int ticketId;

  const _TicketPage({required this.ticketId});

  @override
  ConsumerState<_TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends ConsumerState<_TicketPage> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _reply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .addHelpdeskComment(widget.ticketId, text);

    if (ok && mounted) _replyController.clear();
  }

  Future<void> _changeStatus(int status) async {
    await ref
        .read(communityViewModelProvider.notifier)
        .updateHelpdeskStatus(widget.ticketId, status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final vm = ref.read(communityViewModelProvider.notifier);

    final ticket = vm.openTicket;
    // The detail payload nests the ticket under one of a few keys depending on
    // the procedure branch; fall back to the payload itself.
    final detail = ticket == null
        ? <String, dynamic>{}
        : (asRow(ticket['ticket'] ?? ticket['helpdesk'] ?? ticket));
    final comments = ticket == null
        ? const <Map<String, dynamic>>[]
        : asRows(ticket['comments'] ?? ticket['thread']);
    final statuses = state.items(CommunityKeys.helpdeskStatuses);

    // Stored paths, from either app's uploader. The mobile one writes an
    // absolute URL and the website's a relative path, so both are handled
    // where they are shown.
    final images = ticket == null
        ? const <String>[]
        : [
            for (final image in (ticket['images'] as List<dynamic>? ?? const []))
              if (image is String && image.trim().isNotEmpty) image.trim(),
          ];

    final urgent = _isUrgent(detail);

    return Scaffold(
      // Named for what it is rather than for the row's id, which the list no
      // longer shows either.
      appBar: AppBar(title: const Text('Complaint')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageConstraints(
                padded: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space5,
                    AppTheme.space4,
                    AppTheme.space5,
                    AppTheme.space4,
                  ),
                  children: [
                    _buildHeader(detail, urgent),
                    const SizedBox(height: AppTheme.space4),
                    if (pick(detail, ['query', 'description', 'details']) !=
                        null)
                      _buildComplaint(detail),
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space5),
                      _buildPhotos(images),
                    ],
                    const SizedBox(height: AppTheme.space5),
                    if (statuses.isNotEmpty) ...[
                      _buildStatusPicker(detail, statuses),
                      const SizedBox(height: AppTheme.space5),
                    ],
                    Row(
                      children: [
                        Text('Replies', style: AppTheme.title),
                        const SizedBox(width: 6),
                        if (comments.isNotEmpty)
                          Text('(${comments.length})', style: AppTheme.caption),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space3),
                    if (comments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space4),
                        decoration: BoxDecoration(
                          color: AppTheme.spacer,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              size: 16,
                              color: AppTheme.lightText,
                            ),
                            const SizedBox(width: AppTheme.space2),
                            Text('No replies yet.', style: AppTheme.caption),
                          ],
                        ),
                      )
                    else
                      for (final comment in comments) _buildComment(comment),
                  ],
                ),
              ),
            ),
            PageConstraints(
              padded: false,
              child: _buildReplyBar(state.isLoading),
            ),
          ],
        ),
      ),
    );
  }

  /// Category, who raised it, and the urgency flag — on the brand gradient,
  /// which is what the app uses to open a screen that is about one thing.
  Widget _buildHeader(Map<String, dynamic> detail, bool urgent) {
    // The detail branch of sp_helpdesk spells the category `categoryName`
    // (the list spells it `p_type_name`) and the flat `Unit`.
    final title =
        pick(detail, ['categoryName', 'p_type_name', 'title', 'subject']) ??
        'Complaint';
    final owner = pick(detail, ['name', 'owner_name']);
    final unit = pick(detail, ['Unit', 'flat_no', 'unit_no', 'flat']);
    // `date` arrives as "Jul 20 2026 6:43PM", which DateTime.tryParse cannot
    // read — show it as sent rather than as an em dash.
    final raised = pick(detail, ['date', 'created_at']);

    return GradientPanel(
      // An urgent complaint opens on red, so the page says what it is before
      // any of it is read.
      gradient: urgent ? AppTheme.duesGradient : AppTheme.heroGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headline.copyWith(
                    fontSize: 20,
                    color: AppTheme.white,
                  ),
                ),
              ),
              if (urgent) ...[
                const SizedBox(width: AppTheme.space2),
                const StatusChip(
                  label: 'Urgent',
                  color: AppTheme.error,
                  icon: Icons.priority_high_rounded,
                  onSurface: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Row(
            children: [
              InitialsAvatar(name: owner, size: 38),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner ?? 'Resident',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                    if (unit != null || raised != null)
                      Text(
                        [unit, raised].where((e) => e != null).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.onGradientMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Photos attached to the complaint, tappable to open full-screen.
  Widget _buildPhotos(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 15,
              color: AppTheme.lightText,
            ),
            const SizedBox(width: 5),
            Text('Photos', style: AppTheme.overline),
            const SizedBox(width: 6),
            Text(
              '${images.length}',
              style: AppTheme.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppTheme.space2),
            itemBuilder: (context, i) {
              final url = _imageUrl(images[i]);
              return InkWell(
                onTap: () => _openPhoto(url),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.network(
                    url,
                    height: 96,
                    width: 96,
                    fit: BoxFit.cover,
                    // A stored path whose file has since gone is not worth an
                    // error state — the tile just says nothing is there.
                    errorBuilder: (_, _, _) => Container(
                      height: 96,
                      width: 96,
                      color: AppTheme.spacer,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 20,
                        color: AppTheme.lightText,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The mobile uploader stores an absolute URL, the website's a path relative
  /// to the uploads route — so only the latter needs a prefix.
  String _imageUrl(String stored) {
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      return stored;
    }
    return '$baseUrl$webApiPrefix/uploads/file/'
        '${stored.startsWith('/') ? stored.substring(1) : stored}';
  }

  void _openPhoto(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppTheme.space4),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(AppTheme.space6),
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: AppTheme.white),
            ),
          ],
        ),
      ),
    );
  }

  /// The resident's own words, headed so the thread below reads as replies to
  /// something rather than as a conversation starting mid-air.
  Widget _buildComplaint(Map<String, dynamic> detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.format_quote_rounded,
              size: 15,
              color: AppTheme.lightText,
            ),
            const SizedBox(width: 5),
            Text('The complaint', style: AppTheme.overline),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Text(
            pick(detail, ['query', 'description', 'details'])!,
            style: AppTheme.body1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPicker(
    Map<String, dynamic> detail,
    List<Map<String, dynamic>> statuses,
  ) {
    final current = pickInt(detail, ['status', 'status_id']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: AppTheme.title),
        const SizedBox(height: 2),
        Text('Tap to update the resident.', style: AppTheme.caption),
        const SizedBox(height: AppTheme.space3),
        Wrap(
          spacing: AppTheme.space2,
          runSpacing: AppTheme.space2,
          children: [
            for (final s in statuses)
              if (pickInt(s, ['status_id', 'id']) != null)
                _StatusOption(
                  label: pick(s, ['status_name', 'name', 'status']) ?? 'Status',
                  selected: current == pickInt(s, ['status_id', 'id']),
                  onTap: () => _changeStatus(pickInt(s, ['status_id', 'id'])!),
                ),
          ],
        ),
      ],
    );
  }

  /// A reply, sided like the web thread: the resident on the left, the office
  /// on the right, keyed off `type` — anything that is not owner/member is the
  /// committee answering.
  Widget _buildComment(Map<String, dynamic> comment) {
    final type = (pick(comment, ['type']) ?? '').toLowerCase();
    final fromResident = type == 'owner' || type == 'member';
    // The server already labels a committee reply in `name` ("Priya Sharma
    // (admin)"), so prefer that over a generic word.
    final author =
        pick(comment, ['name', 'owner_name']) ??
        (fromResident ? 'Resident' : 'Committee');

    // The committee's own replies are filled in the brand blue and the
    // resident's are a plain grey plate — the same asymmetry every messaging
    // app uses to mean "mine" against "theirs".
    final avatar = InitialsAvatar(name: author, size: 28);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: fromResident
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (fromResident) ...[avatar, const SizedBox(width: AppTheme.space2)],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space3,
                vertical: AppTheme.space3 - 2,
              ),
              decoration: BoxDecoration(
                color: fromResident ? AppTheme.spacer : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTheme.radiusMd),
                  topRight: const Radius.circular(AppTheme.radiusMd),
                  // The squared-off corner points at whoever wrote it.
                  bottomLeft: Radius.circular(
                    fromResident ? 3 : AppTheme.radiusMd,
                  ),
                  bottomRight: Radius.circular(
                    fromResident ? AppTheme.radiusMd : 3,
                  ),
                ),
                border: fromResident
                    ? Border.all(color: AppTheme.border)
                    : null,
                boxShadow: fromResident
                    ? null
                    : AppTheme.primaryGlow(opacity: 0.16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author,
                    style: AppTheme.caption.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: fromResident
                          ? AppTheme.darkText
                          : AppTheme.onGradientMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pick(comment, ['description', 'comment', 'details']) ?? '',
                    style: AppTheme.body2.copyWith(
                      color: fromResident ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    // `dateTime`, and formatted by SQL — "Aug 12 2026 5:46PM"
                    // — which DateTime.tryParse cannot read, so it is shown
                    // as sent.
                    pick(comment, ['dateTime', 'created_at', 'date']) ?? '',
                    style: AppTheme.caption.copyWith(
                      fontSize: 10.5,
                      color: fromResident
                          ? AppTheme.deactivatedText
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!fromResident) ...[const SizedBox(width: AppTheme.space2), avatar],
        ],
      ),
    );
  }

  Widget _buildReplyBar(bool isLoading) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space4,
        AppTheme.space3 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              minLines: 1,
              maxLines: 4,
              style: AppTheme.body2,
              decoration: InputDecoration(
                hintText: 'Write a reply…',
                isDense: true,
                fillColor: AppTheme.spacer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space4,
                  vertical: AppTheme.space3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Container(
            decoration: BoxDecoration(
              gradient: isLoading ? null : AppTheme.primaryGradient,
              color: isLoading ? AppTheme.deactivatedText : null,
              shape: BoxShape.circle,
              boxShadow: isLoading ? null : AppTheme.primaryGlow(opacity: 0.22),
            ),
            child: IconButton(
              onPressed: isLoading ? null : _reply,
              icon: const Icon(Icons.send_rounded, size: 18),
              color: AppTheme.white,
              disabledColor: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// One status choice. Replaces ChoiceChip so the selected state matches the
/// app's own pills rather than Material's default grey.
class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(label);
    // An unrecognised status has no colour of its own; the brand blue reads
    // better as "chosen" than the fallback grey would.
    final accent = color == AppTheme.lightText ? AppTheme.primary : color;

    return Material(
      color: selected ? AppTheme.surfaceFor(accent) : AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space3,
            vertical: AppTheme.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: selected ? accent : AppTheme.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 14, color: accent),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? accent : AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
