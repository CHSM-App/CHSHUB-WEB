import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';

/// Raise a complaint on a resident's behalf.
///
/// The resident app has the same form (raise_complaint.dart) for residents
/// filing their own; this is the secretary's copy, so it also has to say which
/// flat the complaint is for — the resident app takes that from the session.
class RaiseComplaintScreen extends ConsumerStatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  ConsumerState<RaiseComplaintScreen> createState() =>
      _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends ConsumerState<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _queryController = TextEditingController();

  int? _flatId;
  int? _category;

  /// 'personal' is a complaint about the resident's own flat; 'community' is
  /// about shared property. The resident app words the toggle the same way.
  String _categoryType = 'personal';
  bool _urgent = false;

  /// The uploader accepts ten per request, so the picker stops there rather
  /// than letting the eleventh fail server-side.
  static const _maxPhotos = 10;
  final List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(communityViewModelProvider.notifier).loadHelpdeskLookups(),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  /// Camera or gallery, then add what came back.
  ///
  /// image_picker asks the OS for its own permission, so there is no separate
  /// permission_handler step — the resident app carries one because it also
  /// reads the gallery directly elsewhere.
  Future<void> _addPhotos(ImageSource source) async {
    final picker = ImagePicker();
    final room = _maxPhotos - _photos.length;

    final picked = source == ImageSource.gallery
        ? await picker.pickMultiImage()
        : [
            ?await picker.pickImage(source: ImageSource.camera),
          ];

    if (!mounted || picked.isEmpty) return;

    setState(() => _photos.addAll(picked.take(room).map((x) => File(x.path))));

    if (picked.length > room) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $_maxPhotos photos can be attached.')),
      );
    }
  }

  Future<void> _pickPhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space5,
            AppTheme.space3,
            AppTheme.space5,
            AppTheme.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              Text('Add photos', style: AppTheme.title),
              const SizedBox(height: 2),
              Text(
                '${_maxPhotos - _photos.length} more can be attached.',
                style: AppTheme.caption,
              ),
              const SizedBox(height: AppTheme.space4),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      hint: 'Take one now',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      hint: 'Pick several',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) await _addPhotos(source);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(communityViewModelProvider.notifier)
        .createHelpdeskTicket(
          // A community complaint belongs to the society, not to a flat, and
          // the picker is not shown for one — so there is nothing to send.
          flatId: _categoryType == 'community' ? null : _flatId,
          category: _category!,
          query: _queryController.text.trim(),
          categoryType: _categoryType,
          urgent: _urgent,
          images: _photos,
        );

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final lookups = ref
        .read(communityViewModelProvider.notifier)
        .helpdeskLookups;

    final categories = asRows(lookups?['categories']);
    final flats = asRows(lookups?['flats']);

    // The pickers are the form: with no categories there is nothing to raise a
    // complaint about, so the page says so rather than showing two dropdowns
    // that open onto nothing.
    if (lookups == null || categories.isEmpty || flats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Raise complaint')),
        body: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    const SizedBox(height: AppTheme.space8),
                    StateMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load the form',
                      message: lookups == null
                          ? 'The categories and flats did not load.'
                          : 'This society has no complaint categories set up '
                                'yet.',
                      actionLabel: 'Try again',
                      onAction: () => ref
                          .read(communityViewModelProvider.notifier)
                          .loadHelpdeskLookups(),
                    ),
                  ],
                ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Raise complaint')),
      body: SafeArea(
        child: PageConstraints(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space5,
                AppTheme.space4,
                AppTheme.space5,
                AppTheme.space8,
              ),
              children: [
                GradientPanel(
                  gradient: _urgent
                      ? AppTheme.duesGradient
                      : AppTheme.heroGradient,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.support_agent_outlined,
                        color: AppTheme.white,
                        size: 26,
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New complaint',
                              style: AppTheme.headline.copyWith(
                                fontSize: 18,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'The resident is told when it is raised, and '
                              'again whenever its status changes.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: AppTheme.onGradientMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space5),

                // Field for field in the order raise_complaint.dart asks for
                // them — type, scope, the complaint, urgency, photos — so the
                // two apps read the same way. The flat picker is the one
                // addition: the resident app knows whose flat it is from the
                // session, and a secretary filing on someone's behalf does
                // not, so it is asked for first.
                _FormCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Scope comes first: it decides whether a flat is asked
                      // for at all, and a field that vanishes after you have
                      // filled it reads as a glitch.
                      final personal = _categoryType == 'personal';
                      final flatField = _buildFlatField(flats);
                      final categoryField = _buildCategoryField(categories);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScopeToggle(),
                          const SizedBox(height: AppTheme.space4),
                          if (constraints.maxWidth < 520 || !personal)
                            Column(
                              children: [
                                if (personal) ...[
                                  flatField,
                                  const SizedBox(height: AppTheme.space4),
                                ],
                                categoryField,
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: flatField),
                                const SizedBox(width: AppTheme.space3),
                                Expanded(child: categoryField),
                              ],
                            ),
                          const SizedBox(height: AppTheme.space3),
                          _buildTypeNote(_selectedCategory(categories)),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                _FormCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _queryController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Complaint',
                          hintText: 'Brief your complaint…',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Describe the complaint'
                            : null,
                      ),
                      const SizedBox(height: AppTheme.space4),
                      _buildUrgentSwitch(),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Attach photos', style: AppTheme.overline),
                          const SizedBox(width: 6),
                          Text(
                            _photos.isEmpty
                                ? 'Optional'
                                : '${_photos.length} of $_maxPhotos',
                            style: AppTheme.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space3),
                      _buildPhotos(),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space6),

                BusyButton(
                  label: 'Raise complaint',
                  icon: Icons.send_rounded,
                  busy: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The flats of the signed-in secretary's own society.
  ///
  /// The scoping is the server's: sp_flat_master's Grid_Show branch is given
  /// the society from the access token, and requireSociety rejects a request
  /// that claims a different one — so there is nothing to filter here.
  ///
  /// Ordered by building and then flat number. A society runs to dozens of
  /// flats across several buildings, and Grid_Show returns them in whatever
  /// order it likes, which leaves the wings interleaved.
  Widget _buildFlatField(List<Map<String, dynamic>> flats) {
    final sorted = [...flats]
      ..sort((a, b) {
        final byBuilding = _buildingOf(a).compareTo(_buildingOf(b));
        if (byBuilding != 0) return byBuilding;

        // Flat numbers are text but read as numbers — "9" belongs before
        // "10", which a plain string sort would get backwards.
        final an = pick(a, ['flat_no', 'unit_no', 'flat']) ?? '';
        final bn = pick(b, ['flat_no', 'unit_no', 'flat']) ?? '';
        final ai = int.tryParse(an);
        final bi = int.tryParse(bn);

        if (ai != null && bi != null) return ai.compareTo(bi);
        return an.compareTo(bn);
      });

    // Only ever built for a personal complaint — a community one belongs to
    // the society rather than to a flat, and the caller leaves this out
    // entirely — so the wording speaks plainly about one flat.
    return AppDropdown<int>(
      value: _flatId,
      label: 'Flat',
      hint: 'Which flat is this for?',
      icon: Icons.home_outlined,
      isDense: false,
      options: [
        for (final f in sorted)
          if (pickInt(f, ['flat_id', 'id']) != null)
            AppOption(pickInt(f, ['flat_id', 'id'])!, _flatLabel(f)),
      ],
      onChanged: (v) => setState(() => _flatId = v),
      validator: (v) => v == null ? 'Choose a flat' : null,
    );
  }

  /// The building a flat sits in, however Grid_Show spelled it.
  String _buildingOf(Map<String, dynamic> flat) =>
      pick(flat, ['build_wing', 'building_name', 'building']) ??
      [
        pick(flat, ['name']),
        pick(flat, ['w_name']),
      ].where((e) => e != null).join(' ');

  /// The categories are sp_usefull_contact's ComplaintType rows — the same
  /// list the resident app's helpdesk page shows, keyed the same way.
  Widget _buildCategoryField(List<Map<String, dynamic>> categories) {
    return AppDropdown<int>(
      value: _category,
      label: 'Complaint type',
      hint: 'Select complaint type',
      // Tinted, as the resident app's helpdesk page has it — the complaint
      // type is the field the form turns on, and the note below it is keyed
      // to the same colour.
      icon: Icons.category_rounded,
      iconColor: AppTheme.primary,
      isDense: false,
      options: [
        // The ComplaintType branch names these `c_type_id` / `c_type_name`,
        // which is what the resident app's helpdesk page reads. The `p_type_*`
        // pair is the other branch's spelling and is kept as a fallback, since
        // a ticket's own row carries the category as `p_type_name`.
        for (final c in categories)
          if (pickInt(c, ['c_type_id', 'p_type_id', 'id']) != null)
            AppOption(
              pickInt(c, ['c_type_id', 'p_type_id', 'id'])!,
              pick(c, ['c_type_name', 'p_type_name', 'name']) ?? 'Category',
            ),
      ],
      onChanged: (v) => setState(() => _category = v),
      validator: (v) => v == null ? 'Please select a complaint type' : null,
    );
  }

  /// The row behind the current choice, for the note under the pickers.
  Map<String, dynamic>? _selectedCategory(
    List<Map<String, dynamic>> categories,
  ) {
    if (_category == null) return null;

    return categories
        .where((c) => pickInt(c, ['c_type_id', 'p_type_id', 'id']) == _category)
        .firstOrNull;
  }

  /// What the chosen type is for, as the resident app's helpdesk page shows
  /// it — the guidance is carried per row, in a column the database spells
  /// `decription`.
  Widget _buildTypeNote(Map<String, dynamic>? selected) {
    final chosen = selected != null;

    final title = chosen
        ? pick(selected, ['c_type_name', 'p_type_name', 'name']) ?? 'Selected'
        : null;

    final body = chosen
        ? pick(selected, ['decription', 'description']) ??
              'Please provide detailed information about this complaint type '
                  'in the description below.'
        : 'Please select a complaint type to see more details';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: chosen ? AppTheme.primarySurface : AppTheme.spacer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: chosen
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            chosen ? Icons.info_outline_rounded : Icons.lightbulb_outline,
            size: 17,
            color: chosen ? AppTheme.primary : AppTheme.lightText,
          ),
          const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: AppTheme.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  body,
                  style: AppTheme.caption.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The attached photos, plus the tile that adds more.
  ///
  /// Sized off the available width rather than fixed at 84px, so the tiles
  /// grow into a wide window instead of leaving a long empty run beside them.
  Widget _buildPhotos() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppTheme.space2;
        final columns = (constraints.maxWidth / 120).floor().clamp(3, 6);
        final tile = (constraints.maxWidth - gap * (columns - 1)) / columns;

        if (_photos.isEmpty) return _buildPhotoEmpty();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final photo in _photos)
              _PhotoThumb(
                file: photo,
                size: tile,
                onTap: () => _previewPhoto(photo),
                onRemove: () => setState(() => _photos.remove(photo)),
              ),
            if (_photos.length < _maxPhotos)
              _AddPhotoTile(size: tile, onTap: _pickPhotoSource),
          ],
        );
      },
    );
  }

  /// The first-run state: one wide target rather than a lone small square,
  /// which reads as a dropzone and is easier to hit.
  Widget _buildPhotoEmpty() {
    return InkWell(
      onTap: _pickPhotoSource,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.spacer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: const BoxDecoration(
                color: AppTheme.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              'Add photos',
              style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'Up to $_maxPhotos, from the camera or gallery',
              style: AppTheme.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  /// A picked photo, full-screen and zoomable — the same viewer the ticket
  /// page uses for photos already attached.
  void _previewPhoto(File photo) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppTheme.space4),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(child: Image.file(photo)),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: AppTheme.white),
            ),
          ],
        ),
      ),
    );
  }

  /// "Ganesh Bhavan 104" — the building and the flat number.
  ///
  /// Grid_Show spells the building `build_wing` ("Ganesh Bhavan"), and splits
  /// the same thing across `name` and `w_name`. It carries no owner: `name` is
  /// the building's, not a resident's, so using it here labelled every flat in
  /// a wing identically.
  String _flatLabel(Map<String, dynamic> flat) {
    final building = _buildingOf(flat);
    final number = pick(flat, ['flat_no', 'unit_no', 'flat']);

    final label = [
      building.isEmpty ? null : building,
      number,
    ].where((e) => e != null && e.isNotEmpty).join(' ');

    return label.isEmpty ? 'Flat' : label;
  }

  /// Personal or community, as a pair of segments rather than a dropdown —
  /// there are only two, and both should be readable without opening anything.
  Widget _buildScopeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scope', style: AppTheme.overline),
        const SizedBox(height: AppTheme.space2),
        Row(
          children: [
            Expanded(
              child: _ScopeOption(
                icon: Icons.lock_outline_rounded,
                label: 'Personal',
                hint: 'Flat and committee',
                selected: _categoryType == 'personal',
                onTap: () => setState(() => _categoryType = 'personal'),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: _ScopeOption(
                icon: Icons.people_outline_rounded,
                label: 'Community',
                // Says what picking it does, not just what it means: this is
                // the one choice on the form that reaches everybody.
                hint: 'Tells all residents',
                selected: _categoryType == 'community',
                onTap: () => setState(() => _categoryType = 'community'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgentSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: _urgent ? AppTheme.surfaceFor(AppTheme.error) : AppTheme.spacer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _urgent
              ? AppTheme.error.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: SwitchListTile(
        value: _urgent,
        onChanged: (v) => setState(() => _urgent = v),
        activeThumbColor: AppTheme.error,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: 2,
        ),
        title: Text(
          'Mark as urgent',
          style: AppTheme.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: _urgent ? AppTheme.error : AppTheme.darkText,
          ),
        ),
        subtitle: Text(
          'Shown first, and flagged red in the list.',
          style: AppTheme.caption,
        ),
      ),
    );
  }
}

/// One group of fields, on its own plate.
///
/// The form is a flat sequence like the resident app's, not a numbered
/// wizard — the cards only break the run of inputs into readable groups.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: child,
    );
  }
}

/// An attached photo: tap to see it full-size, or the corner to remove it.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.file,
    required this.size,
    required this.onTap,
    required this.onRemove,
  });

  final File file;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file, fit: BoxFit.cover),
                  // A press target over the whole tile, above the image so the
                  // ripple is visible on it.
                  Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: onTap),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Camera or gallery, in the sheet that opens before the picker.
class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.spacer,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                label,
                style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(hint, style: AppTheme.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tile that adds more photos, sized to match the thumbnails beside it.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppTheme.spacer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 24,
          color: AppTheme.lightText,
        ),
      ),
    );
  }
}

/// One of the two scope segments.
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primarySurface : AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space3,
            vertical: AppTheme.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppTheme.primary : AppTheme.lightText,
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                label,
                style: AppTheme.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.primary : AppTheme.darkText,
                ),
              ),
              Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
