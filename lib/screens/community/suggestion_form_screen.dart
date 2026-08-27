import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import 'form_fields.dart';

/// File a suggestion or request, or edit one already on the list.
///
/// The fields are suggestion_request.aspx's modal, in its order and with its
/// rules: a subject and the suggestion itself, both required. The website
/// carried nothing else — no category, no priority — and neither does this.
///
/// Unlike the poll form there *is* an edit mode: sp_suggestion_request_master
/// has one Update branch serving both, keyed on whether sug_id is 0, and the
/// website's grid offers an edit button per row.
class SuggestionFormScreen extends ConsumerStatefulWidget {
  const SuggestionFormScreen({super.key, this.suggestionId, this.initial});

  /// Null when filing a new one; the sug_id being edited otherwise.
  final int? suggestionId;

  /// The row being edited, so the fields open on what is already stored.
  final Map<String, dynamic>? initial;

  @override
  ConsumerState<SuggestionFormScreen> createState() =>
      _SuggestionFormScreenState();
}

class _SuggestionFormScreenState extends ConsumerState<SuggestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _detailsController;

  bool get _isEdit => widget.suggestionId != null;

  /// The column widths sp_suggestion_request_master declares, which the route
  /// passes straight through as NVarChar(250) and NVarChar(500). Capping the
  /// fields here means a long suggestion is refused while it is still being
  /// typed, rather than silently truncated on the way to the database.
  static const _subjectMax = 250;
  static const _detailsMax = 500;

  @override
  void initState() {
    super.initState();
    final row = widget.initial;
    _subjectController = TextEditingController(
      text: row == null ? '' : (row['subject'] ?? '').toString(),
    );
    _detailsController = TextEditingController(
      text: row == null ? '' : (row['details'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  /// True while a save is in flight.
  ///
  /// Tracked on the form rather than read off the shared community state, for
  /// the reason the poll form gives: that state is written by every other
  /// community fetch too, so it both clears before this save is done with it
  /// and sets for loads that have nothing to do with this form.
  bool _saving = false;

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final request = SuggestionRequest(
      subject: _subjectController.text.trim(),
      details: _detailsController.text.trim(),
    );

    setState(() => _saving = true);

    final vm = ref.read(communityViewModelProvider.notifier);
    final ok = _isEdit
        ? await vm.updateSuggestion(widget.suggestionId!, request)
        : await vm.createSuggestion(request);

    if (!mounted) return;
    setState(() => _saving = false);

    // The view model reports the outcome through the shared feedback listener
    // on the list screen, so nothing is shown here — popping is the whole
    // response. A failure leaves the form up with what was typed still in it.
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit suggestion' : 'Add suggestion'),
        elevation: 0,
      ),
      body: SafeArea(
        // Caps the column on a tablet or a browser window, where a two-field
        // form stretched to full width reads as a mistake.
        child: PageConstraints(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppTheme.space4,
                0,
                AppTheme.space8,
              ),
              children: [
                FormSection(
                  title: 'Suggestion / request',
                  icon: Icons.lightbulb_outline_rounded,
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: _subjectMax,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'What is it about?',
                        prefixIcon: Icon(Icons.subject_rounded, size: 20),
                        // The counter only matters as the cap is approached,
                        // and an always-on "0/250" under an empty field reads
                        // as a demand rather than a limit.
                        counterText: '',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Give the suggestion a subject.'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    TextFormField(
                      controller: _detailsController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 6,
                      maxLength: _detailsMax,
                      decoration: const InputDecoration(
                        labelText: 'Suggestion / request',
                        hintText: 'Say what you are proposing, and why.',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Write the suggestion itself.'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space5),
                BusyButton(
                  label: _isEdit ? 'Save changes' : 'Add suggestion',
                  icon: _isEdit ? Icons.check_rounded : Icons.add_rounded,
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
