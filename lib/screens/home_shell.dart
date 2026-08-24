import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/responsive.dart';
import '../widgets/bottom_bar_view.dart';
import 'accounts/accounts_screen.dart';
import 'billing/billing_screen.dart';
import 'community/community_screen.dart';
import 'create_dialog.dart';
import 'dashboard/dashboard_screen.dart';

/// The four sections the secretary works in day to day.
///
/// Tabs are kept alive by an IndexedStack rather than rebuilt on every switch:
/// each holds a loaded list and a scroll position, and refetching those on a
/// tab tap would make moving between Billing and Accounts feel like a reload.
///
/// Navigation changes shape with the window: the notched bottom bar on a
/// phone, a side rail once there is width for it. Same destinations either way.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabIcons = TabIconData.items;

  static const _tabs = <Widget>[
    DashboardScreen(),
    BillingScreen(),
    AccountsScreen(),
    CommunityScreen(),
  ];

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _openCreateMenu() => CreateDialog.show(context);

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _index, children: _tabs);

    if (Breakpoints.useRail(context)) {
      return Scaffold(
        body: Row(
          children: [
            _buildRail(context),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      // The bar has no centre action to hang this on, so it sits above it as
      // an ordinary FAB.
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateMenu,
        tooltip: 'Create',
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomBarView(
        currentIndex: _index,
        onTap: _select,
        items: _tabIcons,
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    // Labels are always visible on a desktop window, where there is room; on a
    // tablet only the selected one shows, to keep the rail narrow.
    final extended =
        Breakpoints.isDesktop(context) &&
        MediaQuery.sizeOf(context).width >= 1320;

    return NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: _select,
      extended: extended,
      minExtendedWidth: 210,
      labelType: extended ? null : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
        child: Column(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm + 2),
                boxShadow: AppTheme.primaryGlow(opacity: 0.22),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: AppTheme.white,
                size: 22,
              ),
            ),
            if (extended) ...[
              const SizedBox(height: AppTheme.space2),
              Text('Secretary', style: AppTheme.title.copyWith(fontSize: 14)),
            ],
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space5),
            child: IconButton.filled(
              onPressed: _openCreateMenu,
              tooltip: 'Create',
              icon: const Icon(Icons.add_rounded, size: 21),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.all(AppTheme.space3),
              ),
            ),
          ),
        ),
      ),
      destinations: [
        for (final tab in _tabIcons)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: Text(tab.label),
          ),
      ],
    );
  }
}
