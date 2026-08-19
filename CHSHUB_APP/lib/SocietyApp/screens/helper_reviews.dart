import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';
import 'package:society_app/domain/models/helper.dart';

class ReviewPopupHelper {
  static void showReviewPopup(
    BuildContext context,
    Helper helper,
    Color categoryColor,
    WidgetRef ref, {
    VoidCallback? onReviewAdded,
  }) {
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
                                  await _submitReview(
                                    context,
                                    helper,
                                    ref,
                                    rating,
                                    feedbackController.text,
                                    onReviewAdded,
                                  );
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

  static Future<void> _submitReview(
  BuildContext context,
  Helper helper,
  WidgetRef ref,
  double rating,
  String comment,
  VoidCallback? onReviewAdded,
) async {
  // final basicInfo = ref.watch(basicInfoViewModelProvider);
  // final ownerIdFromVM = basicInfo.ownerId;
  // final societyId = basicInfo.societyID;
  // final loginType = basicInfo.loginType;

  // int finalOwnerId = 0;
  // int memberId = 0;

  // if (loginType == "owner") {
  //   finalOwnerId = ownerIdFromVM ?? 0;
  // } else {
  //   memberId = ownerIdFromVM ?? 0;
  // }

  // final helperReview = Helper(
  //   usefullContactId: helper.usefullContactId ?? 0,
  //   ownerId: finalOwnerId,
  //   memberId: memberId,
  //   societyId: societyId,
  //   comment: comment,
  //   rating: rating,
  // );
   final basicInfo = ref.watch(basicInfoViewModelProvider);
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
                        debugPrint("loginType: $loginType");
                        debugPrint("ownerIdFromVM: $ownerIdFromVM");
                        debugPrint("finalOwnerId: $finalOwnerId");
                        debugPrint("memberId: $memberId");
                        final helperReview = Helper(
                          usefullContactId: helper.usefullContactId ?? 0,
                          ownerId: finalOwnerId,
                          memberId: memberId,
                          societyId: societyId,
                          comment:comment,
                          rating: rating,
                        );


  try {
    // ✅ Add the review first
    await ref.read(HelperViewModelProvider.notifier).addReview(helperReview);

    // ✅ Optimistic UI: bump the count in local state right away so the
    // provider card updates instantly, instead of waiting on the network
    // round-trips below (which may return a stale review_count anyway).
    ref
        .read(HelperViewModelProvider.notifier)
        .bumpReviewCount(helper.usefullContactId);

    // ✅ Also show the new review immediately in the "Reviews (N)" sheet
    // itself, instead of waiting on the background helperReview() refetch.
    ref
        .read(HelperViewModelProvider.notifier)
        .addReviewOptimistically(helperReview);

    // ✅ Notify listeners (bottom sheet / provider list) immediately.
    onReviewAdded?.call();

    // ✅ Reconcile with the backend in the background (review list detail
    // + full helper list), without blocking the "instant" UI update above.
    unawaited(
      ref
          .read(HelperViewModelProvider.notifier)
          .helperReview(
            helper.usefullContactId ?? 0,
            helper.pTypeName ?? "helper",
          ),
    );
    unawaited(
      ref
          .read(HelperViewModelProvider.notifier)
          .getHelperList(basicInfo.societyID ?? ''),
    );

    if (context.mounted) {
      Navigator.pop(context, true); // Close the dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close dialog even on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.map(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
}

class ReviewsBottomSheet extends ConsumerStatefulWidget {
  final Helper helper;
  final Color categoryColor;
  final VoidCallback? onUpdated;

  const ReviewsBottomSheet({
    super.key,
    required this.helper,
    required this.categoryColor,
    this.onUpdated,
  });

  @override
  ConsumerState<ReviewsBottomSheet> createState() => _ReviewsBottomSheetState();
}

class _ReviewsBottomSheetState extends ConsumerState<ReviewsBottomSheet> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  void _loadData(){
Future.microtask(() {
      ref
          .read(HelperViewModelProvider.notifier)
          .helperReview(
            widget.helper.usefullContactId ?? 0,
            widget.helper.pTypeName ?? "helper",
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(HelperViewModelProvider);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
   final reviewCount = reviewState.helperReviewDetails.value?.length ?? 0;
    // Responsive values for the bottom sheet
    final headerPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    final listPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    final buttonPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    final titleSize = isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);
    final buttonHeight = isDesktop ? 52.0 : (isTablet ? 48.0 : 45.0);
    final borderRadius = isDesktop ? 24.0 : 20.0;

    return reviewState.helperReviewDetails.when(
      loading: () => const Center(child: CircularProgressIndicator()),
       error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
      data: (reviews) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: isDesktop ? 0.8 : (isTablet ? 0.75 : 0.7),
          minChildSize: isDesktop ? 0.5 : (isTablet ? 0.45 : 0.4),
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius),
                  topRight: Radius.circular(borderRadius),
                ),
                boxShadow: isDesktop
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, -2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Handle bar for mobile
                  if (!isDesktop)
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  // Header
                  Container(
                    padding: EdgeInsets.all(headerPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child:
                     //    final reviewCount = reviews.length;

Text(
  'Reviews ($reviewCount)',
  style: TextStyle(
    fontSize: titleSize,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF2E3B62),
  ),
),

                        ),
                        // IconButton(
                        //   onPressed: () => Navigator.pop(context),
                        //   icon: Icon(Icons.close, size: isDesktop ? 28 : 24),
                        //   padding: EdgeInsets.all(isDesktop ? 12 : 8),
                
                        // ),
                        IconButton(
  onPressed: () => Navigator.pop(context),
  icon: Icon(Icons.close, size: isDesktop ? 28 : 24),
  padding: EdgeInsets.all(isDesktop ? 12 : 8),
),

                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: reviews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: isDesktop ? 64 : (isTablet ? 56 : 48),
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No reviews yet!',
                                  style: TextStyle(
                                    fontSize: isDesktop
                                        ? 18
                                        : (isTablet ? 16 : 14),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to leave a review',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 14 : 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 800 : double.infinity,
                              ),
                              child: RefreshIndicator(
                                onRefresh: () async => _loadData(),
                                child: ListView.builder(
                                  controller: scrollController,
                                  padding: EdgeInsets.all(listPadding),
                                  itemCount: reviews.length,
                                  itemBuilder: (context, index) {
                                    return _buildReviewCard(reviews[index]);
                                  },
                                ),
                              ),
                            ),
                          ),
                  ),
                  // Add review button
                  SafeArea(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonPadding,
                        vertical: buttonPadding * 0.6,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 800 : double.infinity,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => ReviewPopupHelper.showReviewPopup(
                          context,
                          widget.helper,
                          widget.categoryColor,
                          ref,
                          onReviewAdded: widget.onUpdated,
                        ),
                        
                        icon: Icon(Icons.add, size: isDesktop ? 20 : 18),
                        label: Text(
                          'Add Review',
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.categoryColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 16 : 12,
                            ),
                          ),
                          elevation: isDesktop ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewCard(Helper review) {
    final dateText = review.date != null
        ? DateFormat.yMMMd().format(
            DateTime.tryParse(review.date!) ?? DateTime.now(),
          )
        : 'Unknown date';

    // Get current owner ID for comparison
    final currentOwnerId = ref.watch(basicInfoViewModelProvider).ownerId;
    final reviewOwnerId =
        review.ownerId; // Assuming this field exists in Helper model
    final isOwner =
        currentOwnerId != null &&
        reviewOwnerId != null &&
        currentOwnerId == reviewOwnerId;

    // Responsive values
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth <= 600;

    // Dynamic sizing based on screen size
    final cardPadding = isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0);
    final cardMargin = isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0);
    final avatarRadius = isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);
    final spacingBetween = isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0);
    final nameTextSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final unitTextSize = isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0);
    final commentTextSize = isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0);
    final dateTextSize = isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0);
    final deleteButtonPadding = isDesktop ? 10.0 : (isTablet ? 8.0 : 6.0);
    final deleteIconSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final deleteTextSize = isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0);

    return Container(
      margin: EdgeInsets.only(bottom: cardMargin),
      constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        ),
        elevation: isDesktop ? 3 : 2,
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: isMobile
              ? _buildMobileLayout(
                  review,
                  dateText,
                  isOwner,
                  avatarRadius,
                  spacingBetween,
                  nameTextSize,
                  unitTextSize,
                  commentTextSize,
                  dateTextSize,
                  deleteButtonPadding,
                  deleteIconSize,
                  deleteTextSize,
                )
              : _buildTabletDesktopLayout(
                  review,
                  dateText,
                  isOwner,
                  avatarRadius,
                  spacingBetween,
                  nameTextSize,
                  unitTextSize,
                  commentTextSize,
                  dateTextSize,
                  deleteButtonPadding,
                  deleteIconSize,
                  deleteTextSize,
                  isDesktop,
                ),
        ),
      ),
    );
  }

  // Mobile layout (vertical stacking for better space utilization)
  Widget _buildMobileLayout(
    Helper review,
    String dateText,
    bool isOwner,
    double avatarRadius,
    double spacingBetween,
    double nameTextSize,
    double unitTextSize,
    double commentTextSize,
    double dateTextSize,
    double deleteButtonPadding,
    double deleteIconSize,
    double deleteTextSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with avatar, name, and rating
        Row(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey[200],
              child: Text(
                review.owner?.isNotEmpty == true
                    ? review.owner![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: nameTextSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: spacingBetween),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.owner ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: nameTextSize,
                    ),
                  ),
                  Text(
                    widget.helper.unit ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: unitTextSize,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    (review.rating ?? 0.0).toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: unitTextSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacingBetween),
        // Comment section
        if (review.comment?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              review.comment!,
              style: TextStyle(fontSize: commentTextSize, height: 1.4),
            ),
          ),
        // Footer row with date and delete button
        Row(
          children: [
            Text(
              dateText,
              style: TextStyle(fontSize: dateTextSize, color: Colors.grey[600]),
            ),
            const Spacer(),
            if (isOwner)
              _buildDeleteButton(
                review,
                deleteButtonPadding,
                deleteIconSize,
                deleteTextSize,
              ),
          ],
        ),
      ],
    );
  }

  // Tablet/Desktop layout (horizontal layout)
  Widget _buildTabletDesktopLayout(
    Helper review,
    String dateText,
    bool isOwner,
    double avatarRadius,
    double spacingBetween,
    double nameTextSize,
    double unitTextSize,
    double commentTextSize,
    double dateTextSize,
    double deleteButtonPadding,
    double deleteIconSize,
    double deleteTextSize,
    bool isDesktop,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: Colors.grey[200],
          child: Text(
            review.owner?.isNotEmpty == true
                ? review.owner![0].toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: nameTextSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: spacingBetween),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          review.owner ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: nameTextSize,
                          ),
                        ),
                        SizedBox(width: spacingBetween * 0.5),
                        Text(
                          '• ${widget.helper.unit ?? 'Unknown'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: unitTextSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          (review.rating ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: unitTextSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (review.comment?.isNotEmpty == true) ...[
                SizedBox(height: spacingBetween * 0.5),
                Text(
                  review.comment!,
                  style: TextStyle(fontSize: commentTextSize, height: 1.4),
                ),
              ],
              SizedBox(height: spacingBetween * 0.7),
              Row(
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: dateTextSize,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (isOwner)
                    _buildDeleteButton(
                      review,
                      deleteButtonPadding,
                      deleteIconSize,
                      deleteTextSize,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(
    Helper review,
    double padding,
    double iconSize,
    double textSize,
  ) {
    return GestureDetector(
      onTap: () => _showDeleteConfirmation(review),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: iconSize, color: Colors.red[600]),
            SizedBox(width: padding * 0.4),
            Text(
              'Delete',
              style: TextStyle(
                fontSize: textSize,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Helper review) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth > 600 && screenWidth < 1024;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
          ),
          contentPadding: EdgeInsets.all(isDesktop ? 24 : 20),
          titlePadding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 20,
            isDesktop ? 24 : 20,
            isDesktop ? 24 : 20,
            isDesktop ? 16 : 12,
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 16,
            0,
            isDesktop ? 24 : 16,
            isDesktop ? 24 : 16,
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red[600],
                  size: isDesktop ? 24 : 20,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Text(
                  'Delete Review',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E3B62),
                    fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 400 : double.infinity,
            ),
            child: Text(
              'Are you sure you want to delete this review? This action cannot be undone.',
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                height: 1.4,
                color: Colors.grey[700],
              ),
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 20,
                  vertical: isDesktop ? 12 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isDesktop ? 15 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 12 : 8),
            // Delete button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteReview(review);

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 20,
                  vertical: isDesktop ? 12 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                ),
                elevation: isDesktop ? 2 : 1,
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  fontSize: isDesktop ? 15 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteReview(Helper review) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call the delete review method (you'll need to implement this in your provider)
      await ref
          .read(HelperViewModelProvider.notifier)
          .deleteHelperReview(review.reviewId ?? 0);

      // Hide loading indicator
      if (mounted) Navigator.pop(context);
 ref
          .read(HelperViewModelProvider.notifier)
          .getHelperList(ref.watch(basicInfoViewModelProvider).societyID ?? '');
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Review deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Refresh reviews
      ref
          .read(HelperViewModelProvider.notifier)
          .helperReview(
            widget.helper.usefullContactId ?? 0,
            widget.helper.pTypeName ?? "helper",
          );
    } catch (error) {
      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.map(error)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class AddReviewDialog extends ConsumerStatefulWidget {
  final Helper helper;
  final Color categoryColor;
  final VoidCallback? onSubmitted;

  const AddReviewDialog({
    super.key,
    required this.helper,
    required this.categoryColor,
    this.onSubmitted,
  });

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;

  bool get _valid =>
      _nameController.text.trim().isNotEmpty &&
      _flatController.text.trim().isNotEmpty &&
      _commentController.text.trim().isNotEmpty;



  Future<void> _submitReview() async {
    final review = HelperReview(
      owner: _nameController.text.trim(),
      comment: _commentController.text.trim(),
      rating: _rating,
      date: DateTime.now().toIso8601String(),
    );

    // Call ViewModel
    final basicInfo = ref.watch(basicInfoViewModelProvider);
    final ownerIdFromVM = basicInfo.ownerId;
    final societyId = basicInfo.societyID;
    final loginType = basicInfo.loginType;

 
    int finalOwnerId = 0;
    int memberId = 0;
    // 2. loginType check
    // 2. loginType check
                        if (loginType?.toLowerCase() == "owner") {
                          finalOwnerId = ownerIdFromVM ?? 0;
                        } else {
                          memberId = ownerIdFromVM ?? 0;
                        }
                        debugPrint("loginType: $loginType");
                        debugPrint("ownerIdFromVM: $ownerIdFromVM");
                        debugPrint("finalOwnerId: $finalOwnerId");
                        debugPrint("memberId: $memberId");
    //                     final correctUsefullId = widget.helper.usefullContactId != null && widget.helper.usefullContactId != 0
    // ? widget.helper.usefullContactId
    // : widget.helper.helperId;

//print("Final usefullContactId used for review: $correctUsefullId");

final helperReview = Helper(
  usefullContactId: widget.helper.usefullContactId??0,
  ownerId: finalOwnerId,
  memberId: memberId,
  societyId: societyId,
  comment: _commentController.text.trim(),
  rating: _rating,
);

                        // final helperReview = Helper(
                        //   usefullContactId: widget.helper.usefullContactId ?? 0,
                        //   ownerId: finalOwnerId,
                        //   memberId: memberId,
                        //   societyId: societyId,
                        //   comment: _commentController.text,
                        //   rating: _rating,
                        // );

    try {
      await ref.read(HelperViewModelProvider.notifier).addReview(helperReview);

      if (context.mounted) {
        Navigator.pop(context);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text("Review submitted successfully"),
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(HelperViewModelProvider);
    final isSubmitting = reviewState.isLoading;

    final name = widget.helper.orgname ?? widget.helper.pName ?? 'Unknown';
    return AlertDialog(
      title: Text('Add review for $name'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TextField(
            //   controller: _nameController,
            //   decoration: const InputDecoration(
            //     labelText: 'Your name',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // const SizedBox(height: 12),
            // TextField(
            //   controller: _flatController,
            //   decoration: const InputDecoration(
            //     labelText: 'Flat No',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Rating:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 8,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _rating = v),
                    activeColor: widget.categoryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.categoryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting || !_valid ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.categoryColor,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _flatController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
