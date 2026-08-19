import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/booked_amenities.dart';
import 'package:society_app/SocietyApp/screens/helpdesk.dart';
import 'package:society_app/SocietyApp/screens/home_screen.dart';
import 'package:society_app/SocietyApp/screens/notification.dart';
import 'package:society_app/SocietyApp/screens/payment.dart';
import 'package:society_app/SocietyApp/screens/profile_screen.dart';
import 'package:society_app/SocietyApp/screens/visitor_mgmt.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/core/network_overlay.dart';
import 'package:society_app/domain/models/basicinfo.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class AnimatedBottomNavScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const AnimatedBottomNavScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AnimatedBottomNavScreen> createState() =>
      _AnimatedBottomNavScreenState();
}

class _AnimatedBottomNavScreenState
    extends ConsumerState<AnimatedBottomNavScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _tapAnimationController;

  final List<AnimationController> _tabAnimationControllers = [];
  final List<Animation<double>> _tabScaleAnimations = [];

  int _currentIndex = 0;
  bool _hasMultipleFlats = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    HelpDeskScreen(),
    VisitorManagementScreen(),
    const PaymentScreen(),
    const BookedAmenitiesScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _initializeAnimations();

    Future.microtask(() {
      ref.read(bottomNavIndexProvider.notifier).state = widget.initialIndex;
    });

    Future.microtask(() async {
      await ref.read(basicInfoViewModelProvider.notifier).getBasicInfo();
      ref
          .read(broadcastViewModelProvider.notifier)
          .getNotification(
            ref.watch(basicInfoViewModelProvider).societyID ?? "",
            ref.watch(basicInfoViewModelProvider).ownerId ?? 0,
          );
      await _checkMultipleFlats();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainAnimationController.forward();
    });
  }

  Future<void> _checkMultipleFlats() async {
    final basicInfo = ref.read(basicInfoViewModelProvider);
    final mobile = basicInfo.mobile ?? '';
    final loginFlatId = basicInfo.flatId;
    final loginOwnerId = basicInfo.ownerId;

    final flats = await ref
        .read(basicInfoViewModelProvider.notifier)
        .checkUser(mobile);
    if (flats == null || !mounted) return;

    final filteredFlats = _filterFlats(flats, mobile, loginFlatId, loginOwnerId);
    setState(() {
      _hasMultipleFlats = filteredFlats.length > 1;
    });
  }

  List<BasicInfo> _filterFlats(
    List<BasicInfo> flats,
    String mobile,
    int? loginFlatId,
    int? loginOwnerId,
  ) {
    final uniqueFlats = flats.where((flat) {
      if (flat.preMob != mobile) return false;
      if (flat.flatId == loginFlatId && flat.ownerId == loginOwnerId) {
        return true;
      }
      if (flat.flatId != loginFlatId) return true;
      return false;
    }).toList();

    return {for (var f in uniqueFlats) "${f.flatId}_${f.ownerId}": f}
        .values
        .toList();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _tapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      final animation = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
      _tabAnimationControllers.add(controller);
      _tabScaleAnimations.add(animation);
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _tapAnimationController.dispose();
    for (var controller in _tabAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ✅ Animate selected tab and switch page
  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();
    _animateSelectedTab(index);

    setState(() => _currentIndex = index);
    ref.read(bottomNavIndexProvider.notifier).state = index;
  }

  void _animateSelectedTab(int index) {
    _tabAnimationControllers[index].forward().then((_) {
      _tabAnimationControllers[index].reverse();
    });
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // Go back to Home tab instead of exiting
      setState(() {
        _currentIndex = 0;
      });
      return false; // prevent exit
    }
    return true; // exit app when already on Home
  }

  PreferredSizeWidget buildAppBar(BasicInfo basicInfo) {
    final residentName = basicInfo.name;
    final unit = basicInfo.unit;
    final notificationAsync = ref
        .watch(broadcastViewModelProvider)
        .notificationList;

    final unseenCount = notificationAsync.maybeWhen(
      data: (list) => list.where((n) => n.seenStatus != 1).length,
      orElse: () => 0,
    );

    return AppBar(
      backgroundColor: const Color(0xFF000C33),
      elevation: 0,
      toolbarHeight: 70,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${residentName ?? 'Loading...'}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: _hasMultipleFlats
                ? () => _showFlatSelectionDialog(context)
                : null,
            child: Row(
              children: [
                Text(
                  unit ?? 'Loading...',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                if (_hasMultipleFlats) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              },
            ),
            if (unseenCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unseenCount.toString(),
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // GestureDetector(
        //   onTap: () => Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) => ProfileScreen()),
        //   ),
        //   child: _buildProfileAvatar(basicInfo),
        // ),
        Padding(
          padding: const EdgeInsets.only(right: 12), // move it slightly inside
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            ),
            child: _buildProfileAvatar(basicInfo),
          ),
        ),
      ],
    );
  }

  void _showFlatSelectionDialog(BuildContext context) async {
    final userVM = ref.read(basicInfoViewModelProvider.notifier);

    // Logged-in user info
    final basicInfo = ref.watch(basicInfoViewModelProvider);
    final mobile = basicInfo.mobile ?? '';
    final loginFlatId = basicInfo.flatId;
    final loginOwnerId = basicInfo.ownerId;

    // Fetch all flats linked to this mobile
    final flats = await userVM.checkUser(mobile);

    if (flats == null || flats.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No flats found")));
      return;
    }

    final filteredFlats = _filterFlats(flats, mobile, loginFlatId, loginOwnerId);

    if (filteredFlats.length <= 1) {
      setState(() => _hasMultipleFlats = false);
      return;
    }

    // Sort → current logged-in flat always first
    filteredFlats.sort((a, b) {
      if (a.flatId == loginFlatId && a.ownerId == loginOwnerId) return -1;
      if (b.flatId == loginFlatId && b.ownerId == loginOwnerId) return 1;
      return 0;
    });

    // -----------------------------
    // Show Dialog
    // -----------------------------
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.home_outlined, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Switch Unit',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: (filteredFlats.length * 110.0).clamp(150.0, 320.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredFlats.length,
              itemBuilder: (context, index) {
                final flat = filteredFlats[index];

                final isCurrent =
                    flat.flatId == loginFlatId && flat.ownerId == loginOwnerId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.blue.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.blue.shade700
                          : Colors.grey.shade200,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? Colors.blue.shade100
                          : Colors.blue.shade50,
                      child: Icon(
                        Icons.home,
                        size: 28,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      flat.name ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (flat.societyName != null &&
                              flat.societyName!.isNotEmpty)
                            Text(
                              flat.societyName!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          Text(
                            "${flat.buildName ?? ''} • Flat ${flat.flatNo ?? ''}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle, color: Colors.blue.shade700)
                        : Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                    onTap: isCurrent
                        ? null
                        : () async {
                            await ref
                                .read(basicInfoViewModelProvider.notifier)
                                .selectFlat(
                                  flat.preMob ?? '',
                                  flat.flatId,
                                  flat.ownerId,
                                  ref,
                                  "nav",
                                );
                            Navigator.pop(context);
                          },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String getInitial(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';

    // Common prefixes
    final prefixes = [
      'mr ',
      'mr.',
      'mrs ',
      'mrs.',
      'miss ',
      'ms ',
      'ms.',
      'dr ',
      'dr.',
    ];

    String cleaned = name.toLowerCase().trim();

    for (var p in prefixes) {
      if (cleaned.startsWith(p)) {
        cleaned = cleaned.replaceFirst(p, '').trim();
        break;
      }
    }

    return cleaned.substring(0, 1).toUpperCase();
  }

  Widget _buildProfileAvatar(BasicInfo user) {
    if (user.profileImage != null && user.profileImage!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          user.profileImage!,
          width: 45,
          height: 45,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(user),
        ),
      );
    }
    return _fallbackAvatar(user);
  }

  Widget _fallbackAvatar(BasicInfo user) => CircleAvatar(
    radius: 22,
    backgroundColor: Colors.blue[400],
    child: Text(
      getInitial(user.name), // ← FIXED HERE
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildAnimatedBottomNav() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _mainAnimationController,
              curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
            ),
          ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2E3B62),
        unselectedItemColor: Colors.grey,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        onTap: _onTabTapped,
        items: [
          _buildAnimatedItem(Icons.home, 'Home', 0),
          _buildAnimatedItem(Icons.headset_mic, 'Helpdesk', 1),
          _buildAnimatedItem(Icons.people, 'Visitors', 2),
          _buildAnimatedItem(Icons.account_balance_wallet, 'Dues', 3),
          _buildAnimatedItem(Icons.pool, 'Amenities', 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildAnimatedItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedBuilder(
        animation: _tabScaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _tabScaleAnimations[index].value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 8 : 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2E3B62).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: isSelected ? 26 : 22),
            ),
          );
        },
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(basicInfoViewModelProvider);

    // Home's quick-action buttons switch tabs by updating bottomNavIndexProvider
    // instead of pushing a new AnimatedBottomNavScreen route. Mirror it into
    // _currentIndex so IndexedStack/the bottom nav actually reflect the change.
    ref.listen<int>(bottomNavIndexProvider, (previous, next) {
      if (next != _currentIndex) {
        setState(() => _currentIndex = next);
      }
    });

    // getBasicInfo() re-enters AsyncValue.loading() on every refresh (e.g.
    // Profile's initState/pull-to-refresh), not just the first load. If that
    // loading state tore down this Scaffold/PageView while this screen was
    // just hidden behind a pushed route, the PageView loses its scroll
    // position when it's rebuilt and snaps back to its initial page instead
    // of the tab the user had selected. So once we have data at least once,
    // keep rendering it through subsequent loading/error pulses.
    final cachedData = state.basicInfoResult.value;

    if (cachedData == null) {
      return state.basicInfoResult.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          backgroundColor: Colors.grey[50],
          body: ErrorStatePage(
            error: error,
            onRetry: () =>
                ref.read(basicInfoViewModelProvider.notifier).getBasicInfo(),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedBottomNav(),
              const ConnectivityBanner(),
            ],
          ),
        ),
        data: (data) => _buildShell(data),
      );
    }

    return _buildShell(cachedData);
  }

  Widget _buildShell(List<BasicInfo> data) {
    if (data.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No user data available')),
      );
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: buildAppBar(data.first),
        // IndexedStack (not PageView) so the active tab is driven directly
        // by _currentIndex and never depends on a PageController staying
        // attached: when this shell rebuilds while hidden behind a pushed
        // route (e.g. Profile refreshing its own data), a PageController
        // can get detached/reattached and silently reset to its initial
        // page instead of the tab the user had selected. IndexedStack has
        // no such state to lose, and it keeps every tab's own state alive.
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimatedBottomNav(),
            const ConnectivityBanner(),
          ],
        ),
      ),
    );
  }
}
