import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

/// Book a facility on a resident's behalf — a page, not a bottom sheet.
///
/// The form was a `showModalBottomSheet` on the bookings list. A booking asks
/// for a facility, who it is for, a date range, a time range and a charge,
/// which is more than a sheet shows without scrolling inside a sheet that is
/// itself being dragged — and the list behind it was never the point. As a
/// page it gets the full height, the fields group under headings, and it is
/// dismissed by the back arrow like every other screen.
///
/// Laid out like [RaiseComplaintScreen]: a gradient hero, then one card per
/// group, on a width-capped column so it reads on a tablet and in the browser
/// as well as on a phone.
class BookFacilityScreen extends ConsumerStatefulWidget {
  const BookFacilityScreen({super.key});

  @override
  ConsumerState<BookFacilityScreen> createState() => _BookFacilityScreenState();
}

class _BookFacilityScreenState extends ConsumerState<BookFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  int? _facilityId;
  int? _flatId;
  DateTime _fromDate = DateTime.now();
  DateTime? _toDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(communityViewModelProvider.notifier).loadBookingLookups(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// HH:mm, which is what the server stores — not the localised 12-hour text
  /// [TimeOfDay.format] gives back.
  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> _listFrom(
    Map<String, dynamic>? source,
    String key,
  ) {
    final raw = source?[key];
    if (raw is! List) return const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// The chosen facility's row, for its per-day cost.
  Map<String, dynamic>? _facilityRow(List<Map<String, dynamic>> facilities) {
    if (_facilityId == null) return null;
    return facilities
        .where((f) => pickInt(f, ['facility_id', 'id']) == _facilityId)
        .firstOrNull;
  }

  /// Nights inclusive of both ends, as the server prices them.
  int get _days {
    final to = _toDate;
    if (to == null) return 1;
    final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final until = DateTime(to.year, to.month, to.day);
    return until.difference(from).inDays + 1;
  }

  /// True once To falls before From — the charge cannot be worked out, and the
  /// server would reject it.
  bool get _rangeInvalid => _toDate != null && _days < 1;

  /*
   * The charge, worked out the way the web page and facility_booking.aspx.cs
   * do it (:505-535): cost x days, plus 18% GST, with a zero cost meaning the
   * facility is free.
   *
   * Computed here from the `cost` the lookups payload already carries per
   * facility, rather than from the /charge endpoint the web calls — the figure
   * is the same one, and it means picking a facility prices the booking
   * immediately instead of after a round trip.
   */
  double? _baseCharge(List<Map<String, dynamic>> facilities) {
    final row = _facilityRow(facilities);
    if (row == null) return null;
    final cost = row['cost'];
    if (cost == null) return null;
    return (cost is num ? cost.toDouble() : double.tryParse('$cost')) ?? 0;
  }

  Future<void> _submit(List<Map<String, dynamic>> facilities) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // The validators cover the fields; the date range is a relationship
    // between two of them, so it is checked here.
    if (_rangeInvalid) {
      showAppSnack(
        context,
        'The To date falls before the From date.',
        success: false,
      );
      return;
    }

    final base = _baseCharge(facilities);
    final total = base == null || base == 0 ? 0.0 : _totalFor(base);

    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .createBooking(
          FacilityBookingRequest(
            facilityId: _facilityId!,
            name: _nameController.text.trim(),
            fromDate: _iso(_fromDate),
            toDate: _toDate == null ? null : _iso(_toDate!),
            bookDate: _iso(_fromDate),
            flatId: _flatId,
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            contact: _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            fromTime: _fromTime == null ? null : _hhmm(_fromTime!),
            toTime: _toTime == null ? null : _hhmm(_toTime!),
            amount: total,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            // A resident booking, as opposed to an outside hirer — this is
            // what decides which rate the society charges.
            societyIn: _flatId != null,
          ),
        );

    if (ok && mounted) Navigator.pop(context);
  }

  double _totalFor(double base) {
    final subtotal = base * _days;
    return subtotal + subtotal * 0.18;
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final state = ref.watch(communityViewModelProvider);
    final vm = ref.read(communityViewModelProvider.notifier);

    // Prefer the lookups payload; fall back to the facilities list the
    // bookings screen already loaded.
    final facilities = _listFrom(vm.bookingLookups, 'facilities').isNotEmpty
        ? _listFrom(vm.bookingLookups, 'facilities')
        : state.items(CommunityKeys.facilities);
    final flats = _listFrom(vm.bookingLookups, 'flats');
    final residents = _listFrom(vm.bookingLookups, 'residents');

    // Nothing to book: the facility picker is the form, so the page says so
    // rather than showing a dropdown that opens onto an empty list.
    if (vm.bookingLookups == null && facilities.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book a facility')),
        body: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    const SizedBox(height: AppTheme.space8),
                    StateMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load the form',
                      message: 'The facilities did not load.',
                      actionLabel: 'Try again',
                      onAction: vm.loadBookingLookups,
                    ),
                  ],
                ),
        ),
      );
    }

    if (facilities.isEmpty && !state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book a facility')),
        body: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: AppTheme.space8),
              const StateMessage(
                icon: Icons.meeting_room_outlined,
                title: 'No facilities yet',
                message:
                    'This society has no bookable facilities set up. Add one '
                    'from the web dashboard first.',
              ),
            ],
          ),
        ),
      );
    }

    final base = _baseCharge(facilities);

    return Scaffold(
      appBar: AppBar(title: const Text('Book a facility')),
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
                _buildHero(base, facilities),
                const SizedBox(height: AppTheme.space5),

                // Which facility. First, because it sets the charge every
                // other figure on the page is derived from.
                _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _GroupTitle(step: '1', title: 'Which facility'),
                      const SizedBox(height: AppTheme.space4),
                      _buildFacilityDropdown(facilities),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // Who it is for.
                _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _GroupTitle(step: '2', title: 'Who it is for'),
                      const SizedBox(height: AppTheme.space4),
                      if (residents.isNotEmpty) ...[
                        _buildResidentPicker(residents),
                        const SizedBox(height: AppTheme.space4),
                      ],
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Booked by',
                          hintText: 'Who the booking is in the name of',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a name'
                            : null,
                      ),
                      if (flats.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space4),
                        _buildFlatPicker(flats),
                      ],
                      const SizedBox(height: AppTheme.space4),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact number',
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Address (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // When.
                _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _GroupTitle(step: '3', title: 'When'),
                      const SizedBox(height: AppTheme.space4),
                      _buildWhen(),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // What it costs.
                _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _GroupTitle(step: '4', title: 'Charges'),
                      const SizedBox(height: AppTheme.space3),
                      _buildCharges(base),
                      const SizedBox(height: AppTheme.space4),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space6),

                BusyButton(
                  label: 'Book facility',
                  icon: Icons.event_available_rounded,
                  busy: state.isLoading,
                  onPressed: () => _submit(facilities),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The hero doubles as the page's summary and its running total: the charge
  /// is what the form is ultimately deciding, so it is kept in view from the
  /// top rather than only appearing at the bottom of the scroll.
  Widget _buildHero(double? base, List<Map<String, dynamic>> facilities) {
    final row = _facilityRow(facilities);
    final name = row == null
        ? null
        : pick(row, ['facility_name', 'name']) ?? 'Facility';

    final String figure;
    if (base == null) {
      figure = '—';
    } else if (base == 0) {
      figure = 'Free';
    } else if (_rangeInvalid) {
      figure = '—';
    } else {
      figure = money(_totalFor(base));
    }

    return GradientPanel(
      gradient: AppTheme.heroGradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'New booking',
                  style: AppTheme.headline.copyWith(
                    fontSize: 18,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name == null
                      ? 'Pick a facility to price the booking.'
                      : '$_days day${_days == 1 ? '' : 's'} · '
                            'includes 18% GST',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppTheme.onGradientMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'CHARGES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppTheme.onGradientMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                figure,
                style: AppTheme.headline.copyWith(
                  fontSize: 20,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The facility as a dropdown — the field of record.
  ///
  /// The tiles below it are the same choice made visually, but this is what
  /// validates, what a keyboard reaches, and what a screen reader announces as
  /// a labelled control. Each option carries the per-day cost, so the list can
  /// be compared without leaving the menu.
  Widget _buildFacilityDropdown(List<Map<String, dynamic>> facilities) {
    return AppDropdown<int>(
      value: _facilityId,
      label: 'Facility',
      hint: 'Select a facility',
      icon: Icons.meeting_room_rounded,
      // Tinted: the facility is the field this whole form turns on, and the
      // charge below is keyed to the same colour.
      iconColor: AppTheme.primary,
      isDense: false,
      options: [
        for (final f in facilities)
          if (pickInt(f, ['facility_id', 'id']) != null)
            AppOption(
              pickInt(f, ['facility_id', 'id'])!,
              _optionLabel(f),
            ),
      ],
      onChanged: (v) => setState(() => _facilityId = v),
      validator: (v) => v == null ? 'Choose a facility' : null,
    );
  }

  /// "Clubhouse — ₹2,000 / day", so the menu can be compared on price.
  String _optionLabel(Map<String, dynamic> facility) {
    final name = pick(facility, ['facility_name', 'name']) ?? 'Facility';
    final cost = facility['cost'];
    final value = cost is num ? cost.toDouble() : double.tryParse('$cost');
    if (value == null) return name;
    return value == 0 ? '$name — Free' : '$name — ${money(value)} / day';
  }

  /// Picking a resident fills their name, contact and address, as the web page
  /// and the legacy form both do.
  Widget _buildResidentPicker(List<Map<String, dynamic>> residents) {
    return AppDropdown<int>(
      value: null,
      label: 'Resident (optional)',
      helperText: 'Fills in the name, contact and address below',
      icon: Icons.person_outline,
      isDense: false,
      options: [
        for (final r in residents)
          if (pickInt(r, ['owner_id', 'id']) != null)
            AppOption(
              pickInt(r, ['owner_id', 'id'])!,
              pick(r, ['name', 'owner_name']) ?? 'Resident',
            ),
      ],
      onChanged: (v) {
        final r = residents
            .where((x) => pickInt(x, ['owner_id', 'id']) == v)
            .firstOrNull;
        if (r == null) return;

        setState(() {
          _nameController.text = pick(r, ['name', 'owner_name']) ?? '';
          _contactController.text = pick(r, ['contact', 'pre_mob']) ?? '';
          _addressController.text = pick(r, ['address', 'off_addr1']) ?? '';
          final flat = pickInt(r, ['flat_id']);
          if (flat != null) _flatId = flat;
        });
      },
    );
  }

  Widget _buildFlatPicker(List<Map<String, dynamic>> flats) {
    return AppDropdown<int>(
      value: _flatId,
      label: 'Flat (optional)',
      helperText: 'Leave empty for an outside booking',
      icon: Icons.home_outlined,
      isDense: false,
      options: [
        for (final f in flats)
          if (pickInt(f, ['flat_id', 'flatId']) != null)
            AppOption(
              pickInt(f, ['flat_id', 'flatId'])!,
              [
                pick(f, ['building_name', 'build_name']),
                pick(f, ['flat_no', 'unit_no']),
              ].where((e) => e != null).join(' · '),
            ),
      ],
      onChanged: (v) => setState(() => _flatId = v),
    );
  }

  /// Dates on one row, times on the next — paired so a range reads as a range.
  /// They stack on a narrow phone, where two pickers side by side leave each
  /// too cramped to show a full date.
  Widget _buildWhen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 380;

        final fromDate = _PickerField(
          label: 'From date',
          icon: Icons.event_outlined,
          value: prettyDate(_fromDate),
          onTap: () async {
            final picked = await showSingleDateDialog(
              context: context,
              initial: _fromDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _fromDate = picked);
          },
        );

        final toDate = _PickerField(
          label: 'To date',
          icon: Icons.event_repeat_outlined,
          value: _toDate == null ? null : prettyDate(_toDate!),
          placeholder: 'Same day',
          error: _rangeInvalid,
          onClear: _toDate == null ? null : () => setState(() => _toDate = null),
          onTap: () async {
            final picked = await showSingleDateDialog(
              context: context,
              initial: _toDate ?? _fromDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _toDate = picked);
          },
        );

        final fromTime = _PickerField(
          label: 'From time',
          icon: Icons.schedule_outlined,
          value: _fromTime?.format(context),
          placeholder: 'Not set',
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _fromTime ?? const TimeOfDay(hour: 10, minute: 0),
            );
            if (picked != null) setState(() => _fromTime = picked);
          },
        );

        final toTime = _PickerField(
          label: 'To time',
          icon: Icons.schedule_rounded,
          value: _toTime?.format(context),
          placeholder: 'Not set',
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime:
                  _toTime ??
                  _fromTime ??
                  const TimeOfDay(hour: 18, minute: 0),
            );
            if (picked != null) setState(() => _toTime = picked);
          },
        );

        Widget pair(Widget a, Widget b) => tight
            ? Column(
                children: [a, const SizedBox(height: AppTheme.space4), b],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: a),
                  const SizedBox(width: AppTheme.space3),
                  Expanded(child: b),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pair(fromDate, toDate),
            const SizedBox(height: AppTheme.space4),
            pair(fromTime, toTime),
            if (_rangeInvalid) ...[
              const SizedBox(height: AppTheme.space3),
              _Note(
                icon: Icons.error_outline_rounded,
                tone: AppTheme.error,
                text: 'The To date falls before the From date.',
              ),
            ],
          ],
        );
      },
    );
  }

  /// The charge as a receipt rather than one computed string.
  ///
  /// The web page and the legacy form both show the working — cost, days, GST,
  /// total — because a secretary is quoting this figure to a resident and has
  /// to be able to explain it. Same figures, one line each.
  Widget _buildCharges(double? base) {
    if (base == null) {
      return const _Note(
        icon: Icons.lightbulb_outline,
        tone: AppTheme.lightText,
        text: 'Choose a facility to see the charge.',
      );
    }

    if (base == 0) {
      return const _Note(
        icon: Icons.check_circle_outline_rounded,
        tone: AppTheme.success,
        text: 'This facility is free to book.',
      );
    }

    if (_rangeInvalid) {
      return const _Note(
        icon: Icons.error_outline_rounded,
        tone: AppTheme.error,
        text: 'Fix the dates to price the booking.',
      );
    }

    final subtotal = base * _days;
    final gst = subtotal * 0.18;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _ChargeRow(
            label: '${money(base)} × $_days day${_days == 1 ? '' : 's'}',
            value: money(subtotal),
          ),
          const SizedBox(height: AppTheme.space2),
          _ChargeRow(label: 'GST @ 18%', value: money(gst)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.space3),
            child: Divider(height: 1, color: AppTheme.border),
          ),
          _ChargeRow(
            label: 'Total',
            value: money(subtotal + gst),
            emphasised: true,
          ),
        ],
      ),
    );
  }
}

// ── Pieces ───────────────────────────────────────────────────────────────

/// The white panel each group of fields sits on. Mirrors the card in
/// raise_complaint_screen.dart, so the two forms read as one app.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: child,
    );
  }
}

/// A numbered group heading — "1 Which facility".
class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.primarySurface,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: AppTheme.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space2),
        Text(title, style: AppTheme.title.copyWith(fontSize: 15)),
      ],
    );
  }
}

/// A tappable field that opens a picker — dates and times.
///
/// [InputDecorator] rather than a read-only [TextFormField]: the value is
/// never typed, and a text field that cannot be typed into still shows a
/// caret and raises the keyboard on some platforms.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.error = false,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final String? value;
  final String? placeholder;
  final bool error;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final empty = value == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: false,
          prefixIcon: Icon(
            icon,
            size: 19,
            color: error ? AppTheme.error : AppTheme.lightText,
          ),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 17),
                  onPressed: onClear,
                  tooltip: 'Clear',
                  visualDensity: VisualDensity.compact,
                ),
          errorText: error ? '' : null,
          // The message is shown once under the pair rather than twice, so the
          // field only needs the red outline.
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
        child: Text(
          value ?? placeholder ?? 'Not set',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: empty
              ? AppTheme.body2.copyWith(color: AppTheme.deactivatedText)
              : AppTheme.body2,
        ),
      ),
    );
  }
}

/// One line of the charge breakdown.
class _ChargeRow extends StatelessWidget {
  const _ChargeRow({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final style = emphasised
        ? AppTheme.title.copyWith(fontSize: 15)
        : AppTheme.caption;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: emphasised
              ? AppTheme.title.copyWith(fontSize: 15)
              : AppTheme.body2,
        ),
      ],
    );
  }
}

/// A tinted one-line note — the empty, free and invalid states of the charge
/// box, and the date-range warning.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.tone, required this.text});

  final IconData icon;
  final Color tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(tone),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: tone.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: tone),
          const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Text(
              text,
              style: AppTheme.caption.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
