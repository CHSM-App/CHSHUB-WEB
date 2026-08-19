import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/broadcast.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/main.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class SecurityAlertDialog extends StatefulWidget {
  const SecurityAlertDialog({super.key});

  @override
  _SecurityAlertDialogState createState() => _SecurityAlertDialogState();
}

class _SecurityAlertDialogState extends State<SecurityAlertDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
             
              constraints: BoxConstraints(maxWidth: 400),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Section
                  Container(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Send Message',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        // Message Options
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionCard(
                                title: 'Admin',
                                icon: Icons.admin_panel_settings,
                                color: Colors.blue[50]!,
                                iconColor: Colors.blue[600]!,
                                onTap: () => _sendMessageTo('Admin'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildOptionCard(
                                title: 'Security',
                                icon: Icons.security,
                                color: Colors.green[50]!,
                                iconColor: Colors.green[600]!,
                                onTap: () => _sendMessageTo('Security'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Security Alert Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Security Alert',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Alert Options Grid
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Fire Alert',
                                icon: Icons.local_fire_department,
                                color: Colors.red[50]!,
                                iconColor: Colors.red[600]!,
                                onTap: () => _sendSecurityAlert(
                                  "1",
                                  'Fire Alert',
                                  'URGENT: Fire detected in the building. Please evacuate immediately!',
                                  AlertLevel.critical,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Stuck in Lift',
                                icon: Icons.elevator,
                                color: Colors.orange[50]!,
                                iconColor: Colors.orange[600]!,
                                onTap: () => _sendSecurityAlert(
                                  "2",
                                  'Stuck in Lift',
                                  'HELP: Someone is stuck in the elevator. Please send assistance immediately.',
                                  AlertLevel.high,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Animal Threat',
                                icon: Icons.pets,
                                color: Colors.green[50]!,
                                iconColor: Colors.green[600]!,
                                onTap: () => _sendSecurityAlert(
                                  "3",
                                  'Animal Threat',
                                  'CAUTION: Dangerous animal spotted in the premises. Please handle with care.',
                                  AlertLevel.medium,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Visitor Threat',
                                icon: Icons.person_off,
                                color: Colors.purple[50]!,
                                iconColor: Colors.purple[600]!,
                                onTap: () => _sendSecurityAlert(
                                  "4",
                                  'Visitor Threat',
                                  'ALERT: Suspicious visitor activity detected. Please investigate immediately.',
                                  AlertLevel.high,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Action Buttons
                  Container(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return AnimatedOptionCard(
      title: title,
      icon: icon,
      color: color,
      iconColor: iconColor,
      onTap: onTap,
    );
  }

  Widget _buildAlertCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return AnimatedAlertCard(
      title: title,
      icon: icon,
      color: color,
      iconColor: iconColor,
      onTap: onTap,
    );
  }

  // Send message functionality
  void _sendMessageTo(String recipient) {
    Navigator.of(context).pop(); // Close dialog first

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MessageComposeDialog(recipient: recipient);
      },
    );
  }

  // Send security alert functionality
  void _sendSecurityAlert(
    String alertType,
    String alertTitle,
    String message,
    AlertLevel level,
  ) {
    Navigator.of(context).pop(); // Close dialog first

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertConfirmationDialog(
          alertType: alertType,
          alertTitle: alertTitle,
          message: message,
          level: level,
          parentContext: context,
        );
      },
    );
  }

  // Process the security alert
}

enum AlertLevel { critical, high, medium }

// Assuming these providers exist somewhere in your codebase
// final basicInfoViewModelProvider = ...;
// final alertViewModelProvider = ...;

class MessageComposeDialog extends ConsumerStatefulWidget {
  final String recipient;

  const MessageComposeDialog({super.key, required this.recipient});

  @override
  ConsumerState<MessageComposeDialog> createState() =>
      _MessageComposeDialogState();
}

class _MessageComposeDialogState extends ConsumerState<MessageComposeDialog> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final subject = _subjectController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both subject and message')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🧩 Step 1: Get basic info
      final basicInfo = ref.watch(basicInfoViewModelProvider);
      final fId = basicInfo.flatId ?? 0;
      final societyId = basicInfo.societyID ?? "";
      final ownerId = basicInfo.ownerId ?? 0;
      final loginType = basicInfo.loginType?.toLowerCase() ?? "";
      final ownerType = (loginType == "owner") ? 1 : 0;
      final type = widget.recipient == 'Admin' ? 'admin' : 'security';

      debugPrint("📤 Sending owner message to backend...");

      final response = await ref
          .read(alertViewModelProvider.notifier)
          .addOwnerMessage(
            fId,
            message,
            type,
            societyId,
            subject,
            ownerId,
            ownerType,
          );

      final rId = response['r_id'] ?? 0;

      await ref
          .read(directoryViewModelProvider.notifier)
          .loadAllTokens(societyId);

      final tokenState = ref.read(directoryViewModelProvider);

      tokenState.allTokens.when(
        data: (data) {
          final tokenList = data.map((e) => e.webToken ?? '').toList();
          debugPrint("✅ Tokens fetched: $tokenList");
          final notification = SendNotification(
            tokens: tokenList,
            title: subject,
            body: message,
          );

          debugPrint("🚀 Sending push notification to API...");
          ref
              .read(alertViewModelProvider.notifier)
              .sendNotification(notification);
          // 🧩 Step 3: Insert notification in DB for each user
          for (var token in data) {
            final broadcast = Broadcast(
              societyId: societyId,
              title: subject,
              body: message,
              userType: "Member",
              userId: token.userId,
              notificationType: "Message",
              seenStatus: 0,
              notificationId: rId,
              ownerId: ownerId,
            );

            ref
                .read(broadcastViewModelProvider.notifier)
                .insertNotification(broadcast);
          }

          Navigator.of(context).pop();
          Future.delayed(const Duration(milliseconds: 100), () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Message sent to ${widget.recipient} successfully!',
                ),
                backgroundColor: widget.recipient == 'Admin'
                    ? Colors.blue[600]
                    : Colors.green[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          });
        },
        error: (error, stackTrace) =>
            Center(child: Text(ErrorMessageMapper.map(error))),
        loading: () => Center(child: CircularProgressIndicator()),
      );
      // 🧩 Step 5: Success UI
    } catch (e, st) {
      debugPrint('❌ Error sending message: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessageMapper.map(e))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

// @override
// Widget build(BuildContext context) {
//   return AlertDialog(
//     backgroundColor: Colors.white,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//     title: Row(
//       children: [
//         Icon(
//           widget.recipient == 'Admin'
//               ? Icons.admin_panel_settings
//               : Icons.security,
//           color: widget.recipient == 'Admin'
//               ? Colors.blue[600]
//               : Colors.green[600],
//         ),
//         const SizedBox(width: 12),
//         Text('Message to ${widget.recipient}'),
//       ],
//     ),
//     // ✅ Scrollable content to prevent overflow
//     content: SingleChildScrollView(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Subject',
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _subjectController,
//             decoration: InputDecoration(
//               hintText: 'Type your subject here...',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                   color: widget.recipient == 'Admin'
//                       ? Colors.blue[600]!
//                       : Colors.green[600]!,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Compose your message:',
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _messageController,
//             maxLines: 4,
//             decoration: InputDecoration(
//               hintText: 'Type your message here...',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                   color: widget.recipient == 'Admin'
//                       ? Colors.blue[600]!
//                       : Colors.green[600]!,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//     actions: [
//       TextButton(
//         onPressed: () => Navigator.of(context).pop(),
//         child: const Text('Cancel'),
//       ),
//       ElevatedButton(
//         onPressed: _isLoading ? null : _sendMessage,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: widget.recipient == 'Admin'
//               ? Colors.blue[600]
//               : Colors.green[600],
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         child: _isLoading
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               )
//             : const Text('Send', style: TextStyle(color: Colors.white)),
//       ),
//     ],
//   );
// }
// }


// @override
// Widget build(BuildContext context) {
//   final mediaQuery = MediaQuery.of(context);

//   return SingleChildScrollView( // 👈 allows dialog to move when keyboard appears
//     child: Center(
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           // Limit dialog height so it never overflows
//           maxHeight: mediaQuery.size.height * 0.85,
//           maxWidth: mediaQuery.size.width * 0.95,
//         ),
//         child: AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Row(
//             children: [
//               Icon(
//                 widget.recipient == 'Admin'
//                     ? Icons.admin_panel_settings
//                     : Icons.security,
//                 color: widget.recipient == 'Admin'
//                     ? Colors.blue[600]
//                     : Colors.green[600],
//               ),
//               const SizedBox(width: 12),
//               Flexible(
//                 child: Text(
//                   'Message to ${widget.recipient}',
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Subject',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: _subjectController,
//                   decoration: InputDecoration(
//                     hintText: 'Type your subject here...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(
//                         color: widget.recipient == 'Admin'
//                             ? Colors.blue[600]!
//                             : Colors.green[600]!,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Compose your message:',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: _messageController,
//                   maxLines: 4,
//                   decoration: InputDecoration(
//                     hintText: 'Type your message here...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(
//                         color: widget.recipient == 'Admin'
//                             ? Colors.blue[600]!
//                             : Colors.green[600]!,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _sendMessage,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: widget.recipient == 'Admin'
//                     ? Colors.blue[600]
//                     : Colors.green[600],
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : const Text('Send', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
// }


// @override
// Widget build(BuildContext context) {
//   final mediaQuery = MediaQuery.of(context);

//   return LayoutBuilder(
//     builder: (context, constraints) {
//       return SingleChildScrollView(
//         padding: EdgeInsets.only(
//           bottom: mediaQuery.viewInsets.bottom, // 👈 moves dialog when keyboard appears
//         ),
//         child: Center(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               maxHeight: constraints.maxHeight * 0.95,
//               maxWidth: constraints.maxWidth * 0.95,
//             ),
//             child: Material(
//               type: MaterialType.transparency,
//               child: AlertDialog(
//                 backgroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),

//                 // 👇 Important: allows content inside dialog to scroll
//                 scrollable: true,

//                 title: Row(
//                   children: [
//                     Icon(
//                       widget.recipient == 'Admin'
//                           ? Icons.admin_panel_settings
//                           : Icons.security,
//                       color: widget.recipient == 'Admin'
//                           ? Colors.blue[600]
//                           : Colors.green[600],
//                     ),
//                     const SizedBox(width: 12),
//                     Flexible(
//                       child: Text(
//                         'Message to ${widget.recipient}',
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),

//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Subject',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     TextField(
//                       controller: _subjectController,
//                       decoration: InputDecoration(
//                         hintText: 'Type your subject here...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(
//                             color: widget.recipient == 'Admin'
//                                 ? Colors.blue[600]!
//                                 : Colors.green[600]!,
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     Text(
//                       'Compose your message:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     TextField(
//                       controller: _messageController,
//                       maxLines: 4,
//                       decoration: InputDecoration(
//                         hintText: 'Type your message here...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(
//                             color: widget.recipient == 'Admin'
//                                 ? Colors.blue[600]!
//                                 : Colors.green[600]!,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: const Text('Cancel'),
//                   ),
//                   ElevatedButton(
//                     onPressed: _isLoading ? null : _sendMessage,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: widget.recipient == 'Admin'
//                           ? Colors.blue[600]
//                           : Colors.green[600],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : const Text('Send',
//                             style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }
// }
@override
Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: mediaQuery.viewInsets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * 0.95,
              maxWidth: constraints.maxWidth * 0.95,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                // 👇 Remove scrollable: true - we're handling scroll with SingleChildScrollView
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),

                title: Row(
                  children: [
                    Icon(
                      widget.recipient == 'Admin'
                          ? Icons.admin_panel_settings
                          : Icons.security,
                      color: widget.recipient == 'Admin'
                          ? Colors.blue[600]
                          : Colors.green[600],
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Message to ${widget.recipient}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                content: SingleChildScrollView( // 👈 Add this wrapper
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 👈 Important: prevents Column from expanding
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subject',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'Type your subject here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.recipient == 'Admin'
                                  ? Colors.blue[600]!
                                  : Colors.green[600]!,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Compose your message:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type your message here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.recipient == 'Admin'
                                  ? Colors.blue[600]!
                                  : Colors.green[600]!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.recipient == 'Admin'
                          ? Colors.blue[600]
                          : Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Send',
                            style: TextStyle(color: Colors.white)),
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
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Row(
//         children: [
//           Icon(
//             widget.recipient == 'Admin'
//                 ? Icons.admin_panel_settings
//                 : Icons.security,
//             color: widget.recipient == 'Admin'
//                 ? Colors.blue[600]
//                 : Colors.green[600],
//           ),
//           const SizedBox(width: 12),
//           Text('Message to ${widget.recipient}'),
//         ],
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Subject',
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _subjectController,
//             decoration: InputDecoration(
//               hintText: 'Type your subject here...',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                   color: widget.recipient == 'Admin'
//                       ? Colors.blue[600]!
//                       : Colors.green[600]!,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Compose your message:',
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _messageController,
//             maxLines: 4,
//             decoration: InputDecoration(
//               hintText: 'Type your message here...',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                   color: widget.recipient == 'Admin'
//                       ? Colors.blue[600]!
//                       : Colors.green[600]!,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),

//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading ? null : _sendMessage,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: widget.recipient == 'Admin'
//                 ? Colors.blue[600]
//                 : Colors.green[600],
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: _isLoading
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 )
//               : const Text('Send', style: TextStyle(color: Colors.white)),
//         ),
//       ],
//     );
//   }
// }

// Alert Confirmation Dialog
// Fixed AlertConfirmationDialog with proper error handling

class AlertConfirmationDialog extends ConsumerStatefulWidget {
  final String alertType;
  final String alertTitle;
  final String message;
  final AlertLevel level;
  final BuildContext parentContext;

  const AlertConfirmationDialog({
    super.key,
    required this.alertType,
    required this.alertTitle,
    required this.message,
    required this.level,
    required this.parentContext,
  });

  @override
  ConsumerState<AlertConfirmationDialog> createState() =>
      _AlertConfirmationDialogState();
}

class _AlertConfirmationDialogState
    extends ConsumerState<AlertConfirmationDialog> {
  bool _isSending = false;

  void _processSecurityAlert(
    String alertTitle,
    String message,
    AlertLevel level,
    BuildContext context,
  ) {
    // Use the root scaffold messenger to ensure context is valid
    final scaffoldMessenger = rootScaffoldMessengerKey.currentState;
    final rootContext = navigatorKey.currentContext;

    if (scaffoldMessenger == null || rootContext == null) {
      debugPrint("⚠️ Unable to show snackbar — context not ready");
      return;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getAlertIcon(level), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$alertTitle Sent!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Security team has been notified',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getAlertColor(level),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(rootContext, rootNavigator: true).push(
              PageRouteBuilder(
                opaque: false,
                barrierDismissible: true,
                pageBuilder: (_, __, ___) => AlertDetailsDialog(
                  alertType: alertTitle,
                  message: message,
                  level: level,
                ),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(_getAlertIcon(widget.level),
              color: _getAlertColor(widget.level), size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Confirm ${widget.alertTitle}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          minWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAlertColor(widget.level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.message,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will immediately notify the security team and relevant personnel. Are you sure you want to send this alert?',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _getAlertColor(widget.level),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isSending ? null : _sendAlert,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Send Alert',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Future<void> _sendAlert() async {
    // Prevent multiple taps
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      // ✅ Cache all needed data BEFORE any async operations
      final alertNotifier = ref.read(alertViewModelProvider.notifier);
      final directoryNotifier = ref.read(directoryViewModelProvider.notifier);
      final broadcastNotifier = ref.read(broadcastViewModelProvider.notifier);
      final basicInfo = ref.read(basicInfoViewModelProvider);

      final flatId = basicInfo.flatId;
      final societyId = basicInfo.societyID;
      final ownerId = basicInfo.ownerId;
      final unit = basicInfo.unit;

      // ✅ Validate required data
      if (flatId == null || societyId == null || ownerId == null) {
        throw Exception('Missing required user information');
      }

      debugPrint("📤 Creating alert: ${widget.alertType}");

      // 🧩 Step 1: Create the alert
      final alertResponse = await alertNotifier.addAlertMessage(
        flatId,
        widget.alertType,
        societyId,
      );

      if (alertResponse == null) {
        throw Exception('Alert creation failed: null response');
      }

      final result = alertResponse['success'] == true;
      final securityId = alertResponse['securityId'] ?? 0;

      debugPrint("✅ Alert created. Security ID: $securityId");

      if (!result) {
        throw Exception('Alert creation failed');
      }

      // 🧩 Step 2: Load all tokens
      debugPrint("📡 Loading notification tokens...");
      await directoryNotifier.loadAllTokens(societyId);

      // ✅ Check if widget is still mounted before accessing ref
      if (!mounted) {
        debugPrint("⚠️ Widget disposed before completing alert");
        return;
      }

      final tokenState = ref.read(directoryViewModelProvider);
      final tokensAsyncValue = tokenState.allTokens;

      // ✅ Handle AsyncValue properly
      final tokens = tokensAsyncValue.when(
        data: (data) => data,
        loading: () => <dynamic>[],
        error: (error, stack) {
          debugPrint("❌ Error loading tokens: $error");
          return <dynamic>[];
        },
      );

      if (tokens.isEmpty) {
        debugPrint("⚠️ No tokens found, but continuing...");
      }

      final tokenList = tokens.map((e) => e.webToken ?? '').where((t) => t.isNotEmpty).toList().cast<String>();
      debugPrint('✅ Valid tokens: ${tokenList.length}');

      // 🧩 Step 3: Insert notifications for each user
      debugPrint("📝 Inserting notifications...");
      for (final token in tokens) {
        if (!mounted) break;

        final broadcast = Broadcast(
          societyId: societyId,
          title: "Security Alert",
          body: "An ${widget.alertTitle} alert has been raised from Unit: ${unit ?? 'Unknown'}",
          userType: "Member",
          userId: token.userId,
          notificationType: "Alert",
          seenStatus: 0,
          notificationId: securityId,
          ownerId: ownerId,
        );

        await broadcastNotifier.insertNotification(broadcast);
      }

      // 🧩 Step 4: Send push notification
      if (tokenList.isNotEmpty) {
        debugPrint("🚀 Sending push notifications...");
        final notification = SendNotification(
          tokens: tokenList,
          title: "Security Alert",
          body: "An ${widget.alertTitle} alert has been raised from Unit: ${unit ?? 'Unknown'}",
        );

        await alertNotifier.sendNotification(notification);
        debugPrint("✅ Push notifications sent successfully");
      }

      // ✅ Step 5: Close dialog and show success message
      if (!mounted) return;

      Navigator.of(context).pop();
      _processSecurityAlert(
        widget.alertTitle,
        widget.message,
        widget.level,
        context,
      );
    } catch (e, st) {
      debugPrint("❌ Error sending alert: $e\n$st");

      if (!mounted) return;

      setState(() => _isSending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.map(e)),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getAlertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Icons.warning;
      case AlertLevel.high:
        return Icons.priority_high;
      case AlertLevel.medium:
        return Icons.info;
    }
  }

  Color _getAlertColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Colors.red[600]!;
      case AlertLevel.high:
        return Colors.orange[600]!;
      case AlertLevel.medium:
        return Colors.blue[600]!;
    }
  }
}
// class AlertConfirmationDialog extends ConsumerWidget {
//   final String alertType;
//   final String alertTitle;
//   final String message;
//   final AlertLevel level;
//   final BuildContext parentContext;

//   const AlertConfirmationDialog({
//     super.key,
//     required this.alertType,
//     required this.alertTitle,
//     required this.message,
//     required this.level,
//     required this.parentContext,
//   });
//   void _processSecurityAlert(
//     String alertTitle,
//     String message,
//     AlertLevel level,
//     BuildContext context,
//   ) {
//     // Use the root scaffold messenger to ensure context is valid
//     final scaffoldMessenger = rootScaffoldMessengerKey.currentState;
//     final rootContext = navigatorKey.currentContext;

//     if (scaffoldMessenger == null || rootContext == null) {
//       debugPrint("⚠️ Unable to show snackbar — context not ready");
//       return;
//     }

//     scaffoldMessenger.showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(_getAlertIcon(level), color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     '$alertTitle Sent!',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const Text(
//                     'Security team has been notified',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: _getAlertColor(level),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 4),
//         action: SnackBarAction(
//           label: 'View',
//           textColor: Colors.white,
//           onPressed: () {

//             // ✅ Use root navigator instead of dialog context
//             Navigator.of(rootContext, rootNavigator: true).push(
//               PageRouteBuilder(
//                 opaque: false,
//                 barrierDismissible: true,
//                 pageBuilder: (_, __, ___) => AlertDetailsDialog(
//                   alertType: alertTitle,
//                   message: message,
//                   level: level,
//                 ),
//                 transitionsBuilder: (_, animation, __, child) {
//                   return FadeTransition(
//                     opacity: animation,
//                     child: SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(0, 0.1),
//                         end: Offset.zero,
//                       ).animate(animation),
//                       child: child,
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// @override
// Widget build(BuildContext context, WidgetRef ref) {
//   final maxHeight = MediaQuery.of(context).size.height * 0.8; // limit height

//   return AlertDialog(
//     backgroundColor: Colors.white,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//     title: Row(
//       children: [
//         Icon(_getAlertIcon(level), color: _getAlertColor(level), size: 28),
//         const SizedBox(width: 12),
//         Flexible(
//           child: Text(
//             'Confirm $alertTitle',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),

//     // 👇 Wrap content in scrollable container with constraints
//     content: ConstrainedBox(
//       constraints: BoxConstraints(
//         maxHeight: maxHeight,
//         minWidth: MediaQuery.of(context).size.width * 0.8,
//       ),
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: _getAlertColor(level).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 message,
//                 style: TextStyle(color: Colors.grey[700], fontSize: 14),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'This will immediately notify the security team and relevant personnel. Are you sure you want to send this alert?',
//               style: TextStyle(color: Colors.grey[600], fontSize: 13),
//             ),
//           ],
//         ),
//       ),
//     ),

//     actions: [
//       TextButton(
//         onPressed: () => Navigator.of(context).pop(),
//         child: const Text('Cancel'),
//       ),
//       ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _getAlertColor(level),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         onPressed: () async {
//           try {
//             // ✅ Cache providers and values first
//             final alertNotifier = ref.read(alertViewModelProvider.notifier);
//             final directoryNotifier =
//                 ref.read(directoryViewModelProvider.notifier);
//             final broadcastNotifier =
//                 ref.read(broadcastViewModelProvider.notifier);
//             final basicInfo = ref.read(basicInfoViewModelProvider);

//             final flatId = basicInfo.flatId ?? 0;
//             final societyId = basicInfo.societyID ?? "";
//             final ownerId = basicInfo.ownerId ?? 0;
//             final unit = basicInfo.unit ?? "";

//             // 🧩 Step 1: Create the alert
//             final alertResponse = await alertNotifier.addAlertMessage(
//               flatId,
//               alertType,
//               societyId,
//             );

//             final result = alertResponse?['success'] == true;
//             final securityId = alertResponse?['securityId'] ?? 0;

//             debugPrint("✅ Alert created successfully. Security ID: $securityId");

//             if (!result) {
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Failed to create alert')),
//                 );
//               }
//               return;
//             }

//             // 🧩 Step 2: Load all tokens
//             final tokenResult = await directoryNotifier.loadAllTokens(societyId);
//             final tokenState = ref.read(directoryViewModelProvider);
//             final tokens = tokenState.allTokens.asData?.value ?? [];
//             final tokenList = tokens.map((e) => e.webToken ?? '').toList();
//             debugPrint('✅ Tokens fetched: $tokenList');

//             // 🧩 Step 3: Insert notifications
//             for (final token in tokens) {
//               final broadcast = Broadcast(
//                 societyId: societyId,
//                 title: "Security Alert",
//                 body: "An alert has been raised from Unit: $unit",
//                 userType: "Member",
//                 userId: token.userId,
//                 notificationType: "Alert",
//                 seenStatus: 0,
//                 notificationId: securityId,
//                 ownerId: ownerId,
//               );

//               await broadcastNotifier.insertNotification(broadcast);
//             }
// debugPrint("title:$alertTitle");
// debugPrint("body:An $alertTitle alert has been raise");
//             // 🧩 Step 4: Send push notification
//             final notification = SendNotification(
//               tokens: tokenList,
//               title: "Security Alert",
//               body: "An $alertTitle alert has been raised from Unit: $unit",
//             );

//             await alertNotifier.sendNotification(notification);

//             debugPrint("✅ All notifications sent successfully.");

//             // ✅ Step 5: Only now close the dialog
//             if (context.mounted) {
//               Navigator.of(context).pop();
//               _processSecurityAlert(alertTitle, message, level, context);
//             }
//           } catch (e, st) {
//             debugPrint("❌ Error sending alert: $e\n$st");
//             if (context.mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Failed to send alert: $e')),
//               );
//             }
//           }
//         },
//         child: const Text(
//           'Send Alert',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//     ],
//   );
// }
//   IconData _getAlertIcon(AlertLevel level) {
//     switch (level) {
//       case AlertLevel.critical:
//         return Icons.warning;
//       case AlertLevel.high:
//         return Icons.priority_high;
//       case AlertLevel.medium:
//         return Icons.info;
//     }
//   }

//   Color _getAlertColor(AlertLevel level) {
//     switch (level) {
//       case AlertLevel.critical:
//         return Colors.red[600]!;
//       case AlertLevel.high:
//         return Colors.orange[600]!;
//       case AlertLevel.medium:
//         return Colors.blue[600]!;
//     }
//   }

//   void _showAlertDetails(
//     BuildContext context,
//     String alertType,
//     String message,
//     AlertLevel level,
//   ) {
//     showDialog(
//       context: context,
//       requestFocus: true,
//       builder: (BuildContext ctx) => AlertDetailsDialog(
//         alertType: alertType,
//         message: message,
//         level: level,
//       ),
//     );
//   }
// }

// Alert Details Dialog
class AlertDetailsDialog extends StatelessWidget {
  final String alertType;
  final String message;
  final AlertLevel level;

  const AlertDetailsDialog({
    super.key,
    required this.alertType,
    required this.message,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("Showing details for $alertType alert.");
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Alert Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getAlertIcon(), color: _getAlertColor()),
              SizedBox(width: 8),
              Text(
                alertType,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(message),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sent',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Time: ${DateTime.now().toString().substring(0, 16)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    );
  }

  IconData _getAlertIcon() {
    switch (level) {
      case AlertLevel.critical:
        return Icons.warning;
      case AlertLevel.high:
        return Icons.priority_high;
      case AlertLevel.medium:
        return Icons.info;
    }
  }

  Color _getAlertColor() {
    switch (level) {
      case AlertLevel.critical:
        return Colors.red[600]!;
      case AlertLevel.high:
        return Colors.orange[600]!;
      case AlertLevel.medium:
        return Colors.blue[600]!;
    }
  }
}

// Animated Card Components (unchanged from previous version)
class AnimatedOptionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const AnimatedOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  _AnimatedOptionCardState createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<AnimatedOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 32, color: widget.iconColor),
                  SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedAlertCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const AnimatedAlertCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  _AnimatedAlertCardState createState() => _AnimatedAlertCardState();
}

class _AnimatedAlertCardState extends State<AnimatedAlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(16),
              //color: Colors.white,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 28, color: widget.iconColor),
                  SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
