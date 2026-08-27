import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';
import '../../widgets/time_dialog.dart';
import 'form_fields.dart';

/// Call a meeting.
///
/// The fields are the website's, in its order: subject, details, date and
/// time. There is no audience picker because `meeting_search.aspx` has none
/// either — the server tells the whole society — so unlike a notice this form
/// says who will be told rather than asking.
///
/// Passing [existing] edits that meeting instead of creating one, which is the
/// same PUT the website's edit modal sends.
class MeetingFormScreen extends ConsumerStatefulWidget {
  const MeetingFormScreen({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends ConsumerState<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _detailsController;

  DateTime? _meetingDate;
  TimeOfDay? _meetingTime;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final row = widget.existing;

    _subjectController = TextEditingController(
      text: row == null
          ? ''
          : pick(row, ['subject', 'meeting_name', 'name', 'title']) ?? '',
    );
    _detailsController = TextEditingController(
      text: row == null
          ? ''
          : pick(row, ['details', 'description', 'venue']) ?? '',
    );

    if (row != null) {
      final raw = row['meeting_date'] ?? row['meetingDate'] ?? row['date'];
      _meetingDate = raw is DateTime ? raw : DateTime.tryParse('$raw');
      _meetingTime = _timeFrom(row['meeting_time'] ?? row['meetingTime']);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  /// The stored time, which arrives either as a full timestamp or as HH:mm.
  ///
  /// `sp_meeting_master` holds it in a datetime column, so a saved meeting
  /// comes back as a whole date whose date half is meaningless — only the
  /// clock part is read.
  static TimeOfDay? _timeFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return TimeOfDay.fromDateTime(raw);

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return TimeOfDay.fromDateTime(parsed);

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// yyyy-MM-dd, which is what the route's date validator accepts.
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// HH:mm, 24-hour — the route parses a clock time, not a localised one.
  static String _clock(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // The date is required by the route but lives in a picker, which no
    // validator covers — so it is checked here rather than failing server-side.
    if (_meetingDate == null) {
      showAppSnack(context, 'Pick the meeting date.', success: false);
      return;
    }

    // Required, as on meeting_search.aspx: sp_meeting_master stores the time
    // and a meeting announced without one leaves residents guessing.
    if (_meetingTime == null) {
      showAppSnack(context, 'Pick the meeting time.', success: false);
      return;
    }

    final details = _detailsController.text.trim();
    final request = MeetingRequest(
      subject: _subjectController.text.trim(),
      details: details.isEmpty ? null : details,
      meetingDate: _iso(_meetingDate!),
      meetingTime: _clock(_meetingTime!),
    );

    final notifier = ref.read(communityViewModelProvider.notifier);
    final id = _isEdit
        ? pickInt(widget.existing!, ['meet_id', 'meeting_id', 'id'])
        : null;

    final ok = _isEdit && id != null
        ? await notifier.updateMeeting(id, request)
        : await notifier.createMeeting(request);

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit meeting' : 'Call a meeting')),
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
                        Icons.groups_rounded,
                        color: AppTheme.white,
                        size: 26,
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Edit meeting' : 'Call a meeting',
                              style: AppTheme.headline.copyWith(
                                fontSize: 18,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? 'Changes show on the board straight away.'
                                  : 'Every resident is notified — a meeting '
                                        'has no audience picker.',
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
                  title: 'Meeting',
                  icon: Icons.article_outlined,
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      textCapitalization: TextCapitalization.sentences,
                      // meeting_master.subject is nvarchar(150) and the route
                      // rejects anything longer, so the field stops there
                      // rather than letting the save fail.
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'What the meeting is about',
                        prefixIcon: Icon(Icons.title_rounded, size: 20),
                        counterText: '',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a subject'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _detailsController,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        hintText: 'Agenda, venue, anything to bring',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space3),
                FormSection(
                  title: 'When',
                  icon: Icons.schedule_outlined,
                  children: [
                    PickerField(
                      label: 'Meeting date',
                      icon: Icons.event_outlined,
                      value: _meetingDate == null
                          ? 'Pick a date'
                          : prettyDate(_meetingDate),
                      onTap: () async {
                        final picked = await showSingleDateDialog(
                          context: context,
                          initial: _meetingDate ?? DateTime.now(),
                          // Unlike a notice's valid-to, a past date is
                          // meaningful here: minutes are sometimes filed for a
                          // meeting that already happened.
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _meetingDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    PickerField(
                      label: 'Time',
                      icon: Icons.access_time_rounded,
                      value: _meetingTime == null
                          ? 'Pick a time'
                          : _meetingTime!.format(context),
                      onTap: () async {
                        final picked = await showTimeDialog(
                          context: context,
                          initial: _meetingTime,
                          title: 'Meeting at',
                        );
                        if (picked != null) {
                          setState(() => _meetingTime = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space6),
                BusyButton(
                  label: _isEdit ? 'Save changes' : 'Call meeting',
                  icon: _isEdit ? Icons.check_rounded : Icons.groups_rounded,
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
