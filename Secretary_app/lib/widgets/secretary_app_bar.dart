import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// The app bar from CHSHUB_app, in Secretary colours.
///
/// Same anatomy: a deep navy bar, a two-line greeting on the left, and actions
/// on the right — a bell carrying an unread count and an avatar. CHSHUB hard-
/// codes its badge to "2"; here the count is passed in and the badge is simply
/// absent at zero, so it never claims unread items that do not exist.
class SecretaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SecretaryAppBar({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.avatarName,
    this.notificationCount = 0,
    this.onNotifications,
    this.onAvatar,
    this.onSubtitleTap,
    this.bottom,
    this.leading,
  });

  /// "Hello, Pallavi (Secretary)" — the line the user reads first.
  final String greeting;

  /// The plain name the avatar takes its initials from.
  ///
  /// Passed separately because the greeting is prose: deriving initials from
  /// "Hello, Pallavi (Secretary)" picks up the bracketed role and gets them
  /// wrong. Falls back to parsing the greeting when not given.
  final String? avatarName;

  /// The society below it. Tappable when [onSubtitleTap] is given, which is
  /// where CHSHUB puts its unit switcher.
  final String subtitle;

  final int notificationCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onAvatar;
  final VoidCallback? onSubtitleTap;

  /// A TabBar, when the screen underneath has one.
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  static const double _toolbarHeight = 72;

  @override
  Size get preferredSize =>
      Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryDark,
      foregroundColor: AppTheme.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _toolbarHeight,
      leading: leading,
      automaticallyImplyLeading: leading != null,
      // The bar is dark, so the status bar icons above it must be light.
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      // A gradient rather than a flat fill, matching the hero panels the
      // screens below use.
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppTheme.heroGradient),
      ),
      title: _buildTitle(),
      titleSpacing: leading != null ? 0 : 20,
      actions: [
        _NotificationBell(count: notificationCount, onPressed: onNotifications),
        _Avatar(source: avatarName ?? greeting, onTap: onAvatar),
        const SizedBox(width: AppTheme.space4),
      ],
      bottom: bottom,
    );
  }

  Widget _buildTitle() {
    final subtitleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              color: Colors.white70,
            ),
          ),
        ),
        if (onSubtitleTap != null) ...[
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 17,
            color: Colors.white70,
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            height: 1.25,
            letterSpacing: -0.2,
            color: AppTheme.white,
          ),
        ),
        const SizedBox(height: 1),
        if (onSubtitleTap == null)
          subtitleRow
        else
          InkWell(
            onTap: onSubtitleTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: subtitleRow,
            ),
          ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, size: 24),
          color: AppTheme.white,
          tooltip: 'Notifications',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  // A ring in the bar's own colour separates the badge from
                  // the bell beneath it.
                  border: Border.all(color: AppTheme.primaryDark, width: 1.5),
                ),
                child: Text(
                  // Past 99 the number stops being readable at this size.
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.source, this.onTap});

  /// A plain name, or the greeting to pull one out of.
  final String source;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          height: 38,
          width: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
          ),
          child: Text(
            _initials(source),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Initials from the greeting, so there is something to show without an
  /// avatar image. "Hello, Pallavi Patade" -> "PP".
  static String _initials(String source) {
    // Strip a trailing "(Secretary)" before anything else — the greeting the
    // app bar shows carries the role in brackets, and taking initials from it
    // would spell the role rather than the person.
    var name = source.replaceAll(RegExp(r'\([^)]*\)'), ' ').trim();

    // "Hello, Pallavi" -> "Pallavi".
    if (name.contains(',')) name = name.split(',').last.trim();

    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(p))
        .toList();

    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
