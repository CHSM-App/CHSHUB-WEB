import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/user.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import 'change_password_form.dart';
import 'edit_profile_screen.dart';
import 'photo_viewer.dart';

/// The signed-in user's profile: who they are, which society they administer,
/// and the account actions that belong to them.
///
/// Replaces the old Settings screen as the destination of the app bar avatar.
/// The anatomy is a hero that carries identity, a responsive body of detail
/// cards, and the account actions last — the order someone scans in when they
/// open a profile to check something rather than to change it.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // The cached session only carries name/username/society. Re-reading
    // /auth/me fills in the email and contact the detail cards show, so the
    // screen is not permanently half-empty after a cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authViewModelProvider.notifier).loadMe();
    });
  }

  Future<void> _refresh() => ref.read(authViewModelProvider.notifier).loadMe();

  Future<void> _openEdit(User? user) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (saved == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      // A white bar with a dark title, as CHSHUB_app's profile screen has.
      //
      // The gradient band this screen used to open with is gone. On a hub or a
      // dashboard the brand bar is a header for a whole section; on a profile
      // it was a large field of saturated blue carrying one word, and it made
      // the page read as heavy before any of its content had been seen. The
      // colour now lives where CHSHUB puts it — in the avatar and in the
      // tinted icon plates — and the chrome stays out of the way.
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.darkerText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        // A light bar needs dark status bar icons above it.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        // No action in the bar. Editing is already offered twice below — the
        // pencil on the avatar and the "Edit profile" row — and a third copy in
        // the corner only competed with them.
        title: Text('Profile', style: AppTheme.headline.copyWith(fontSize: 21)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        child: SafeArea(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppTheme.space8),
            children: [
              PageConstraints(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.space4),
                    _IdentityCard(user: user, onEdit: () => _openEdit(user)),
                    const SizedBox(height: AppTheme.space5),
                    // Only what the identity card above does not already show.
                    // Repeating the email and contact here was what made the
                    // page read as padding — the same four values twice, once
                    // in a card and once in a list.
                    _TenantCard(user: user),
                    const SizedBox(height: AppTheme.space5),
                    Text('Account', style: AppTheme.title),
                    const SizedBox(height: AppTheme.space2),
                    MenuTile(
                      icon: Icons.badge_outlined,
                      color: AppTheme.primary,
                      title: 'Edit profile',
                      subtitle: 'Update your name, email and contact number',
                      onTap: () => _openEdit(user),
                    ),
                    MenuTile(
                      icon: Icons.lock_outline,
                      color: AppTheme.violet,
                      title: 'Change password',
                      subtitle: 'Choose a new password for this account',
                      // Not barrier-dismissible: a tap outside would throw
                      // away a half-typed password with no confirmation, and
                      // the dialog already has an explicit Cancel.
                      onTap: () => showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const ChangePasswordForm(),
                      ),
                    ),
                    MenuTile(
                      icon: Icons.logout_rounded,
                      color: AppTheme.error,
                      title: 'Sign out',
                      subtitle: 'End this session on this device',
                      onTap: _confirmSignOut,
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

  Future<void> _confirmSignOut() async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to continue.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Stay signed in',
      destructive: true,
    );

    if (!confirmed) return;

    // AuthGate watches tokenProvider and swaps back to the login screen once
    // the tokens are cleared, so no navigation is needed here.
    await ref.read(authViewModelProvider.notifier).logout();
  }
}

/// Name, role and the account's key facts — the first thing on the page.
///
/// Follows CHSHUB_app's profile card: a gradient avatar beside the name and
/// login, then a divided row of facts underneath. The colour on this screen is
/// concentrated here and in the tinted icon plates, which is what lets the page
/// itself stay light.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user, required this.onEdit});

  final User? user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Secretary';
    final role = user?.userType ?? 'Secretary';
    final isVillage = (user?.tenantType ?? '').toLowerCase() == 'village';
    final place = isVillage
        ? (user?.villageName ?? user?.societyName)
        : (user?.societyName ?? user?.villageName);

    return Container(
      decoration: BoxDecoration(
        // A wash from the faintest brand tint down to white, rather than flat
        // white. It is only a few percent of colour, but it is what makes this
        // read as the page's hero instead of as the first of three identical
        // cards — and it ties the card to the avatar sitting on it.
        gradient: const LinearGradient(
          colors: [AppTheme.primarySurface, AppTheme.cardBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.55],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowLg,
      ),
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                name: name,
                onEdit: onEdit,
                size: 68,
                photoUrl: user?.photoUrl,
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headline.copyWith(fontSize: 21),
                    ),
                    if (user?.username != null) ...[
                      const SizedBox(height: 2),
                      Text('@${user!.username}', style: AppTheme.caption),
                    ],
                    const SizedBox(height: AppTheme.space3),
                    // Tinted chips on white, not the translucent white plates
                    // the old blue panel needed — these carry their own colour
                    // and read as labels rather than as holes in the surface.
                    Wrap(
                      spacing: AppTheme.space2,
                      runSpacing: AppTheme.space2,
                      children: [
                        StatusChip(
                          label: role,
                          color: AppTheme.primary,
                          icon: Icons.verified_user_outlined,
                        ),
                        if (place != null)
                          StatusChip(
                            label: place,
                            color: AppTheme.teal,
                            icon: Icons.apartment_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          const Divider(height: 1, color: AppTheme.spacer),
          const SizedBox(height: AppTheme.space3),
          _IdentityFacts(user: user),
        ],
      ),
    );
  }
}

/// The three facts along the bottom of the identity card.
///
/// Email and contact rather than invented metrics: they are what someone opens
/// a profile to check, and showing them here means the common case needs no
/// scrolling at all. Each is elided rather than wrapped — a long address must
/// not be allowed to grow the card.
class _IdentityFacts extends StatelessWidget {
  const _IdentityFacts({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final facts = <_Fact>[
      _Fact(Icons.mail_outline_rounded, 'Email', user?.email),
      _Fact(Icons.phone_outlined, 'Contact', user?.contactNo),
      _Fact(
        Icons.tag_rounded,
        'Code',
        (user?.tenantType ?? '').toLowerCase() == 'village'
            ? (user?.villageId ?? user?.societyId)
            : (user?.societyId ?? user?.villageId),
      ),
    ];

    // Stacked on a narrow phone, where three columns would leave each of them
    // too narrow to show an email at all.
    final stacked = MediaQuery.sizeOf(context).width < 380;

    if (stacked) {
      return Column(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTheme.space3),
            _FactView(fact: facts[i], row: true),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < facts.length; i++) ...[
          if (i > 0)
            const SizedBox(
              height: 34,
              child: VerticalDivider(width: AppTheme.space4, color: AppTheme.spacer),
            ),
          Expanded(child: _FactView(fact: facts[i], row: false)),
        ],
      ],
    );
  }
}

class _Fact {
  const _Fact(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;
}

class _FactView extends StatelessWidget {
  const _FactView({required this.fact, required this.row});

  final _Fact fact;

  /// Icon beside the text rather than above it, for the stacked layout.
  final bool row;

  @override
  Widget build(BuildContext context) {
    final value = fact.value;
    final isEmpty = value == null || value.trim().isEmpty;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fact.label, style: AppTheme.overline.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          isEmpty ? 'Not set' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body2.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isEmpty ? AppTheme.deactivatedText : AppTheme.darkerText,
          ),
        ),
      ],
    );

    if (row) {
      return Row(
        children: [
          Icon(fact.icon, size: 17, color: AppTheme.deactivatedText),
          const SizedBox(width: AppTheme.space3),
          Expanded(child: text),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(fact.icon, size: 17, color: AppTheme.deactivatedText),
        const SizedBox(height: AppTheme.space2),
        text,
      ],
    );
  }
}

/// Initials in a ring, with the edit pencil clipped to its corner.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.onEdit,
    required this.size,
    this.photoUrl,
  });

  final String name;
  final VoidCallback onEdit;
  final double size;

  /// The account's photo, when it has one. Initials stand in otherwise, and
  /// also whenever the photo fails to load — a broken image where a face
  /// should be is worse than the fallback the account always has.
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;

    return SizedBox(
      height: size,
      width: size,
      // The pencil overhangs the ring, so the stack must not clip.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (url != null)
            // Tapping the photo opens it full size. The pencil below is what
            // changes it; this is for simply looking at what is there, which
            // an avatar this small cannot show.
            GestureDetector(
              onTap: () => showPhotoViewer(context, url),
              child: ClipOval(
                child: SizedBox(
                  height: size,
                  width: size,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initials(),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _initials(),
                  ),
                ),
              ),
            )
          else
            _initials(),
          // The pencil, on the avatar itself — the affordance people look for
          // on a profile before they look at the app bar. Ringed in the card's
          // own colour so it reads as sitting on top of the avatar.
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowSm,
              ),
              padding: const EdgeInsets.all(2.5),
              child: Material(
                color: AppTheme.primarySurface,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials() {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppTheme.white,
        ),
      ),
    );
  }
}

// ── Detail cards ──────────────────────────────────────────────────────────

/// Where this account sits: the society or village it administers, and the
/// designation it holds there.
///
/// The identity card above already carries the name, username, email, contact
/// and code, so this deliberately does not repeat them — it answers the one
/// question that card leaves open.
class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    // A village tenant has village_name where a society has society_name; the
    // card is titled after whichever this account actually administers.
    final isVillage = (user?.tenantType ?? '').toLowerCase() == 'village';
    final placeName = isVillage
        ? (user?.villageName ?? user?.societyName)
        : (user?.societyName ?? user?.villageName);

    return _DetailCard(
      title: isVillage ? 'Village' : 'Society',
      icon: Icons.apartment_rounded,
      color: AppTheme.teal,
      rows: [
        _Detail('Name', placeName, Icons.location_city_rounded),
        _Detail('Designation', user?.userType, Icons.workspace_premium_outlined),
        _Detail('Username', user?.username, Icons.alternate_email_rounded),
      ],
    );
  }
}

class _Detail {
  const _Detail(this.label, this.value, this.icon);

  final String label;
  final String? value;
  final IconData icon;
}

/// A titled card of label/value rows.
///
/// Empty values render as a muted dash rather than being dropped: a missing
/// email is worth seeing on a profile, since it is the thing to go and fill in.
class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_Detail> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconPlate(icon: icon, color: color, size: 34),
              const SizedBox(width: AppTheme.space3),
              Text(title, style: AppTheme.title),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppTheme.spacer),
            _DetailRow(detail: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});

  final _Detail detail;

  @override
  Widget build(BuildContext context) {
    final value = detail.value;
    final isEmpty = value == null || value.trim().isEmpty;

    // Label and value on one line, not stacked. Stacking gave every row two
    // lines of text and a gap, which is what left this card looking mostly
    // empty; side by side the same three facts read as a compact spec sheet.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
      child: Row(
        children: [
          Icon(detail.icon, size: 17, color: AppTheme.deactivatedText),
          const SizedBox(width: AppTheme.space3),
          Text(detail.label, style: AppTheme.caption),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Text(
              isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: isEmpty
                    ? AppTheme.deactivatedText
                    : AppTheme.darkerText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
