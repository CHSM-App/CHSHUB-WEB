import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';

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
      .loadHelpdesk(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _refresh);
  }

  Future<void> _openTicket(int id) async {
    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .openHelpdeskTicket(id);
    if (!ok || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TicketSheet(ticketId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.helpdesk);

    return Scaffold(
      appBar: AppBar(title: const Text('Helpdesk')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                hint: 'Search complaints',
              ),
            ),
            Expanded(
              child: RowsView(
                rows: rows,
                onRefresh: _refresh,
                emptyIcon: Icons.sentiment_satisfied_alt_outlined,
                emptyTitle: 'No complaints',
                emptyMessage: 'Nothing needs attention right now.',
                builder: (items) => ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _buildTicket(items[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

    // `status` is an integer code (1 New, 2 In-Progress, …). Resolved against
    // the statuses the server sent rather than printing the number, and left
    // off entirely if that list has not arrived — a bare "1" tells a
    // secretary nothing.
    final status = _statusLabel(pickInt(row, ['status']));

    return AppCard(
      onTap: id == null ? null : () => _openTicket(id),
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
              if (status != null)
                StatusChip(label: status, color: statusColor(status)),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.caption,
            ),
          ],
          const SizedBox(height: 8),
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
                  [owner, flat].where((e) => e != null).join(' · '),
                  style: AppTheme.caption,
                ),
              ),
              Text(
                prettyDate(row['created_at'] ?? row['date']),
                style: AppTheme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The ticket thread: details, comments, status change and reply box.
class _TicketSheet extends ConsumerStatefulWidget {
  final int ticketId;

  const _TicketSheet({required this.ticketId});

  @override
  ConsumerState<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends ConsumerState<_TicketSheet> {
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

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              children: [
                // The detail branch of sp_helpdesk spells the category
                // `categoryName` (the list spells it `p_type_name`) and the
                // flat `Unit`, and the complaint itself is `query`.
                Text(
                  pick(detail, [
                        'categoryName',
                        'p_type_name',
                        'title',
                        'subject',
                      ]) ??
                      'Complaint',
                  style: AppTheme.headline.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    pick(detail, ['name', 'owner_name']),
                    pick(detail, ['Unit', 'flat_no', 'unit_no', 'flat']),
                    // `date` arrives as "Jul 20 2026 6:43PM", which
                    // DateTime.tryParse cannot read — show it as sent rather
                    // than as an em dash.
                    pick(detail, ['date', 'created_at']),
                  ].where((e) => e != null).join(' · '),
                  style: AppTheme.caption,
                ),
                if (pick(detail, ['query', 'description', 'details']) !=
                    null) ...[
                  const SizedBox(height: 14),
                  Text(
                    pick(detail, ['query', 'description', 'details'])!,
                    style: AppTheme.body2,
                  ),
                ],
                const SizedBox(height: 18),
                if (statuses.isNotEmpty) _buildStatusPicker(detail, statuses),
                const SizedBox(height: 18),
                Text('Replies', style: AppTheme.title),
                const SizedBox(height: 8),
                if (comments.isEmpty)
                  Text('No replies yet.', style: AppTheme.caption)
                else
                  for (final comment in comments) _buildComment(comment),
              ],
            ),
          ),
          _buildReplyBar(state.isLoading),
        ],
      ),
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in statuses)
              if (pickInt(s, ['status_id', 'id']) != null)
                ChoiceChip(
                  label: Text(
                    pick(s, ['status_name', 'name', 'status']) ?? 'Status',
                  ),
                  selected: current == pickInt(s, ['status_id', 'id']),
                  onSelected: (_) =>
                      _changeStatus(pickInt(s, ['status_id', 'id'])!),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final byAdmin = (pick(comment, ['type']) ?? '').toLowerCase().contains(
      'admin',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: byAdmin
            ? AppTheme.primary.withValues(alpha: 0.07)
            : AppTheme.chipBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pick(comment, ['description', 'comment', 'details']) ?? '',
            style: AppTheme.body2,
          ),
          const SizedBox(height: 4),
          Text(
            [
              // The server already labels a committee reply in `name`
              // ("Priya Sharma (admin)"), so prefer that over a generic word.
              pick(comment, ['name', 'owner_name']) ??
                  (byAdmin ? 'Committee' : null),
              // `dateTime`, and formatted by SQL — "Aug 12 2026 5:46PM" —
              // which DateTime.tryParse cannot read, so it is shown as sent.
              pick(comment, ['dateTime', 'created_at', 'date']),
            ].where((e) => e != null).join(' · '),
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(bool isLoading) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write a reply…',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: isLoading ? null : _reply,
            icon: const Icon(Icons.send, size: 18),
          ),
        ],
      ),
    );
  }
}
