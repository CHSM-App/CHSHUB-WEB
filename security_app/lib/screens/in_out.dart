import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/visitors.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class InOutScreen extends ConsumerStatefulWidget {
  const InOutScreen({super.key});

  @override
  _InOutScreenState createState() => _InOutScreenState();
}

class _InOutScreenState extends ConsumerState<InOutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'All';
  DateTimeRange? _dateRange;

  static const List<String> _typeOptions = [
    'All',
    'Guest',
    'Cab',
    'Delivery',
    'Service',
  ];

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _typeFilter != 'All' || _dateRange != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Fetch visitor list after first frame only if checked in
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isCheckedIn = ref.read(staffmodelProvider).isCheckedIn;
      
      if (isCheckedIn) {
        final societyId = ref.read(securitymodelProvider).SocietyId ?? "";
        await ref.read(visitormodelProvider.notifier).getVisitorList(societyId);

        // Debug print to check API data
        final visitors = ref.read(visitormodelProvider).visitorsList.value;
        print("DEBUG Visitors fetched: ${visitors?.map((v) => v.name).toList()}");
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static const Map<String, int> _monthAbbr = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  DateTime? _parseDdMonYyyy(String raw) {
    final parts = raw.trim().split(' ');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _monthAbbr[parts[1].toLowerCase()];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime? _parseVisitorDate(Visitors v) {
    final raw = v.inDate ?? v.preDate;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw) ?? _parseDdMonYyyy(raw);
  }

  List<Visitors> _applyHistoryFilters(List<Visitors> visitors) {
    return visitors.where((v) {
      if (_typeFilter != 'All' &&
          (v.type?.toLowerCase() != _typeFilter.toLowerCase())) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = v.name?.toLowerCase().contains(query) ?? false;
        final matchesUnit = v.unit?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesUnit) return false;
      }

      if (_dateRange != null) {
        final date = _parseVisitorDate(v);
        if (date == null) return false;
        final day = DateTime(date.year, date.month, date.day);
        final start = _dateRange!.start;
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
        );
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      final societyId = ref.read(securitymodelProvider).SocietyId ?? "";
      await ref
          .read(visitormodelProvider.notifier)
          .getVisitorHistory(societyId, picked.start, picked.end);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _typeFilter = 'All';
      _dateRange = null;
    });
  }

  String _formatHistoryDateTime(Visitors visitor) {
    final date = _parseVisitorDate(visitor);
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : (visitor.inDate ?? 'N/A');
    final timeStr = visitor.outTime ?? visitor.inTime;
    return timeStr != null && timeStr.isNotEmpty ? '$dateStr  •  $timeStr' : dateStr;
  }

  Widget _buildHistoryFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by name or unit',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _typeFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _typeOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _typeFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _dateRange != null ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: _dateRange != null
                        ? Border.all(color: Colors.blue[200]!)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 18,
                        color: _dateRange != null ? Colors.blue[700] : Colors.grey[600],
                      ),
                      if (_dateRange != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                          style: TextStyle(fontSize: 13, color: Colors.blue[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear filters',
                  onPressed: _clearFilters,
                  icon: Icon(Icons.filter_alt_off_outlined, size: 20, color: Colors.red[400]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = ref.watch(staffmodelProvider).isCheckedIn;
    final visitorState = ref.watch(visitormodelProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Content
          Opacity(
            opacity: isCheckedIn ? 1.0 : 0.5,
            child: AbsorbPointer(
              absorbing: !isCheckedIn,
              child: visitorState.visitorsList.when(
                loading: () => Column(
                  children: [
                    _buildTabBar(0, 0, 0),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
                error: (error, stack) => Column(
                  children: [
                    _buildTabBar(0, 0, 0),
                    Expanded(
                      child: Center(child: Text(getErrorMessage(error))),
                    ),
                  ],
                ),
                data: (visitors) {
                  // Separate visitors into tabs dynamically
                  final insideVisitors = visitors.where((v) => v.status == 1).toList();
                  final waitingVisitors = visitors.where((v) => v.status == 2).toList();

                  // History tab: when a date range is picked, source from the
                  // server-side ranged fetch; otherwise fall back to today's data.
                  final bool useRangedHistory = _dateRange != null;
                  final historySource = useRangedHistory
                      ? visitorState.visitorHistoryList
                      : AsyncValue.data(
                          visitors.where((v) => v.status == 3).toList(),
                        );

                  return historySource.when(
                    loading: () => Column(
                      children: [
                        _buildTabBar(insideVisitors.length, waitingVisitors.length, 0),
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    ),
                    error: (error, stack) => Column(
                      children: [
                        _buildTabBar(insideVisitors.length, waitingVisitors.length, 0),
                        Expanded(
                          child: Center(child: Text(getErrorMessage(error))),
                        ),
                      ],
                    ),
                    data: (historyVisitorlist) {
                      final filteredHistory = _applyHistoryFilters(historyVisitorlist);

                      return Column(
                        children: [
                          // Tab Bar
                          _buildTabBar(
                            insideVisitors.length,
                            waitingVisitors.length,
                            historyVisitorlist.length,
                          ),

                          if (_tabController.index == 2) _buildHistoryFilterBar(),

                          // Tab Bar View
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildVisitorList(
                                  insideVisitors,
                                  buttonType: 'out',
                                ),
                                _buildVisitorList(
                                  waitingVisitors,
                                  buttonType: 'in',
                                ),
                                _buildVisitorList(
                                  filteredHistory,
                                  buttonType: 'none',
                                  isHistory: true,
                                  isFiltered: _hasActiveFilters,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Overlay for disabled state
          if (!isCheckedIn)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Please check in to manage visitor entries',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E3B62),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Check in Required',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int insideCount, int waitingCount, int historyCount) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue[600],
        indicatorWeight: 3,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: [
          Tab(text: 'Inside ($insideCount)'),
          Tab(text: 'Waiting ($waitingCount)'),
          Tab(text: 'History ($historyCount)'),
        ],
      ),
    );
  }

  Widget _buildVisitorList(
    List<Visitors> visitors, {
    required String buttonType,
    bool isHistory = false,
    bool isFiltered = false,
  }) {
    if (visitors.isEmpty) {
      String msg = '';
      if (buttonType == 'out') {
        msg = 'No visitors currently inside';
      } else if (buttonType == 'in') {
        msg = 'No visitors waiting at gate';
      } else if (isFiltered) {
        msg = 'No history matches your filters';
      } else {
        msg = 'No visitor history';
      }
      return RefreshIndicator(
        color: Colors.blue[600],
        onRefresh: _refreshVisitors,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    buttonType == 'out'
                        ? Icons.people_outline
                        : buttonType == 'in'
                            ? Icons.front_hand_outlined
                            : Icons.history,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    msg,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.blue[600],
      onRefresh: _refreshVisitors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visitors.length,
        itemBuilder: (context, index) {
          final visitor = visitors[index];
          return _buildVisitorCard(
            visitor,
            buttonType: buttonType,
            isHistory: isHistory,
          );
        },
      ),
    );
  }

  Future<bool> _showOutConfirmDialog(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: Colors.red[600], size: 24),
                const SizedBox(width: 8),
                const Text('Confirm OUT'),
              ],
            ),
            content: Text('Do you want to mark $name as OUT?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showInConfirmDialog(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.login, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                const Text('Confirm IN'),
              ],
            ),
            content: Text('Do you want to mark $name as IN?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _refreshVisitors() async {
    final societyId = ref.read(securitymodelProvider).SocietyId ?? "";
    await ref.read(visitormodelProvider.notifier).getVisitorList(societyId);
  }

  Widget _buildVisitorCard(
    Visitors visitor, {
    required String buttonType,
    bool isHistory = false,
  }) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (visitor.type?.toLowerCase()) {
      case 'taxi':
      case 'cab':
        icon = Icons.local_taxi;
        iconColor = Colors.amber[800]!;
        iconBgColor = Colors.amber[100]!;
        break;
      case 'service':
        icon = Icons.home_repair_service_outlined;
        iconColor = Colors.blue[700]!;
        iconBgColor = Colors.blue[100]!;
        break;
      case 'delivery':
        icon = Icons.delivery_dining;
        iconColor = Colors.green[700]!;
        iconBgColor = Colors.green[100]!;
        break;
      case 'guest':
        icon = Icons.person_outline;
        iconColor = Colors.orange[700]!;
        iconBgColor = Colors.orange[100]!;
        break;
      default:
        icon = Icons.person_outline;
        iconColor = Colors.grey[700]!;
        iconBgColor = Colors.grey[200]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
       CircleAvatar(
  radius: 25,
  backgroundColor: Colors.grey[200],
  backgroundImage: (visitor.image != null &&
          visitor.image!.isNotEmpty)
      ? NetworkImage(visitor.image!)
      : null,
  child: (visitor.image == null || visitor.image!.isEmpty)
      ? Icon(
          icon,
          color: iconColor,
          size: 26,
        )
      : null,
),

          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visitor.name ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (visitor.unit != null && visitor.unit!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.home_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          visitor.unit ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      visitor.contactNo ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (isHistory) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatHistoryDateTime(visitor),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (visitor.purpose != null && visitor.purpose!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              visitor.purpose!,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (buttonType != 'none')
            ElevatedButton(
              onPressed: () async {
                final notifier = ref.read(visitormodelProvider.notifier);

                if (buttonType == 'out') {
                  final confirm = await _showOutConfirmDialog(
                    visitor.name ?? 'Visitor',
                  );

                  if (confirm) {
                    await notifier.updateWaitingStatus(visitor.visitorId ?? 0);
                    await _refreshVisitors();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('${visitor.name} marked OUT'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red[600],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }

                if (buttonType == 'in') {
                  final confirm = await _showInConfirmDialog(
                    visitor.name ?? 'Visitor',
                  );

                  if (confirm) {
                    await notifier.updateInsideStatus(visitor.visitorId ?? 0);
                    await _refreshVisitors();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('${visitor.name} marked IN'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green[600],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonType == 'out'
                    ? Colors.red[400]
                    : Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonType == 'out' ? 'Out' : 'In',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}