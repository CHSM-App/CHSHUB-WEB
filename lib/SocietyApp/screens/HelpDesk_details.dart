
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/full_screen_gallery.dart';
import 'package:society_app/domain/models/broadcast.dart';
import 'package:society_app/domain/models/helpdesk_comment.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class ComplaintDetailPage extends ConsumerStatefulWidget {
  final int? helpdeskID;
  final int? notifyStatusId;
  const ComplaintDetailPage({
    super.key,
    required this.helpdeskID,
    this.notifyStatusId,
  });
  @override
  ConsumerState<ComplaintDetailPage> createState() =>
      _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends ConsumerState<ComplaintDetailPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Map<String, dynamic> getStatusInfo(int statusId) {
    switch (statusId) {
      case 1:
        return {"text": "New", "color": Colors.blue};
      case 2:
        return {"text": "In-Progress", "color": Colors.orange};
      case 3:
        return {"text": "On-Hold", "color": Colors.amber};
      case 4:
        return {"text": "Closed", "color": Colors.green};
      default:
        return {"text": "Unknown", "color": Colors.grey};
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 helpdeskID: ${widget.helpdeskID}, notifyStatusId: ${widget.notifyStatusId}');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
_loadData();
   
  }

// void _loadData(){
//  Future.microtask(() async {
//       final helpdeskVM = ref.read(HelpdeskViewModelProvider.notifier);
//       await helpdeskVM.getHelpdeskListByHelpdeskID(widget.helpdeskID!);
//       await helpdeskVM.getHelpdeskComments(widget.helpdeskID!);

//       if (widget.notifyStatusId != null && widget.notifyStatusId! > 0) {
//         final info = ref.read(basicInfoViewModelProvider);
//         await ref
//             .read(broadcastViewModelProvider.notifier)
//             .updateNotificationStatus(
//               widget.notifyStatusId!,
//               info.societyID ?? "",
//               info.ownerId ?? 0,
//             );
//               ref.read(broadcastViewModelProvider.notifier)
//             .getNotification(info.societyID!, info.ownerId!);
//       }
//       //{ Navigator.pop(context);
//    ref
//           .read(HelpdeskViewModelProvider.notifier)
//           .getHelpdeskList(
//             ref.watch(basicInfoViewModelProvider).societyID??"",ref.watch(basicInfoViewModelProvider).ownerId??0,
//           );

     
          
//     });
// }

void _loadData() {
  Future.microtask(() async {
    final helpdeskVM = ref.read(HelpdeskViewModelProvider.notifier);
    await helpdeskVM.getHelpdeskListByHelpdeskID(widget.helpdeskID!);
    await helpdeskVM.getHelpdeskComments(widget.helpdeskID!);

    // Notification update if needed
    if (widget.notifyStatusId != null && widget.notifyStatusId! > 0) {
      final info = ref.read(basicInfoViewModelProvider);
      await ref.read(broadcastViewModelProvider.notifier)
          .updateNotificationStatus(widget.notifyStatusId!, info.societyID ?? "", info.ownerId ?? 0);
      await ref.read(broadcastViewModelProvider.notifier)
          .getNotification(info.societyID!, info.ownerId!);
    }

    ref.read(HelpdeskViewModelProvider.notifier)
      .getHelpdeskList(
        ref.watch(basicInfoViewModelProvider).societyID ?? "",
        ref.watch(basicInfoViewModelProvider).ownerId ?? 0,
      );

    if (mounted) setState(() {}); // <-- Refresh UI
  });
}

  @override
  void dispose() {
    _animController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaintDetail = ref.watch(HelpdeskViewModelProvider).complaintDetail;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Complaint Details")),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: complaintDetail.when(
              data: (complaints) {
                if (complaints.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Center(child: Text("No complaint found")),
                        ),
                      ),
                    ),
                  );
                }

                final complaint = complaints.first;
                final statusInfo = getStatusInfo(complaint.status ?? 0);
                final commentsState = ref.watch(HelpdeskViewModelProvider).complaintComments;
                final List<String> images =
                    (complaint.image != null && complaint.image!.isNotEmpty)
                        ? complaint.image!
                            .split(",")
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : [];

                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Complaint Card - FIXED OVERFLOW
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FIXED: Using Column instead of Row to prevent overflow
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        complaint.categoryName.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "• ${complaint.unit ?? ''}",
                                        style: const TextStyle(color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Status badge on separate line
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusInfo["color"],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    statusInfo["text"],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              complaint.query ?? '',
                              softWrap: true,
                            ),
                            const SizedBox(height: 10),
                            // FIXED: Wrapped in Flexible widgets
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Raised by ${complaint.name ?? ''}",
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  complaint.date ?? '',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Mark Resolved Button
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: ElevatedButton(
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.blue,
                      //       foregroundColor: Colors.white,
                      //       padding: const EdgeInsets.symmetric(vertical: 14),
                      //       textStyle: const TextStyle(
                      //         fontSize: 16,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //     onPressed: () async {
                      //       final result = await ref
                      //           .read(HelpdeskViewModelProvider.notifier)
                      //           .updateRequest(1, 1, widget.helpdeskID!);

                      //       if (result != null) {
                      //         await ref
                      //             .read(HelpdeskViewModelProvider.notifier)
                      //             .getHelpdeskListByHelpdeskID(widget.helpdeskID!);
                      //       }
                      //     },
                      //     child: const Text("Mark as Resolved"),
                      //   ),
                      // ),
                      // Mark Resolved Section
   SizedBox(
  width: double.infinity,
  child: complaint.status == 4
      ? Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "Resolved",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        )
      : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () async {
            final result = await ref
                .read(HelpdeskViewModelProvider.notifier)
                .updateRequest(1, 1, widget.helpdeskID!);

            if (result != null) {
              await ref
                  .read(HelpdeskViewModelProvider.notifier)
                  .getHelpdeskListByHelpdeskID(widget.helpdeskID!);
            }
          },
          child: const Text("Mark as Resolved"),
        ),
),

                      const SizedBox(height: 20),

                      // Photos Section
                      const Text(
                        "Photos",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),

                      if (images.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(images.length, (index) {
                            final imgUrl = images[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenGallery(
                                      images: images,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imgUrl,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 120,
                                      width: 120,
                                      child: Center(
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
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(
                                    height: 120,
                                    width: 120,
                                    child: Icon(Icons.broken_image, color: Colors.black, size: 44),
                                  ),
                                ),
                              ),
                            );
                          }),
                        )
                      else
                        const Text("No photos attached"),

                      const SizedBox(height: 20),

                      // Comments Section
                      const Text(
                        "Comments",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),

                      commentsState.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                "No comments yet",
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final c = comments[index];
                              final screenWidth = MediaQuery.of(context).size.width;
                              final textScale = MediaQuery.of(context).textScaler;

                              final name = c.name ?? 'Unknown';
                              final commentText = c.description ?? '';
                              final time = c.dateTime != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(
                                      DateTime.tryParse(c.dateTime!) ?? DateTime.now(),
                                    )
                                  : 'No time';

                              return Container(
                                width: screenWidth,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Card(
                                  color: Colors.white,
                                  elevation: 2,
                                  shadowColor: Colors.black26,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // FIXED: Name + Time Row with proper overflow handling
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: textScale.scale(15),
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              time,
                                              style: TextStyle(
                                                fontSize: textScale.scale(11),
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Comment text
                                        Text(
                                          commentText,
                                          style: TextStyle(
                                            fontSize: textScale.scale(14),
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                          softWrap: true,
                                        ),

                                        // Delete button
                                        
if (c.ownerId == ref.read(basicInfoViewModelProvider).ownerId &&
    c.type == ref.read(basicInfoViewModelProvider).loginType) ...[
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                textStyle: TextStyle(
                                                  fontSize: textScale.scale(13),
                                                ),
                                              ),
                                              onPressed: () async {
                                                final result = await ref
                                                    .read(HelpdeskViewModelProvider.notifier)
                                                    .updateRequest(2, c.comment_id ?? 0, 0);

                                                if (result != null) {
                                                  await ref
                                                      .read(HelpdeskViewModelProvider.notifier)
                                                      .getHelpdeskComments(widget.helpdeskID!);
                                                } else {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text("Failed to delete comment"),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.delete, size: 18),
                                              label: const Text("Delete"),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
                      ),
                      const SizedBox(height: 100), // Space for fixed comment box
                    ],
                  ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
               error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
            ),
          ),

          // Fixed comment input area at the bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Input field
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        isDense: true,
                      ),
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () async {
                        final commentText = _commentController.text.trim();
                        if (commentText.isEmpty) return;

                        final newComment = HelpdeskComment(
                          helpdeskId: widget.helpdeskID ?? 0,
                          flatId: ref.watch(basicInfoViewModelProvider).flatId,
                          description: commentText,
                          dateTime: DateTime.now().toIso8601String(),
                          ownerId: ref.watch(basicInfoViewModelProvider).ownerId,
                          type: ref.watch(basicInfoViewModelProvider).loginType
                        );

                        await ref
                            .read(HelpdeskViewModelProvider.notifier)
                            .insertComments(newComment);

                        final response = ref.read(HelpdeskViewModelProvider);

                        // Send notifications
                        await ref
                            .read(directoryViewModelProvider.notifier)
                            .loadAllTokens(
                              ref.watch(basicInfoViewModelProvider).societyID ?? "",
                            );

                        final tokenState = ref.watch(directoryViewModelProvider);
                        late List<String> tokenList;

                        tokenState.allTokens.when(
                          data: (tokens) async {
                            tokenList = tokens.map((e) => e.webToken ?? '').toList();
                            debugPrint('✅ Tokens fetched: $tokenList');

                            for (var token in tokens) {
                              final broadcast = Broadcast(
                                societyId:
                                    ref.watch(basicInfoViewModelProvider).societyID ?? "",
                                title: "Helpdesk Ticket Update",
                                body:
                                    "A new helpdesk comments has been created from Unit: ${ref.watch(basicInfoViewModelProvider).unit}",
                                userType: "Member",
                                userId: token.userId,
                                notificationType: "Helpdesk",
                                seenStatus: 0,
                                notificationId: widget.helpdeskID,
                                ownerId:
                                    ref.watch(basicInfoViewModelProvider).ownerId ?? 0,
                              );

                              await ref
                                  .read(broadcastViewModelProvider.notifier)
                                  .insertNotification(broadcast);
                            }

                            final notification = SendNotification(
                              tokens: tokenList,
                              title: "Helpdesk Ticket Update",
                              body: commentText,
                              clickAction:"helpdesk comment"
                            );

                            await ref
                                .read(alertViewModelProvider.notifier)
                                .sendNotification(notification);
                          },
                          loading: () => debugPrint('Loading tokens...'),
                            error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
                        );

                        if (response.data != null) {
                          _commentController.clear();
                          await ref
                              .read(HelpdeskViewModelProvider.notifier)
                              .getHelpdeskComments(widget.helpdeskID!);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to add comment")),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}