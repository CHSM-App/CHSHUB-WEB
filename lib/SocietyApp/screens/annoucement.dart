import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/domain/models/broadcast.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

Map<String, dynamic> getCategoryStyle(String? category) {
  switch (category?.toLowerCase()) {
    case 'event':
      return {
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.celebration_outlined,
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      };
    case 'meeting':
      return {
        'color': const Color(0xFF3B82F6),
        'icon': Icons.groups_outlined,
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      };
    case 'maintenance':
      return {
        'color': const Color(0xFFF59E0B),
        'icon': Icons.build_outlined,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      };
    case 'notice':
      return {
        'color': const Color(0xFFEF4444),
        'icon': Icons.campaign_outlined,
        'gradient': [const Color(0xFFEF4444), const Color(0xFFF59E0B)],
      };
    case 'helpdesk':
      return {
        'color': const Color(0xFF06B6D4),
        'icon': Icons.headset_mic_outlined,
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF8B5CF6)],
      };
    default:
      return {
        'color': const Color(0xFF6B7280),
        'icon': Icons.notifications_outlined,
        'gradient': [const Color(0xFF6B7280), const Color(0xFF9CA3AF)],
      };
  }
}

class AnnouncementsScreen extends ConsumerStatefulWidget {
  final int? selectedAnnouncement;
  final String? selectedAnnouncementType;

  const AnnouncementsScreen({
    super.key,
    this.selectedAnnouncement,
    this.selectedAnnouncementType,
  });

  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();


      
    

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

    _fadeController.forward();
    _slideController.forward();
    
     WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _loadData();
    if (widget.selectedAnnouncement != null && mounted) {
      _showAnnouncementDialog(
        widget.selectedAnnouncement!,
        widget.selectedAnnouncementType,
      );
    }
  });

  }
Future<void> _loadData() async {
  var basicInfo = ref.read(basicInfoViewModelProvider);

  if ((basicInfo.societyID ?? '').isEmpty || (basicInfo.ownerId ?? 0) == 0) {
    await ref.read(basicInfoViewModelProvider.notifier).getBasicInfo();
    basicInfo = ref.read(basicInfoViewModelProvider);
  }

  await ref.read(broadcastViewModelProvider.notifier).getBroadcast(
    basicInfo.societyID ?? '',
    basicInfo.ownerId ?? 0,
  );
}


  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAnnouncementDialog(int id, [String? notificationType]) async {
    final notices = ref.read(broadcastViewModelProvider).broadcastList;
    debugPrint('[DIALOG_LOOKUP] requested id=$id type=$notificationType');
    notices.whenData((list) {
      for (final n in list) {
        debugPrint(
          '[DIALOG_LOOKUP] candidate record=${n.record} type=${n.notificationType} name=${n.name}',
        );
      }
    });
    bool matches(Broadcast n) =>
        n.record == id &&
        (notificationType == null ||
            (n.notificationType ?? '').toLowerCase() ==
                notificationType.toLowerCase());
    final announcement = notices.maybeWhen(
      data: (list) => list.any(matches) ? list.firstWhere(matches) : null,
      orElse: () => null,
    );
    debugPrint(
      '[DIALOG_LOOKUP] resolved -> record=${announcement?.record} '
      'type=${announcement?.notificationType} name=${announcement?.name}',
    );


    final style = getCategoryStyle(announcement?.notificationType);

    // Prepare visibility flags
    final hasValidDate =
        announcement?.toDate != null && announcement!.toDate!.trim().isNotEmpty;
    final hasDescription =
        announcement?.description != null &&
        announcement!.description!.trim().isNotEmpty;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Announcement Details',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.5,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== HEADER =====
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: style['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  style['icon'],
                                  color: style['color'],
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      announcement?.name ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      announcement?.notificationType ??
                                          'General',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: style['color'].withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => {
                                  ref
                                      .read(broadcastViewModelProvider.notifier)
                                      .updateNotificationStatus(
                                        announcement?.notifyStatusId ?? 0,
                                        ref
                                                .watch(
                                                  basicInfoViewModelProvider,
                                                )
                                                .societyID ??
                                            "",
                                        ref
                                                .watch(
                                                  basicInfoViewModelProvider,
                                                )
                                                .ownerId ??
                                            0,
                                      ),
                                  Navigator.of(context).pop(),
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(height: 1, color: const Color(0xFFE5E7EB)),

                    // ===== BODY CONTENT =====
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show valid date only if available
                            if (hasValidDate) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: style['color'],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Valid Date: ${_formatToReadableDate(announcement.toDate)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Show details only if description is present
                            if (hasDescription) ...[
                              const Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  announcement.description!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF374151),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ===== BOTTOM BUTTON =====
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => {
                            ref
                                .read(broadcastViewModelProvider.notifier)
                                .updateNotificationStatus(
                                  announcement?.notifyStatusId ?? 0,
                                  ref
                                          .watch(basicInfoViewModelProvider)
                                          .societyID ??
                                      "",
                                  ref
                                          .watch(basicInfoViewModelProvider)
                                          .ownerId ??
                                      0,
                                ),
                            Navigator.of(context).pop(),
                              ref.read(broadcastViewModelProvider.notifier)
            .getNotification(ref.read(basicInfoViewModelProvider).societyID!, ref.read(basicInfoViewModelProvider).ownerId!)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: style['color'],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatToReadableDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('d MMM yyyy').format(parsedDate); // → 25 Oct 2025
    } catch (e) {
      return rawDate; // fallback if parsing fails
    }
  }

@override
Widget build(BuildContext context) {
  final notices = ref.watch(broadcastViewModelProvider).broadcastList;

  return Scaffold(
    backgroundColor: const Color(0xFFF8F9FA),
    appBar: AppBar(
      leading: const BackButton(color: Colors.black),
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Announcements',
        style: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    body: notices.when(
      loading: () => const Center(child: CircularProgressIndicator()),
  error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),

      data: (announcements) {
        final filteredAnnouncements = announcements.where((a) {
          final type = (a.notificationType ?? '').toLowerCase().trim();
          return ['event', 'notice', 'meeting'].contains(type);
        }).toList();

        // ✅ Empty state widget if no announcements found
        if (filteredAnnouncements.isEmpty) {
          return RefreshIndicator(
            onRefresh: _loadData,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'ll notify you when something arrives',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // ✅ Show list with animation if data exists
        return RefreshIndicator(
          onRefresh: _loadData,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredAnnouncements.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 800 + (index * 100)),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: AnnouncementCard(
                          announcement: filteredAnnouncements[index],
                          index: index,
                          formatDate: _formatDate,
                          onTap: () => _showAnnouncementDialog(
                            filteredAnnouncements[index].record ?? 0,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}

    }
class AnnouncementCard extends StatefulWidget {
  final Broadcast announcement;
  final int index;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.index,
    required this.formatDate,
    required this.onTap,
  });

  @override
  _AnnouncementCardState createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard>
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
    final style = getCategoryStyle(widget.announcement.notificationType);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white, // ✅ White card background
            borderRadius: BorderRadius.circular(20), // ✅ Rounded corners
            // boxShadow: [
            //   BoxShadow(
            //     color: style['color'].withOpacity(0.15), // soft colored shadow
            //     blurRadius: 18,
            //     offset: const Offset(0, 6),
            //   ),
            // ],
            border: Border.all(
              color: style['color'].withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // ✅ Left gradient accent
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    // gradient: LinearGradient(
                    //   colors: List<Color>.from(style['gradient'] ?? <Color>[]),
                    //   begin: Alignment.topCenter,
                    //   end: Alignment.bottomCenter,
                    // ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              // ✅ Main card content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon box with gradient
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: List<Color>.from(
                                style['gradient'] ?? <Color>[],
                              ),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: style['color'].withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            style['icon'],
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.announcement.name ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (widget.announcement.seenStatus == 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.fiber_new,
                                        color: Colors.red.shade400,
                                        size: 26,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: List<Color>.from(
                                      style['gradient'] ?? <Color>[],
                                    ).map((c) => c.withOpacity(0.15)).toList(),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.announcement.notificationType ??
                                      'General',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: style['color'],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                 
                    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // ✅ Wrap in Expanded to prevent overflow
    Expanded(
      child: Text(
        widget.announcement.description != null &&
                widget.announcement.description!.length > 30
            ? '${widget.announcement.description!.substring(0, 30)}...'
            : (widget.announcement.description ??
                'No description available'),
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis, // just in case
        maxLines: 10,
      ),
    ),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: style['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.announcement.timestamp ?? '',
        style: TextStyle(
          fontSize: 12,
          color: style['color'],
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ],
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
  
}
