import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/responsive.dart';
import '../presentation/providers/viewmodel_provider.dart';
import '../presentation/viewModels/community_viewmodel.dart';
import '../widgets/app_widgets.dart';
import '../widgets/secretary_app_bar.dart';
import 'community/notifications_screen.dart';
import 'profile/profile_screen.dart';

/// An entry on a hub screen.
class HubEntry {
  const HubEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.builder,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  /// Built lazily so opening the hub does not construct every screen behind it.
  final Widget Function() builder;

  final String? badge;
}

/// The shared shape of Billing, Accounts and Community: a titled intro and a
/// list of destinations.
///
/// On a phone the entries are full-width rows; once there is width they become
/// a grid of cards, because a single column of rows across a desktop window is
/// mostly empty space.
class HubScaffold extends ConsumerWidget {
  const HubScaffold({
    super.key,
    required this.title,
    required this.intro,
    required this.entries,
  });

  final String title;
  final String intro;
  final List<HubEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = Breakpoints.isPhone(context);
    final user = ref.watch(authViewModelProvider).user;
    final unread = ref
        .watch(communityViewModelProvider)
        .items(CommunityKeys.notifications)
        .length;

    return Scaffold(
      // The same bar the dashboard shows, greeting included. These are the
      // other three bottom-bar destinations, and a flat titled AppBar on them
      // made switching tabs look like leaving the app — the gradient, the bell
      // and the avatar all disappeared. The bar is the one thing that must not
      // change between tabs, so the greeting is built the same way here rather
      // than swapped for the section name; the section is already named by the
      // selected item in the bottom bar and by the intro under the bar.
      appBar: SecretaryAppBar(
        greeting:
            'Hello, ${user?.name ?? 'there'} '
            '(${user?.userType ?? 'Secretary'})',
        avatarName: user?.name,
        avatarPhotoUrl: user?.photoUrl,
        subtitle: user?.societyName ?? 'Society',
        notificationCount: unread,
        onNotifications: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
        onAvatar: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            PageConstraints(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The section name, which used to be the app bar's title.
                  // The bar now carries the same greeting on every tab, so the
                  // page has to say which section this is — and as a heading on
                  // the page it can be read at a size the bar had no room for.
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppTheme.space4,
                      bottom: AppTheme.space2,
                    ),
                    child: Text(title, style: AppTheme.headline),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space5),
                    child: Text(intro, style: AppTheme.body2),
                  ),
                  if (phone)
                    for (final entry in entries)
                      MenuTile(
                        icon: entry.icon,
                        color: entry.color,
                        title: entry.title,
                        subtitle: entry.subtitle,
                        badge: entry.badge,
                        onTap: () => _open(context, entry),
                      )
                  else
                    ResponsiveGrid(
                      minTileWidth: 250,
                      aspectRatio: 1.5,
                      children: [
                        for (final entry in entries)
                          _HubCard(
                            entry: entry,
                            onTap: () => _open(context, entry),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, HubEntry entry) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => entry.builder()));
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.entry, required this.onTap});

  final HubEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconPlate(icon: entry.icon, color: entry.color, size: 44),
              const Spacer(),
              if (entry.badge != null)
                StatusChip(label: entry.badge!, color: entry.color),
            ],
          ),
          const Spacer(),
          Text(entry.title, style: AppTheme.title.copyWith(fontSize: 15.5)),
          const SizedBox(height: 3),
          Text(
            entry.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}
