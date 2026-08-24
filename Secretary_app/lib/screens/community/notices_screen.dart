import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

/// Notices and announcements.
class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
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
      .loadNotices(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _refresh);
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this notice?'),
        content: const Text('Residents will no longer see it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(communityViewModelProvider.notifier).deleteNotice(id);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.notices);

    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _NoticeForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New notice'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                hint: 'Search notices',
              ),
            ),
            Expanded(
              child: RowsView(
                rows: rows,
                onRefresh: _refresh,
                emptyIcon: Icons.campaign_outlined,
                emptyTitle: 'No notices',
                emptyMessage: 'Publish one to tell residents something.',
                builder: (items) => ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _buildNotice(items[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice(Map<String, dynamic> row) {
    final id = pickInt(row, ['notice_id', 'id']);
    final title = pick(row, ['name', 'title', 'notice_name']);
    final description = pick(row, ['description', 'details']);
    final validTo = row['valid_to'] ?? row['validTo'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title ?? 'Notice',
                  style: AppTheme.title.copyWith(fontSize: 15),
                ),
              ),
              if (id != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppTheme.error,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(id),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description, style: AppTheme.caption),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                prettyDate(row['date'] ?? row['created_at']),
                style: AppTheme.caption,
              ),
              if (validTo != null) ...[
                const Spacer(),
                StatusChip(
                  label: 'Until ${prettyDate(validTo)}',
                  color: AppTheme.info,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Publish a notice to a chosen audience.
class _NoticeForm extends ConsumerStatefulWidget {
  const _NoticeForm();

  @override
  ConsumerState<_NoticeForm> createState() => _NoticeFormState();
}

class _NoticeFormState extends ConsumerState<_NoticeForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _recipientsId;
  DateTime? _validTo;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .createNotice(
          NoticeRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            recipientsId: _recipientsId,
            validTo: _validTo == null
                ? null
                : '${_validTo!.year.toString().padLeft(4, '0')}-'
                      '${_validTo!.month.toString().padLeft(2, '0')}-'
                      '${_validTo!.day.toString().padLeft(2, '0')}',
          ),
        );

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final recipients = state.items(CommunityKeys.noticeRecipients);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              Text('New notice', style: AppTheme.headline),
              const SizedBox(height: 6),
              Text(
                'Residents in the chosen group get a push notification.',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              if (recipients.isNotEmpty) ...[
                const SizedBox(height: 14),
                AppDropdown<int>(
                  value: _recipientsId,
                  label: 'Send to',
                  icon: Icons.groups_outlined,
                  isDense: false,
                  options: [
                    for (final r in recipients)
                      if (pickInt(r, ['recipients_id', 'id']) != null)
                        AppOption(
                          pickInt(r, ['recipients_id', 'id'])!,
                          pick(r, ['name', 'recipients', 'title']) ?? 'Group',
                        ),
                  ],
                  onChanged: (v) => setState(() => _recipientsId = v),
                ),
              ],
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showSingleDateDialog(
                    context: context,
                    initial: _validTo ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _validTo = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Show until (optional)',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(
                    _validTo == null ? 'No end date' : prettyDate(_validTo),
                    style: AppTheme.body2,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text('Publish notice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
