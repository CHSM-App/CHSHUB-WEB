import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:society_app/SocietyApp/screens/annoucement.dart';
import 'package:society_app/SocietyApp/screens/document_list.dart';
import 'package:society_app/SocietyApp/screens/noc_request.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/members.dart';
import 'package:society_app/SocietyApp/screens/productlist.dart';
import 'package:society_app/SocietyApp/screens/security_dailog.dart';
import 'package:society_app/SocietyApp/screens/service.dart';
import 'package:society_app/SocietyApp/screens/society_polls.dart';
import '../../presentation/providers/viewModel_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Main controllers
  late final AnimationController _pageController;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;
  late final Animation<double> _pageScale;

  // Individual card controllers (staggered) - Updated count for new cards
  final int _cardCount = 11;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardScales = [];
  final List<Animation<double>> _cardFades = [];

  // Scroll & parallax (ValueNotifier to minimize rebuilds)
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);

  // Track pressing state per card index for tap animation
  final Map<int, bool> _isPressed = {};
  bool _isServicesExpanded = false;

  @override
  void initState() {
    super.initState();

    // Page-level animations
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pageFade = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    );
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
        );
    _pageScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutBack),
    );

    // Card controllers initialization
    for (int i = 0; i < _cardCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + (i * 70)),
      );

      final scale = Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));

      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));

      _cardControllers.add(controller);
      _cardScales.add(scale);
      _cardFades.add(fade);

      _isPressed[i] = false;
    }

    // Scroll listener -> ValueNotifier (less rebuilding)
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });

    // Start animations
    _pageController.forward();

    // Stagger cards
    _startStaggeredCards();

    // Kick off loading of due/transaction
    Future.microtask(() async {
      _initPushNotifications();
    _loadData();

  });

    
  }
  Future<void> _loadData() async {
  //  ref.read(alertViewModelProvider.notifier).initListeners();
      final flatId = ref.watch(basicInfoViewModelProvider).flatId ?? 0;
      await ref
          .read(TransactionViewModelProvider.notifier)
          .getTransactionDue(flatId);

      await ref
          .read(visitorViewModelProvider.notifier)
          .getVisitorList(DateTime.now().toString().split(' ')[0], flatId);
    await ref
        .read(broadcastViewModelProvider.notifier)
  
      .getBroadcast(ref.read(basicInfoViewModelProvider).societyID ?? "", ref.read(basicInfoViewModelProvider).ownerId ?? 0);

  await ref.read(broadcastViewModelProvider.notifier).getNotification(ref.read(basicInfoViewModelProvider).societyID??"",ref.read(basicInfoViewModelProvider).ownerId??0);
}

  void _startStaggeredCards() {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  Future<void> _initPushNotifications() async {
    NotificationSettings settings = await ref
        .read(firebaseMessagingProvider)
        .requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await ref
          .read(alertViewModelProvider.notifier)
          .insertToken(
            ref.watch(basicInfoViewModelProvider).ownerId ?? 0,
            ref.watch(basicInfoViewModelProvider).loginType ?? '',
          );

      debugPrint("token inserted");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: 
      FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: ScaleTransition(
            scale: _pageScale,
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollOffset,
              builder: (context, offset, _) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with parallax
                      Transform.translate(
                        offset: Offset(0, offset * 0.25),
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildDashboardCard(0, isSmallScreen)),
                                      SizedBox(width: 8),
                                    Expanded(child: _buildDashboardCard(1, isSmallScreen)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Main area
                      Padding(
                        padding: EdgeInsets.only(
                          left: isSmallScreen ? 6 : 10,
                          right: isSmallScreen ? 6 : 10,
                          top: 0,
                          bottom: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeTransition(
                              opacity: _pageFade,
                              child: Padding(
                                padding: EdgeInsets.only(left: isSmallScreen ? 6 : 10),
                                child: Text(
                                  'Quick Access',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E3B62),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            buildHorizontalCards(isSmallScreen),
                            const SizedBox(height: 10),

                            Consumer(
                              builder: (context, ref, _) {
                                final asyncBroadcast = ref
                                    .watch(broadcastViewModelProvider)
                                    .broadcastList;

                                return asyncBroadcast.when(
                                  data: (broadcastList) {
                                    final now = DateTime.now();
                                    final filteredList = broadcastList.where((item) {
                                      try {
                                        final validDateString =
                                            item.toDate ?? item.timestamp ?? '';
                                        final validDate = DateTime.parse(validDateString);
                                        return validDate.isAfter(now) ||
                                            validDate.isAtSameMomentAs(now);
                                      } catch (_) {
                                        return false;
                                      }
                                    }).toList();

                                    if (filteredList.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    final showViewMore = filteredList.length > 2;
                                    final limitedList = filteredList.take(2).toList();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FadeTransition(
                                          opacity: _pageFade,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isSmallScreen ? 6 : 10,
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'Recent Announcements',
                                                    style: TextStyle(
                                                      fontSize: isSmallScreen ? 14 : 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF2E3B62),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (showViewMore)
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => AnnouncementsScreen(),
                                                        ),
                                                      );
                                                    },
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: const Size(50, 30),
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      'View More',
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 11 : 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFF2196F3),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ListView.separated(
                                          physics: const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: limitedList.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final item = limitedList[index];
                                            final icon = (item.notificationType?.toLowerCase() == 'event')
                                                ? Icons.celebration
                                                : Icons.campaign;

                                            return _buildAnnouncementCard(
                                              item.name ?? 'No Title',
                                              item.description ?? '',
                                              item.timestamp ?? '',
                                              icon,
                                              isSmallScreen,
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                    loading: () => const SizedBox.shrink(),

                                    // error: (err, _) => const SizedBox.shrink(),
                                    error: (err, _) => ErrorStatePage(
                                      error: err,
                                      onRetry: _loadData,
                                    ),
                                  );
                                },
                            ),

                            const SizedBox(height: 10),
                            FadeTransition(
                              opacity: _pageFade,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: isSmallScreen ? 6 : 10,
                                  right: isSmallScreen ? 6 : 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Services',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2E3B62),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isServicesExpanded = !_isServicesExpanded;
                                        });
                                      },
                                      child: Text(
                                        _isServicesExpanded ? 'View Less' : 'View More',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2196F3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            buildVerticalCards(isSmallScreen),

                            const SizedBox(height: 10),
                            FadeTransition(
                              opacity: _pageFade,
                              child: Padding(
                                padding: EdgeInsets.only(left: isSmallScreen ? 6 : 10),
                                child: Text(
                                  'Community',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E3B62),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            _buildMarketplaceCard(8, isSmallScreen),
                            const SizedBox(height: 12),
                            _buildHappyCommunityCard(9, isSmallScreen),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      ),floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const SecurityAlertDialog(),
          );
        },
        backgroundColor: const Color(0xFF2E3B62),
        child: const Icon(
          color: Colors.white,
          Icons.security,
          size: 25,
        ),
      ),
    );
  }
  
  Widget _buildDashboardCard(int animationIndex, bool isSmallScreen) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0), // space between cards
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        height: isSmallScreen ? 115 : 125, // increased card height
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  animationIndex == 0
                      ? _getPendingDuesText()
                      : _getVisitorsToday(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 47, 88),
                  ),
                ),
              ),
            ),

            Text(
              animationIndex == 0 ? "Pending Dues" : "Visitors Today",
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.blueGrey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
         SizedBox(height: 15), // smaller gap

          // const Spacer(),

            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 30 : 34, // bigger button
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: animationIndex == 0
                      ? const Color(0xFFE31837)
                      : const Color(0xFF008116),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // more rounded
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  ref.read(bottomNavIndexProvider.notifier).state =
                      animationIndex == 0 ? 3 : 2;
                },
                child: Text(
                  animationIndex == 0 ? "Pay" : "View",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  String _getPendingDuesText() {
    final state = ref.watch(TransactionViewModelProvider);
    return state.transaction.maybeWhen(
      data: (balance) => balance,
      loading: () => 'Loading...',
      orElse: () => 'Error',
    );
  }
  
String _getVisitorsToday() {
  final state = ref.watch(visitorViewModelProvider);

  return state.visitorList.maybeWhen(
    data: (visitors) {
      final today = _onlyDate(DateTime.now());
      final Set<int> uniqueVisitors = {};

      for (final v in visitors) {
        if (v.visitorId == null) continue;

        // status 3 visitor skip
        if (v.status == 3) continue;

        bool counted = false;

        // in_date today
        if (v.inDate != null && v.inDate!.isNotEmpty) {
          try {
            final inDate = _onlyDate(DateFormat('dd MMM yyyy').parse(v.inDate!));
            if (inDate == today) {
              uniqueVisitors.add(v.visitorId!);
              counted = true;
            }
          } catch (_) {}
        }

        // pre_date today
        if (!counted && v.preDate != null && v.preDate!.isNotEmpty) {
          try {
            final preDate = _onlyDate(DateTime.parse(v.preDate!));
            if (preDate == today) {
              uniqueVisitors.add(v.visitorId!);
            }
          } catch (_) {}
        }
      }

      return uniqueVisitors.length.toString();
    },
    loading: () => 'Loading...',
    orElse: () => '0',
  );
}

DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  Widget buildHorizontalCards(bool isSmallScreen) {
    return GridView.count(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: isSmallScreen ? 12 : 20,
      mainAxisSpacing: isSmallScreen ? 12 : 20,
      childAspectRatio: isSmallScreen ? 0.85 : 0.95,
      children: [
        _buildAnimatedFeatureCard(
          0,
          title: 'Helpdesk',
          icon: Icons.headset_mic,
          color: const Color(0xFF4CAF50),
          onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
          subtitle: "Helpdesk",
          isSmallScreen: isSmallScreen,
        ),
        _buildAnimatedFeatureCard(
          1,
          title: 'Visitors',
          icon: Icons.people_outline,
          color: const Color(0xFF2196F3),
          onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
          subtitle: "Visitor",
          isSmallScreen: isSmallScreen,
        ),
        _buildAnimatedFeatureCard(
          2,
          title: 'Notices',
          icon: Icons.campaign,
          color: const Color(0xFFFF9800),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AnnouncementsScreen()),
          ),
          subtitle: "Announcements",
          isSmallScreen: isSmallScreen,
        ),
        _buildAnimatedFeatureCard(
          3,
          title: 'Payment',
          icon: Icons.payment,
          color: const Color(0xFFE91E63),
          onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 3,
          subtitle: "Maintenance",
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }


  Widget _buildAnimatedFeatureCard(
  int index, {
  required String title,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  String? subtitle,
  required bool isSmallScreen,
}) {
  final safeIndex = index.clamp(0, _cardScales.length - 1);

  // ✅ Watch both broadcast & notification providers
  final broadcastState = ref.watch(broadcastViewModelProvider);
  final broadcastList = broadcastState.broadcastList.asData?.value ?? [];
  final notificationList = broadcastState.notificationList.asData?.value ?? [];

  String normalize(String? text) => (text ?? '').toLowerCase().trim();
  int unseenCount = 0;

  // ✅ Announcements (from broadcastList)
  if (normalize(subtitle) == 'announcements') {
    unseenCount = broadcastList
        .where((n) =>
            n.seenStatus == 0 &&
            ['notice', 'event', 'meeting'].contains(normalize(n.notificationType)))
        .length;
  }
  // ✅ Helpdesk (from notificationList)
  else if (normalize(subtitle).contains('helpdesk')) {
    unseenCount = notificationList
        .where((n) =>
            n.seenStatus == 0 &&
            normalize(n.notificationType).contains('helpdesk'))
        .length;
  }
  else if (normalize(subtitle).contains('maintenance')) {
    unseenCount = notificationList
        .where((n) =>
            n.seenStatus == 0 &&
            normalize(n.notificationType).contains('maintenance'))
        .length;
  }
   else if (normalize(subtitle).contains('visitor')) {
    unseenCount = notificationList
        .where((n) =>
            n.seenStatus == 0 &&
            normalize(n.notificationType).contains('visitor'))
        .length;
  }
  
  
  // ✅ Other types (optional fallback)
  else {
    unseenCount = broadcastList
        .where((n) =>
            n.seenStatus == 0 &&
            normalize(n.notificationType) == normalize(subtitle))
        .length;
  }

  final isLoading =
      broadcastState.broadcastList.isLoading || broadcastState.notificationList.isLoading;

  return AnimatedBuilder(
    animation: Listenable.merge([_cardControllers[safeIndex]]),
    builder: (context, child) {
      final scale = _cardScales[safeIndex].value;
      final opacity = _cardFades[safeIndex].value;
      final pressed = _isPressed[safeIndex] ?? false;
      final tapScale = pressed ? 0.96 : 1.0;

      return Transform.scale(
        scale: scale * tapScale,
        child: Opacity(
          opacity: opacity,
          child: _buildTappableCard(
            onTapDown: () => _setPressed(safeIndex, true),
            onTapUp: () => _onCardTap(safeIndex, onTap),
            onTapCancel: () => _setPressed(safeIndex, false),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.06),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: isSmallScreen ? 22 : 28),
                      ),
                      if (!isLoading && unseenCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 3 : 5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unseenCount.toString(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E3B62),
                        height: 1.2,
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

  Widget _buildMarketplaceCard(int animationIndex, bool isSmallScreen) {
    final safeIndex = animationIndex.clamp(0, _cardScales.length - 1);
    return AnimatedBuilder(
      animation: Listenable.merge([_cardControllers[safeIndex]]),
      builder: (context, child) {
        final scale = _cardScales[safeIndex].value;
        final opacity = _cardFades[safeIndex].value;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductScreen()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A5ACD).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🛍️ Community Marketplace',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              'Discover amazing deals from your neighbors! Buy and sell items within our society.',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 12,
                                vertical: isSmallScreen ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Shop Now →',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: isSmallScreen ? 60 : 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.store,
                            color: Colors.white,
                            size: isSmallScreen ? 30 : 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHappyCommunityCard(int animationIndex, bool isSmallScreen) {
    final safeIndex = animationIndex.clamp(0, _cardScales.length - 1);
    return AnimatedBuilder(
      animation: Listenable.merge([_cardControllers[safeIndex]]),
      builder: (context, child) {
        final scale = _cardScales[safeIndex].value;
        final opacity = _cardFades[safeIndex].value;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E3B62).withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3B62).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.groups,
                            color: const Color(0xFF2E3B62),
                            size: isSmallScreen ? 24 : 32,
                          ),
                          Positioned(
                            top: 0,
                            right: 2,
                            child: Container(
                              width: isSmallScreen ? 4 : 6,
                              height: isSmallScreen ? 4 : 6,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            left: 0,
                            child: Container(
                              width: isSmallScreen ? 3 : 4,
                              height: isSmallScreen ? 3 : 4,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 16),
                    Text(
                      'Welcome to Our Community!',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E3B62),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      'Together we build stronger bonds and create lasting memories. Thank you for being part of our wonderful society family.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red.withOpacity(0.6),
                          size: isSmallScreen ? 12 : 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'United We Live',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.favorite,
                          color: Colors.red.withOpacity(0.6),
                          size: isSmallScreen ? 12 : 14,
                        ),
                      ],
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

  Widget _buildTappableCard({
    required Widget child,
    required VoidCallback onTapUp,
    required VoidCallback onTapDown,
    required VoidCallback onTapCancel,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: 1.0,
        child: child,
      ),
    );
  }

  void _setPressed(int index, bool value) {
    if (!mounted) return;
    setState(() {
      _isPressed[index] = value;
    });
  }

  void _onCardTap(int index, VoidCallback onTap) {
    _setPressed(index, false);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) onTap();
    });
  }

  Widget _buildAnnouncementCard(
    String title,
    String content,
    String time,
    IconData icon,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF9800),
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E3B62),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVerticalCards(bool isSmallScreen) {
    final allServices = [
      {
        'title': 'Amenities',
        'icon': Icons.pool,
        'color': const Color(0xFF2196F3),
        'onTap': () => ref.read(bottomNavIndexProvider.notifier).state = 4,
      },
      {
        'title': 'Buy & Sell',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFF9C27B0),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductScreen()),
        ),
      },
      {
        'title': 'Services',
        'icon': Icons.build,
        'color': const Color.fromARGB(255, 197, 48, 48),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ServiceScreen()),
        ),
      },
      {
        'title': 'Directory',
        'icon': Icons.phone,
        'color': const Color(0xFF4CAF50),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DirectoryScreen()),
        ),
      },
      {
        'title': 'Polls',
        'icon': Icons.poll,
        'color': const Color.fromARGB(255, 248, 162, 69),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PollsScreen()),
        ),
      },
      {
        'title': 'Documents',
        'icon': Icons.description,
        'color': const Color(0xFFF44336),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DocumentListPage()),
          );
        },
      },
      {
        'title': 'NOC',
        'icon': Icons.verified_outlined,
        'color': const Color(0xFF00897B),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NocRequestScreen()),
          );
        },
      },
    ];

    List<List<Map<String, dynamic>>> getServiceRows(
      List<Map<String, dynamic>> services,
    ) {
      List<List<Map<String, dynamic>>> rows = [];
      for (int i = 0; i < services.length; i += 3) {
        rows.add(
          services.sublist(
            i,
            (i + 3 > services.length) ? services.length : i + 3,
          ),
        );
      }
      return rows;
    }

    final visibleServices = _isServicesExpanded
        ? allServices
        : allServices.take(3).toList();
    final serviceRows = getServiceRows(visibleServices);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 8,
        vertical: 10,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: Column(
            children: serviceRows.asMap().entries.map((entry) {
              int rowIndex = entry.key;
              List<Map<String, dynamic>> row = entry.value;

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: rowIndex == 0 || _isServicesExpanded ? 1.0 : 0.0,
                child: Column(
                  children: [
                    if (rowIndex > 0) SizedBox(height: isSmallScreen ? 12 : 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...row.map(
                          (service) => Expanded(
                            child: _buildServiceItem(service, isSmallScreen),
                          ),
                        ),
                        ...List.generate(
                          3 - row.length,
                          (index) => const Expanded(child: SizedBox()),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service, bool isSmallScreen) {
    return GestureDetector(
      onTap: service['onTap'] as VoidCallback,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 4 : 5),
            decoration: BoxDecoration(
              color: (service['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              service['icon'] as IconData,
              color: service['color'] as Color,
              size: isSmallScreen ? 24 : 30,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            service['title'] as String,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E3B62),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}