import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:security_app/core/storage/network_overlay.dart';

class BottomNavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  final Color inactiveColor;

  BottomNavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
    this.inactiveColor = Colors.grey,
  });
}

class AnimatedBottomNav extends StatefulWidget {
  final List<Widget> screens;
  final List<BottomNavItem> items;
  final int initialIndex;

  const AnimatedBottomNav({
    super.key,
    required this.screens,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _navSlideController;

  final List<AnimationController> _tabControllers = [];
  final List<Animation<double>> _tabScales = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _navSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    for (int i = 0; i < widget.items.length; i++) {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navSlideController.forward();
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

  @override
  Widget build(BuildContext context) {
    // Removed Scaffold wrapper - now just returns the content
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (index != _currentIndex) {
                setState(() => _currentIndex = index);
              }
            },
            children: widget.screens,
          ),
        ),
        const ConnectivityBanner(),
        SlideTransition(
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
            items: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isSelected = index == _currentIndex;

              return BottomNavigationBarItem(
                label: item.label,
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
                              ? item.activeColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: isSelected ? 26 : 22,
                          color: isSelected
                              ? item.activeColor
                              : item.inactiveColor,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
