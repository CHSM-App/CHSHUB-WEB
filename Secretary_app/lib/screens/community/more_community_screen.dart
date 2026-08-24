import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';

/// The read-mostly community lists, grouped as tabs.
///
/// Messages, polls, suggestions, events, meetings and documents are all the
/// same shape — a titled row with a date — so they share one renderer instead
/// of six near-identical screens.
class MoreCommunityScreen extends ConsumerStatefulWidget {
  const MoreCommunityScreen({super.key, this.initialTab = 0});

  /// Which tab to open on: 0 messages, 1 polls, 2 suggestions, 3 events,
  /// 4 meetings, 5 documents. Lets the create menu on the home shell land
  /// directly on the list the user asked for.
  final int initialTab;

  @override
  ConsumerState<MoreCommunityScreen> createState() =>
      _MoreCommunityScreenState();
}

class _MoreCommunityScreenState extends ConsumerState<MoreCommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 6,
    vsync: this,
    // Clamped: an out-of-range index throws rather than falling back, and the
    // caller passes a plain int.
    initialIndex: widget.initialTab.clamp(0, 5),
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vm = ref.read(communityViewModelProvider.notifier);
      vm.loadMessages();
      vm.loadPolls();
      vm.loadSuggestions();
      vm.loadEvents();
      vm.loadMeetings();
      vm.loadDocuments();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final state = ref.watch(communityViewModelProvider);
    final vm = ref.read(communityViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.border,
          indicatorColor: AppTheme.white,
          tabs: const [
            Tab(text: 'Messages'),
            Tab(text: 'Polls'),
            Tab(text: 'Suggestions'),
            Tab(text: 'Events'),
            Tab(text: 'Meetings'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _tab(
              rows: state.rows(CommunityKeys.messages),
              onRefresh: vm.loadMessages,
              icon: Icons.mail_outline,
              emptyTitle: 'No messages',
              emptyMessage: 'Messages residents send the committee show here.',
              titleKeys: const ['subject', 'title', 'message', 'description'],
            ),
            _tab(
              rows: state.rows(CommunityKeys.polls),
              onRefresh: vm.loadPolls,
              icon: Icons.poll_outlined,
              emptyTitle: 'No polls',
              titleKeys: const ['question', 'title', 'poll_name', 'name'],
            ),
            _tab(
              rows: state.rows(CommunityKeys.suggestions),
              onRefresh: () => vm.loadSuggestions(),
              icon: Icons.lightbulb_outline,
              emptyTitle: 'No suggestions',
              titleKeys: const [
                'subject',
                'title',
                'suggestion',
                'description',
              ],
            ),
            _tab(
              rows: state.rows(CommunityKeys.events),
              onRefresh: () => vm.loadEvents(),
              icon: Icons.celebration_outlined,
              emptyTitle: 'No events',
              titleKeys: const ['event_name', 'name', 'title'],
            ),
            _tab(
              rows: state.rows(CommunityKeys.meetings),
              onRefresh: () => vm.loadMeetings(),
              icon: Icons.groups_outlined,
              emptyTitle: 'No meetings',
              titleKeys: const ['meeting_name', 'name', 'title', 'subject'],
            ),
            _tab(
              rows: state.rows(CommunityKeys.documents),
              onRefresh: () => vm.loadDocuments(),
              icon: Icons.folder_outlined,
              emptyTitle: 'No documents',
              titleKeys: const ['file_name', 'name', 'title', 'document_name'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab({
    required rows,
    required Future<void> Function() onRefresh,
    required IconData icon,
    required String emptyTitle,
    required List<String> titleKeys,
    String? emptyMessage,
  }) {
    return RowsView(
      rows: rows,
      onRefresh: onRefresh,
      emptyIcon: icon,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      builder: (items) => ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: items.length,
        itemBuilder: (context, i) => _buildRow(items[i], icon, titleKeys),
      ),
    );
  }

  Widget _buildRow(
    Map<String, dynamic> row,
    IconData icon,
    List<String> titleKeys,
  ) {
    final title = pick(row, titleKeys);
    final subtitle = pick(row, [
      'description',
      'details',
      'message',
      'venue',
      'location',
      'owner_name',
      'name',
    ]);
    final status = pick(row, ['status', 'status_name']);

    // Unread messages come back with read/seen flags — worth surfacing since
    // the point of the tab is to notice them.
    final unread = row.containsKey('is_read')
        ? !asBool(row['is_read'])
        : (row.containsKey('seen_status')
              ? !asBool(row['seen_status'])
              : false);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ?? 'Item',
                        style: AppTheme.title.copyWith(
                          fontSize: 15,
                          fontWeight: unread
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (unread)
                      const StatusChip(label: 'New', color: AppTheme.primary),
                  ],
                ),
                if (subtitle != null && subtitle != title) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      prettyDate(
                        row['date'] ??
                            row['created_at'] ??
                            row['event_date'] ??
                            row['meeting_date'],
                      ),
                      style: AppTheme.caption,
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 8),
                      StatusChip(label: status, color: statusColor(status)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
