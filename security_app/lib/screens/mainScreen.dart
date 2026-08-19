import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/screens/notification.dart';
import 'package:security_app/screens/home.dart';
import 'package:security_app/screens/in_out.dart';
import 'package:security_app/screens/settings_page.dart';
import 'package:security_app/screens/staff_attendance.dart';
import 'package:security_app/core/storage/network_overlay.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen({super.key});

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen>
    with TickerProviderStateMixin {
  late AnimationController _navSlideController;
  late PageController _pageController;

  final List<AnimationController> _tabControllers = [];
  final List<Animation<double>> _tabScales = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _currentIndex);

    _navSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Initialize tab animations for 4 tabs
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );

      final animation = Tween<double>(
        begin: 1,
        end: 1.2,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));

      _tabControllers.add(controller);
      _tabScales.add(animation);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _navSlideController.forward();
      
      await ref.read(securitymodelProvider.notifier).loadDataFromStorage();
      final staffId = ref.read(securitymodelProvider).userId;
      ref
          .read(staffmodelProvider.notifier)
          .fetchStaffAttendanceStatus(int.parse(staffId ?? "0"));
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navSlideController.dispose();
    for (final c in _tabControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();

    _tabControllers[index].forward().then((_) {
      _tabControllers[index].reverse();
    });

    setState(() => _currentIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  // Helper function to get initials from name
  String getInitial(String? name) {
    if (name == null || name.isEmpty) return 'U';
    List<String> words = name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }

  PreferredSizeWidget buildAppBar(dynamic userDetails) {
    final userName = userDetails.name ?? "Guest User";
    final societyName = userDetails.societyName ?? "No Society";
    final isCheckedIn = ref.watch(staffmodelProvider).isCheckedIn;

    return AppBar(
      
      backgroundColor: const Color(0xFF1E3A8A),
      automaticallyImplyLeading: false,
      elevation: 0,
      toolbarHeight: 75,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [const Color(0xFF000C33), const Color(0xFF000C33)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          // Profile Avatar
          _buildProfileAvatar(userDetails),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  societyName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isCheckedIn
                            ? Colors.green[400]
                            : Colors.orange[400],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isCheckedIn ? Colors.green : Colors.orange)
                                    .withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCheckedIn ? 'On Duty' : 'Off Duty',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Check In/Out Button
        _buildCheckInOutButton(context, ref, isCheckedIn, userDetails),
        const SizedBox(width: 8),
        // Notification Button
        //_buildNotificationButton(context),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildCheckInOutButton(
      BuildContext context, WidgetRef ref, bool isCheckedIn, dynamic userDetails) {
    return Container(
      decoration: BoxDecoration(
        color: isCheckedIn ? Colors.red[400] : Colors.green[400],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? Colors.red : Colors.green).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        isCheckedIn ? Icons.logout : Icons.login,
                        color: isCheckedIn ? Colors.red[600] : Colors.green[600],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCheckedIn ? 'Check Out' : 'Check In',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    isCheckedIn
                        ? 'Are you sure you want to check out? This will mark you as off duty.'
                        : 'Are you sure you want to check in? This will mark you as on duty.',
                    style: const TextStyle(fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isCheckedIn ? Colors.red[600] : Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        isCheckedIn ? 'Check Out' : 'Check In',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

            if (confirmed != true) return;

            final newStatus = !isCheckedIn;
            final statusFlag = newStatus ? 1 : 0;

            try {
              await ref
                  .read(staffmodelProvider.notifier)
                  .staffEntryExit(userDetails.staffId, statusFlag);
              await ref.read(staffmodelProvider.notifier).fetchStaffAttendanceStatus(
                  int.parse(ref.read(securitymodelProvider).userId ?? "0"));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(newStatus ? Icons.login : Icons.logout,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          newStatus
                              ? 'Checked In Successfully'
                              : 'Checked Out Successfully',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    backgroundColor: newStatus ? Colors.green[600] : Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update attendance: $e'),
                    backgroundColor: Colors.red[600],
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCheckedIn ? Icons.logout : Icons.login,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isCheckedIn ? 'Check Out' : 'Check In',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red[500],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
  }

  Widget _buildProfileAvatar(dynamic user) {
    final profileImage = user.image;
    final userName = user.name;

    final hasDbImage = profileImage != null && profileImage.isNotEmpty;

    if (hasDbImage) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: SizedBox(
            width: 48,
            height: 48,
            child: Image.network(
              profileImage,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.white.withOpacity(0.2),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white.withOpacity(0.2),
                  child: Center(
                    child: Text(
                      getInitial(userName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          getInitial(userName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBottomNav() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _navSlideController,
          curve: Curves.elasticOut,
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedItemColor: const Color(0xFF2E3B62),
        unselectedItemColor: Colors.grey,
        items: [
          _buildAnimatedItem(Icons.home, 'Home', 0),
          _buildAnimatedItem(Icons.people, 'Visitors', 1),
          _buildAnimatedItem(Icons.how_to_reg, 'Attendance', 2),
          _buildAnimatedItem(Icons.person, 'Profile', 3),
        ],
      ),
    );
  }
  

  BottomNavigationBarItem _buildAnimatedItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = index == _currentIndex;

    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedBuilder(
        animation: _tabScales[index],
        builder: (_, __) {
          return Transform.scale(
            scale: _tabScales[index].value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 8 : 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2E3B62).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: isSelected ? 26 : 22,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  final state = ref.watch(securitymodelProvider);
  final screens = const [
    HomeScreen(),
    InOutScreen(),
    StaffAttendancePage(),
    SettingsScreen(),
  ];

  return state.loginDetails.when(
    loading: () => _buildLoadingScreen(),
    error: (error, _) => _buildErrorScreen(getErrorMessage(error)),
    data: (loginData) {
      if (loginData.isEmpty) {
        return const Scaffold(
          body: Center(child: Text('No user data available')),
        );
      }

      final userDetails = loginData.first;

      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          
          if (_currentIndex == 0) {
            // If on home screen, exit the app
            SystemNavigator.pop();
          } else {
            // If on other tabs, go back to home
            _onTabTapped(0);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: buildAppBar(userDetails),
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: screens,
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
    },
  );
}
}