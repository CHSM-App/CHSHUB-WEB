import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/apptheme.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/helper_reviews.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/helper.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({super.key});

  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerOpacityAnimation;
  late Animation<double> _headerScaleAnimation;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerOpacityAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _headerScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scrollController = ScrollController()..addListener(_onScroll);
    _animationController.forward();

   _loadData();
  }

  void _onScroll() {
    const double threshold = 150.0;
    final double offset = _scrollController.offset;
    final double progress = (offset / threshold).clamp(0.0, 1.0);

    setState(() {
      _scrollProgress = progress;
    });

    _headerAnimationController.animateTo(progress);
  }
Future<void> _loadData() async {
   Future.microtask(
      () => ref
          .read(HelperViewModelProvider.notifier)
          .getHelperList(ref.watch(basicInfoViewModelProvider).societyID ?? ''),
    );
}
  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final Map<String, Map<String, dynamic>> categoryConfigs = {
    'Plumber': {'icon': Icons.plumbing, 'color': ServiceColors.plumber},
    'Milk Supplier': {
      'icon': Icons.local_drink,
      'color': ServiceColors.milkSupplier,
    },
    'Maid': {'icon': Icons.cleaning_services, 'color': ServiceColors.maid},
    'TV Cable': {'icon': Icons.tv, 'color': ServiceColors.tvCable},
    'Building Cleaner': {
      'icon': Icons.apartment,
      'color': ServiceColors.buildingCleaner,
    },
    'Electrician': {
      'icon': Icons.electrical_services,
      'color': ServiceColors.electrician,
    },
    'Committee Members': {
      'icon': Icons.people,
      'color': ServiceColors.commiteeMember,
    },
    'Mechanic': {'icon': Icons.build, 'color': const Color(0xFF795548)},
    'Carpenter': {'icon': Icons.carpenter, 'color': const Color(0xFF8BC34A)},
    'painting': {'icon': Icons.format_paint, 'color': const Color(0xFFFF5722)},
    'packer': {'icon': Icons.inventory, 'color': const Color(0xFF009688)},
    'beauty': {'icon': Icons.face, 'color': const Color(0xFFE91E63)},
  };

  Map<String, dynamic> _createServiceCategory(
    String categoryName,
    List<Helper> providers,
  ) {
    final config = categoryConfigs[categoryName] ??
        {'icon': Icons.miscellaneous_services, 'color': Colors.grey};

    return {
      'name': categoryName,
      'icon': config['icon'] as IconData,
      'color': config['color'] as Color,
      'providers': providers,
    };
  }

  List<Map<String, dynamic>> _buildServiceCategories(List<Helper> helpers) {
    final Map<String, List<Helper>> groupedProviders = {};

    for (var helper in helpers) {
      final type = helper.pTypeName ?? 'Unknown';
      if (!groupedProviders.containsKey(type)) {
        groupedProviders[type] = [];
      }
      groupedProviders[type]!.add(helper);
    }

    return groupedProviders.entries.map((entry) {
      return _createServiceCategory(entry.key, entry.value);
    }).toList();
  }

  Map<String, dynamic> _getGridParameters(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 0.95,
        'crossAxisSpacing': 12.0,
        'mainAxisSpacing': 12.0,
        'padding': 16.0,
      };
    } else if (screenWidth < 900) {
      return {
        'crossAxisCount': 3,
        'childAspectRatio': 1.0,
        'crossAxisSpacing': 16.0,
        'mainAxisSpacing': 16.0,
        'padding': 20.0,
      };
    } else {
      return {
        'crossAxisCount': 4,
        'childAspectRatio': 1.1,
        'crossAxisSpacing': 20.0,
        'mainAxisSpacing': 20.0,
        'padding': 24.0,
      };
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1024;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1024;
    final isMobile = screenSize.width < 600;

    final iconSize = isDesktop ? 120.0 : (isTablet ? 100.0 : 80.0);
    final titleSize = isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);
    final subtitleSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final buttonPadding = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 24 : 32),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: iconSize,
                        color: Colors.indigo.withOpacity(0.4),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: isMobile ? 24 : 32),

              // Title
              Text(
                'No Services Available',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E3B62),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isMobile ? 12 : 16),

              // Subtitle
              Text(
                'There are currently no service providers\navailable in your community.',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isMobile ? 32 : 40),

              // Refresh Button
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(HelperViewModelProvider.notifier)
                    .getHelperList(
                      ref.read(basicInfoViewModelProvider).societyID ?? '',
                    ),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPadding * 1.5,
                    vertical: buttonPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(HelperViewModelProvider);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1024;

    final headerHeight = _getResponsiveHeaderHeight(context);
    final topMargin = _getResponsiveTopMargin(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, const Color(0xFF3B4A73), Colors.grey[50]!],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _headerAnimationController,
                  builder: (context, child) {
                    return SizedBox(
                      height: headerHeight - (_scrollProgress * (headerHeight * 0.4)),
                      child: Transform.scale(
                        scale: _headerScaleAnimation.value,
                        child: Opacity(
                          opacity: _headerOpacityAnimation.value,
                          child: _buildHeader(context),
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      top: topMargin - (_scrollProgress * (topMargin * 0.5)),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isDesktop ? 40 : 30),
                        topRight: Radius.circular(isDesktop ? 40 : 30),
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: () => ref
                          .read(HelperViewModelProvider.notifier)
                          .getHelperList(
                            ref.watch(basicInfoViewModelProvider).societyID ?? '',
                          ),
                      child: serviceState.helpers.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => ErrorStatePage(
                          error: error,
                          onRetry: () => ref
                              .read(HelperViewModelProvider.notifier)
                              .getHelperList(
                                ref.read(basicInfoViewModelProvider).societyID ?? '',
                              ),
                        ),
                        data: (helpers) {
                          final serviceCategories = _buildServiceCategories(helpers);
                          
                          // Check if there are no services
                          if (serviceCategories.isEmpty) {
                            return _buildEmptyState(context);
                          }
                          
                          return _buildServiceGrid(serviceCategories);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getResponsiveHeaderHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 80;
    if (screenWidth < 1024) return 140;
    return 160;
  }

  double _getResponsiveTopMargin(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 15;
    if (screenWidth < 1024) return 20;
    return 25;
  }

  Widget _buildHeader(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 200;

    // Responsive base values
    final basePadding = isDesktop ? 32.0 : (isTablet ? 28.0 : 12.0);
    final baseIconSize = isDesktop ? 36.0 : (isTablet ? 32.0 : 22.0);
    final baseTitleSize = isDesktop ? 32.0 : (isTablet ? 28.0 : 18.0);
    final baseSubtitleSize = isDesktop ? 18.0 : (isTablet ? 16.0 : 12.0);
    final baseIconPadding = isDesktop ? 16.0 : (isTablet ? 14.0 : 8.0);
    final baseSpacing = isDesktop ? 20.0 : (isTablet ? 16.0 : 8.0);

    // Dynamic values based on scroll
    final dynamicPadding = basePadding * (1 - _scrollProgress * 0.4);
    final dynamicIconSize = baseIconSize * (1 - _scrollProgress * 0.3);
    final dynamicTitleSize = baseTitleSize * (1 - _scrollProgress * 0.25);
    final dynamicSubtitleSize = baseSubtitleSize * (1 - _scrollProgress * 0.2);
    final dynamicIconPadding = baseIconPadding * (1 - _scrollProgress * 0.3);
    final dynamicSpacing = baseSpacing * (1 - _scrollProgress * 0.2);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dynamicPadding,
          vertical: isMobile ? 8.0 : dynamicPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Back Button
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: dynamicIconSize,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(HelperViewModelProvider.notifier).getHelperList(
                          ref.watch(basicInfoViewModelProvider).societyID ?? '',
                        );
                  },
                ),

                SizedBox(width: dynamicSpacing * 0.5),

                // Service Icon
                Container(
                  padding: EdgeInsets.all(dynamicIconPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  ),
                  child: Icon(
                    Icons.home_repair_service,
                    color: Colors.white,
                    size: dynamicIconSize,
                  ),
                ),

                SizedBox(width: dynamicSpacing),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMobile ? 'Services' : 'Community Services',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dynamicTitleSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_scrollProgress < 0.6 && !isMobile)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Find trusted providers',
                            style: TextStyle(
                              color: Colors.white.withOpacity(
                                0.8 * (1 - _scrollProgress * 0.7),
                              ),
                              fontSize: dynamicSubtitleSize,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // Search icon for tablet/desktop
                if (isTablet || isDesktop)
                  Container(
                    padding: EdgeInsets.all(dynamicIconPadding * 0.8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.8),
                      size: dynamicIconSize * 0.8,
                    ),
                  ),
              ],
            ),

            // Breadcrumb for desktop
            if (isDesktop && _scrollProgress < 0.5)
              Padding(
                padding: EdgeInsets.only(top: dynamicSpacing * 0.8),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Community Hub',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildServiceGrid(List<Map<String, dynamic>> serviceCategories) {
    final gridParams = _getGridParameters(context);

    return Padding(
      padding: EdgeInsets.all(gridParams['padding']),
      child: GridView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridParams['crossAxisCount'],
          crossAxisSpacing: gridParams['crossAxisSpacing'],
          mainAxisSpacing: gridParams['mainAxisSpacing'],
          childAspectRatio: gridParams['childAspectRatio'],
        ),
        itemCount: serviceCategories.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(serviceCategories[index], index);
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> category, int index) {
    final String name = category['name'];
    final IconData icon = category['icon'];
    final Color color = category['color'];
    final List<Helper> providers = category['providers'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Responsive font sizes
    final titleFontSize = isMobile ? 13.0 : (screenWidth < 900 ? 14.0 : 16.0);
    final subtitleFontSize = isMobile ? 11.0 : 12.0;
    final iconSize = isMobile ? 26.0 : (screenWidth < 900 ? 28.0 : 32.0);
    final cardPadding = isMobile ? 12.0 : (screenWidth < 900 ? 16.0 : 20.0);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceProvidersListPage(
                    categoryName: name,
                    categoryIcon: icon,
                    categoryColor: color,
                    helpers: providers,
                    onProvidersUpdated: () => setState(() {}),
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Container
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                      ),
                      child: Icon(icon, size: iconSize, color: color),
                    ),

                    SizedBox(height: isMobile ? 8 : 12),

                    // Category Name
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E3B62),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: isMobile ? 3 : 4),

                    // Provider Count
                    Text(
                      '${providers.length} provider${providers.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.grey[600],
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}




//------------------------------  Service Provider List Details --------------------------------------------//


class ServiceProvidersListPage extends ConsumerStatefulWidget {
  final String categoryName;
  final List<Helper> helpers;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback? onProvidersUpdated;

  const ServiceProvidersListPage({
    super.key,
    required this.categoryName,
    required this.helpers,
    required this.categoryColor,
    required this.categoryIcon,
    this.onProvidersUpdated,
  });

  @override
  ConsumerState<ServiceProvidersListPage> createState() =>
      _ServiceProvidersListPageState();
}

class _ServiceProvidersListPageState
    extends ConsumerState<ServiceProvidersListPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
   
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make call to $phone'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not make the call. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  

  //------------Service Provider List Review Click Review Bottom Sheet Open----------------------//
  void _showReviews(Helper helper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewsBottomSheet(
        helper: helper,
        categoryColor: widget.categoryColor,
        onUpdated: () {
          widget.onProvidersUpdated?.call();
        },
      ),
    );
  }

  // Live helpers for this category, refreshed as soon as the provider
  // refetches (e.g. right after a review is added), instead of relying on
  // the static snapshot passed in via widget.helpers.
  List<Helper> _liveHelpers() {
    final helperState = ref.watch(HelperViewModelProvider);
    // displayHelpers() applies any pending optimistic review-count
    // overrides on top of the latest known list (falling back to
    // widget.helpers only if nothing has loaded yet), so this can never
    // regress to a stale count during a background refresh.
    return helperState
        .displayHelpers(widget.helpers)
        .where((h) => (h.pTypeName ?? 'Unknown') == widget.categoryName)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final helpers = _liveHelpers();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.categoryColor,
              widget.categoryColor.withOpacity(0.8),
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(helpers),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildProvidersList(helpers),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<Helper> helpers) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.categoryIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${helpers.length} providers available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersList(List<Helper> helpers) {
    if (helpers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No providers available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: helpers.length,
      itemBuilder: (context, index) {
        final helper = helpers[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey(
            '${helper.usefullContactId}_${helper.reviewCount}_${helper.avgRating}',
          ),
          duration: Duration(milliseconds: 800 + (index * 100)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _buildProviderCard(helper, index),
            );
          },
        );
      },
    );
  }

  Widget _buildProviderCard(Helper helper, int index) {
    final name = helper.pName ?? 'Unknown';
    final type = helper.orgname ?? 'Unknown';
    final rating = helper.avgRating ?? 0.0;
    final reviewCount = helper.reviewCount ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderDetailsPage(
              helper: helper,
              categoryColor: widget.categoryColor,
              onUpdated: () {
                setState(() {});
                widget.onProvidersUpdated?.call();
                ref
                    .read(HelperViewModelProvider.notifier)
                    .getHelperList(
                      ref.watch(basicInfoViewModelProvider).societyID ?? '',
                    );
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.categoryColor.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.categoryIcon,
                    color: widget.categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3B62),
                        ),
                      ),
                      if (type.isNotEmpty)
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (rating > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (helper.contactNo != null && helper.contactNo!.isNotEmpty)
              _buildInfoRow(Icons.phone, helper.contactNo!),
            if (helper.contactaddress != null &&
                helper.contactaddress!.isNotEmpty)
              _buildInfoRow(Icons.location_on, helper.contactaddress!),
            if (helper.unit != null && helper.unit!.isNotEmpty)
              _buildInfoRow(Icons.home, 'Unit: ${helper.unit!}'),
            _buildInfoRow(Icons.reviews, '$reviewCount reviews'),
            const SizedBox(height: 16),
            Row(
              children: [
                if (helper.contactNo != null && helper.contactNo!.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(helper.contactNo!),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.categoryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (helper.contactNo != null && helper.contactNo!.isNotEmpty)
                  const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviews(helper),
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text('Reviews'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.categoryColor,
                      side: BorderSide(color: widget.categoryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

//----------------------------------Service Provider Details---------------------------------------------------------//

class ServiceProviderDetailsPage extends ConsumerStatefulWidget {
  final Helper helper;
  final Color categoryColor;
  final VoidCallback? onUpdated;

  const ServiceProviderDetailsPage({
    super.key,
    required this.helper,
    required this.categoryColor,
    this.onUpdated,
  });

  @override
  ConsumerState<ServiceProviderDetailsPage> createState() =>
      _ServiceProviderDetailsPageState();
}

class _ServiceProviderDetailsPageState
    extends ConsumerState<ServiceProviderDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshHelperData());
  }

  // 🔄 Refresh helper data from API
  Future<void> _refreshHelperData() async {
    await ref
        .read(HelperViewModelProvider.notifier)
        .getHelperWorkDetails(widget.helper.usefullContactId ?? 0, "NA");
    await ref
        .read(HelperViewModelProvider.notifier)
        .helperReview(
          widget.helper.usefullContactId ?? 0,
          widget.helper.pTypeName ?? "helper",
        );
  }

  // 📞 Call helper
  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot make call to $phone'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not make the call. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Assign Helper API
  Future<void> _addHelper(BuildContext context, int helperId) async {
    final ownerDetails = ref.watch(basicInfoViewModelProvider);
    final helperData = Helper(
      helperId: helperId,
      flatId: ownerDetails.flatId,
      societyId: ownerDetails.societyID,
    );

    try {
      await ref
          .read(HelperViewModelProvider.notifier)
          .helperAssignFlat(helperData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Helper successfully assigned to flat!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 🔄 Refresh after success
      await _refreshHelperData();
      widget.onUpdated?.call();
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.map(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
Future<void> _unassignHelper(BuildContext context,int? workId) async {
  final ownerDetails = ref.watch(basicInfoViewModelProvider);

  // 🛑 Validate IDs
  if (workId == null || workId == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid helper work ID.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    debugPrint("🔹 Unassigning helper => workId: $workId");

    // 🔄 Call ViewModel to hit API
    await ref.read(HelperViewModelProvider.notifier).flatunAssign(workId);

    // ✅ Success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Helper unassigned successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // 🔄 Refresh after success
    await _refreshHelperData();
    widget.onUpdated?.call();

    if (mounted) setState(() {});

  } catch (e) {
    // ❌ Error message
    debugPrint("❌ Failed to unassign helper: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorMessageMapper.map(e)),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final ownerDetails = ref.watch(basicInfoViewModelProvider);
    final name = widget.helper.pName ?? 'Unknown';
    final type = widget.helper.orgname ?? 'Unknown';
    final rating = widget.helper.avgRating ?? 0.0;
    final reviewCount = widget.helper.reviewCount ?? 0;
    final pTypeName = widget.helper.pTypeName ?? "";
    final allowedTypes = ['Maid', 'Building Cleaner', 'Milk Supplier'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, name, type),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildReviewCard(),
                  const SizedBox(height: 16),
                  _buildWorkingFlatsCard(),
                  const SizedBox(height: 16),
                  _buildLocationCard(),
                  const SizedBox(height: 16),
//  if (allowedTypes.contains(pTypeName))
//   Consumer(
//     builder: (context, ref, _) {
//       final workState = ref.watch(HelperViewModelProvider);
//       final ownerDetails = ref.watch(basicInfoViewModelProvider);

//       return workState.WorkDetails.when(
//         loading: () => const SizedBox(),
//           error: (err, _) => ErrorStatePage(message: "Failes",onRetry: _refreshHelperData,),
//         data: (units) {
//           if (units.isEmpty) {
//             return AssignButton(context, widget.categoryColor, widget.helper);
//           }

//           // Find current work entry for this flat
//           final currentWork = units.firstWhere(
//             (u) => u.flatId == ownerDetails.flatId,
//           );

//           // ✅ Extract correct workId safely
//           final int validWorkId = currentWork.helperId ??
//               currentWork.workId ??
//               currentWork.helperId ??
//               0;

//           return UnassignButtonWithWorkId(
//             context,
//             widget.categoryColor,
//             widget.helper,
//             validWorkId,
//           );
//         },
//       );
//     },
//   ),

if (allowedTypes.contains(pTypeName))
  Consumer(
    builder: (context, ref, _) {
      final workState = ref.watch(HelperViewModelProvider);
      final ownerDetails = ref.watch(basicInfoViewModelProvider);

      return workState.WorkDetails.when(
        loading: () => const SizedBox(),
        error: (err, _) => ErrorStatePage(
          error: err,
          onRetry: _refreshHelperData,
        ),
        data: (units) {
          if (units.isEmpty) {
            return AssignButton(context, widget.categoryColor, widget.helper);
          }

          // ✅ Use where().firstOrNull pattern (requires collection package)
          final currentWork = units
              .where((u) => u.flatId == ownerDetails.flatId)
              .firstOrNull;

          if (currentWork == null) {
            return AssignButton(context, widget.categoryColor, widget.helper);
          }

          final int validWorkId = currentWork.workId ?? 
              currentWork.helperId ?? 
              0;

          return UnassignButtonWithWorkId(
            context,
            widget.categoryColor,
            widget.helper,
            validWorkId,
          );
        },
      );
    },
  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget UnassignButtonWithWorkId(
  BuildContext context,
  Color categoryColor,
  Helper helper,
  int? workId,
) {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () async {
            debugPrint("🔹 Unassign button pressed, workId: $workId");
            await _unassignHelper(context, workId);
          },
          label: const Text('Unassign Flat'),
          icon: const Icon(Icons.remove_circle_outline),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
  );
}

  // ✅ Assign Button
  Widget AssignButton(
      BuildContext context, Color categoryColor, Helper helper) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await _addHelper(context, helper.usefullContactId ?? 0);
            },
            label: const Text('Assign Flat'),
            icon: const Icon(Icons.add_home),
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Unassign Button
  Widget UnassignButton(
      BuildContext context, Color categoryColor, Helper helper) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await _unassignHelper(context,helper.workId??0);
            },
            label: const Text('Unassign Flat'),
            icon: const Icon(Icons.remove_circle_outline),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔷 Sliver AppBar (unchanged design)
  Widget _buildSliverAppBar(BuildContext context, String name, String type) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: widget.categoryColor,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.categoryColor,
                widget.categoryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child:
                          const Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
  // Watch the helper review details from the provider
  final helperReviewState = ref.watch(HelperViewModelProvider);

  // Compute rating and review count dynamically
  final rating = helperReviewState.helperReviewDetails.when(
    loading: () => 0.0,
    error: (_, __) => 0.0,
    data: (reviews) {
      if (reviews.isEmpty) return 0.0;
      final total = reviews.fold<double>(
        0.0,
        (sum, r) => sum + (r.rating ?? 0.0),
      );
      return total / reviews.length;
    },
  );

  final reviewCount = helperReviewState.helperReviewDetails.when(
    loading: () => 0,
    error: (_, __) => 0,
    data: (reviews) => reviews.length,
  );

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3B62),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.phone, color: widget.categoryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                widget.helper.contactNo ?? 'N/A',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              Text(
                '${rating.toStringAsFixed(1)} rating ($reviewCount reviews)',
                style: const TextStyle(fontSize: 16),
                
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildWorkingFlatsCard() {
    final workState = ref.watch(HelperViewModelProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Working At',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3B62),
              ),
            ),
            const SizedBox(height: 12),
            workState.WorkDetails.when(
              loading: () => const Center(child: CircularProgressIndicator()),
               error: (err, _) => ErrorStatePage(error: err, onRetry: _refreshHelperData),
              data: (units) => units.isEmpty
                  ? Text(
                      'No working flats assigned',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: units.map((unit) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.categoryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.categoryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            unit.unit ?? "Unknown",
                            style: TextStyle(
                              color: widget.categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Society Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3B62),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: widget.categoryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.helper.societyName ?? 'No address provided',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final type = widget.helper.pTypeName ?? '';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _makeCall(widget.helper.contactNo),
            icon: const Icon(Icons.call),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.categoryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showReviewPopup(context),
            icon: const Icon(Icons.rate_review),
            label: const Text('Add Review'),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.categoryColor,
              side: BorderSide(color: widget.categoryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard() {
    final reviewState = ref.watch(HelperViewModelProvider);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3B62),
                  ),
                ),
                Icon(
                  Icons.reviews_outlined,
                  color: widget.categoryColor,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 16),

            reviewState.helperReviewDetails.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              // error: (err, _) => Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.red.shade50,
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(Icons.error_outline, color: Colors.red.shade700),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: Text(
              //           "Error loading reviews",
              //           style: TextStyle(color: Colors.red.shade700),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
                  error: (err, _) => ErrorStatePage(error: err, onRetry: _refreshHelperData),
            
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No reviews yet",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Be the first to leave a review!",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: reviews.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.categoryColor.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.categoryColor.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Name and Rating
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: widget.categoryColor.withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (review.owner ?? "A")
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: widget.categoryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.owner ?? "Anonymous",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Color(0xFF2E3B62),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (i) => Icon(
                                              i < (review.rating?.round() ?? 0)
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color:
                                                  i <
                                                      (review.rating?.round() ??
                                                          0)
                                                  ? Colors.amber.shade600
                                                  : Colors.grey.shade300,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            review.rating?.toStringAsFixed(1) ?? '0.0',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Comment
                            Expanded(
                              child: Text(
                                review.comment ?? "No comment provided.",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Date
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  review.date ?? "",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewPopup(BuildContext context) {
    double rating = 1.0;
    TextEditingController feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Add Rating & Review",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Share your experience to help us improve",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15),

                    // ⭐ Rating with Half
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      glow: true,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 3),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onRatingUpdate: (val) {
                        rating = val;
                      },
                    ),

                    const SizedBox(height: 15),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          99,
                        ), // Limit text length to 100 characters
                      ],
                      decoration: InputDecoration(
                        hintText: "Write your feedback...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),

                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setDialogState(() => isSubmitting = true);

                                  final basicInfo =
                                      ref.watch(basicInfoViewModelProvider);
                                  final ownerIdFromVM = basicInfo.ownerId;
                                  final societyId = basicInfo.societyID;
                                  final loginType = basicInfo.loginType;

                                  int finalOwnerId = 0;
                                  int memberId = 0;

                                  // 2. loginType check
                                  if (loginType?.toLowerCase() == "owner") {
                                    finalOwnerId = ownerIdFromVM ?? 0;
                                  } else {
                                    memberId = ownerIdFromVM ?? 0;
                                  }
                                  final helperReview = Helper(
                                    usefullContactId:
                                        widget.helper.usefullContactId ?? 0,
                                    ownerId: finalOwnerId,
                                    memberId: memberId,
                                    societyId: societyId,
                                    comment: feedbackController.text,
                                    rating: rating,
                                  );

                                  try {
                                    await ref
                                        .read(HelperViewModelProvider.notifier)
                                        .addReview(helperReview);

                                    ref
                                        .read(HelperViewModelProvider.notifier)
                                        .bumpReviewCount(
                                          widget.helper.usefullContactId,
                                        );

                                    if (context.mounted) {
                                      widget.onUpdated
                                          ?.call(); // ✅ Trigger parent refresh
                                      Navigator.pop(context);
                                      await ref
                                          .read(HelperViewModelProvider.notifier)
                                          .getHelperWorkDetails(
                                            widget.helper.usefullContactId ?? 0,
                                            "NA",
                                          );
                                      await ref
                                          .read(HelperViewModelProvider.notifier)
                                          .helperReview(
                                            widget.helper.usefullContactId ?? 0,
                                            widget.helper.pTypeName ?? "helper",
                                          );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      setDialogState(() => isSubmitting = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Network error"),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Submit"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
