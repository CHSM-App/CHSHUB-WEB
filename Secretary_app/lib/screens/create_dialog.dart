import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'community/more_community_screen.dart';
import 'community/notices_screen.dart';

/// One choice in the create dialog.
class _CreateOption {
  const _CreateOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.build,
  });

  final IconData icon;
  final Color color;
  final String title;

  /// Built lazily so opening the dialog does not construct four screens.
  final Widget Function() build;
}

/// The panel behind the create button.
///
/// Built the way CHSHUB_app and Security_app build their security-alert
/// dialog, because that is the shape the suite already uses for "pick one
/// action": a `Center` over a transparent Material, holding a card that fades
/// in while sliding up, with the choices as a 2×2 grid of tinted tiles that
/// shrink slightly when pressed.
///
/// The options are deliberately *not* another shortcut to the receipt form:
/// the dashboard's quick actions already carry that, along with bills,
/// notices and complaints. These are the community items with no other
/// one-tap route, where reaching them otherwise means Community, then More,
/// then the right tab inside that.
class CreateDialog extends StatefulWidget {
  const CreateDialog({super.key});

  /// Shows the dialog and pushes whatever the user picked.
  ///
  /// The push happens here, after the dialog has closed, rather than from
  /// inside a tile — otherwise the new route animates in while the dialog is
  /// still on screen.
  static Future<void> show(BuildContext context) async {
    final screen = await showDialog<Widget>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const CreateDialog(),
    );

    if (screen == null || !context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  State<CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<CreateDialog>
    with TickerProviderStateMixin {
  late final AnimationController _slideController = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );

  late final AnimationController _fadeController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      );

  late final Animation<double> _fade = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

  static const _options = <_CreateOption>[
    _CreateOption(
      icon: Icons.campaign_outlined,
      color: AppTheme.primary,
      title: 'Notice',
      build: _buildNotices,
    ),
    _CreateOption(
      icon: Icons.groups_outlined,
      color: AppTheme.info,
      title: 'Meeting',
      build: _buildMeetings,
    ),
    _CreateOption(
      icon: Icons.poll_outlined,
      color: AppTheme.violet,
      title: 'Poll',
      build: _buildPolls,
    ),
    _CreateOption(
      icon: Icons.celebration_outlined,
      color: AppTheme.warning,
      title: 'Event',
      build: _buildEvents,
    ),
  ];

  // Top-level functions rather than closures, so `_options` can stay const.
  static Widget _buildNotices() => const NoticesScreen();
  static Widget _buildMeetings() => const MoreCommunityScreen(initialTab: 4);
  static Widget _buildPolls() => const MoreCommunityScreen(initialTab: 1);
  static Widget _buildEvents() => const MoreCommunityScreen(initialTab: 3);

  @override
  void initState() {
    super.initState();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.9,
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(AppTheme.space5),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [_buildHeader(), _buildGrid(), _buildCancel()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space6,
        AppTheme.space6,
        AppTheme.space6,
        AppTheme.space4,
      ),
      child: Column(
        children: [
          Text('Create', style: AppTheme.title.copyWith(fontSize: 20)),
          const SizedBox(height: AppTheme.space1),
          Text(
            'What would you like to add?',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  /// Two rows of two. A fixed grid rather than a wrapping one: with four
  /// options it is always 2×2, and GridView would need its own scroll
  /// handling inside a dialog that is already sized to its content.
  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTile(_options[0])),
              const SizedBox(width: AppTheme.space3),
              Expanded(child: _buildTile(_options[1])),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Expanded(child: _buildTile(_options[2])),
              const SizedBox(width: AppTheme.space3),
              Expanded(child: _buildTile(_options[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(_CreateOption option) {
    return _AnimatedTile(
      icon: option.icon,
      title: option.title,
      color: AppTheme.surfaceFor(option.color),
      iconColor: option.color,
      onTap: () => Navigator.pop(context, option.build()),
    );
  }

  Widget _buildCancel() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
          ),
          child: Text(
            'Cancel',
            style: AppTheme.body2.copyWith(
              color: AppTheme.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tinted tile that shrinks a little while held, as CHSHUB's alert cards do.
class _AnimatedTile extends StatefulWidget {
  const _AnimatedTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.95,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 28, color: widget.iconColor),
              const SizedBox(height: AppTheme.space2),
              Flexible(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
