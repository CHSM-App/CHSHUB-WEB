import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/facilitySlot.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class SelectAmenityScreen extends ConsumerStatefulWidget {
  const SelectAmenityScreen({super.key});

  @override
  ConsumerState<SelectAmenityScreen> createState() =>
      _SelectAmenityScreenState();
}

class _SelectAmenityScreenState extends ConsumerState<SelectAmenityScreen> {
  final bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(
      () => ref
          .read(facilitiesViewModelProvider.notifier)
          .loadFacilities(ref.watch(basicInfoViewModelProvider).societyID ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amenitiesState = ref.watch(facilitiesViewModelProvider).facilities;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Available Amenities',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: amenitiesState.when(
        data: (amenities) {
          // Check if amenities list is empty
          if (amenities.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: _buildEmptyState(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: amenities.length,
                itemBuilder: (context, index) {
                  final amenity = amenities[index];
                  return _buildAmenityCard(context, amenity);
                },
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, _) => ErrorStatePage(
          error: err,
          onRetry: _loadData,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.apartment,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Facilities Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'There are no amenities available\nat the moment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
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

  Widget _buildAmenityCard(BuildContext context, dynamic amenity) {
    String bookingTypeText = '';
    String priceText = '';
    Color badgeColor = Colors.grey.shade200;
    Color badgeTextColor = Colors.black87;

    // Map slot to booking type
    switch (amenity.slot) {
      case 1: // Per Day
        bookingTypeText = 'Daily';
        priceText = amenity.cost == 0 ? 'Free' : '₹${amenity.cost}/day';
        badgeColor = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFF92400E);
        break;
      case 2: // Hourly
        bookingTypeText = 'Hourly';
        priceText = amenity.cost == 0 ? 'Free' : '₹${amenity.cost}/hr';
        badgeColor = const Color(0xFFDCF2FF);
        badgeTextColor = const Color(0xFF0369A1);
        break;
      case 3: // Slot Based
        bookingTypeText = 'Slot Based';
        priceText = 'From ₹${amenity.cost ?? 0}';
        badgeColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        break;
      default:
        bookingTypeText = 'Other';
        priceText = amenity.cost == 0 ? 'Free' : '₹${amenity.cost}';
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Facilityslot(
              facilityId: amenity.facilityId ?? 0,
              slot: amenity.slot ?? 0,
              cost: amenity.cost ?? 0,
              name: amenity.name ?? 'Unknown Amenity',
              bookingTypeText: '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with fixed height
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.home_repair_service,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
            ),
            // Content container with flexible sizing
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      '${amenity.name?[0].toUpperCase()}${amenity.name?.substring(1) ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Description
                    Text(
                      amenity.description ?? 'No description',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Badge and price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bookingTypeText,
                              style: TextStyle(
                                fontSize: 8,
                                color: badgeTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            priceText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}