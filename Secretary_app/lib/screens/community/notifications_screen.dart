import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'helpdesk_screen.dart';

/// The alerts behind the bell.
///
/// The server returns only unseen rows, so everything here is unread and
/// tapping one both clears it and opens what it is about.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() =>
      ref.read(communityViewModelProvider.notifier).loadNotifications();

  /// Clears the alert, then opens the screen it points at.
  ///
  /// Only helpdesk has a screen of its own so far; the rest clear and stay
  /// put rather than navigating somewhere that does not exist.
  Future<void> _open(Map<String, dynamic> row) async {
    final id = pickInt(row, ['notify_status_id', 'id']);
    if (id != null) {
      await ref
          .read(communityViewModelProvider.notifier)
          .markNotificationSeen(id);
    }

    if (!mounted) return;

    if (_kindOf(row) == _Kind.helpdesk) {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const HelpdeskScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RowsView(
          rows: rows,
          onRefresh: _refresh,
          emptyIcon: Icons.notifications_none_rounded,
          emptyTitle: 'All caught up',
          emptyMessage: 'New alerts will appear here.',
          builder: (items) => PageConstraints(
            padded: false,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space5,
                AppTheme.space4,
                AppTheme.space5,
                AppTheme.space8,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.space3),
              itemBuilder: (context, i) => _NotificationCard(
                row: items[i],
                kind: _kindOf(items[i]),
                onTap: () => _open(items[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What an alert is about, which decides its colour, icon and destination.
enum _Kind { helpdesk, notice, event, meeting, poll, other }

_Kind _kindOf(Map<String, dynamic> row) {
  final type = (pick(row, ['notification_type', 'type']) ?? '').toLowerCase();

  if (type.contains('helpdesk') || type.contains('complaint')) {
    return _Kind.helpdesk;
  }
  if (type.contains('notice')) return _Kind.notice;
  if (type.contains('event')) return _Kind.event;
  if (type.contains('meeting')) return _Kind.meeting;
  if (type.contains('poll') || type.contains('vote')) return _Kind.poll;
  return _Kind.other;
}

({IconData icon, Color color, String label}) _styleFor(_Kind kind) =>
    switch (kind) {
      _Kind.helpdesk => (
        icon: Icons.support_agent_outlined,
        color: AppTheme.primary,
        label: 'Helpdesk',
      ),
      _Kind.notice => (
        icon: Icons.campaign_outlined,
        color: AppTheme.info,
        label: 'Notice',
      ),
      _Kind.event => (
        icon: Icons.celebration_outlined,
        color: AppTheme.success,
        label: 'Event',
      ),
      _Kind.meeting => (
        icon: Icons.groups_outlined,
        color: AppTheme.warning,
        label: 'Meeting',
      ),
      _Kind.poll => (
        icon: Icons.how_to_vote_outlined,
        color: AppTheme.info,
        label: 'Poll',
      ),
      _Kind.other => (
        icon: Icons.notifications_none_rounded,
        color: AppTheme.lightText,
        label: 'Alert',
      ),
    };

/// One alert.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.row,
    required this.kind,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final _Kind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(kind);
    final title = pick(row, ['title', 'name']) ?? style.label;
    final body = pick(row, ['body', 'description', 'message']);
    // Already relative — the procedure runs it through GetRelativeTime, so it
    // arrives as "2 hours ago" rather than a date to format.
    final when = pick(row, ['timestamp', 'created_at', 'date']);

    return AppCard(
      onTap: onTap,
      accent: style.color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconPlate(icon: style.icon, color: style.color),
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
                        style: AppTheme.title.copyWith(fontSize: 14.5),
                      ),
                    ),
                    // Every row here is unread — the server sends no others —
                    // so the dot marks the whole list rather than a state that
                    // varies within it.
                    const SizedBox(width: AppTheme.space2),
                    Container(
                      height: 8,
                      width: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: style.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                if (body != null && body.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body2.copyWith(height: 1.35),
                  ),
                ],
                const SizedBox(height: AppTheme.space2),
                Row(
                  children: [
                    StatusChip(label: style.label, color: style.color),
                    const Spacer(),
                    if (when != null)
                      Text(
                        when,
                        style: AppTheme.caption.copyWith(fontSize: 11),
                      ),
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
