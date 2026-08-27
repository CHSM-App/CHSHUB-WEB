import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';
import 'suggestion_form_screen.dart';

/// One tab's identity - its list key, its accent and how a row of it reads.
///
/// Lists that are genuinely different things were previously drawn by one
/// renderer against a pile of fallback column names, so every row came out as
/// title + date whatever it was. Each kind now says what it is worth showing.
class _Section {
  const _Section({
    required this.label,
    required this.listKey,
    required this.icon,
    required this.color,
    required this.titleKeys,
    required this.bodyKeys,
    required this.dateKeys,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String label;
  final String listKey;
  final IconData icon;
  final Color color;
  final List<String> titleKeys;
  final List<String> bodyKeys;
  final List<String> dateKeys;
  final String emptyTitle;
  final String emptyMessage;
}

/// The messages residents send in, and the suggestions they put forward.
class MoreCommunityScreen extends ConsumerStatefulWidget {
  const MoreCommunityScreen({super.key, this.initialTab = 0});

  /// Which tab to open on: 0 messages, 1 suggestions. Lets the create menu on
  /// the home shell land directly on the list the user asked for.
  final int initialTab;

  @override
  ConsumerState<MoreCommunityScreen> createState() =>
      _MoreCommunityScreenState();
}

class _MoreCommunityScreenState extends ConsumerState<MoreCommunityScreen>
    with SingleTickerProviderStateMixin {
  /// Column names come from two unrelated stored procedures, so each section
  /// still lists the spellings it may arrive under - but only the ones that
  /// procedure actually returns, rather than the union of both.
  static const List<_Section> _sections = [
    _Section(
      label: 'Messages',
      listKey: CommunityKeys.messages,
      icon: Icons.forum_rounded,
      color: AppTheme.primary,
      titleKeys: ['subject', 'title', 'message', 'description'],
      bodyKeys: ['message', 'description', 'details'],
      dateKeys: ['date', 'created_at', 'msg_date'],
      emptyTitle: 'No messages',
      emptyMessage: 'Messages residents send the committee show up here.',
    ),
    _Section(
      label: 'Suggestions',
      listKey: CommunityKeys.suggestions,
      icon: Icons.lightbulb_rounded,
      color: AppTheme.warning,
      titleKeys: ['subject', 'title', 'suggestion'],
      bodyKeys: ['details', 'description'],
      dateKeys: ['date', 'created_at', 'sug_date'],
      emptyTitle: 'No suggestions',
      emptyMessage: 'Ideas residents put forward collect here.',
    ),
  ];

  /// The suggestions tab, whose floating button files a new one. Named rather
  /// than written as `1` at each use so the two stay in step if a tab is added.
  static const _suggestionsTab = 1;

  late final TabController _tabs = TabController(
    length: _sections.length,
    vsync: this,
    // Clamped: an out-of-range index throws rather than falling back, and the
    // caller passes a plain int.
    initialIndex: widget.initialTab.clamp(0, _sections.length - 1),
  );

  @override
  void initState() {
    super.initState();
    // The segmented bar marks the live tab and the floating button belongs to
    // one tab only, so both redraw as the user swipes rather than only on tap.
    _tabs.addListener(_onTabChanged);
    Future.microtask(() {
      final vm = ref.read(communityViewModelProvider.notifier);
      vm.loadMessages();
      vm.loadSuggestions();
    });
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh(String listKey) {
    final vm = ref.read(communityViewModelProvider.notifier);
    return listKey == CommunityKeys.messages
        ? vm.loadMessages()
        : vm.loadSuggestions();
  }

  /// Open a message in full, and mark it read.
  ///
  /// The list truncates the body to two lines, which is enough to recognise a
  /// message but not to answer one - so the whole thing gets a sheet. Reading
  /// it is what marks it read: the secretary has now seen it, and asking them
  /// to press a second button to say so would leave the badge lying whenever
  /// they did not bother.
  void _openMessage(Map<String, dynamic> row) {
    final id = asInt(row['r_id'] ?? row['id']);
    if (id != null && asIntOr(row['view_status'], 1) == 0) {
      ref.read(communityViewModelProvider.notifier).markMessageRead(id);
    }

    final author = pick(row, ['owner_name', 'name']);
    final flat = pick(row, ['flat_no', 'unit_no']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => _MessageSheet(row: row, author: author, flat: flat),
    );
  }

  /// File a new suggestion, or edit one already on the list.
  Future<void> _openSuggestionForm({Map<String, dynamic>? row}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestionFormScreen(
          suggestionId: row == null ? null : asInt(row['sug_id'] ?? row['id']),
          initial: row,
        ),
      ),
    );
    // The view model reloads the list itself on a successful save, so there
    // is nothing to do with the result here.
  }

  Future<void> _deleteSuggestion(Map<String, dynamic> row) async {
    final id = asInt(row['sug_id'] ?? row['id']);
    if (id == null) return;

    final subject = pick(row, ['subject', 'title']) ?? 'this suggestion';
    final confirmed = await confirmAction(
      context,
      title: 'Delete suggestion?',
      message: '"$subject" will be removed for everyone.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !mounted) return;
    await ref.read(communityViewModelProvider.notifier).deleteSuggestion(id);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final state = ref.watch(communityViewModelProvider);
    final onSuggestions = _tabs.index == _suggestionsTab;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Community'),
        elevation: 0,
        // The segmented control Announcements and the post-dated cheques
        // screen use, rather than a row of pills in the body: it belongs to
        // the app bar the way a page's own tabs do, and two full-width pills
        // floating above the list read as buttons rather than as tabs.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(SegmentedTabBar.height),
          child: SegmentedTabBar(
            selectedIndex: _tabs.index,
            // Drives the controller rather than setState, so a tap here and a
            // swipe of the view below end in the same place.
            onSelected: _tabs.animateTo,
            tabs: [
              for (final s in _sections)
                SegmentTab(
                  label: s.label,
                  icon: s.icon,
                  count: state.rows(s.listKey).value?.items.length,
                ),
            ],
          ),
        ),
      ),
      // Only the suggestions tab can be added to: messages are written by
      // residents, and a committee member has no way to send one from here.
      floatingActionButton: onSuggestions
          ? FloatingActionButton.extended(
              onPressed: _openSuggestionForm,
              backgroundColor: AppTheme.warning,
              foregroundColor: AppTheme.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add suggestion'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (final s in _sections)
                    _SectionList(
                      section: s,
                      rows: state.rows(s.listKey),
                      onRefresh: () => _refresh(s.listKey),
                      onTap: s.listKey == CommunityKeys.messages
                          ? _openMessage
                          : (row) => _openSuggestionForm(row: row),
                      onDelete: s.listKey == CommunityKeys.suggestions
                          ? _deleteSuggestion
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab's list.
class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.section,
    required this.rows,
    required this.onRefresh,
    required this.onTap,
    this.onDelete,
  });

  final _Section section;
  final Rows rows;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic> row) onTap;
  final void Function(Map<String, dynamic> row)? onDelete;

  @override
  Widget build(BuildContext context) {
    return RowsView(
      rows: rows,
      onRefresh: onRefresh,
      emptyIcon: section.icon,
      emptyTitle: section.emptyTitle,
      emptyMessage: section.emptyMessage,
      builder: (items) => PageConstraints(
        padded: false,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppTheme.space4,
            AppTheme.space4,
            AppTheme.space4,
            // Clears the floating button on the tab that has one.
            onDelete == null ? AppTheme.space8 : AppTheme.space8 * 2,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _SectionCard(
            section: section,
            row: items[i],
            onTap: () => onTap(items[i]),
            onDelete: onDelete == null ? null : () => onDelete!(items[i]),
          ),
        ),
      ),
    );
  }
}

/// A row, drawn for what it is.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.row,
    required this.onTap,
    this.onDelete,
  });

  final _Section section;
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final title = pick(row, section.titleKeys) ?? 'Untitled';
    final body = pick(row, section.bodyKeys);
    final status = pick(row, ['status', 'status_name']);
    final author = pick(row, ['owner_name', 'name', 'flat_no', 'unit_no']);
    final date = pick(row, section.dateKeys);

    // The footer's parts, each included only when the row actually carries
    // it. The sender is already on the avatar for a message; on the other tab
    // it is the only place the name appears.
    final meta = <String>[
      if (date != null) relativeDate(date),
      if (author != null && section.listKey != CommunityKeys.messages) author,
    ];

    // Unread messages come back with read/seen flags - worth surfacing since
    // the point of the tab is to notice them. sp_owner_master returns
    // view_status, where 0 means unseen.
    final unread = section.listKey == CommunityKeys.messages
        ? asIntOr(row['view_status'], 1) == 0
        : (row.containsKey('is_read') ? !asBool(row['is_read']) : false);

    return AppCard(
      onTap: onTap,
      // On the messages tab the spine is spent on one that still needs
      // reading, so it marks the few among many. A suggestion has no such
      // state - every row is alike - so it carries the section's colour and
      // the tab reads as a set rather than as a column of plain boxes.
      accent: section.listKey == CommunityKeys.messages
          ? (unread ? section.color : null)
          : section.color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A message is from a person, so it gets their initials. A
          // suggestion is a thing the society holds, and gets the glyph.
          if (section.listKey == CommunityKeys.messages && author != null)
            InitialsAvatar(name: author, size: 42)
          else
            IconPlate(icon: section.icon, color: section.color, size: 42),
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
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.subtitle.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: AppTheme.space2),
                      StatusChip(label: 'New', color: section.color),
                    ],
                    // Edit is the whole card's tap, so the overflow carries
                    // only the destructive action - which should never be a
                    // stray thumb landing on a list.
                    if (onDelete != null)
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.deactivatedText,
                          ),
                          onPressed: onDelete,
                        ),
                      ),
                  ],
                ),
                if (body != null && body != title) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body2,
                  ),
                ],
                // The footer only appears when there is something to put in
                // it. sp_suggestion_request_master's grid returns no date at
                // all, so an always-drawn row left every suggestion card with
                // a clock against an em dash — a stamp that said nothing and
                // a band of empty space under every row.
                if (meta.isNotEmpty || status != null) ...[
                  const SizedBox(height: AppTheme.space2 + 2),
                  Row(
                    children: [
                      if (meta.isNotEmpty)
                        Flexible(
                          child: Text(
                            meta.join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.caption,
                          ),
                        ),
                      if (status != null) ...[
                        if (meta.isNotEmpty)
                          const SizedBox(width: AppTheme.space2),
                        StatusChip(label: status, color: statusColor(status)),
                      ],
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
}

/// One message, in full.
///
/// The list shows two lines of the body; this is where the rest of it, and
/// who sent it, actually live.
class _MessageSheet extends StatelessWidget {
  const _MessageSheet({
    required this.row,
    required this.author,
    required this.flat,
  });

  final Map<String, dynamic> row;
  final String? author;
  final String? flat;

  @override
  Widget build(BuildContext context) {
    final subject = pick(row, ['subject', 'title']);
    final body = pick(row, ['message', 'description', 'details']);
    final date = pick(row, ['date', 'created_at', 'msg_date']);
    final contact = pick(row, ['contact_no', 'mobile_no', 'phone']);
    final email = pick(row, ['email', 'email_id']);

    return AppBottomSheet(
      title: subject ?? 'Message',
      subtitle: relativeDate(date),
      children: [
        Row(
          children: [
            InitialsAvatar(name: author ?? '?', size: 46),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    author ?? 'Unknown sender',
                    style: AppTheme.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (flat != null) ...[
                    const SizedBox(height: 2),
                    Text(flat!, style: AppTheme.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            // A message with no body is a subject line and nothing else -
            // saying so beats an empty panel that reads as a failed load.
            body ?? 'This message has no further text.',
            style: AppTheme.body1.copyWith(height: 1.45),
          ),
        ),
        // Only shown when the row carries them: sp_owner_master's view does
        // not promise either column, and an empty "Contact" row is worse
        // than none at all.
        if (contact != null || email != null) ...[
          const SizedBox(height: AppTheme.space5),
          if (contact != null)
            _ContactRow(icon: Icons.call_outlined, value: contact),
          if (email != null) ...[
            if (contact != null) const SizedBox(height: AppTheme.space3),
            _ContactRow(icon: Icons.mail_outline_rounded, value: email),
          ],
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.deactivatedText),
        const SizedBox(width: AppTheme.space3),
        Expanded(
          child: Text(
            value,
            style: AppTheme.body2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
