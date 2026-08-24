import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/presentation/viewModels/login_viewmodel.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final int gateKeeperId;

  const EditProfileScreen({Key? key, required this.gateKeeperId}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _societyController = TextEditingController();

  String? _profileImagePath;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isDataLoaded = false;
  bool _isUpdating = false;

  @override
  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(securitymodelProvider);
    
      _prefillIfAvailable(state);

      ref.listen(securitymodelProvider, (prev, next) {
        _prefillIfAvailable(next);

        if (next.error != null && _isDataLoaded) {
          _showSnackBar(next.error!, Colors.red);
        }

        if (_isUpdating && !next.isLoading && next.data["update"] != null) {
          _isUpdating = false;
          _showSnackBar("Profile updated successfully!", const Color(0xFF10B981));
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      });
    });
  }

  void _prefillIfAvailable(SecurityState next) {
    if (!_isDataLoaded &&
        next.loginDetails.hasValue &&
        next.loginDetails.value!.isNotEmpty) {
      final data = next.loginDetails.value!.first;

      _nameController.text = data.name ?? "";
      _phoneController.text = data.contactNo ?? "";
      _emailController.text = data.email ?? "";
      _addressController.text = data.address ?? "";
      _societyController.text = data.societyName ?? "";
      _profileImagePath = data.image ?? "";

      _isDataLoaded = true;
      setState(() {});
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securitymodelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, state),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileImage(),
                const SizedBox(height: 32),
                _buildTextField(
                  enabled: true,
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  enabled: true,
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your phone' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  enabled:true,
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _societyController,
                  label: 'Society Name',
                  icon: Icons.apartment_outlined,
                   enabled: false,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter society name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  enabled:true,
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your address' : null,
                ),
                const SizedBox(height: 32),
                _buildSaveButton(state),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, SecurityState state) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 62,
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundImage: _selectedImageFile != null
                    ? FileImage(_selectedImageFile!)
                    : (_profileImagePath != null && _profileImagePath!.isNotEmpty)
                        ? NetworkImage(_profileImagePath!)
                        : null,
                child: (_selectedImageFile == null &&
                        (_profileImagePath == null || _profileImagePath!.isEmpty))
                    ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator, required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 22),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(SecurityState state) {
    final isLoading = state.isLoading && _isUpdating;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : _saveProfile,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions() {
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
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Change Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              _buildOption(
                icon: Icons.camera_alt_outlined,
                title: 'Camera',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageFromCamera();
                },
              ),
              _buildOption(
                icon: Icons.photo_library_outlined,
                title: 'Gallery',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageFromGallery();
                },
              ),
              if (_selectedImageFile != null ||
                  (_profileImagePath != null && _profileImagePath!.isNotEmpty))
                _buildOption(
                  icon: Icons.delete_outline,
                  title: 'Remove Photo',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar(getErrorMessage(e), Colors.red);
    }
  }

  Future<void> _selectImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar(getErrorMessage(e), Colors.red);
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      setState(() {
        _isUpdating = true;
      });

      await ref
          .read(securitymodelProvider.notifier)
          .deleteStaffImage(widget.gateKeeperId.toString());

      setState(() {
        _selectedImageFile = null;
        _profileImagePath = null;
        _isUpdating = false;
      });

      _showSnackBar('Photo removed successfully', const Color(0xFF10B981));
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      _showSnackBar('Failed to remove photo', Colors.red);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      try {
        String? updatedImagePath = _profileImagePath;

        if (_selectedImageFile != null) {
          final imageResult = await ref.read(staffmodelProvider.notifier).addProfileImage(
                _selectedImageFile!,
                widget.gateKeeperId,
              );

          if (imageResult != null && imageResult['success'] == true) {
            updatedImagePath =
                "https://chshub.co.in/upload/ProfilePhoto/${widget.gateKeeperId}/${_selectedImageFile!.path.split('/').last}";
          }
        }

        final loginData = LoginData(
          staffId: widget.gateKeeperId,
          name: _nameController.text,
          contactNo: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          societyName: _societyController.text,
          image: updatedImagePath ?? "",
        );

        await ref.read(securitymodelProvider.notifier).updateGateKeeper(loginData);
      } catch (e) {
        setState(() {
          _isUpdating = false;
        });
        _showSnackBar(getErrorMessage(e), Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _societyController.dispose();
    super.dispose();
  }
}