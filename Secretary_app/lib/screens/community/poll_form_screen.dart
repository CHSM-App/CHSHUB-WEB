import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';
import 'form_fields.dart';

/// Start a poll.
///
/// The fields are Vote.aspx's, in its order: topic, description, expiry, the
/// options, the audience and the two voting rules. There is no edit mode —
/// sp_polls has no update branch, and a question changed after people had
/// voted would leave those votes answering something else.
class PollFormScreen extends ConsumerStatefulWidget {
  const PollFormScreen({super.key});

  @override
  ConsumerState<PollFormScreen> createState() => _PollFormScreenState();
}

/// Who a poll is put to, as ddlAudience on Vote.aspx offered them.
///
/// The values are the website's own — the route maps them to recipient groups
/// itself — so they are sent as strings rather than converted here.
enum _Audience {
  all('1', 'All members', 'Owners, tenants and the committee.'),
  committee('2', 'Committee', 'Committee members only.'),
  owners('3', 'Owners', 'Every flat owner in the society.'),
  tenants('4', 'Tenants', 'Every tenant in the society.');

  const _Audience(this.value, this.label, this.note);

  final String value;
  final String label;
  final String note;
}

class _PollFormScreenState extends ConsumerState<PollFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Starts at two because the route rejects a poll with fewer.
  final _optionControllers = [TextEditingController(), TextEditingController()];

  DateTime? _expiry;
  _Audience _audience = _Audience.all;
  bool _allowMultipleVotes = false;
  bool _oneVotePerUnit = false;

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// yyyy-MM-dd, which is what the route's date validator accepts.
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    setState(() => _optionControllers.removeAt(index).dispose());
  }

  /// True while a save is in flight.
  ///
  /// Tracked here rather than read off the shared community state: that state
  /// is written by every other community fetch too, so it both goes false
  /// before this save has finished with it and goes true for loads that have
  /// nothing to do with this form. A second tap while the first save is still
  /// running is what left the screen sitting there — the view model's guard
  /// returns false for it without running anything or reporting an error, and
  /// a false result is what decides not to pop.
  bool _saving = false;

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // The date is a picker, which no validator covers.
    if (_expiry == null) {
      showAppSnack(context, 'Pick the date voting closes.', success: false);
      return;
    }

    final options = [
      for (final c in _optionControllers)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ];

    if (options.length < 2) {
      showAppSnack(
        context,
        'Give the poll at least two options.',
        success: false,
      );
      return;
    }

    if (options.toSet().length != options.length) {
      showAppSnack(context, 'Two options say the same thing.', success: false);
      return;
    }

    final description = _descriptionController.text.trim();
    final request = PollRequest(
      topic: _topicController.text.trim(),
      description: description.isEmpty ? null : description,
      expiryDate: _iso(_expiry!),
      options: options,
      audience: _audience.value,
      allowMultipleVotes: _allowMultipleVotes,
      oneVotePerUnit: _oneVotePerUnit,
    );

    setState(() => _saving = true);

    final bool ok;
    try {
      ok = await ref
          .read(communityViewModelProvider.notifier)
          .createPoll(request);
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Without this the screen stayed put and said nothing when the server
    // refused a poll ("Poll options cannot contain a comma"): createPoll
    // returns false, which is correctly read as "do not pop", but the reason
    // was only ever written into the view model state and never shown here.
    listenForFeedback(ref, context, communityViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New poll')),
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
                        Icons.how_to_vote_rounded,
                        color: AppTheme.white,
                        size: 26,
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ask the society',
                              style: AppTheme.headline.copyWith(
                                fontSize: 18,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Everyone in the group you choose is asked to '
                              'vote before the closing date.',
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
                FormSection(
                  title: 'Question',
                  icon: Icons.help_outline_rounded,
                  children: [
                    TextFormField(
                      controller: _topicController,
                      textCapitalization: TextCapitalization.sentences,
                      // Polls.Topic is nvarchar(200) and the route rejects
                      // anything longer.
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        hintText: 'What is being decided',
                        prefixIcon: Icon(Icons.title_rounded, size: 20),
                        counterText: '',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a topic'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Any background residents should have',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space3),
                FormSection(
                  title: 'Options',
                  icon: Icons.list_alt_rounded,
                  children: [
                    for (var i = 0; i < _optionControllers.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[i],
                              textCapitalization: TextCapitalization.sentences,
                              maxLength: 100,
                              decoration: InputDecoration(
                                labelText: 'Option ${i + 1}',
                                hintText: i == 0 ? 'Yes' : 'No',
                                counterText: '',
                                isDense: true,
                              ),
                              validator: (v) {
                                final text = v?.trim() ?? '';
                                // The first two are the minimum the route
                                // accepts; any the user added beyond them may
                                // be left blank and are simply dropped.
                                if (i < 2 && text.isEmpty) {
                                  return 'Enter an option';
                                }
                                // sp_PollOptions splits the joined string on
                                // commas, so one here would silently become
                                // two options.
                                if (text.contains(',')) {
                                  return 'No commas, please';
                                }
                                return null;
                              },
                            ),
                          ),
                          // Only past the first two: removing either would
                          // leave a poll the route rejects.
                          if (_optionControllers.length > 2 && i >= 2)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: AppTheme.error,
                              tooltip: 'Remove',
                              onPressed: () => _removeOption(i),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppTheme.space2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add option'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space3),
                FormSection(
                  title: 'Voting',
                  icon: Icons.groups_outlined,
                  children: [
                    AppDropdown<_Audience>(
                      value: _audience,
                      label: 'Who votes',
                      icon: Icons.groups_outlined,
                      isDense: false,
                      options: [
                        for (final a in _Audience.values) AppOption(a, a.label),
                      ],
                      onChanged: (v) =>
                          setState(() => _audience = v ?? _Audience.all),
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
                            _audience.note,
                            style: AppTheme.caption.copyWith(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    PickerField(
                      label: 'Voting closes',
                      icon: Icons.event_outlined,
                      value: _expiry == null
                          ? 'Pick a date'
                          : prettyDate(_expiry),
                      onTap: () async {
                        final picked = await showSingleDateDialog(
                          context: context,
                          initial:
                              _expiry ??
                              DateTime.now().add(const Duration(days: 7)),
                          // A poll that closed before it opened would take no
                          // votes at all.
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _expiry = picked);
                      },
                    ),
                    const SizedBox(height: AppTheme.space2),
                    SwitchListTile.adaptive(
                      value: _allowMultipleVotes,
                      onChanged: (v) => setState(() => _allowMultipleVotes = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Allow more than one option',
                        style: AppTheme.body2,
                      ),
                      subtitle: Text(
                        _allowMultipleVotes
                            ? 'Residents can pick several options.'
                            : 'A second vote moves the first, rather than '
                                  'adding to it.',
                        style: AppTheme.caption.copyWith(fontSize: 11.5),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      value: _oneVotePerUnit,
                      onChanged: (v) => setState(() => _oneVotePerUnit = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text('One vote per flat', style: AppTheme.body2),
                      subtitle: Text(
                        _oneVotePerUnit
                            ? 'Once someone in a flat votes, the flat is done.'
                            : 'Every resident votes for themselves.',
                        style: AppTheme.caption.copyWith(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space6),
                BusyButton(
                  label: 'Start poll',
                  icon: Icons.how_to_vote_rounded,
                  busy: _saving,
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
