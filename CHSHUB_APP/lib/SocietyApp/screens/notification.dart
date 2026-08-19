import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/helpdesk_details.dart';
import 'package:society_app/SocietyApp/screens/annoucement.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/maintenanceBill.dart';
import 'package:society_app/SocietyApp/screens/society_polls.dart';
import '../../domain/models/broadcast.dart';
import '../../presentation/providers/viewModel_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // Animation controllers for fade and slide (from directory)
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize continuous animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Initialize fade and slide animations (from directory)
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
    _loadData();
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final info = ref.read(basicInfoViewModelProvider);

      if ((info.societyID ?? "").isNotEmpty && (info.ownerId ?? 0) != 0) {
        ref.read(broadcastViewModelProvider.notifier)
            .getNotification(info.societyID!, info.ownerId!);
        
        // Start fade and slide animations
        _fadeController.forward();
        _slideController.forward();
      } else {
        debugPrint("⚠️ Basic info not ready yet - getBroadcast skipped");
      }
    }); 
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Dialog types that should show dialog instead of navigating
  bool _shouldShowDialog(String? type) {
    final dialogTypes = ['gas', 'water', 'power', 'custom', 'fire'];
    return dialogTypes.contains(type?.toLowerCase());
  }

  // Show notification dialog
  void _showNotificationDialog(Broadcast notification) {
    final color = _getNotificationColor(notification.notificationType);
    final icon = _getNotificationIcon(notification.notificationType);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  notification.title ?? 'Notification',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message/Body
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Text(
                      notification.body ?? 'No message',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Timestamp
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTimeAgo(notification.timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Update notification status
                      _updateNotificationStatus(notification);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Update status when dialog is dismissed
      _updateNotificationStatus(notification);
    });
  }

  // Update notification status
  void _updateNotificationStatus(Broadcast notification) {
    final info = ref.read(basicInfoViewModelProvider);
    if (notification.notifyStatusId != null) {
      ref.read(broadcastViewModelProvider.notifier).updateNotificationStatus(
        notification.notifyStatusId!,
        info.societyID ?? "",
        info.ownerId ?? 0,
      );
    }
    _loadData();
  }

  // Refresh both broadcast (Notices) and notification (Helpdesk/Maintenance/
  // Visitor) lists so home-screen badges update as soon as a detail screen
  // marks its notification as read and the user comes back.
  void _refreshBroadcastAndNotifications() {
    final info = ref.read(basicInfoViewModelProvider);
    ref.read(broadcastViewModelProvider.notifier)
        .getBroadcast(info.societyID ?? "", info.ownerId ?? 0);
    ref.read(broadcastViewModelProvider.notifier)
        .getNotification(info.societyID ?? "", info.ownerId ?? 0);
  }

  void _handleNotificationTap(Broadcast notification) async {
    final type = notification.notificationType?.toLowerCase() ?? '';
    debugPrint(
      '[NOTIF_TAP] type=$type notificationType=${notification.notificationType} '
      'notificationId=${notification.notificationId} record=${notification.record} '
      'notifyStatusId=${notification.notifyStatusId}',
    );

    // Check if this notification type should show dialog
    if (_shouldShowDialog(type)) {
      _showNotificationDialog(notification);
      return;
    }

    // Original navigation logic for other types
    switch (type) {
      case 'notice':
      case 'event':
      case 'meeting':
        _updateNotificationStatus(notification);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnnouncementsScreen(
              selectedAnnouncement:
                  notification.record ?? notification.notificationId ?? 0,
              selectedAnnouncementType: notification.notificationType,
            ),
          ),
        ).then((_) => _refreshBroadcastAndNotifications());
        break;

      case 'helpdesk comment':
      case 'helpdesk':
        final helpdeskId = notification.record ?? notification.notificationId ?? 0;
        if (helpdeskId != 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailPage(
                helpdeskID: notification.record ?? notification.notificationId,
                notifyStatusId: notification.notifyStatusId ?? 0,
              ),
            ),
          ).then((_) => _refreshBroadcastAndNotifications());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Helpdesk ID not found')),
          );
        }
        break;

      case 'maintenance':
        final maintenanceId = notification.record ?? notification.notificationId ?? 0;
        if (maintenanceId != 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrintMaintenanceBill(
                maintenanceId: notification.notificationId ?? 0,
                notifyStatusId: notification.notifyStatusId ?? 0,
              ),
            ),
          ).then((_) => _refreshBroadcastAndNotifications());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maintenance ID not found')),
          );
        }
        break;
        //  case 'poll':
        // final pollId = notification.record ?? notification.notificationId ?? 0;
        // if (pollId != 0) {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => PollsScreen(
        //         pollId: notification.notificationId ?? 0,
        //         notifyStatusId: notification.notifyStatusId ?? 0,
        //       ),
        //     ),
        //   ).then((_) {
        //     final info = ref.read(basicInfoViewModelProvider);
        //     ref.read(broadcastViewModelProvider.notifier)
        //         .getBroadcast(info.societyID ?? "", info.ownerId ?? 0);
        //   });
        // } else {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(content: Text('Maintenance ID not found')),
        //   );
        // }
        // break;
        case 'poll':
  final pollId = notification.record ?? notification.notificationId ?? 0;
  if (pollId != 0) {
    // 1️⃣ Update notification status first
    _updateNotificationStatus(notification);

    // 2️⃣ Navigate to PollsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PollsScreen(
          pollId: pollId, // ✅ pass correct pollId
          notifyStatusId: notification.notifyStatusId ?? 0,
        ),
      ),
    ).then((_) => _refreshBroadcastAndNotifications());
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll ID not found')), // ✅ correct msg
    );
  }
  break;


      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unknown notification type'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'notice':
        return Icons.campaign_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'helpdesk comment':
      case 'helpdesk':
        return Icons.support_agent_rounded;
      case 'visitor':
        return Icons.person_outline_rounded;
      case 'gas':
        return Icons.local_gas_station_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'power':
        return Icons.bolt_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'custom':
        return Icons.settings_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'notice':
        return const Color(0xFF6366F1);
      case 'event':
        return const Color(0xFFEC4899);
      case 'helpdesk comment':
      case 'helpdesk':
        return const Color(0xFF10B981);
      case 'visitor':
        return const Color(0xFFF59E0B);
      case 'gas':
        return const Color(0xFFEF4444);
      case 'water':
        return const Color(0xFF3B82F6);
      case 'power':
        return const Color(0xFFFBBF24);
      case 'fire':
        return const Color(0xFFDC2626);
      case 'custom':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Just now';
    return timestamp;
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(broadcastViewModelProvider).notificationList;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 50,
            flexibleSpace: SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.blue.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          notificationState.when(
            data: (notifications) {
              final unseenNotifications =
                  notifications.where((n) => n.seenStatus == 0).toList();

              if (unseenNotifications.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              return SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Header with animated count badge
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Row(
                            children: [
                              _buildAnimatedCountBadge(unseenNotifications.length),
                            ],
                          ),
                        ),

                        // Notification List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: unseenNotifications.length,
                          itemBuilder: (context, index) {
                            return TweenAnimationBuilder(
                              duration: Duration(milliseconds: 800 + (index * 100)),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: _buildModernNotificationCard(
                                    unseenNotifications[index],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading notifications...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (err, st) => SliverFillRemaining(
              child: _buildErrorState(err),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return ErrorStatePage(
      error: error,
      onRetry: _loadData,
    );
  }

  Widget _buildAnimatedCountBadge(int count) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade500,
                  Colors.blue.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(_glowAnimation.value),
                  blurRadius: 12 + (_glowAnimation.value * 8),
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fiber_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count New',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernNotificationCard(Broadcast notification) {
    final color = _getNotificationColor(notification.notificationType);
    final icon = _getNotificationIcon(notification.notificationType);
    final isUnseen = notification.seenStatus == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnseen
            ? Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isUnseen 
                ? color.withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            blurRadius: isUnseen ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Subtitle gradient overlay for unseen
              if (isUnseen)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with gradient
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color,
                                color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        // Unseen indicator - pulsing dot
                        if (isUnseen)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            notification.title ?? 'No Title',
                            style: TextStyle(
                              fontWeight: isUnseen ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Body text
                          Text(
                            notification.body ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnseen ? Colors.grey.shade700 : Colors.grey.shade600,
                              height: 1.4,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Footer with type and time
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  notification.notificationType?.toUpperCase() ?? 'INFO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),

                              // Time
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      _getTimeAgo(notification.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications right now',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}