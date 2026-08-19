import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/helpdesk_details.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/helpdesk_page.dart';
import 'package:society_app/domain/models/helpdesk.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class HelpDeskScreen extends ConsumerStatefulWidget {
  const HelpDeskScreen({super.key});

  @override
  _HelpDeskScreenState createState() => _HelpDeskScreenState();
}

class _HelpDeskScreenState extends ConsumerState<HelpDeskScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Trigger backend fetch
   _loadData();
    

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }
void _loadData(){
   Future.microtask(() {
      ref
          .read(HelpdeskViewModelProvider.notifier)
          .getHelpdeskList(
            ref.watch(basicInfoViewModelProvider).societyID??"",ref.watch(basicInfoViewModelProvider).ownerId??0,
          );
    });
}
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String searchQuery = '';
  String filterStatus = 'All';
  String raisedByFilter = 'All';

  String normalizeStatus(int status) {
    switch (status) {
      case 1:
        return "Open";
      case 2:
        return "In-Progress";
      case 3:
        return "On-Hold";
      case 4:
        return "Resolved";
      default:
        return "Unknown";
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void showFilterDialog() {
    String tempStatus = filterStatus;
    String tempRaisedBy = raisedByFilter;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: const Text('Filter Complaints'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Complaint Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text('All'),
                      value: 'All',
                      groupValue: tempStatus,
                      onChanged: (value) =>
                          setDialogState(() => tempStatus = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Open'),
                      value: 'Open',
                      groupValue: tempStatus,
                      onChanged: (value) =>
                          setDialogState(() => tempStatus = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('In-Progress'),
                      value: 'In-Progress',
                      groupValue: tempStatus,
                      onChanged: (value) =>
                          setDialogState(() => tempStatus = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('On-Hold'),
                      value: 'On-Hold',
                      groupValue: tempStatus,
                      onChanged: (value) =>
                          setDialogState(() => tempStatus = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Resolved'),
                      value: 'Resolved',
                      groupValue: tempStatus,
                      onChanged: (value) =>
                          setDialogState(() => tempStatus = value!),
                    ),
                    const Divider(),
                    const Text(
                      'Raised By',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text('All'),
                      value: 'All',
                      groupValue: tempRaisedBy,
                      onChanged: (value) =>
                          setDialogState(() => tempRaisedBy = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Raised by Me'),
                      value: 'Me',
                      groupValue: tempRaisedBy,
                      onChanged: (value) =>
                          setDialogState(() => tempRaisedBy = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      filterStatus = tempStatus;
                      raisedByFilter = tempRaisedBy;
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(HelpdeskViewModelProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: 
      state.requestList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
        data: (complaints) {
          final currentOwnerId = ref.watch(basicInfoViewModelProvider).ownerId;
          
          final filteredComplaints = complaints.where((complaint) {
            final matchesSearch = complaint.query
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
            
            bool matchesStatus = filterStatus == 'All';
            if (!matchesStatus) {
              final complaintStatus = normalizeStatus(complaint.status ?? 0);
              matchesStatus = filterStatus == complaintStatus;
            }
            
            bool matchesRaisedBy = raisedByFilter == 'All';
            if (!matchesRaisedBy && raisedByFilter == 'Me') {
              matchesRaisedBy = complaint.ownerId == currentOwnerId;
            }

            return matchesSearch && matchesStatus && matchesRaisedBy;
          }).toList();

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), 
                 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search complaints',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: (value) {
                              setState(() => searchQuery = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.filter_list, color: Colors.black),
                          onPressed: showFilterDialog,
                        ),
                      ],
                    ),
                  ),
                  
                  if (filterStatus != 'All' || raisedByFilter != 'All')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filters: ${filterStatus != 'All' ? 'Status: $filterStatus' : ''}${filterStatus != 'All' && raisedByFilter != 'All' ? ', ' : ''}${raisedByFilter != 'All' ? 'Raised by: $raisedByFilter' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                filterStatus = 'All';
                                raisedByFilter = 'All';
                              });
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: filteredComplaints.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No complaints found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search or filters',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredComplaints.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              return TweenAnimationBuilder(
                                duration: Duration(milliseconds: 800 + (index * 100)),
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                curve: Curves.easeOutBack,
                                builder: (context, double value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: ComplaintCard(
                                      complaint: filteredComplaints[index],
                                      index: index,
                                      normalizeStatus: normalizeStatus,
                                      getStatusColor: getStatusColor,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    
      floatingActionButton: FloatingActionButton.extended(
  backgroundColor: Colors.blue,
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpdeskPage(),
      ),
    );

    if (result == true) {
      final info = ref.read(basicInfoViewModelProvider);

      ref
          .read(HelpdeskViewModelProvider.notifier)
          .getHelpdeskList(
            info.societyID ?? "",
            info.ownerId ?? 0,
          );
    }
  },
  label: const Text(
    "Raise New Complaint",
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
  icon: const Icon(
    Icons.add_rounded,
    color: Colors.white,
  ),
),

    );
  }
}



class ComplaintCard extends StatefulWidget {
  final HelpdeskRequest complaint; // Use typed HelpdeskRequest
  final int index;
  final String Function(int) normalizeStatus;
  final Color Function(int) getStatusColor;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.index,
    required this.normalizeStatus,
    required this.getStatusColor,
  });

  @override
  _ComplaintCardState createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<ComplaintCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int seenStatus = widget.complaint.seenStatus ?? 1; // Default to 1 if null

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailPage(
              helpdeskID: widget.complaint.helpdeskId!,
              notifyStatusId: widget.complaint.notifyStatusId,
            ),
          ),
        );
        
      },
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Top Row (Title + Category + Status + NEW tag)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Complaint Type
                    Expanded(
                      child: Text(
                        widget.complaint.pTypeName ?? "-",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Category
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.complaint.categoryType ?? "-",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Status
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.getStatusColor(
                              widget.complaint.status ?? 0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.normalizeStatus(
                                widget.complaint.status ?? 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                  
                    if (seenStatus == 0) ...[
  const SizedBox(width: 6),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      "NEW",
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
],

                  ],
                ),

                const SizedBox(height: 16),

                // 🔹 Complaint Query Text
                Text(
                  widget.complaint.query ?? "-",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // 🔹 Footer (Raised By + Date)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "Raised by: ${widget.complaint.name ?? "-"}",
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.complaint.date ?? "-",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
