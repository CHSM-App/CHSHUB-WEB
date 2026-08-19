import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/basicinfo.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
    final bool _isPopulated = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'email': TextEditingController(),
    };
   _loadData();
  }
  
Future<void> _loadData() async {
 Future.microtask(() {
      ref.read(basicInfoViewModelProvider.notifier).getBasicInfo();
    });
}
  void _populateFields(BasicInfo basicInfo) {
    _controllers['name']?.text = basicInfo.name ?? '';
    _controllers['phone']?.text = basicInfo.preMob ?? '';
    _controllers['email']?.text = basicInfo.email ?? '';

  }

  Future<void> _updateProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final userData = BasicInfo(
      contactNo: _controllers['phone']!.text.trim(),
      name: _controllers['name']!.text.trim(),
      email: _controllers['email']!.text.trim(),
      ownerId: ref.watch(basicInfoViewModelProvider).ownerId,
      login: ref.watch(basicInfoViewModelProvider).loginType?.toLowerCase(),
    );

    setState(() => _isSaving = true);
    try {
      if (_image != null) {
        await ref
            .read(basicInfoViewModelProvider.notifier)
            .addProfileImage(File(_image!.path), userData.ownerId.toString());
      }

      await ref
          .read(basicInfoViewModelProvider.notifier)
          .updateProfile(userData);

      _showSnackBar('Profile updated successfully');
    } catch (e) {
      _showSnackBar(ErrorMessageMapper.map(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Future<void> _updateProfile() async {
  //   final userData = BasicInfo(
  //     contactNo: _controllers['phone']!.text.trim(),
  //     name: _controllers['name']!.text.trim(),
  //     email: _controllers['email']!.text.trim(),
  //     ownerId: ref.watch(basicInfoViewModelProvider).ownerId,
  //     login: ref.watch(basicInfoViewModelProvider).loginType?.toLowerCase(),
  //   );
  //   if (!_formKey.currentState!.validate()) return;

  //   try {
  //     if (_image != null) {
  //       await ref
  //           .read(basicInfoViewModelProvider.notifier)
  //           .addProfileImage(File(_image!.path), userData.ownerId.toString());
  //     }

  //     await ref
  //         .read(basicInfoViewModelProvider.notifier)
  //         .updateProfile(userData);
  //     final state = ref.watch(basicInfoViewModelProvider);
  //     Future.delayed(const Duration(milliseconds: 500));
  //     if (state.data?['success'] == true) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Profile updated successfully'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       }
  //       return;
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to update profile: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    final basicInfoAsync = ref.watch(basicInfoViewModelProvider).basicInfoResult;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: basicInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
         error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
        data: (basicInfo) {
          if (basicInfo.isNotEmpty) _populateFields(basicInfo.first);
          final user = basicInfo.isNotEmpty ? basicInfo.first : BasicInfo();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ✅ Profile Avatar Tap → Preview | Edit Icon → Bottom Sheet
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showImagePreview(user),
                          child: _buildProfileAvatar(user),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showImageOptionsSheet(context, user),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ..._buildFormFields(),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (basicInfoAsync.isLoading || _isSaving)
                            ? null
                            : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Avatar widget
  Widget _buildProfileAvatar(BasicInfo user) {
    final hasPicked = _image != null;
    final hasDbImage =
        user.profileImage != null && user.profileImage!.isNotEmpty;
    if (hasPicked) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: FileImage(File(_image!.path)),
      );
    }

    if (hasDbImage) {
      return ClipOval(
        child: Image.network(
          user.profileImage!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(user),
        ),
      );
    }

    return _buildFallbackAvatar(user);
  }


String getInitial(String? name) {
  if (name == null || name.trim().isEmpty) return 'U';

  // Common prefixes
  final prefixes = [
    'mr ', 'mr.', 
    'mrs ', 'mrs.', 
    'miss ', 
    'ms ', 'ms.',
    'dr ', 'dr.'
  ];

  String cleaned = name.toLowerCase().trim();

  for (var p in prefixes) {
    if (cleaned.startsWith(p)) {
      cleaned = cleaned.replaceFirst(p, '').trim();
      break;
    }
  }

  return cleaned.substring(0, 1).toUpperCase();
}
Widget _buildFallbackAvatar(BasicInfo user) => CircleAvatar(
      radius: 48,
      backgroundColor: Colors.blue[400],
      child: Text(
        getInitial(user.name),   // ← FIXED HERE
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

  // Widget _buildFallbackAvatar(BasicInfo user) => CircleAvatar(
  //       radius: 48,
  //       backgroundColor: Colors.blue[400],
  //       child: Text(
  //         (user.name?.isNotEmpty ?? false)
  //             ? user.name!.substring(0, 1).toUpperCase()
  //             : 'U',
  //         style: const TextStyle(
  //             color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
  //       ),
  //     );

  // ✅ Bottom Sheet with edit/remove options (only when edit icon is tapped)
  void _showImageOptionsSheet(BuildContext context, BasicInfo user) {
    final hasImage = _image != null ||
        (user.profileImage != null && user.profileImage!.isNotEmpty);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildImageOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _buildImageOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a Photo',
                subtitle: 'Use your camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (hasImage)
                _buildImageOption(
                  icon: Icons.delete_outline,
                  title: 'Remove Image',
                  subtitle: 'Delete current profile picture',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmRemoveImage();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BasicInfo user) {
  final imageProvider = _image != null
      ? FileImage(File(_image!.path))
      : (user.profileImage != null && user.profileImage!.isNotEmpty
          ? NetworkImage(user.profileImage!)
          : null);

  if (imageProvider == null) return;

  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: SizedBox(
          width: 280,  // ✅ fixed width
          height: 280, // ✅ fixed height
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Image(
              image: imageProvider as ImageProvider,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}

  void _confirmRemoveImage() {
  final viewModel = ref.read(basicInfoViewModelProvider.notifier);
  final loginType = ref.watch(basicInfoViewModelProvider).loginType ?? '';
  final ownerId = ref.watch(basicInfoViewModelProvider).ownerId?.toString() ?? '';

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Remove Profile Image'),
      content: const Text(
        'Are you sure you want to remove your profile picture?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // close dialog
            try {
              // Show loading while deleting
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
                
              );

              // 🔥 Call ViewModel API
              await viewModel.deleteProfileImage(ownerId);
              if (mounted) {
                Navigator.pop(context); // close loading dialog
                setState(() => _image = null);
                _showSnackBar('Profile image removed successfully');
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context); // close loading dialog
                _showSnackBar(ErrorMessageMapper.map(e), isError: true);
              }
            }
          },
          child: const Text(
            'Remove',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}


  // ✅ Helper for bottom sheet options
  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? Colors.red : const Color(0xFF4A5FBF)),
        title: Text(title,
            style: TextStyle(
                color: isDestructive ? Colors.red : Colors.black,
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ),
    );
  }

  // ✅ Image Picker
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) setState(() => _image = picked);
    } catch (e) {
      _showSnackBar('Failed to pick image', isError: true);
    }
  }

  // ✅ Form Fields
  List<Widget> _buildFormFields() {
    final fields = [
      {'label': 'Full Name', 'key': 'name', 'icon': Icons.person_outline},
      {'label': 'Phone Number', 'key': 'phone', 'icon': Icons.phone_outlined},
      {'label': 'Email', 'key': 'email', 'icon': Icons.email_outlined},
    ];

    return fields
        .map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _controllers[f['key'] as String],
              validator: (v) =>
                  _validateField(v, f['key'] as String, f['label'] as String),
              decoration: InputDecoration(
                labelText: f['label'] as String,
                prefixIcon: Icon(f['icon'] as IconData, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[600]!),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  String? _validateField(String? value, String key, String label) {
    if (value == null || value.trim().isEmpty) return 'Please enter $label';
    if (key == 'email' &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email';
    }
    return null;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }
}


