import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';
import 'form_fields.dart';

/// Put a festival or gathering on the society calendar.
///
/// The fields are the website's, in its order: name, description, from and to.
/// `sp_event_master` stores a span rather than a single day, so both dates are
/// required — a one-day event is saved with the same date twice, which is what
/// picking only a start does here.
///
/// Passing [existing] edits that event instead of creating one.
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  DateTime? _fromDate;
  DateTime? _toDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final row = widget.existing;

    _nameController = TextEditingController(
      text: row == null ? '' : pick(row, ['event_name', 'name', 'title']) ?? '',
    );
    _descriptionController = TextEditingController(
      text: row == null
          ? ''
          : pick(row, ['description', 'details', 'venue']) ?? '',
    );

    if (row != null) {
      _fromDate = _dateFrom(
        row['from_date'] ?? row['fromDate'] ?? row['event_date'],
      );
      _toDate = _dateFrom(row['to_date'] ?? row['toDate']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static DateTime? _dateFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  /// yyyy-MM-dd, which is what the route's date validator accepts.
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Both dates are required by the route but live in pickers, which no
    // validator covers — checked here rather than failing server-side.
    if (_fromDate == null) {
      showAppSnack(context, 'Pick the date the event starts.', success: false);
      return;
    }

    // A single-day event is the common case, so an unset end date means "same
    // day" rather than an error — the route wants both, and asking twice for
    // one afternoon's event would be the wrong kind of careful.
    final to = _toDate ?? _fromDate!;

    if (to.isBefore(_fromDate!)) {
      showAppSnack(
        context,
        'The event cannot end before it starts.',
        success: false,
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final request = EventRequest(
      name: _nameController.text.trim(),
      description: description.isEmpty ? null : description,
      fromDate: _iso(_fromDate!),
      toDate: _iso(to),
    );

    final notifier = ref.read(communityViewModelProvider.notifier);
    final id = _isEdit ? pickInt(widget.existing!, ['event_id', 'id']) : null;

    final ok = _isEdit && id != null
        ? await notifier.updateEvent(id, request)
        : await notifier.createEvent(request);

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit event' : 'New event')),
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
                        Icons.celebration_rounded,
                        color: AppTheme.white,
                        size: 26,
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Edit event' : 'Plan something',
                              style: AppTheme.headline.copyWith(
                                fontSize: 18,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? 'Changes show on the calendar straight '
                                        'away.'
                                  : 'Residents are notified and it goes on '
                                        'the society calendar.',
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
                  title: 'Event',
                  icon: Icons.article_outlined,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      // event_master.event_name is nvarchar(150) and the route
                      // rejects anything longer, so the field stops there
                      // rather than letting the save fail.
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Event name',
                        hintText: 'Ganesh Utsav, annual day, a clean-up drive',
                        prefixIcon: Icon(Icons.title_rounded, size: 20),
                        counterText: '',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter an event name'
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
                        hintText: 'Venue, timings, what residents should know',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space3),
                FormSection(
                  title: 'When',
                  icon: Icons.event_outlined,
                  children: [
                    PickerField(
                      label: 'Starts',
                      icon: Icons.event_available_outlined,
                      value: _fromDate == null
                          ? 'Pick a date'
                          : prettyDate(_fromDate),
                      onTap: () async {
                        final picked = await showSingleDateDialog(
                          context: context,
                          initial: _fromDate ?? DateTime.now(),
                          // Past dates allowed: an event is sometimes recorded
                          // after it has happened.
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setState(() {
                          _fromDate = picked;
                          // An end date left behind the new start would be
                          // saved as an impossible span, so it follows along.
                          if (_toDate != null && _toDate!.isBefore(picked)) {
                            _toDate = picked;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    PickerField(
                      label: 'Ends',
                      icon: Icons.event_busy_outlined,
                      value: _toDate == null
                          ? 'Same day'
                          : prettyDate(_toDate),
                      onClear: _toDate == null
                          ? null
                          : () => setState(() => _toDate = null),
                      onTap: () async {
                        final start = _fromDate ?? DateTime.now();
                        final picked = await showSingleDateDialog(
                          context: context,
                          initial: _toDate ?? start,
                          firstDate: start,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _toDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space6),
                BusyButton(
                  label: _isEdit ? 'Save changes' : 'Schedule event',
                  icon: _isEdit
                      ? Icons.check_rounded
                      : Icons.celebration_rounded,
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
