import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/full_screen_gallery.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewProductScreen extends ConsumerStatefulWidget {
  final int productID;

  const ViewProductScreen({super.key, required this.productID});

  @override
  ConsumerState<ViewProductScreen> createState() => _ViewProductScreenState();
}

class _ViewProductScreenState extends ConsumerState<ViewProductScreen> {
  late PageController _pageController;
  int _selectedImage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // fetch product when screen opens
  _loadData();
  }
Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productViewModelProvider.notifier).viewProduct(widget.productID);
    });
}
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _callSeller(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact number not available")),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open dialer")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Product Details")),
      body: state.viewProductDetails?.when(
            data: (product1) {
              final product = product1.isNotEmpty ? product1.first : null;
              final List<String> images = (product?.imagePath ?? "")
    .split(",")
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Image Carousel
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
                                          const Icon(Icons.broken_image,
                                              size: 50),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),

                    const SizedBox(height: 10),

                    // Thumbnail strip
                    if (images.length > 1)
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (ctx, idx) {
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() => _selectedImage = idx);
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
                                          borderRadius:
                                              BorderRadius.circular(8),
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

                    // Product details
                    Text(
                      product?.productName ?? "",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₹ ${product?.price ?? 0}",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text("Description",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(product?.description ?? "No description available"),

                    const SizedBox(height: 20),
                  

                    const Text("Quantity",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(product?.availableQuantity  ?? "Not provided"),
                  const SizedBox(height: 20),
                    const Text("Contact Info",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(product?.contactNo  ?? "Not provided"),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _callSeller(product?.contactNo),
                        icon: const Icon(Icons.call),
                        label: const Text("Contact Seller"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
