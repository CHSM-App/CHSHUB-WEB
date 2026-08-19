import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/full_screen_gallery.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

import '../../domain/models/product_sell.dart';
 // <-- Import where FullScreenGallery is defined

class EditProductScreen extends ConsumerStatefulWidget {
  final int productID;

  const EditProductScreen({super.key, required this.productID});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  late PageController _pageController;
  int _selectedImage = 0;

  @override
  void initState() {
    super.initState();
   
    
    _pageController = PageController();
     _loadData();
  }

Future<void> _loadData() async {
   WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productViewModelProvider.notifier).viewProduct(widget.productID);
    });
}
  @override
  void dispose() {
   
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }
void _submit() async {
  final isValid = _formKey.currentState?.validate() ?? false;
  if (!isValid) return;

   final product = ProductSell(
    availableQuantity: _qtyCtrl.text.trim(),
    description: _descCtrl.text.trim(),
    price: _priceCtrl.text.trim(),
    productId: widget.productID, // Or your backend ID logic
    imagePath: null, // Will be handled in image upload logic
    productName: _titleCtrl.text.trim(),
    societyId: ref.watch(basicInfoViewModelProvider).societyID, // Example society ID
    status: "Available",
    warranty: null,
    oId: ref.watch(basicInfoViewModelProvider).ownerId, // Owner ID from logged-in user
    contactNo: _contactCtrl.text.trim(),
    ownerName: ref.watch(basicInfoViewModelProvider).name, // From logged-in user
    postedDate: DateTime.now().toIso8601String(),
    availability: 1,
  );
  final notifier = await ref.read(productViewModelProvider.notifier).updateProduct(product);

  

 final state = ref.read(productViewModelProvider);
  if (state.error != null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessageMapper.map(state.error!))),
      );
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product updated successfully")),
      );
      Navigator.pop(context); // Go back after successful submission
    }
  }
 

}
  @override
  Widget build(BuildContext context) {
     final productState = ref.watch(productViewModelProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text("Product Details")),
      body: productState.viewProductDetails?.when(
            data: (product1) {
              final product = product1.isNotEmpty ? product1.first : null;
              final List<String> images = (product?.imagePath ?? "")
    .split(",")
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();
if (product != null) {
      _titleCtrl.text = product.productName ?? "";
      _descCtrl.text = product.description ?? "";
      _priceCtrl.text = product.price?.toString() ?? "";
      _contactCtrl.text = product.contactNo ?? "";
      _qtyCtrl.text=product.availableQuantity??"";
    }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Image Carousel ----------
            SizedBox(
              height: 300,
              child: images.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                      ),
                      child: const Center(
                        child: Icon(Icons.image,
                            size: 80, color: Colors.grey),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) =>
                            setState(() => _selectedImage = index),
                        itemCount: images.length,
                        itemBuilder: (context, idx) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenGallery(
                                    images: images,
                                    initialIndex: idx,
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              images[idx],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 10),

            // ---------- Thumbnails ----------
            if (images.length > 1)
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, idx) {
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          idx,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _selectedImage = idx);

                        // open gallery on thumbnail tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenGallery(
                              images: images,
                              initialIndex: idx,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.network(
                              images[idx],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                            if (_selectedImage == idx)
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(labelText: 'Product title', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product title' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descCtrl,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                        ),
                        const SizedBox(height: 12),
                       
                        TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Quantity' : null,
                        ),
                         const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(prefixText: '₹ ', labelText: 'Price', border: OutlineInputBorder()),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter price';
                            final p = double.tryParse(v.trim());
                            if (p == null || p <= 0) return 'Enter valid price';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contactCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Contact (phone/email)', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter contact' : null,
                        ),
                        const SizedBox(height: 18),

                        // Action buttons
                        Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 5,
        ),
        onPressed: productState.isLoading ? null : _submit,
        icon: productState.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.cloud_upload, color: Colors.white),
        label: productState.isLoading
            ? const Text(
                "Updating...",
                style: TextStyle(color: Colors.white),
              )
            : const Text(
                "Update Product Details",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    ),
  ],
),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ],
        )
      );
            },
    loading: () =>
                const Center(child: CircularProgressIndicator()),
             error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
          ) ??
          const Center(child: CircularProgressIndicator()), // fallback
    );
  }
}