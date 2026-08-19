import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/add_product.dart';
import 'package:society_app/SocietyApp/screens/edit_product.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/view_product.dart';
import 'package:society_app/domain/models/product_sell.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen>
    with TickerProviderStateMixin {
  // Constants
  static const List<String> _tabs = ['All Products', 'My Products'];
  static const Color _backgroundColor = Color(0xFFF6F6F6);
  static const Color _appBarColor = Color.fromARGB(255, 241, 244, 247);
  static const Color _selectorColor = Color(0xFFF0F0F0);

  // State variables
  int _selectedTabIndex = 0;
  bool _isRetrying = false;
  late final PageController _pageController;
  
  // Animation controllers for fade and slide
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeController();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _loadInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Initialization methods
  void _initializeController() {
    _pageController = PageController(initialPage: _selectedTabIndex);
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTabData();
    });
  }

  // Data loading methods
  void _loadTabData() {
    final basicInfo = ref.watch(basicInfoViewModelProvider);
    final societyId = basicInfo.societyID;
    final ownerId = basicInfo.ownerId;

    if (societyId == null || ownerId == null) return;

    final productNotifier = ref.read(productViewModelProvider.notifier);

    // Reset and start animations
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();

    if (_selectedTabIndex == 0) {
      // Load all products (excluding current user's products)
      productNotifier.fetchProductList(societyId);
    } else {
      // Load only current user's products
      productNotifier.fetchOwnerProductList(societyId, ownerId);
    }
  }

  // Event handlers
  void _onTabSelected(int index) {
    if (index == _selectedTabIndex) return;
    
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _loadTabData();
  }

  void _onPageChanged(int index) {
    if (index != _selectedTabIndex) {
      setState(() => _selectedTabIndex = index);
      _loadTabData();
    }
  }

  void _onProductCardTap(ProductSell product) {
    final currentOwnerId = ref.watch(basicInfoViewModelProvider).ownerId;
    final isOwnProduct = product.oId == currentOwnerId;

    if (isOwnProduct) {
      // Navigate to edit screen for own products
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProductScreen(productID: product.productId),
        ),
      );
    } else {
      // Navigate to view screen for other users' products
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewProductScreen(productID: product.productId),
        ),
      );
    }
  }

  void _onAddProductPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );

    if (result == true) {
      _loadTabData();
    }
  }
  
  void _onDeleteProduct(ProductSell product) async {
    final notifier = ref.read(productViewModelProvider.notifier);
    await notifier.deleteProduct(product.productId ?? 0);

    final state = ref.read(productViewModelProvider);
    if(state.data?['success'] == true){
      _loadTabData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete product")),
      );
    }
  }

  // Retry handler
  Future<void> _onRetryPressed() async {
    setState(() {
      _isRetrying = true;
    });
    
    _loadTabData();
    
    // Wait a bit to ensure the loading state is visible
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Widget builders
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarColor,
      elevation: 0,
      title: const Text('Products', style: TextStyle(color: Colors.black)),
      iconTheme: const IconThemeData(color: Colors.black),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildTabSelector(),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _selectorColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / _tabs.length;
            return Stack(
              children: [
                _buildSlidingSelector(segmentWidth),
                _buildTabButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlidingSelector(double segmentWidth) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _selectedTabIndex * segmentWidth,
      top: 0,
      width: segmentWidth,
      height: 40,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final isSelected = index == _selectedTabIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => _onTabSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(_tabs[index]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        _buildAllProductsTab(),
        _buildMyProductsTab(),
      ],
    );
  }

  Widget _buildAllProductsTab() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(productViewModelProvider).productListDetails;
        final currentOwnerId = ref.watch(basicInfoViewModelProvider).ownerId;

        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorStatePage(error: err, onRetry: _loadTabData),
          data: (products) {
            // Filter out current user's products for "All Products" tab
            final otherUsersProducts = products
                .where((product) => product.oId != currentOwnerId)
                .toList();

            return RefreshIndicator(
              onRefresh: () async => _loadTabData(),
              child: _buildProductList(
                context,
                otherUsersProducts,
                isMyProductTab: false
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyProductsTab() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(productViewModelProvider).ownerProductListDetails;

        return state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
         error: (err, _) => ErrorStatePage(error: err, onRetry: _loadTabData),
          data: (products) => RefreshIndicator(
            onRefresh: () async => _loadTabData(),
            child: _buildProductList(
              context,
              products,
              isMyProductTab: true
            ),
          ),
        );
      },
    );
  }


  Widget _buildProductList(
    BuildContext context,
    List<ProductSell> products,
    {required bool isMyProductTab}
  ) {
    if (products.isEmpty) {
      return _buildEmptyState(isMyProductTab);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => TweenAnimationBuilder(
            duration: Duration(milliseconds: 800 + (index * 100)),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: _buildProductCard(
                  context,
                  products[index],
                  isMyProductTab: isMyProductTab,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMyProductTab) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isMyProductTab ? 'No products added yet' : 'No products found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isMyProductTab) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first product',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductSell product,
    {required bool isMyProductTab}
  ) {
    return ProductCard(
      product: product,
      isMyProductTab: isMyProductTab,
      onTap: () => _onProductCardTap(product),
      onDelete: () => _showDeleteConfirmation(product),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.blue,
      onPressed: _onAddProductPressed,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // Dialog methods
  void _showDeleteConfirmation(ProductSell product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${product.productName ?? 'this product'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onDeleteProduct(product);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Separate card widget with tap animation
class ProductCard extends StatefulWidget {
  final ProductSell product;
  final bool isMyProductTab;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.isMyProductTab,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(widget.product),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProductInfo(widget.product, widget.isMyProductTab),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(ProductSell product) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageContent(product),
      ),
    );
  }

  Widget _buildImageContent(ProductSell product) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return Image.network(
        product.imagePath ?? "",
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[400],
        size: 40,
      ),
    );
  }

  Widget _buildProductInfo(ProductSell product, bool isMyProductTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductHeader(product, isMyProductTab),
        const SizedBox(height: 8),
        _buildProductDescription(product),
        const SizedBox(height: 12),
        _buildProductFooter(product, isMyProductTab),
      ],
    );
  }

  Widget _buildProductHeader(ProductSell product, bool isMyProductTab) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            product.productName ?? 'Unknown Product',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isMyProductTab) _buildDeleteButton(product),
      ],
    );
  }

  Widget _buildDeleteButton(ProductSell product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: widget.onDelete,
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: const EdgeInsets.all(4),
        tooltip: "Delete Product",
      ),
    );
  }

  Widget _buildProductDescription(ProductSell product) {
    return Text(
      product.description ?? 'No description available',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.4,
      ),
    );
  }

  Widget _buildProductFooter(ProductSell product, bool isMyProductTab) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _buildPriceTag(product)),
        const SizedBox(width: 8),
        _buildActionIndicator(isMyProductTab),
      ],
    );
  }

  Widget _buildPriceTag(ProductSell product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "\₹${product.price ?? '0'}",
        style: const TextStyle(
          fontSize: 16,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildActionIndicator(bool isMyProductTab) {
    final isOwnProduct = isMyProductTab;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwnProduct ? Icons.edit : Icons.visibility,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isOwnProduct ? 'Edit' : 'View',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}