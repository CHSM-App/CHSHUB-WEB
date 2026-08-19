import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/full_screen_gallery.dart';
import 'package:society_app/SocietyApp/screens/gatepass.dart';
import 'package:society_app/SocietyApp/screens/visitor_dailogs.dart';
import 'package:society_app/domain/models/visitor.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class VisitorManagementScreen extends ConsumerStatefulWidget {
  const VisitorManagementScreen({super.key});
  @override
  _VisitorManagementScreenState createState() =>
      _VisitorManagementScreenState();
}

class _VisitorManagementScreenState
    extends ConsumerState<VisitorManagementScreen>
    with TickerProviderStateMixin {
  // Animation controllers for fade and slide (matching Directory screen)
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedTabIndex = 0; // Default to "scheduled" Tab
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers (matching Directory screen style)
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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });

    // Fetch visitor list from API
    _loadData();
  }

  Future<void> _loadData() async {
    Future.microtask(() {
      ref
          .read(visitorViewModelProvider.notifier)
          .getVisitorList(
            'byflat',
            ref.watch(basicInfoViewModelProvider).flatId ?? 0,
          );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _selectedTabIndex) return;

    setState(() => _selectedTabIndex = index);
    HapticFeedback.lightImpact();

    // Reset and restart animations for list only
    // _fadeController.reset();
    // _slideController.reset();
    // _fadeController.forward();
    // _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final visitorState = ref.watch(visitorViewModelProvider);

    return visitorState.visitorList.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
      data: (visitors) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickStats(visitors),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 30),
                          _buildTabBar(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildVisitorsList(visitors),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(List<Visitor> visitors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Today',
              _getTotalToday(visitors),
              Icons.people,
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Currently Inside',
              _getCurrentlyInside(visitors),
              Icons.login,
              const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Waiting',
              _getWaiting(visitors),
              Icons.access_time,
              const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3B62),
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Add',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3B62),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Guest',
                  Icons.person_add,
                  const Color(0xFF4CAF50),
                  () => VisitorManagementDialogs.showAddEntryDialog(
                    context,
                    ref,
                    type: EntryType.guest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionCard(
                  'Cab',
                  Icons.local_taxi,
                  const Color(0xFFFF9800),
                  () => VisitorManagementDialogs.showAddEntryDialog(
                    context,
                    ref,
                    type: EntryType.cab,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionCard(
                  'Delivery',
                  Icons.local_shipping,
                  const Color(0xFF2196F3),
                  () => VisitorManagementDialogs.showAddEntryDialog(
                    context,
                    ref,
                    type: EntryType.delivery,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionCard(
                  'Service',
                  Icons.build,
                  const Color(0xFF9C27B0),
                  () => VisitorManagementDialogs.showAddEntryDialog(
                    context,
                    ref,
                    type: EntryType.service,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AnimatedTapCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3B62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visitors List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3B62),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabItem('Scheduled', 0),
                _buildTabItem('Active', 1),
                _buildTabItem('Waiting', 2),
                _buildTabItem('History', 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<Visitor> _getFilteredVisitors(List<Visitor> visitors) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    switch (_selectedTabIndex) {
      case 1: // Active Today
        return visitors.where((v) {
          if (v.status != 1 || v.inDate == null) return false;

          try {
            final inDate = DateFormat("d MMM yyyy").parse(v.inDate!);
            return inDate == todayOnly;
          } catch (e) {
            return false;
          }
        }).toList();

      case 2: // Waiting Today
        return visitors.where((v) {
          if (v.status != 2 || v.inDate == null) return false;

          try {
            final inDate = DateFormat("d MMM yyyy").parse(v.inDate!);
            return inDate == todayOnly;
          } catch (e) {
            return false;
          }
        }).toList();

      // case 3: // History (all with outDate not null)
      //   return visitors.where((v) => v.outDate != null).toList();
      case 3: // History (Exited visitors)
  return visitors.where((v) {
    if (v.status != 3) return false;
    if (v.outDate == null || v.outDate!.isEmpty) return false;

    try {
      final outDate =
          DateFormat("d MMM yyyy").parse(v.outDate!);
      return !outDate.isAfter(todayOnly); // past or today
    } catch (e) {
      return false;
    }
  }).toList();


      case 0: // Pre-approved Upcoming
        return visitors.where((v) {
          if (v.status != 0) return false;

          try {
            final preDate = DateTime.parse(v.preDate!);
            return preDate.isAfter(todayOnly) && v.inDate == null;
          } catch (e) {
            return false;
          }
        }).toList();

      default:
        return visitors;
    }
  }

  // int _getTotalToday(List<Visitor> visitors) {
  //   final todayStr = DateFormat("d MMM yyyy").format(DateTime.now());
  //   return visitors
  //       .where((v) => v.inDate?.startsWith(todayStr) ?? false)
  //       .length;
  // }
  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

int _getTotalToday(List<Visitor> visitors) {
  final today = _onlyDate(DateTime.now());
  final Set<int> uniqueVisitors = {};

  for (final v in visitors) {
    if (v.visitorId == null) continue;

    // status 3 visitor skip
    if (v.status == 3) continue;

    bool counted = false;

    // in_date today check
    if (v.inDate != null && v.inDate!.isNotEmpty) {
      try {
        final inDate = _onlyDate(DateFormat('dd MMM yyyy').parse(v.inDate!));
        if (inDate == today) {
          uniqueVisitors.add(v.visitorId!);
          counted = true;
        }
      } catch (_) {}
    }

    // pre_date today check (only if not already counted)
    if (!counted && v.preDate != null && v.preDate!.isNotEmpty) {
      try {
        final preDate = _onlyDate(DateTime.parse(v.preDate!));
        if (preDate == today) {
          uniqueVisitors.add(v.visitorId!);
        }
      } catch (_) {}
    }
  }

  return uniqueVisitors.length;
}



  int _getCurrentlyInside(List<Visitor> visitors) {
    final todayStr = DateFormat("d MMM yyyy").format(DateTime.now());
    return visitors
        .where(
          (v) => v.status == 1 && (v.inDate?.startsWith(todayStr) ?? false),
        )
        .length;
  }

  int _getWaiting(List<Visitor> visitors) {
    final todayStr = DateFormat("d MMM yyyy").format(DateTime.now());
    return visitors
        .where(
          (v) => v.status == 2 && (v.inDate?.startsWith(todayStr) ?? false),
        )
        .length;
  }

  Widget _buildVisitorsList(List<Visitor> visitors) {
    final filteredVisitors = _getFilteredVisitors(visitors);

    if (filteredVisitors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 90, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'No visitors found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'There are no visitors in this category right now.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Build list WITHOUT staggered animations on rebuild
    // Only animate on initial load
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: filteredVisitors.map((visitor) {
          return Container(
            key: ValueKey(visitor.visitorId), // Important: Use unique key
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildVisitorCard(visitor),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(String? datetime) {
    if (datetime == null || datetime.isEmpty) return "--";
    try {
      final dateTime = DateTime.parse(datetime);
      return DateFormat("hh:mm a").format(dateTime);
    } catch (e) {
      return datetime;
    }
  }

  Widget _buildVisitorCard(Visitor visitor) {
    return AnimatedTapCard(
      onTap: () => _showVisitorDetails(visitor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 1, color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _getTypeColor(
                      _parseVisitorType(visitor.type),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: visitor.image != null && visitor.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            visitor.image!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              (loadingProgress
                                                      .expectedTotalBytes ??
                                                  1)
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Icon(
                              _getTypeIcon(_parseVisitorType(visitor.type)),
                              color: _getTypeColor(
                                _parseVisitorType(visitor.type),
                              ),
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          _getTypeIcon(_parseVisitorType(visitor.type)),
                          color: _getTypeColor(_parseVisitorType(visitor.type)),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${visitor.type ?? ''}${(visitor.company != null && visitor.company!.isNotEmpty) ? ': ${visitor.company}' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3B62),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visitor.vName ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF2E3B62),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      visitor.preDate != null && visitor.preDate!.isNotEmpty
                          ? DateFormat(
                              'dd MMM yyyy',
                            ).format(DateTime.parse(visitor.preDate!))
                          : visitor.inDate ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2E3B62),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GatePassScreen(
                            guestName: visitor.vName ?? 'Unknown',
                            otp: (visitor.gateOtp ?? 'N/A').toString(),
                            flatNo:
                                ref.watch(basicInfoViewModelProvider).unit ??
                                'N/A',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _parseVisitorType(String? type) {
    switch (type?.toLowerCase().trim()) {
      case "guest":
        return "guest";
      case "cab":
        return "cab";
      case "delivery":
        return "delivery";
      case "service":
        return "service";
      default:
        return "unknown";
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case "guest":
        return const Color(0xFF4CAF50);
      case "cab":
        return const Color(0xFFFF9800);
      case "delivery":
        return const Color(0xFF2196F3);
      case "service":
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case "guest":
        return Icons.person;
      case "cab":
        return Icons.local_taxi;
      case "delivery":
        return Icons.local_shipping;
      case "service":
        return Icons.build;
      default:
        return Icons.person;
    }
  }

  void _showVisitorDetails(Visitor visitor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          VisitorDetailsBottomSheet(visitor: visitor, ref: ref),
    );
  }
}

// Custom Animated Tap Card Widget (matching Directory screen)
class AnimatedTapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedTapCard({super.key, required this.child, required this.onTap});

  @override
  _AnimatedTapCardState createState() => _AnimatedTapCardState();
}

class _AnimatedTapCardState extends State<AnimatedTapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

// Visitor Details Bottom Sheet
// Add this to your VisitorDetailsBottomSheet class in the visitor management screen
// Add this to your VisitorDetailsBottomSheet class in the visitor management screen

class VisitorDetailsBottomSheet extends StatefulWidget {
  final Visitor visitor;
  final WidgetRef ref;

  const VisitorDetailsBottomSheet({
    super.key,
    required this.visitor,
    required this.ref,
  });

  @override
  State<VisitorDetailsBottomSheet> createState() =>
      _VisitorDetailsBottomSheetState();
}

class _VisitorDetailsBottomSheetState extends State<VisitorDetailsBottomSheet> {
  bool _isProcessing = false;

  Future<void> _handleApprove() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Get the parent context BEFORE closing the bottom sheet
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Close the bottom sheet
    if (mounted) {
      Navigator.pop(context);
    }

    // Call the optimistic update method
    final success = await widget.ref
        .read(visitorViewModelProvider.notifier)
        .updateWaitingStatusOptimistic(widget.visitor.visitorId ?? 0);

    // Show result using the captured ScaffoldMessenger
    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Visitor approved successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final errorMessage =
          widget.ref.read(visitorViewModelProvider).error ??
          'Something went wrong. Please try again.';

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _handleApprove(),
          ),
        ),
      );

      widget.ref.read(visitorViewModelProvider.notifier).clearError();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.visitor.image != null &&
                        widget.visitor.image!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenGallery(
                            images: [widget.visitor.image!],
                            initialIndex: 0,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _getTypeColor(
                        _parseVisitorType(widget.visitor.type),
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        widget.visitor.image != null &&
                            widget.visitor.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.visitor.image!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  _getTypeIcon(
                                    _parseVisitorType(widget.visitor.type),
                                  ),
                                  color: _getTypeColor(
                                    _parseVisitorType(widget.visitor.type),
                                  ),
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : Icon(
                            _getTypeIcon(
                              _parseVisitorType(widget.visitor.type),
                            ),
                            color: _getTypeColor(
                              _parseVisitorType(widget.visitor.type),
                            ),
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.visitor.vName ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3B62),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (widget.visitor.company == null ||
                                widget.visitor.company!.isEmpty)
                            ? 'GUEST'
                            : widget.visitor.company!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.home,
              'Flat No',
              widget.ref.watch(basicInfoViewModelProvider).unit ?? 'N/A',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.phone,
              'Contact No',
              widget.visitor.contactNo ?? 'N/A',
            ),
            if (widget.visitor.purpose != null &&
                widget.visitor.purpose!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.description,
                'Reason for Visit',
                widget.visitor.purpose ?? "",
              ),
            ],
            if (widget.visitor.inDate != null &&
                widget.visitor.inDate!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.calendar_today,
                'Check-In Date',
                DateFormat('dd MMM yyyy').format(
                  DateFormat('dd MMM yyyy').parse(widget.visitor.inDate!),
                ),
              ),
            ],
            if (widget.visitor.outDate != null &&
                widget.visitor.outDate!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.calendar_today,
                'Check-Out Date',
                DateFormat('dd MMM yyyy').format(
                  DateFormat('dd MMM yyyy').parse(widget.visitor.outDate!),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (widget.visitor.vehicleNo != null &&
                widget.visitor.vehicleNo!.isNotEmpty)
              _buildDetailRow(
                Icons.directions_car,
                'Vehicle Number',
                widget.visitor.vehicleNo ?? 'N/A',
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      if (widget.visitor.status == 2) {
                        _handleApprove();
                      } else {
                        Navigator.pop(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.visitor.status == 1
                          ? 'Done'
                          : widget.visitor.status == 2
                          ? 'Approve'
                          : 'Done',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2E3B62)),
          ),
        ),
      ],
    );
  }

  String _parseVisitorType(String? type) {
    switch (type?.toLowerCase().trim()) {
      case "guest":
        return "guest";
      case "cab":
        return "cab";
      case "delivery":
        return "delivery";
      case "service":
        return "service";
      default:
        return "unknown";
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case "guest":
        return Icons.person;
      case "cab":
        return Icons.local_taxi;
      case "delivery":
        return Icons.local_shipping;
      case "service":
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case "guest":
        return Colors.green;
      case "cab":
        return Colors.orange;
      case "delivery":
        return Colors.blue;
      case "service":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
