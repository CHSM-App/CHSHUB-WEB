import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';
import 'form_fields.dart';

/// Publish a notice to a chosen audience.
///
/// The fields are the website's, in its order: title, description, valid-to
/// and recipients — `notice_search.aspx`'s modal, less the Category the
/// notice_master table has no column for. Passing [existing] edits that notice
/// instead of creating one, which is the same PUT the website's edit modal
/// sends.
///
/// The list this form saves into lives in [AnnouncementsScreen], alongside
/// meetings and events; this file is only the form.
class NoticeFormScreen extends ConsumerStatefulWidget {
  const NoticeFormScreen({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends ConsumerState<NoticeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  int? _recipientsId;
  DateTime? _validTo;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final row = widget.existing;

    _titleController = TextEditingController(
      text: row == null
          ? ''
          : pick(row, ['name', 'title', 'notice_name']) ?? '',
    );
    _descriptionController = TextEditingController(
      text: row == null ? '' : pick(row, ['description', 'details']) ?? '',
    );

    if (row != null) {
      _recipientsId = pickInt(row, ['recipients_id', 'recipientsId']);
      final raw = row['valid_to'] ?? row['validTo'];
      _validTo = raw is DateTime ? raw : DateTime.tryParse('$raw');
    }

    // The audience picker needs its lookup, which the list screen loads
    // alongside the notices — but the form can be reached before that lands,
    // so it asks for its own rather than rendering an empty dropdown.
    Future.microtask(() {
      if (mounted) {
        ref.read(communityViewModelProvider.notifier).loadNotices();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// yyyy-MM-dd, which is what the route's date validator accepts.
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final description = _descriptionController.text.trim();
    final request = NoticeRequest(
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      recipientsId: _recipientsId,
      validTo: _validTo == null ? null : _iso(_validTo!),
    );

    final notifier = ref.read(communityViewModelProvider.notifier);
    final id = _isEdit ? pickInt(widget.existing!, ['notice_id', 'id']) : null;

    final ok = _isEdit && id != null
        ? await notifier.updateNotice(id, request)
        : await notifier.createNotice(request);

    if (ok && mounted) Navigator.pop(context);
  }

  /// What the chosen group means, spelled out under the picker.
  ///
  /// The ids come from sp_notice_master/GetAllRecipients and the server maps
  /// them to real people in web/lib/notify.js. Saying who a group reaches is
  /// the difference between picking one confidently and guessing.
  String _audienceNote() => switch (_recipientsId) {
    1 => 'Every flat owner in the society.',
    2 => 'Every tenant in the society.',
    3 => 'Owners and tenants alike.',
    4 => 'Committee members only.',
    5 => 'Everyone — owners, tenants and committee.',
    _ => 'Residents in the chosen group get a push notification.',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final recipients = state.items(CommunityKeys.noticeRecipients);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit notice' : 'New notice')),
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
                        Icons.campaign_rounded,
                        color: AppTheme.white,
                        size: 26,
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Edit notice' : 'Announce something',
                              style: AppTheme.headline.copyWith(
                                fontSize: 18,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? 'Changes show on the board straight away.'
                                  : 'Everyone in the group you choose gets a '
                                        'notification the moment it is '
                                        'published.',
                              style: const TextStyle(
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
                 * Two cards — what the notice says, and who sees it and until
                 * when — rather than one run of four fields. The website's
                 * modal shows the same four in the same order; the grouping is
                 * the only thing added, because a phone reads a long textarea
                 * followed by two pickers as one undivided block.
                 */
                FormSection(
                  title: 'Notice',
                  icon: Icons.article_outlined,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      // notice_master.name is nvarchar(150) and the route
                      // rejects anything longer, so the field stops there
                      // rather than letting the save fail.
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter announcement title',
                        prefixIcon: Icon(Icons.title_rounded, size: 20),
                        counterText: '',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter description',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space3),
                FormSection(
                  title: 'Audience',
                  icon: Icons.groups_outlined,
                  children: [
                    if (recipients.isNotEmpty) ...[
                      AppDropdown<int>(
                        value: _recipientsId,
                        label: 'Recipients',
                        icon: Icons.groups_outlined,
                        isDense: false,
                        options: [
                          for (final r in recipients)
                            if (pickInt(r, ['recipients_id', 'id']) != null)
                              AppOption(
                                pickInt(r, ['recipients_id', 'id'])!,
                                pick(r, ['name', 'recipients', 'title']) ??
                                    'Group',
                              ),
                        ],
                        onChanged: (v) => setState(() => _recipientsId = v),
                      ),
                      const SizedBox(height: AppTheme.space2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            size: 14,
                            color: AppTheme.lightText,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _audienceNote(),
                              style: AppTheme.caption.copyWith(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    PickerField(
                      label: 'Valid until',
                      icon: Icons.event_outlined,
                      value: _validTo == null
                          ? 'No end date'
                          : prettyDate(_validTo),
                      // Clearing is the only way back to "no end date", which
                      // the date picker itself cannot express.
                      onClear: _validTo == null
                          ? null
                          : () => setState(() => _validTo = null),
                      onTap: () async {
                        final picked = await showSingleDateDialog(
                          context: context,
                          initial: _validTo ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _validTo = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space6),
                BusyButton(
                  label: _isEdit ? 'Save changes' : 'Publish notice',
                  icon: _isEdit ? Icons.check_rounded : Icons.campaign_rounded,
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
