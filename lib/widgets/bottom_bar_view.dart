import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// One destination in the bottom bar.
class TabIconData {
  const TabIconData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;

  /// The four sections a secretary works in.
  static const List<TabIconData> items = <TabIconData>[
    TabIconData(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      index: 0,
    ),
    TabIconData(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Billing',
      index: 1,
    ),
    TabIconData(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Accounts',
      index: 2,
    ),
    TabIconData(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Community',
      index: 3,
    ),
  ];
}

/// The bottom bar CHSHUB_app actually ships.
///
/// Worth being explicit about, because CHSHUB contains two of these.
/// `bottom_navigation_view/bottom_bar_view.dart` holds a notched bar with a
/// centre FAB, but nothing in the app imports it — it is dead code left over
/// from the template the project started from. The bar that is really on
/// screen is built by `navigation_home_screen._buildAnimatedBottomNav()`, and
/// this is that one:
///
///  * a plain fixed [BottomNavigationBar] on white, elevation 8;
///  * the selected item sits on a rounded tinted plate, its padding growing
///    4 -> 8 and its icon 22 -> 26;
///  * tapping bounces the icon to 1.2x on an elasticOut curve and back;
///  * the whole bar slides up from below on first build, also elasticOut;
///  * a light haptic on each change.
class BottomBarView extends StatefulWidget {
  const BottomBarView({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = TabIconData.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<TabIconData> items;

  @override
  State<BottomBarView> createState() => _BottomBarViewState();
}

class _BottomBarViewState extends State<BottomBarView>
    with TickerProviderStateMixin {
  /// Drives the slide-up on first build.
  late final AnimationController _mainController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// One per tab, for the bounce on selection.
  late final List<AnimationController> _tabControllers;
  late final List<Animation<double>> _tabScales;

  @override
  void initState() {
    super.initState();

    _tabControllers = List.generate(
      widget.items.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );

    _tabScales = [
      for (final controller in _tabControllers)
        Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ),
    ];

    _mainController.forward();
  }

  @override
  void dispose() {
    for (final controller in _tabControllers) {
      controller.dispose();
    }
    _mainController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;

    HapticFeedback.lightImpact();
    // Bounce out and straight back, so the tab settles at its normal size.
    _tabControllers[index].forward().then((_) {
      if (mounted) _tabControllers[index].reverse();
    });

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _mainController,
              // Held back until the last fifth of the run, so the bar arrives
              // after the page behind it has settled.
              curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
            ),
          ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.white,
        selectedItemColor: AppTheme.primaryDark,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        onTap: _handleTap,
        items: [for (final item in widget.items) _buildItem(item)],
      ),
    );
  }

  BottomNavigationBarItem _buildItem(TabIconData item) {
    final isSelected = widget.currentIndex == item.index;

    return BottomNavigationBarItem(
      icon: AnimatedBuilder(
        animation: _tabScales[item.index],
        builder: (context, child) {
          return Transform.scale(
            scale: _tabScales[item.index].value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 8 : 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryDark.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: isSelected ? 26 : 22,
              ),
            ),
          );
        },
      ),
      label: item.label,
    );
  }
}
