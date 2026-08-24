import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/community_requests.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

/// Facility bookings — the clubhouse, hall and other amenities.
class FacilityBookingsScreen extends ConsumerStatefulWidget {
  const FacilityBookingsScreen({super.key});

  @override
  ConsumerState<FacilityBookingsScreen> createState() =>
      _FacilityBookingsScreenState();
}

class _FacilityBookingsScreenState
    extends ConsumerState<FacilityBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() =>
      ref.read(communityViewModelProvider.notifier).loadBookings();

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text('The slot will be free for someone else.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(communityViewModelProvider.notifier).deleteBooking(id);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.bookings);

    return Scaffold(
      appBar: AppBar(title: const Text('Facility bookings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _BookingForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New booking'),
      ),
      body: SafeArea(
        child: RowsView(
          rows: rows,
          onRefresh: _refresh,
          emptyIcon: Icons.event_available_outlined,
          emptyTitle: 'No bookings',
          emptyMessage: 'Facilities are free at the moment.',
          builder: (items) => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 118),
            itemCount: items.length,
            itemBuilder: (context, i) => _buildBooking(items[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildBooking(Map<String, dynamic> row) {
    final id = pickInt(row, ['facility_book_id', 'booking_id', 'id']);
    final facility = pick(row, ['facility_name', 'facility', 'name']);
    final person = pick(row, ['name', 'owner_name', 'booked_by']);
    final flat = pick(row, ['flat_no', 'unit_no', 'flat']);
    final fromDate = row['from_date'] ?? row['book_date'];
    final toDate = row['to_date'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility ?? 'Facility',
                      style: AppTheme.title.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [person, flat].where((e) => e != null).join(' · '),
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(row['amount']),
                    style: AppTheme.title.copyWith(fontSize: 14),
                  ),
                  if (id != null)
                    TextButton(
                      onPressed: () => _confirmDelete(id),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule, size: 13, color: AppTheme.lightText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  toDate == null
                      ? prettyDate(fromDate)
                      : '${prettyDate(fromDate)} — ${prettyDate(toDate)}',
                  style: AppTheme.caption,
                ),
              ),
              if (pick(row, ['from_time']) != null)
                Text(
                  '${pick(row, ['from_time'])}'
                  '${pick(row, ['to_time']) != null ? ' – ${pick(row, ['to_time'])}' : ''}',
                  style: AppTheme.caption,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Book a facility for a resident.
class _BookingForm extends ConsumerStatefulWidget {
  const _BookingForm();

  @override
  ConsumerState<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends ConsumerState<_BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _facilityId;
  int? _flatId;
  DateTime _fromDate = DateTime.now();
  DateTime? _toDate;

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
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
            contact: _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            amount: double.tryParse(_amountController.text.trim()),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            // A resident booking, as opposed to an outside hirer — this
            // is what decides which rate the society charges.
            societyIn: _flatId != null,
          ),
        );

    if (ok && mounted) Navigator.pop(context);
  }

  List<Map<String, dynamic>> _listFrom(
    Map<String, dynamic>? source,
    String key,
  ) {
    final raw = source?[key];
    if (raw is! List) return const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final vm = ref.read(communityViewModelProvider.notifier);

    // Prefer the lookups payload; fall back to the facilities list the bookings
    // screen already loaded.
    final facilities = _listFrom(vm.bookingLookups, 'facilities').isNotEmpty
        ? _listFrom(vm.bookingLookups, 'facilities')
        : state.items(CommunityKeys.facilities);
    final flats = _listFrom(vm.bookingLookups, 'flats');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              Text('New booking', style: AppTheme.headline),
              const SizedBox(height: 20),
              AppDropdown<int>(
                value: _facilityId,
                label: 'Facility',
                icon: Icons.meeting_room_outlined,
                isDense: false,
                options: [
                  for (final f in facilities)
                    if (pickInt(f, ['facility_id', 'id']) != null)
                      AppOption(
                        pickInt(f, ['facility_id', 'id'])!,
                        pick(f, ['facility_name', 'name']) ?? 'Facility',
                      ),
                ],
                onChanged: (v) => setState(() => _facilityId = v),
                validator: (v) => v == null ? 'Choose a facility' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Booked by'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              if (flats.isNotEmpty) ...[
                const SizedBox(height: 14),
                AppDropdown<int>(
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
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact number'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _dateField('From', _fromDate, (d) {
                      setState(() => _fromDate = d);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateField('To (optional)', _toDate, (d) {
                      setState(() => _toDate = d);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Charge',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
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
                    : const Text('Book facility'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPick,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showSingleDateDialog(
          context: context,
          initial: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: Text(
          value == null ? 'Not set' : prettyDate(value),
          style: AppTheme.body2,
        ),
      ),
    );
  }
}
