import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/visitor_request.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';

/// Gate entries.
class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key});

  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen> {
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
      .loadVisitors(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _refresh);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.visitors);

    return Scaffold(
      appBar: AppBar(title: const Text('Visitors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _VisitorForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add visitor'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                hint: 'Search visitors',
              ),
            ),
            Expanded(
              child: RowsView(
                rows: rows,
                onRefresh: _refresh,
                emptyIcon: Icons.how_to_reg_outlined,
                emptyTitle: 'No visitors',
                builder: (items) => ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _buildVisitor(items[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitor(Map<String, dynamic> row) {
    final id = pickInt(row, ['visitor_id', 'id']);
    final name = pick(row, ['v_name', 'visitor_name', 'name']);
    final type = pick(row, ['type', 'visitor_type', 'entry_type']);
    final flat = pick(row, ['flat_no', 'unit_no', 'flat']);
    final contact = pick(row, ['contact_no', 'mobile_no', 'phone']);
    final outTime = pick(row, ['out_time', 'out_date']);
    final stillInside = outTime == null;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _typeColor(type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_typeIcon(type), size: 19, color: _typeColor(type)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Visitor',
                  style: AppTheme.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  [type, flat, contact].where((e) => e != null).join(' · '),
                  style: AppTheme.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  'In ${prettyDate(row['in_date'] ?? row['in_time'])}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          if (stillInside && id != null)
            TextButton(
              onPressed: () => ref
                  .read(communityViewModelProvider.notifier)
                  .checkoutVisitor(id),
              child: const Text('Check out'),
            )
          else
            const StatusChip(label: 'Left', color: AppTheme.deactivatedText),
        ],
      ),
    );
  }

  static IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'cab':
        return Icons.local_taxi_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'service':
        return Icons.handyman_outlined;
      default:
        return Icons.person_outline;
    }
  }

  static Color _typeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'cab':
        return AppTheme.warning;
      case 'delivery':
        return AppTheme.info;
      case 'service':
        return AppTheme.primary;
      default:
        return AppTheme.success;
    }
  }
}

/// Register a visitor.
///
/// One form for every type: the legacy page had four panels, but all four wrote
/// the same columns, so `type` only changes which optional fields are shown.
class _VisitorForm extends ConsumerStatefulWidget {
  const _VisitorForm();

  @override
  ConsumerState<_VisitorForm> createState() => _VisitorFormState();
}

class _VisitorFormState extends ConsumerState<_VisitorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _companyController = TextEditingController();
  final _purposeController = TextEditingController();

  String _type = 'Guest';
  int? _flatId;

  @override
  void initState() {
    super.initState();
    // Flats are needed to attach the visitor to a unit.
    Future.microtask(
      () => ref.read(communityViewModelProvider.notifier).loadBookingLookups(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _vehicleController.dispose();
    _companyController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final now = DateTime.now();
    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .createVisitor(
          VisitorRequest(
            name: _nameController.text.trim(),
            type: _type,
            contactNo: _value(_contactController),
            flatId: _flatId,
            vehicleNo: _value(_vehicleController),
            company: _value(_companyController),
            purpose: _value(_purposeController),
            inDate:
                '${now.year.toString().padLeft(4, '0')}-'
                '${now.month.toString().padLeft(2, '0')}-'
                '${now.day.toString().padLeft(2, '0')}',
            inTime:
                '${now.hour.toString().padLeft(2, '0')}:'
                '${now.minute.toString().padLeft(2, '0')}',
          ),
        );

    if (ok && mounted) Navigator.pop(context);
  }

  String? _value(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final lookups = ref
        .read(communityViewModelProvider.notifier)
        .bookingLookups;
    final flats = lookups == null
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            (lookups['flats'] as List?)?.map(
                  (e) => Map<String, dynamic>.from(e as Map),
                ) ??
                const [],
          );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              Text('Add visitor', style: AppTheme.headline),
              const SizedBox(height: 20),
              AppDropdown<String>(
                value: _type,
                label: 'Type',
                icon: Icons.badge_outlined,
                isDense: false,
                options: const [
                  AppOption('Guest', 'Guest', icon: Icons.person_outline),
                  AppOption('Cab', 'Cab', icon: Icons.local_taxi_outlined),
                  AppOption(
                    'Delivery',
                    'Delivery',
                    icon: Icons.local_shipping_outlined,
                  ),
                  AppOption('Service', 'Service', icon: Icons.build_outlined),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'Guest'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Visitor name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact number'),
              ),
              if (flats.isNotEmpty) ...[
                const SizedBox(height: 14),
                AppDropdown<int>(
                  value: _flatId,
                  label: 'Visiting flat',
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
              if (_type == 'Cab' || _type == 'Delivery') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle number',
                  ),
                ),
              ],
              if (_type != 'Guest') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose (optional)',
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
                    : const Text('Register visitor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
