import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../core/utils/error_formatter.dart';
import '../../domain/models/auth_requests.dart';
import '../../domain/models/user.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import 'photo_viewer.dart';

/// Edit your own name, username, email and contact number.
///
/// Pops `true` once a save succeeds, so the profile behind it knows to refresh.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final User? user;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _contact;

  /// Drives the live initials in the header, so the avatar tracks what is being
  /// typed rather than what was loaded.
  String _preview = '';

  /// A photo picked this session, shown before it is uploaded so the choice is
  /// visible immediately. Null means nothing new was picked.
  File? _pickedPhoto;

  /// The path the picked photo was stored at, once uploaded. Null until then.
  String? _uploadedPath;

  /// Set when the existing photo is to be removed on save.
  bool _photoRemoved = false;

  bool _uploading = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: user?.name ?? '');
    _username = TextEditingController(text: user?.username ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _contact = TextEditingController(text: user?.contactNo ?? '');
    _preview = _name.text;
    _name.addListener(() {
      if (_name.text != _preview) setState(() => _preview = _name.text);
    });
  }

  /// What to send as the request's photoPath.
  ///
  /// Null leaves the stored photo alone, the empty string removes it, and a
  /// path replaces it — the three states the endpoint reads.
  String? get _photoPathToSave {
    if (_uploadedPath != null) return _uploadedPath;
    if (_photoRemoved) return UpdateProfileRequest.photoRemoved;
    return null;
  }

  /// Offers the camera, the gallery, and removal when there is a photo to
  /// remove — the same three choices CHSHUB_app's editor gives.
  Future<void> _showPhotoOptions() async {
    final hasPhoto =
        _pickedPhoto != null ||
        (!_photoRemoved && (widget.user?.photoUrl != null));

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuTile(
              icon: Icons.photo_camera_outlined,
              color: AppTheme.primary,
              title: 'Take a photo',
              subtitle: 'Use the camera',
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.camera);
              },
            ),
            MenuTile(
              icon: Icons.photo_library_outlined,
              color: AppTheme.teal,
              title: 'Choose from gallery',
              subtitle: 'Pick one of your photos',
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              MenuTile(
                icon: Icons.delete_outline_rounded,
                color: AppTheme.error,
                title: 'Remove photo',
                subtitle: 'Go back to your initials',
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _pickedPhoto = null;
                    _uploadedPath = null;
                    _photoRemoved = true;
                  });
                },
              ),
            const SizedBox(height: AppTheme.space4),
          ],
        ),
      ),
    );
  }

  /// Picks a photo and uploads it straight away.
  ///
  /// Uploading here rather than on save means the slow part happens while the
  /// user is still filling the form, and a failure is reported next to the
  /// avatar that caused it instead of surfacing as a failed save.
  Future<void> _pick(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        // Downscaled and recompressed before upload: a modern phone camera
        // produces several megabytes, and the uploader caps files at 10MB.
        // An avatar is never displayed larger than a few hundred points.
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      if (!mounted) return;
      // A denied camera or photo permission arrives here as a PlatformException.
      showAppSnack(context, formatError(e), success: false);
      return;
    }

    if (picked == null || !mounted) return;

    final file = File(picked.path);
    setState(() {
      _pickedPhoto = file;
      _photoRemoved = false;
      _uploadedPath = null;
      _uploading = true;
    });

    final path = await ref
        .read(authViewModelProvider.notifier)
        .uploadProfilePhoto(file);

    if (!mounted) return;

    setState(() {
      _uploading = false;
      _uploadedPath = path;
      // Drop the preview when the upload failed, so the avatar does not show a
      // photo that will not be saved.
      if (path == null) _pickedPhoto = null;
    });

    if (path == null) {
      showAppSnack(
        context,
        ref.read(authViewModelProvider).error ??
            'Could not upload that photo.',
        success: false,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _contact.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final user = widget.user;
    return _name.text.trim() != (user?.name ?? '').trim() ||
        _username.text.trim() != (user?.username ?? '').trim() ||
        _email.text.trim() != (user?.email ?? '').trim() ||
        _contact.text.trim() != (user?.contactNo ?? '').trim() ||
        // A picked or removed photo is an unsaved change like any other, so
        // leaving without saving has to warn about it too.
        _photoPathToSave != null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // A photo is still on its way up. Saving now would store the profile
    // without it and leave the upload writing a file nothing references.
    if (_uploading) {
      showAppSnack(
        context,
        'The photo is still uploading — one moment.',
        success: false,
      );
      return;
    }

    // Nothing to send, and the endpoint would still rewrite the row — just
    // close, so an accidental open cannot touch the account.
    if (!_isDirty) {
      Navigator.pop(context, false);
      return;
    }

    final ok = await ref
        .read(authViewModelProvider.notifier)
        .updateProfile(
          name: _name.text,
          username: _username.text,
          email: _email.text,
          contactNo: _contact.text,
          photoPath: _photoPathToSave,
        );

    if (!mounted) return;

    showAppSnack(
      context,
      ok
          ? 'Profile updated.'
          : (ref.read(authViewModelProvider).error ??
                'Could not save your profile.'),
      success: ok,
    );

    if (ok) Navigator.pop(context, true);
  }

  /// Confirms before throwing away typed changes.
  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;

    return confirmAction(
      context,
      title: 'Discard changes?',
      message: 'Your edits to this profile have not been saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
  }

  /// Leaves without saving, asking first if anything was typed.
  Future<void> _cancel() async {
    final discard = await _confirmDiscard();
    if (!mounted || !discard) return;
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        // White bar and a light page, matching the profile screen this opens
        // from and CHSHUB_app's own edit page.
        appBar: AppBar(
          backgroundColor: AppTheme.cardBackground,
          foregroundColor: AppTheme.darkerText,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          title: Text(
            'Edit profile',
            style: AppTheme.headline.copyWith(fontSize: 21),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppTheme.space8),
              children: [
                const SizedBox(height: AppTheme.space5),
                _EditHeader(
                  name: _preview,
                  role: widget.user?.userType,
                  photo: _pickedPhoto,
                  photoUrl: _photoRemoved ? null : widget.user?.photoUrl,
                  uploading: _uploading,
                  onChangePhoto: _showPhotoOptions,
                ),
                const SizedBox(height: AppTheme.space5),
                PageConstraints(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(AppTheme.space5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your details', style: AppTheme.title),
                            const SizedBox(height: AppTheme.space4),
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter your name'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.space4),
                            TextFormField(
                              controller: _username,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                helperText: 'What you sign in with',
                                prefixIcon: Icon(
                                  Icons.alternate_email_rounded,
                                ),
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'Enter a username';
                                if (value.contains(' ')) {
                                  return 'A username cannot contain spaces';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space2),
                      AppCard(
                        padding: const EdgeInsets.all(AppTheme.space5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('How to reach you', style: AppTheme.title),
                            const SizedBox(height: AppTheme.space4),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              // Optional — the account may have been created
                              // from a phone number alone — but a value that is
                              // present should at least look like an address.
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return null;
                                final looksValid = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(value);
                                return looksValid
                                    ? null
                                    : 'Enter a valid email address';
                              },
                            ),
                            const SizedBox(height: AppTheme.space4),
                            TextFormField(
                              controller: _contact,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _save(),
                              decoration: const InputDecoration(
                                labelText: 'Contact number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                final digits = (v ?? '').replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                if (digits.isEmpty) return null;
                                return digits.length < 10
                                    ? 'Enter a 10-digit number'
                                    : null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space5),
                      BusyButton(
                        label: 'Save changes',
                        icon: Icons.check_rounded,
                        busy: isLoading,
                        onPressed: _save,
                      ),
                      const SizedBox(height: AppTheme.space3),
                      TextButton(
                        onPressed: isLoading ? null : _cancel,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// The avatar above the form, carrying the initials as they are typed — the one
/// piece of feedback a form of text fields otherwise lacks.
///
/// On the light page rather than on a band of brand colour. CHSHUB_app puts the
/// avatar at the top of its edit form the same way, and the earlier full-width
/// gradient strip here pushed the fields — the only thing the page exists for —
/// down the screen to make room for decoration.
class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.name,
    required this.role,
    required this.photo,
    required this.photoUrl,
    required this.uploading,
    required this.onChangePhoto,
  });

  final String name;
  final String? role;

  /// A photo picked this session, shown before it has finished uploading.
  final File? photo;

  /// The photo already stored on the account, if any and not being removed.
  final String? photoUrl;

  final bool uploading;
  final VoidCallback onChangePhoto;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    final typed = name.trim();
    final display = typed.isEmpty ? 'Secretary' : typed;

    return Column(
      children: [
        SizedBox(
          height: _size,
          width: _size,
          // The camera badge overhangs the circle, so this must not clip.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildAvatar(context, display),
              if (uploading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.shadowSm,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Material(
                    color: AppTheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      // Disabled mid-upload: picking again would leave two
                      // uploads racing to set the saved path.
                      onTap: uploading ? null : onChangePhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: 15,
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5),
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.title.copyWith(fontSize: 17),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          typed.isEmpty
              ? 'Your initials update as you type'
              : (role ?? 'Secretary'),
          style: AppTheme.caption,
        ),
        // No text button under this. The camera badge on the avatar already
        // opens the same sheet, and two controls for one action a few points
        // apart read as two different things.
      ],
    );
  }

  /// The picked photo if there is one, then the stored photo, then initials.
  ///
  /// Both photos are tappable, and open full size. That matters most here: this
  /// is where a photo is chosen, and an 96pt circle is too small to tell a good
  /// crop from a bad one.
  Widget _buildAvatar(BuildContext context, String display) {
    final local = photo;
    final remote = photoUrl;

    if (local != null) {
      return GestureDetector(
        onTap: () => showPhotoViewer(context, null, file: local),
        child: _circle(child: Image.file(local, fit: BoxFit.cover)),
      );
    }

    if (remote != null) {
      return GestureDetector(
        onTap: () => showPhotoViewer(context, remote),
        child: _circle(
          child: Image.network(
            remote,
            fit: BoxFit.cover,
            // A photo that will not load must not leave a broken box where a
            // face should be — fall back to what the account always has.
            errorBuilder: (_, _, _) => _initials(display),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _initials(display),
          ),
        ),
      );
    }

    return _initials(display);
  }

  Widget _circle({required Widget child}) {
    return ClipOval(
      child: SizedBox(height: _size, width: _size, child: child),
    );
  }

  Widget _initials(String display) {
    return Container(
      height: _size,
      width: _size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(display),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppTheme.white,
        ),
      ),
    );
  }
}
