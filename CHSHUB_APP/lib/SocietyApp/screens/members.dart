import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/domain/models/directory.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen>
    with TickerProviderStateMixin {
  // Tabs
  static const List<String> _tabs = ['Residents', 'Committee', 'Emergency'];
  static const Color _backgroundColor = Color(0xFFF6F6F6);
  static const Color _appBarColor = Color(0xFFF1F4F7);
  static const Color _selectorColor = Color(0xFFEFEFEF);

  int _selectedTabIndex = 0;
  late final PageController _pageController;
  
  // Animation controllers for fade and slide
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);

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

    // Wait until the first frame is built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final basicInfo = ref.read(basicInfoViewModelProvider);
      final societyId = basicInfo.societyID ?? '';

      // Only load if societyId is valid
      if (societyId.isNotEmpty) {
        _loadTabData();
      } else {
        // Wait for basicInfo to be updated and then load
        ref.listen(basicInfoViewModelProvider, (previous, next) {
          if (next.societyID != null && next.societyID!.isNotEmpty) {
            _loadTabData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadTabData() {
    final basicInfo = ref.read(basicInfoViewModelProvider);
    final societyId = basicInfo.societyID ?? '';
    final directoryNotifier = ref.read(directoryViewModelProvider.notifier);

    // Reset and start animations
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();

    switch (_selectedTabIndex) {
      case 0:
        directoryNotifier.loadNeighbours(societyId);
        break;
      case 1:
        directoryNotifier.loadCommitteeMembers(societyId);
        break;
      case 2:
        directoryNotifier.loadEmergencyContacts();
        break;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarColor,
      elevation: 0,
      title: const Text('Society Directory',
          style: TextStyle(color: Colors.black)),
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
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: _selectedTabIndex * segmentWidth,
                  top: 0,
                  width: segmentWidth,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = index == _selectedTabIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.black : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            child: Text(_tabs[index]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        _buildResidentsTab(),
        _buildCommitteeTab(),
        _buildEmergencyTab(),
      ],
    );
  }

  Widget _buildResidentsTab() {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(directoryViewModelProvider).neighbours;
      return state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
       // error: (err, _) => _buildErrorState(err.toString()),
         error: (err, _) => ErrorStatePage(error: err, onRetry: _loadTabData),
        data: (residents) => RefreshIndicator(
          onRefresh: () async => _loadTabData(),
          child: _buildDirectoryList(
            residents,
            color1: const Color(0xFF673AB7),
            color2: const Color(0xFF9FA8DA),
          ),
        ),
      );
    });
  }

  Widget _buildCommitteeTab() {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(directoryViewModelProvider).committeeMembers;
      return state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
         error: (err, _) => ErrorStatePage(error: err, onRetry: _loadTabData),
        data: (committee) => RefreshIndicator(
          onRefresh: () async => _loadTabData(),
          child: _buildDirectoryList(
            committee,
            color1: const Color(0xFF1E88E5),
            color2: const Color(0xFF64B5F6),
          ),
        ),
      );
    });
  }

  Widget _buildEmergencyTab() {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(directoryViewModelProvider).emergencyContacts;
      return state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStatePage(error: err, onRetry: _loadTabData),
        data: (emergency) => RefreshIndicator(
          onRefresh: () async => _loadTabData(),
          child: _buildDirectoryList(
            emergency,
            color1: const Color(0xFFE53935),
            color2: const Color(0xFFEF9A9A),
          ),
        ),
      );
    });
  }

  Widget _buildDirectoryList(List<Directory> list,
      {required Color color1, required Color color2}) {
    if (list.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(child: Text('No members found')),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 800 + (index * 100)),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: DirectoryCard(
                    item: item,
                    color1: color1,
                    color2: color2,
                    onCall: () => _makeCall(item.contact),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Build error state with retry button
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Call the API again based on current tab
                _loadTabData();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
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
    );
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
}

// Separate card widget with tap animation
class DirectoryCard extends StatefulWidget {
  final Directory item;
  final Color color1;
  final Color color2;
  final VoidCallback onCall;

  const DirectoryCard({
    super.key,
    required this.item,
    required this.color1,
    required this.color2,
    required this.onCall,
  });

  @override
  State<DirectoryCard> createState() => _DirectoryCardState();
}

class _DirectoryCardState extends State<DirectoryCard>
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 15),
          child: Card(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF8F9FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.color1, widget.color2],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.home,
                                size: 16, color: Color(0xFF6C757D)),
                            const SizedBox(width: 5),
                            Text(
                              widget.item.unit ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF6C757D)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 16, color: Color(0xFF6C757D)),
                            const SizedBox(width: 5),
                            Text(
                              widget.item.contact ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF6C757D)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onCall();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.call, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}