import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:security_app/domain/models/notification.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class EntryPage extends ConsumerStatefulWidget {
  final String entryType;
  final bool isOTPEntry;
  final String? enteredCode;
  final String? scannedData;
  final Map<String, dynamic>? prefilledData;

  const EntryPage({
    super.key,
    required this.entryType,
    this.isOTPEntry = false,
    this.enteredCode,
    this.scannedData,
    this.prefilledData,
  });

  @override
  ConsumerState<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends ConsumerState<EntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _flatController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  String? imagePath ;
  bool _isDataPrefilled = false;
  String? _selectedFlat;
  int? flatID;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _prefillFormData();

    Future.microtask(() {
      ref.read(unitsmodelProvider.notifier).fetchUnits(
          ref.read(securitymodelProvider).SocietyId ?? "");
    });
  }

  void _prefillFormData() {
    if (widget.prefilledData != null) {
      _isDataPrefilled = true;
      final data = widget.prefilledData!;
      debugPrint("Pre-filling form with data: $data");
      // Pre-fill common fields
      _nameController.text = data['name'] ?? data['scannedName'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _selectedFlat = data['flat'] ?? data['scannedFlat'] ?? '';

      // Pre-fill entry type specific fields
      switch (widget.entryType) {
        case 'Guest Entry':
          _purposeController.text = data['purpose'] ?? '';
          _addressController.text = data['address'] ?? '';
          break;

        case 'Cab Entry':
          _companyController.text = data['company'] ?? '';
          _vehicleNumberController.text = data['vehicleNumber'] ?? '';
          _addressController.text =
              data['pickupLocation'] ?? data['dropLocation'] ?? '';
          break;

        case 'Delivery Entry':
          _companyController.text = data['company'] ?? '';
          _purposeController.text = data['packageDescription'] ?? '';
          _vehicleNumberController.text = data['vehicleNumber'] ?? '';
          break;

        case 'Service Entry':
          _companyController.text = data['company'] ?? '';
          // _purposeController.text = data['serviceType'] ?? '';
          _vehicleNumberController.text = data['vehicleNumber'] ?? '';
          break;
      }

      if (data['profilePicture'] != null) {
        _selectedImagePath = data['profilePicture'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _vehicleNumberController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _flatController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFFEF4444)
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
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

  Widget _buildFlatDropdown() {
    final unitsState = ref.watch(unitsmodelProvider);

    return unitsState.unitsList.when(
      data: (units) {
        if (units.isEmpty) {
          return _buildDisabledDropdown("No flats available");
        }

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
          child: DropdownButtonFormField<String>(
            initialValue: units.any((u) => u.flatId.toString() == _selectedFlat)
                ? _selectedFlat
                : null,
            decoration: InputDecoration(
              labelText: "Flat Number *",
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.home_outlined,
                color: Color(0xFF6366F1),
                size: 22,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 350,
            isExpanded: true,
            elevation: 8,
            items: units.map((u) {
              final isSelected = u.flatId.toString() == _selectedFlat;
              return DropdownMenuItem<String>(
                value: u.flatId.toString(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF6366F1).withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.apartment,
                          color: isSelected ? Colors.white : const Color(0xFF6366F1),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          u.unit,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected 
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF1F2937),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            selectedItemBuilder: (BuildContext context) {
              return units.map((u) {
                return Row(
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      u.unit,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            onChanged: (value) {
              final selectedUnit =
                  units.firstWhere((u) => u.flatId.toString() == value);

              if (flatID == selectedUnit.flatId) {
                _handleSameFlatSelected(selectedUnit);
              }

              setState(() {
                flatID = selectedUnit.flatId;
                _selectedFlat = selectedUnit.flatId.toString();
              });
            },
            validator: (value) =>
                value == null || value.isEmpty ? "Please select a flat" : null,
          ),
        );
      },
      loading: () => _buildDisabledDropdown("Loading flats..."),
      error: (err, stack) => _buildDisabledDropdown("Error loading flats"),
    );
  }

  Widget _buildDisabledDropdown(String message) {
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
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Flat Number *",
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.home_outlined,
            color: Color(0xFF6366F1),
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        items: const [],
        onChanged: null,
        hint: Text(message),
      ),
    );
  }

  Future<void> _refreshUnits() async {
    await ref.read(unitsmodelProvider.notifier).fetchUnits(
        ref.read(securitymodelProvider).SocietyId ?? "");
  }

  void _handleSameFlatSelected(dynamic selectedUnit) {
    _showSnackBar(
      "Flat ${selectedUnit.unit} reselected",
      const Color(0xFF6366F1),
    );
  }

  void _showImagePickerOptions() {
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
                  _pickImage(true);
                },
              ),
              _buildOption(
                icon: Icons.photo_library_outlined,
                title: 'Gallery',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(false);
                },
              ),
              if (_selectedImagePath != null)
                _buildOption(
                  icon: Icons.delete_outline,
                  title: 'Remove Photo',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImagePath = null;
                    });
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
        _showSnackBar(
          fromCamera
              ? 'Photo captured successfully!'
              : 'Image selected from gallery!',
          const Color(0xFF10B981),
        );
      }
    } catch (e) {
      _showSnackBar(getErrorMessage(e), const Color(0xFFEF4444));
    }
  }

  Widget _buildProfilePictureSection() {
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
                foregroundImage: _selectedImagePath != null
                    ? FileImage(File(_selectedImagePath!))
                    : null,
                child: _selectedImagePath == null
                    ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _showImagePickerOptions,
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

  Widget _buildPrefilledDataNotice() {
    if (!_isDataPrefilled) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isOTPEntry
                      ? 'OTP Verified Successfully!'
                      : 'QR Code Scanned!',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Details have been pre-filled. Please verify and complete.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.enteredCode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Entry Code: ${widget.enteredCode}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getFormFields() {
    List<Widget> fields = [];

    fields.addAll([
      _buildProfilePictureSection(),
      const SizedBox(height: 32),
    ]);

    fields.addAll([
      _buildTextField(
        'Full Name',
        _nameController,
        Icons.person_outline,
        true,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        'Phone Number',
        _phoneController,
        Icons.phone_outlined,
        true,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
      ),
      const SizedBox(height: 16),
      _buildFlatDropdown(),
      const SizedBox(height: 16),
    ]);

    switch (widget.entryType) {
      case 'Guest Entry':
        fields.addAll([
          _buildTextField(
            'Purpose of Visit',
            _purposeController,
            Icons.assignment_outlined,
            true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Address',
            _addressController,
            Icons.location_on_outlined,
            false,
            maxLines: 3,
          ),
        ]);
        break;

      case 'Cab Entry':
        fields.addAll([
          _buildTextField(
            'Company Name',
            _companyController,
            Icons.business_outlined,
            true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Vehicle Number',
            _vehicleNumberController,
            Icons.directions_car_outlined,
            true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Pickup/Drop Location',
            _addressController,
            Icons.location_on_outlined,
            true,
          ),
        ]);
        break;

      case 'Delivery Entry':
        fields.addAll([
          _buildTextField(
            'Company Name',
            _companyController,
            Icons.business_outlined,
            true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Package Description',
            _purposeController,
            Icons.inventory_2_outlined,
            true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Vehicle Number',
            _vehicleNumberController,
            Icons.local_shipping_outlined,
            false,
          ),
        ]);
        break;

      case 'Service Entry':
        fields.addAll([
          _buildTextField(
            'Service Company',
            _companyController,
            Icons.business_outlined,
            true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Vehicle Number',
            _vehicleNumberController,
            Icons.directions_car_outlined,
            false,
          ),
        ]);
        break;
    }

    return fields;
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool required, {
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
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
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 22),
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: maxLines > 1 ? 18 : 18,
          ),
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
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                if (label.contains("Phone") && value.length != 10) {
                  return 'Phone number must be 10 digits';
                }
                return null;
              }
            : null,
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
final visitor_Id = widget.prefilledData != null
      ? widget.prefilledData!['v_id'] as int?
      : null;
    setState(() {
      _isSubmitting = true;
    });

    final flatId = int.tryParse(_selectedFlat ?? "0") ?? 0;
    final guestName = _nameController.text;
    final contactNo = _phoneController.text;
    final purpose = _purposeController.text;
    final address = _addressController.text;
    final vehicleNo = _vehicleNumberController.text;
    final company = _companyController.text;
    final societyId = ref.read(securitymodelProvider).SocietyId ?? "";

    final now = DateTime.now();
    final preDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

if(_isDataPrefilled){
    debugPrint("Updating existing visitor ID: $visitor_Id");
    await ref.read(visitormodelProvider.notifier).updateVisitor(
      visitor_Id,
      guestName,
      contactNo,
      widget.entryType,
    );
 
    return _showSuccessDialog({
      "flat": flatId.toString(),
      "name": guestName,
      "phone": contactNo,
      "purpose": purpose,
      "entryType": widget.entryType,
      "vehicleNo": vehicleNo,
      "company": company,
      "address": address,
    });
}
    try {
      switch (widget.entryType) {
        case "Guest Entry":
          await ref.read(visitormodelProvider.notifier).addGuest(
                flatId,
                guestName,
                preDate,
                contactNo,
                purpose,
                societyId,
                address,
              );
          break;

        case "Cab Entry":
          await ref.read(visitormodelProvider.notifier).addCab(
                flatId,
                guestName,
                vehicleNo,
                preDate,
                contactNo,
                company,
                societyId,
                address,
              );
          break;

        case "Service Entry":
          await ref.read(visitormodelProvider.notifier).addService(
                flatId,
                guestName,
                preDate,
                contactNo,
                company,
                vehicleNo,
                societyId,
              );
          break;

        case "Delivery Entry":
          await ref.read(visitormodelProvider.notifier).addDelivery(
                flatId,
                guestName,
                preDate,
                contactNo,
                purpose,
                vehicleNo,
                company,
                societyId,
              );
          break;
      }

      final visitorState = ref.read(visitormodelProvider);

      if (visitorState.data["success"] != true) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final int visitorId = visitorState.data["visitor_id"];

  /// 🔹 STEP 2: UPLOAD IMAGE (FIX)
  if (_selectedImagePath != null) {
     final result = await ref.read(visitormodelProvider.notifier).addVisitorProfile(
      File(_selectedImagePath!),
      visitorId,
    );

     imagePath =  result['message'];
  }

      await ref
          .read(securitymodelProvider.notifier)
          .getAllTokens(societyId, flatId.toString());

      final tokenState = ref.read(securitymodelProvider);

      tokenState.getAllTokensdata.when(
        data: (tokens) async {
          final validTokens = tokens
              .map((e) => e.token)
              .where((t) => t != null && t.isNotEmpty)
              .cast<String>()
              .toList();

      if (validTokens.isNotEmpty) {
        final notification = SendNotification(
          id: "",
          title: "New ${widget.entryType}",
          body: "${widget.entryType} for $guestName arrived",
          tokens: validTokens,
          visitorName: guestName,
          unit: _selectedFlat ?? "",
          visitorId: visitorId,
          entryType: widget.entryType,
          image: imagePath,
           staff_token: ref.read(securitymodelProvider).token ?? '',
        );

            await ref
                .read(securitymodelProvider.notifier)
                .sendDataMessage(notification);
          }
        },
        loading: () {},
        error: (_, __) {},
      );

      setState(() {
        _isSubmitting = false;
      });

      _showSuccessDialog({
        "flat": flatId.toString(),
        "name": guestName,
        "phone": contactNo,
        "purpose": purpose,
        "entryType": widget.entryType,
        "vehicleNo": vehicleNo,
        "company": company,
        "address": address,
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar(getErrorMessage(e), const Color(0xFFEF4444));
    }
  }

  void _showSuccessDialog(Map<String, dynamic> entryData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Entry Registered!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.entryType} has been registered successfully.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Name:', entryData['name']),
                    _buildDetailRow('Phone:', entryData['phone']),
                    _buildDetailRow('Flat:', entryData['flat']),
                    if (widget.enteredCode != null)
                      _buildDetailRow('Entry Code:', widget.enteredCode!),
                    _buildDetailRow(
                      'Time:',
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Center(
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.entryType,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isDataPrefilled)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.verified,
                color: const Color(0xFF10B981),
                size: 24,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: _refreshUnits,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrefilledDataNotice(),
                  ..._getFormFields(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildSubmitButton() {
  return AbsorbPointer(
    absorbing: _isSubmitting, // Blocks all touch events when submitting
    child: Opacity(
      opacity: _isSubmitting ? 0.6 : 1.0,
      child: Container(
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
            onTap: _submitForm,
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isDataPrefilled ? 'Confirm Entry' : 'Register Entry',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
}