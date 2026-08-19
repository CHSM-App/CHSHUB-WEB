import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/product_sell.dart';
import '../../presentation/providers/viewmodel_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});
 
  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();

    _titleCtrl.addListener(_onPreviewFieldChanged);
    _descCtrl.addListener(_onPreviewFieldChanged);
    _priceCtrl.addListener(_onPreviewFieldChanged);
  }

  void _onPreviewFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _titleCtrl.removeListener(_onPreviewFieldChanged);
    _descCtrl.removeListener(_onPreviewFieldChanged);
    _priceCtrl.removeListener(_onPreviewFieldChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _contactCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

void _submit() async {
  final isValid = _formKey.currentState?.validate() ?? false;
  if (!isValid) return;

  // ✅ Step 0: Require at least one image
  if (_images.isEmpty) {
    _showSnackBar("Please add at least one image before submitting.", isError: true);
    return;
  }

  final product = ProductSell(
    availableQuantity: _qtyCtrl.text.trim(),
    description: _descCtrl.text.trim(),
    price: _priceCtrl.text.trim(),
    productId: 0,
    imagePath: null,
    productName: _titleCtrl.text.trim(),
    societyId: ref.watch(basicInfoViewModelProvider).societyID,
    status: "Available",
    warranty: null,
    oId: ref.watch(basicInfoViewModelProvider).ownerId,
    contactNo: _contactCtrl.text.trim(),
    ownerName: ref.watch(basicInfoViewModelProvider).name,
    postedDate: DateTime.now().toIso8601String(),
    availability: 1,
    type: ref.watch(basicInfoViewModelProvider).loginType,
  );

  try {
    // Step 1: Upload product info first
    await ref.read(productViewModelProvider.notifier).addProduct(product);
    final state = ref.read(productViewModelProvider);

    if (state.error != null) {
      _showSnackBar("Error: ${state.error}", isError: true);
      return;
    }

    // Step 2: Get created product ID
    debugPrint("ℹ️ addProduct response: ${state.data}");
    final rawProductId = state.data?["product_id"];
    final productId = rawProductId is int
        ? rawProductId
        : int.tryParse(rawProductId?.toString() ?? '');
    bool anyImageSuccess = false;

    // Step 3: Upload all images (since at least one exists)
    if (productId != null) {
      for (var image in _images) {
        try {
          await ref
              .read(productViewModelProvider.notifier)
              .addProductImages(File(image.path), productId);
          anyImageSuccess = true;
        } catch (e) {
          debugPrint("❌ Failed to upload image: ${image.path}, error: $e");
        }
      }
    } else {
      debugPrint("❌ Could not resolve product_id from response: ${state.data}");
    }

    // Step 4: Result
    if (anyImageSuccess) {
      _showSnackBar("✅ Product uploaded successfully!");
      _resetForm();

      // ✅ Step 5: Redirect & refresh product list
      Navigator.pop(context, true); // Pop current page and refresh previous list
    } else {
      _showSnackBar("⚠️ Failed to upload images. Please try again.", isError: true);
    }
  } catch (e) {
    debugPrint("❌ Product upload failed: $e");
    _showSnackBar("Failed to upload product", isError: true);
  }
}


  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _images.clear();
      _titleCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _contactCtrl.clear();
      _qtyCtrl.clear();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() => _images.add(picked));
      }
    } catch (e) {
      _showSnackBar("Failed to pick image", isError: true);
    }
  }

  void _showImageSourceSheet() {
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
              _buildImageSourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              _buildImageSourceOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a Photo',
                subtitle: 'Use camera to capture',
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A5FBF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF4A5FBF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }
  Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  int maxLines = 1,
  int? minLines,
  String? prefixText,
  List<TextInputFormatter>? inputFormatters, // <-- added here
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      validator: validator,
      inputFormatters: inputFormatters, // <-- pass it to TextFormField
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A5FBF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF4A5FBF)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4A5FBF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    ),
  );
}


  // Widget _buildModernTextField({
  //   required TextEditingController controller,
  //   required String label,
  //   required String hint,
  //   required IconData icon,
  //   String? Function(String?)? validator,
  //   TextInputType? keyboardType,
  //   int maxLines = 1,
  //   int? minLines,
  //   String? prefixText,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 20),
  //     child: TextFormField(
  //       controller: controller,
  //       keyboardType: keyboardType,
  //       maxLines: maxLines,
  //       minLines: minLines,
  //       validator: validator,
  //       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //       decoration: InputDecoration(
  //         labelText: label,
  //         hintText: hint,
  //         prefixText: prefixText,
  //         prefixIcon: Container(
  //           margin: const EdgeInsets.all(12),
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF4A5FBF).withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(icon, size: 20, color: const Color(0xFF4A5FBF)),
  //         ),
  //         filled: true,
  //         fillColor: Colors.grey.shade50,
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(16),
  //           borderSide: BorderSide.none,
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(16),
  //           borderSide: const BorderSide(color: Color(0xFF4A5FBF), width: 2),
  //         ),
  //         errorBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(16),
  //           borderSide: const BorderSide(color: Colors.red, width: 1),
  //         ),
  //         focusedErrorBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(16),
  //           borderSide: const BorderSide(color: Colors.red, width: 2),
  //         ),
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 16,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildImagePickerSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5FBF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Color(0xFF4A5FBF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Product Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3B62),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add up to 5 high-quality images',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: _images.isEmpty
                ? _buildEmptyImageState()
                : _buildImagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyImageState() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade50,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: Color(0xFF4A5FBF),
              ),
              SizedBox(height: 12),
              Text(
                'Tap to add images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A5FBF),
                ),
              ),
              Text(
                'JPG, PNG up to 10MB',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _images.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (ctx, idx) {
        if (idx == _images.length) {
          return GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                color: Colors.grey.shade50,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 32, color: Color(0xFF4A5FBF)),
                    SizedBox(height: 4),
                    Text(
                      'Add More',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A5FBF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final XFile file = _images[idx];
        return _buildImageItem(file, idx);
      },
    );
  }

  Widget _buildImageItem(XFile file, int index) {
    return Stack(
      children: [
        Container(
          width: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb
                ? FutureBuilder<Uint8List>(
                    future: file.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          width: 140,
                          height: 140,
                        );
                      }
                      return Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  )
                : Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    width: 140,
                    height: 140,
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A5FBF).withOpacity(0.05),
            const Color(0xFF4A5FBF).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A5FBF).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5FBF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.preview_outlined,
                  color: Color(0xFF4A5FBF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3B62),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                child: _images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: _images.first.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Icon(Icons.image, size: 32);
                                },
                              )
                            : Image.file(
                                File(_images.first.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCtrl.text.isEmpty
                          ? 'Product title will appear here'
                          : _titleCtrl.text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _titleCtrl.text.isEmpty
                            ? Colors.grey.shade500
                            : const Color(0xFF2E3B62),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _descCtrl.text.isEmpty
                          ? 'Product description preview...'
                          : (_descCtrl.text.length > 60
                                ? '${_descCtrl.text.substring(0, 60)}...'
                                : _descCtrl.text),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _priceCtrl.text.isEmpty
                            ? '₹ 0.00'
                            : '₹ ${_priceCtrl.text}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addProductState = ref.watch(productViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A5FBF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePickerSection(),

                  _buildModernTextField(
                    controller: _titleCtrl,
                    label: 'Product Title',
                    hint: 'Enter product name',
                    icon: Icons.shopping_bag_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter product title'
                        : null,
                  ),

                  _buildModernTextField(
                    controller: _descCtrl,
                    label: 'Description',
                    hint: 'Describe your product in detail',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                    minLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter description'
                        : null,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _qtyCtrl,
                          label: 'Quantity',
                          hint: 'Available qty',
                          icon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter quantity'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _priceCtrl,
                          label: 'Price',
                          hint: '0.00',
                          icon: Icons.currency_rupee,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixText: '₹ ',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter price';
                            }
                            final p = double.tryParse(v.trim());
                            if (p == null || p <= 0) return 'Enter valid price';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  // _buildModernTextField(
                  //   controller: _contactCtrl,
                  //   label: 'Contact Information',
                  //   hint: 'Phone number ',
                  //   icon: Icons.contact_phone_outlined,
                  //   keyboardType: TextInputType.phone,
                  //   validator: (v) => (v == null || v.trim().isEmpty)
                  //       ? 'Please enter contact information'
                  //       : null,
                  // ),
_buildModernTextField(
  controller: _contactCtrl,
  label: 'Contact Information',
  hint: 'Phone number',
  icon: Icons.contact_phone_outlined,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly, // Only digits
    LengthLimitingTextInputFormatter(10),  // Max 10 digits
  ],
  validator: (v) => (v == null || v.trim().isEmpty)
      ? 'Please enter contact information'
      : (v.trim().length != 10 ? 'Enter a valid 10-digit number' : null),
),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.refresh_outlined),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: addProductState.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A5FBF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF4A5FBF,
                            ).withOpacity(0.3),
                          ),
                          child: addProductState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.publish_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Publish Product',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),

                  _buildPreviewCard(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
