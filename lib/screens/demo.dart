
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:security_app/presentation/providers/viewModel_provider.dart';
// import 'package:security_app/screens/add_visitors.dart';
// import 'package:security_app/screens/qr_scanner_page.dart';
// import 'package:collection/collection.dart';
// import 'package:security_app/screens/securityalert_dialog.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
//   final List<TextEditingController> _codeControllers = List.generate(
//     6,
//     (index) => TextEditingController(),
//   );

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void dispose() {
//     for (var controller in _codeControllers) {
//       controller.dispose();
//     }
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
    
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.15),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
//     _animationController.forward();
    
//     _initPushNotifications();
//     Future.microtask(() async {
//       debugPrint(ref.read(securitymodelProvider).userId.toString());
//       ref.read(visitormodelProvider.notifier).getVisitorList("C10001");
//     });
//   }

//   Future<void> _initPushNotifications() async {
//     NotificationSettings settings = await ref
//         .read(firebaseMessagingProvider)
//         .requestPermission();
//     debugPrint("token inserted1: ${settings.authorizationStatus == AuthorizationStatus.authorized}");

//     await ref.read(visitormodelProvider.notifier).insertToken(ref.read(securitymodelProvider).userId != null ? int.parse( ref.read(securitymodelProvider).userId!): 0);

//     debugPrint("token inserted");
//   }

//   String _determineEntryTypeFromOTP(String otpCode) {
//     if (otpCode.startsWith('1')) {
//       return 'Guest Entry';
//     } else if (otpCode.startsWith('2')) {
//       return 'Cab Entry';
//     } else if (otpCode.startsWith('3')) {
//       return 'Delivery Entry';
//     } else if (otpCode.startsWith('4')) {
//       return 'Service Entry';
//     } else {
//       return 'Guest Entry';
//     }
//   }

//   Future<Map<String, dynamic>?> _validateOTPAndGetDetails(String otpCode) async {
//     try {
//       ref.read(visitormodelProvider.notifier).getVisitorList("C10001");
//       await Future.delayed(const Duration(seconds: 1));
//       debugPrint('Validating OTP: $otpCode');
//       Map<String, dynamic>? visitorDetails = await _validateOTP(otpCode);
//       return visitorDetails;
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> _validateOTP(String otpCode) async {
//     final visitors = ref.read(visitormodelProvider).visitorsList;

//     for(var v  in visitors.value ?? []) {
//       debugPrint("Visitor OTP: ${v.toString()}");
//     }
//     return visitors.maybeWhen(
//       data: (list) {
//         final v = list.firstWhereOrNull(
//           (x) => x.gateOtp?.toString() == otpCode,
//         );

//         if (v == null) return null;

//         return {
//           'v_id': v.visitorId,
//           'name': v.name ?? v.userName ?? '',
//           'phone': v.contactNo,
//           'entryType': v.type,
//           'flat': v.flatId.toString(),
//           'vehicleNumber': v.vehicleNo,
//           'company': v.company,
//           'ownerType': v.ownerType,
//           'status': v.status,
//           'validUntil': DateTime.now().add(const Duration(hours: 2)),
//         };
//       },
//       orElse: () => null,
//     );
//   }

//   void _handleOTPConfirm() async {
//     String enteredCode = _codeControllers.map((controller) => controller.text).join();

//     if (enteredCode.length == 6) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return Dialog(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             child: Container(
//               padding: const EdgeInsets.all(32),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 30,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                       ),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Center(
//                       child: SizedBox(
//                         width: 30,
//                         height: 30,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 3,
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     "Validating OTP...",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF1A1A2E),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "Please wait a moment",
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );

//       try {
//         Map<String, dynamic>? visitorDetails = await _validateOTPAndGetDetails(enteredCode);
//         Navigator.of(context).pop();

//         if (visitorDetails != null) {
//           DateTime validUntil = visitorDetails['validUntil'];
//           if (DateTime.now().isAfter(validUntil)) {
//             _showErrorDialog('OTP has expired. Please generate a new one.');
//             return;
//           }

//           String entryType = visitorDetails['entryType'] ?? _determineEntryTypeFromOTP(enteredCode);

//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => EntryPage(
//                 entryType: entryType,
//                 isOTPEntry: true,
//                 enteredCode: enteredCode,
//                 prefilledData: visitorDetails,
//               ),
//             ),
//           );
//         } else {
//           _showErrorDialog('Invalid OTP. Please check and try again.');
//         }
//       } catch (e) {
//         Navigator.of(context).pop();
//         _showErrorDialog('Failed to validate OTP. Please try again.: $e');
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Text(
//                   'Please enter a complete 6-digit code',
//                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ],
//           ),
//           backgroundColor: const Color(0xFFFF6B6B),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           margin: const EdgeInsets.all(16),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           child: Container(
//             padding: const EdgeInsets.all(28),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(28),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 30,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 70,
//                   height: 70,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFFEBEE),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.error_outline_rounded,
//                     color: Color(0xFFFF6B6B),
//                     size: 36,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Oops!',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1A1A2E),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   message,
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: Colors.grey[700],
//                     height: 1.5,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 28),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF667EEA),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: const Text(
//                       'Got it',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _handleQRScan() async {
//     try {
//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const QrScannerPage()),
//       );

//       if (result != null && result is Map<String, dynamic>) {
//         String otp = result['otp'] ?? '';
//         String name = result['name'] ?? '';
//         String flat = result['flat'] ?? '';

//         if (otp.isNotEmpty) {
//           Map<String, dynamic>? visitorDetails = await _validateOTPAndGetDetails(otp);

//           if (visitorDetails != null) {
//             visitorDetails.addAll({'scannedName': name, 'scannedFlat': flat});
//             String entryType = visitorDetails['entryType'] ?? _determineEntryTypeFromOTP(otp);

//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => EntryPage(
//                   entryType: entryType,
//                   isOTPEntry: true,
//                   enteredCode: otp,
//                   prefilledData: visitorDetails,
//                 ),
//               ),
//             );
//           } else {
//             _showErrorDialog('Invalid QR code. The OTP may have expired or is incorrect.');
//           }
//         } else {
//           _showErrorDialog('Invalid QR code format. Please scan a valid visitor QR code.');
//         }
//       }
//     } catch (e) {
//       _showErrorDialog('Failed to scan QR code. Please try again.');
//     }
//   }

//   void _navigateToEntryPage(String entryType) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => EntryPage(entryType: entryType)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isCheckedIn = ref.watch(staffmodelProvider).isCheckedIn;
    
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           // Modern gradient background
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Colors.white,
//                   Colors.white,
//                 ],
//               ),
//             ),
//           ),
          
//           // Decorative circles
//           Positioned(
//             top: -100,
//             right: -100,
//             child: Container(
//               width: 300,
//               height: 300,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: RadialGradient(
//                   colors: [
//                     const Color(0xFF667EEA).withOpacity(0.1),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),
//           ),
          
//           FadeTransition(
//             opacity: _fadeAnimation,
//             child: SlideTransition(
//               position: _slideAnimation,
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   final screenWidth = constraints.maxWidth;
//                   final isSmallScreen = screenWidth < 360;
//                   final padding = isSmallScreen ? 16.0 : 20.0;

//                   return SingleChildScrollView(
//                     padding: EdgeInsets.all(padding),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // const SizedBox(height: 20),
//                         // _buildHeader(isSmallScreen),
//                        // const SizedBox(height: 32),
//                         _buildVisitorEntrySection(
//                           context,
//                           isSmallScreen,
//                           isCheckedIn,
//                         ),
//                         const SizedBox(height: 32),
//                         _buildSectionTitle('Quick Actions', isSmallScreen),
//                         const SizedBox(height: 16),
//                         _buildVisitorGrid(
//                           isSmallScreen,
//                           isCheckedIn,
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
          
//           // Overlay for disabled state
//           if (!isCheckedIn)
//             Positioned.fill(
//               child: GestureDetector(
//                 onTap: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
//                           ),
//                           const SizedBox(width: 12),
//                           const Expanded(
//                             child: Text(
//                               'Please check in to access features',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       backgroundColor: const Color(0xFF667EEA),
//                       behavior: SnackBarBehavior.floating,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       margin: const EdgeInsets.all(16),
//                       duration: const Duration(seconds: 3),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                   ),
//                   child: Center(
//                     child: Container(
//                       margin: const EdgeInsets.all(32),
//                       padding: const EdgeInsets.all(32),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(28),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 30,
//                             offset: const Offset(0, 15),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             width: 80,
//                             height: 80,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                               ),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.lock_outline,
//                               size: 40,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 24),
//                           const Text(
//                             'Check In Required',
//                             style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1A1A2E),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             'Please check in to access all features\nand manage visitor entries',
//                             style: TextStyle(
//                               fontSize: 15,
//                               color: Colors.grey[600],
//                               height: 1.5,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: isCheckedIn
//           ? Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(20),
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFFFF6B6B).withOpacity(0.4),
//                     blurRadius: 20,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: FloatingActionButton(
//                 onPressed: () {
//                   showDialog(
//                     context: context,
//                     builder: (context) => const SecurityAlertDialog(),
//                   );
//                 },
//                 backgroundColor: Colors.transparent,
//                 elevation: 0,
//                 child: const Icon(
//                   Icons.shield_outlined,
//                   color: Colors.white,
//                   size: 28,
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   Widget _buildHeader(bool isSmallScreen) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF667EEA).withOpacity(0.3),
//                     blurRadius: 20,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.security_rounded,
//                 color: Colors.white,
//                 size: 28,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Security Hub',
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 26 : 30,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF1A1A2E),
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Visitor Management',
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 14 : 15,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildVisitorEntrySection(
//     BuildContext context,
//     bool isSmallScreen,
//     bool isEnabled,
//   ) {
//     return Opacity(
//       opacity: isEnabled ? 1.0 : 0.5,
//       child: AbsorbPointer(
//         absorbing: !isEnabled,
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white,
//                        Colors.white,
//               ],
//             ),
//             borderRadius: BorderRadius.circular(24),
//             // boxShadow: [
//             //   BoxShadow(
//             //     color: const Color(0xFF667EEA).withOpacity(0.15),
//             //     blurRadius: 30,
//             //     offset: const Offset(0, 15),
//             //   ),
//             // ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(24),
//             child: Stack(
//               children: [
//                 // Decorative circles
//                 Positioned(
//                   right: -50,
//                   top: -50,
//                   child: Container(
//                     width: 150,
//                     height: 150,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: RadialGradient(
//                         colors: [
//                           //const Color(0xFF667EEA).withOpacity(0.1),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
                
//                 Padding(
//                   padding: const EdgeInsets.all(28),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             // decoration: BoxDecoration(
//                             //   gradient: LinearGradient(
//                             //     colors: [Color(0xFF667EEA).withOpacity(0.2), Color(0xFF764BA2).withOpacity(0.2)],
//                             //   ),
//                             //   borderRadius: BorderRadius.circular(14),
//                             // ),
//                             child: const Icon(
//                               Icons.qr_code_2_rounded,
//                               color: Color(0xFF667EEA),
//                               size: 28,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Visitor Entry',
//                                   style: TextStyle(
//                                     fontSize: isSmallScreen ? 22 : 24,
//                                     fontWeight: FontWeight.bold,
//                                     color: const Color(0xFF1A1A2E),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Enter OTP code or scan QR',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey[600],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 28),

//                       // OTP Input Fields
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: List.generate(
//                           6,
//                           (index) => Expanded(
//                             child: Container(
//                               margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
//                               height: isSmallScreen ? 56 : 64,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(16),
//                                 border: Border.all(
//                                   color: _codeControllers[index].text.isNotEmpty
//                                       ? const Color(0xFF667EEA)
//                                       : Colors.grey[300]!,
//                                   width: 2,
//                                 ),
//                                 // boxShadow: _codeControllers[index].text.isNotEmpty
//                                 //     ? [
//                                 //         BoxShadow(
//                                 //           color: const Color(0xFF667EEA).withOpacity(0.2),
//                                 //           blurRadius: 12,
//                                 //           offset: const Offset(0, 4),
//                                 //         ),
//                                 //       ]
//                                 //     : [],
//                               ),
//                               child: TextField(
//                                 controller: _codeControllers[index],
//                                 textAlign: TextAlign.center,
//                                 keyboardType: TextInputType.number,
//                                 maxLength: 1,
//                                 style: TextStyle(
//                                   fontSize: isSmallScreen ? 22 : 26,
//                                   fontWeight: FontWeight.bold,
//                                   color: const Color(0xFF667EEA),
//                                 ),
//                                 decoration: const InputDecoration(
//                                   counterText: '',
//                                   border: InputBorder.none,
//                                   contentPadding: EdgeInsets.zero,
//                                 ),
//                                 onChanged: (value) {
//                                   setState(() {});
//                                   if (value.length == 1) {
//                                     if (index < 5) {
//                                       FocusScope.of(context).nextFocus();
//                                     } else {
//                                       FocusScope.of(context).unfocus();
//                                       _handleOTPConfirm();
//                                     }
//                                   } else if (value.isEmpty && index > 0) {
//                                     FocusScope.of(context).previousFocus();
//                                   }
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 28),

//                       // Action Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 3,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                                 ),
//                                 borderRadius: BorderRadius.circular(16),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: const Color(0xFF667EEA).withOpacity(0.4),
//                                     blurRadius: 20,
//                                     offset: const Offset(0, 10),
//                                   ),
//                                 ],
//                               ),
//                               child: ElevatedButton(
//                                 onPressed: _handleOTPConfirm,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.transparent,
//                                   foregroundColor: Colors.white,
//                                   shadowColor: Colors.transparent,
//                                   padding: EdgeInsets.symmetric(
//                                     vertical: isSmallScreen ? 16 : 18,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(Icons.check_circle_rounded, size: 22),
//                                     const SizedBox(width: 10),
//                                     Text(
//                                       'Confirm Entry',
//                                       style: TextStyle(
//                                         fontSize: isSmallScreen ? 16 : 17,
//                                         fontWeight: FontWeight.w600,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Container(
//                             width: isSmallScreen ? 56 : 64,
//                             height: isSmallScreen ? 56 : 64,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
//                               ),
//                               borderRadius: BorderRadius.circular(16),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: const Color(0xFF43E97B).withOpacity(0.4),
//                                   blurRadius: 20,
//                                   offset: const Offset(0, 10),
//                                 ),
//                               ],
//                             ),
//                             child: Material(
//                               color: Colors.transparent,
//                               child: InkWell(
//                                 onTap: _handleQRScan,
//                                 borderRadius: BorderRadius.circular(16),
//                                 child: const Center(
//                                   child: Icon(
//                                     Icons.qr_code_scanner_rounded,
//                                     color: Colors.white,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title, bool isSmallScreen) {
//     return Row(
//       children: [
//         Container(
//           width: 4,
//           height: 24,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//             ),
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: isSmallScreen ? 20 : 22,
//             fontWeight: FontWeight.bold,
//             color: const Color(0xFF1A1A2E),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildVisitorGrid(bool isSmallScreen, bool isEnabled) {
//     return Opacity(
//       opacity: isEnabled ? 1.0 : 0.5,
//       child: AbsorbPointer(
//         absorbing: !isEnabled,
//         child: GridView.count(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           childAspectRatio: 1.1,
//           children: [
//             _buildVisitorTypeCard(
//               'Guest Entry',
//               Icons.person_rounded,
//               [Color(0xFFFA709A), Color(0xFFFF8C94)],
//               isSmallScreen,
//             ),
//             _buildVisitorTypeCard(
//               'Cab Entry',
//               Icons.local_taxi_rounded,
//               [Color(0xFFFEAC5E), Color(0xFFFFC371)],
//               isSmallScreen,
//             ),
//             _buildVisitorTypeCard(
//               'Delivery Entry',
//               Icons.delivery_dining_rounded,
//               [Color(0xFF4FACFE), Color(0xFF00F2FE)],
//               isSmallScreen,
//             ),
//             _buildVisitorTypeCard(
//               'Service Entry',
//               Icons.build_circle_rounded,
//               [Color(0xFF43E97B), Color(0xFF38F9D7)],
//               isSmallScreen,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVisitorTypeCard(
//     String title,
//     IconData icon,
//     List<Color> gradientColors,
//     bool isSmallScreen,
//   ) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () => _navigateToEntryPage(title),
//         borderRadius: BorderRadius.circular(24),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: gradientColors[0].withOpacity(0.2),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Stack(
//             children: [
//               // Gradient circle decoration
//               Positioned(
//                 right: -30,
//                 top: -30,
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     // gradient: RadialGradient(
//                     //   colors: [
//                     //     gradientColors[0].withOpacity(0.15),
//                     //     Colors.transparent,
//                     //   ],
//                     // ),
//                   ),
//                 ),
//               ),
              
//               Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: isSmallScreen ? 60 : 70,
//                       height: isSmallScreen ? 60 : 70,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: gradientColors,
//                         ),
//                         borderRadius: BorderRadius.circular(20),
//                         // boxShadow: [
//                         //   BoxShadow(
//                         //     color: gradientColors[0].withOpacity(0.4),
//                         //     blurRadius: 15,
//                         //     offset: const Offset(0, 8),
//                         //   ),
//                         // ],
//                       ),
//                       child: Icon(
//                         icon,
//                         size: isSmallScreen ? 32 : 36,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 15 : 16,
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFF1A1A2E),
//                       ),
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/screens/add_visitors.dart';
import 'package:security_app/screens/qr_scanner_page.dart';
import 'package:collection/collection.dart';
import 'package:security_app/screens/securityalert_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
    
    _initPushNotifications();
    Future.microtask(() async {
      debugPrint(ref.read(securitymodelProvider).userId.toString());
      ref.read(visitormodelProvider.notifier).getVisitorList("C10001");
    });
  }

  Future<void> _initPushNotifications() async {
    NotificationSettings settings = await ref
        .read(firebaseMessagingProvider)
        .requestPermission();
    debugPrint("token inserted1: ${settings.authorizationStatus == AuthorizationStatus.authorized}");

    await ref.read(visitormodelProvider.notifier).insertToken(ref.read(securitymodelProvider).userId != null ? int.parse( ref.read(securitymodelProvider).userId!): 0);

    debugPrint("token inserted");
  }

  String _determineEntryTypeFromOTP(String otpCode) {
    if (otpCode.startsWith('1')) {
      return 'Guest Entry';
    } else if (otpCode.startsWith('2')) {
      return 'Cab Entry';
    } else if (otpCode.startsWith('3')) {
      return 'Delivery Entry';
    } else if (otpCode.startsWith('4')) {
      return 'Service Entry';
    } else {
      return 'Guest Entry';
    }
  }

  Future<Map<String, dynamic>?> _validateOTPAndGetDetails(String otpCode) async {
    try {
      ref.read(visitormodelProvider.notifier).getVisitorList("C10001");
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Validating OTP: $otpCode');
      Map<String, dynamic>? visitorDetails = await _validateOTP(otpCode);
      return visitorDetails;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _validateOTP(String otpCode) async {
    final visitors = ref.read(visitormodelProvider).visitorsList;

    for(var v  in visitors.value ?? []) {
      debugPrint("Visitor OTP: ${v.toString()}");
    }
    return visitors.maybeWhen(
      data: (list) {
        final v = list.firstWhereOrNull(
          (x) => x.gateOtp?.toString() == otpCode,
        );

        if (v == null) return null;

        return {
          'v_id': v.visitorId,
          'name': v.name ?? v.userName ?? '',
          'phone': v.contactNo,
          'entryType': v.type,
          'flat': v.flatId.toString(),
          'vehicleNumber': v.vehicleNo,
          'company': v.company,
          'ownerType': v.ownerType,
          'status': v.status,
          'validUntil': DateTime.now().add(const Duration(hours: 2)),
        };
      },
      orElse: () => null,
    );
  }

  void _handleOTPConfirm() async {
    String enteredCode = _codeControllers.map((controller) => controller.text).join();

    if (enteredCode.length == 6) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Validating OTP...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please wait a moment",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      try {
        Map<String, dynamic>? visitorDetails = await _validateOTPAndGetDetails(enteredCode);
        Navigator.of(context).pop();

        if (visitorDetails != null) {
          DateTime validUntil = visitorDetails['validUntil'];
          if (DateTime.now().isAfter(validUntil)) {
            _showErrorDialog('OTP has expired. Please generate a new one.');
            return;
          }

          String entryType = visitorDetails['entryType'] ?? _determineEntryTypeFromOTP(enteredCode);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntryPage(
                entryType: entryType,
                isOTPEntry: true,
                enteredCode: enteredCode,
                prefilledData: visitorDetails,
              ),
            ),
          );
        } else {
          _showErrorDialog('Invalid OTP. Please check and try again.');
        }
      } catch (e) {
        Navigator.of(context).pop();
        _showErrorDialog('Failed to validate OTP. Please try again.: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Please enter a complete 6-digit code',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oops!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleQRScan() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerPage()),
      );

      if (result != null && result is Map<String, dynamic>) {
        String otp = result['otp'] ?? '';
        String name = result['name'] ?? '';
        String flat = result['flat'] ?? '';

        if (otp.isNotEmpty) {
          Map<String, dynamic>? visitorDetails = await _validateOTPAndGetDetails(otp);

          if (visitorDetails != null) {
            visitorDetails.addAll({'scannedName': name, 'scannedFlat': flat});
            String entryType = visitorDetails['entryType'] ?? _determineEntryTypeFromOTP(otp);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EntryPage(
                  entryType: entryType,
                  isOTPEntry: true,
                  enteredCode: otp,
                  prefilledData: visitorDetails,
                ),
              ),
            );
          } else {
            _showErrorDialog('Invalid QR code. The OTP may have expired or is incorrect.');
          }
        } else {
          _showErrorDialog('Invalid QR code format. Please scan a valid visitor QR code.');
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to scan QR code. Please try again.');
    }
  }

  void _navigateToEntryPage(String entryType) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EntryPage(entryType: entryType)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = ref.watch(staffmodelProvider).isCheckedIn;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Modern gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),
          
          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isSmallScreen = screenWidth < 360;
                  final padding = isSmallScreen ? 16.0 : 20.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 20),
                        // _buildHeader(isSmallScreen),
                       // const SizedBox(height: 32),
                        _buildVisitorEntrySection(
                          context,
                          isSmallScreen,
                          isCheckedIn,
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Quick Actions', isSmallScreen),
                        const SizedBox(height: 16),
                        _buildVisitorGrid(
                          isSmallScreen,
                          isCheckedIn,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Overlay for disabled state
          if (!isCheckedIn)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Please check in to access features',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF667EEA),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Check In Required',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Please check in to access all features\nand manage visitor entries',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isCheckedIn
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SecurityAlertDialog(),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Hub',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 26 : 30,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visitor Management',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitorEntrySection(
    BuildContext context,
    bool isSmallScreen,
    bool isEnabled,
  ) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !isEnabled,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                       Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            // boxShadow: [
            //   BoxShadow(
            //     color: const Color(0xFF667EEA).withOpacity(0.15),
            //     blurRadius: 30,
            //     offset: const Offset(0, 15),
            //   ),
            // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          //const Color(0xFF667EEA).withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            // decoration: BoxDecoration(
                            //   gradient: LinearGradient(
                            //     colors: [Color(0xFF667EEA).withOpacity(0.2), Color(0xFF764BA2).withOpacity(0.2)],
                            //   ),
                            //   borderRadius: BorderRadius.circular(14),
                            // ),
                            child: const Icon(
                             Icons.person_pin_circle_outlined,
                              color: const Color(0xFF2E3B62),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visitor Entry',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 22 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enter OTP code or scan QR',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // OTP Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
                              height: isSmallScreen ? 56 : 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _codeControllers[index].text.isNotEmpty
                                      ? const Color(0xFF667EEA)
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                // boxShadow: _codeControllers[index].text.isNotEmpty
                                //     ? [
                                //         BoxShadow(
                                //           color: const Color(0xFF667EEA).withOpacity(0.2),
                                //           blurRadius: 12,
                                //           offset: const Offset(0, 4),
                                //         ),
                                //       ]
                                //     : [],
                              ),
                              child: TextField(
                                controller: _codeControllers[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 22 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF667EEA),
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                  if (value.length == 1) {
                                    if (index < 5) {
                                      FocusScope.of(context).nextFocus();
                                    } else {
                                      FocusScope.of(context).unfocus();
                                      _handleOTPConfirm();
                                    }
                                  } else if (value.isEmpty && index > 0) {
                                    FocusScope.of(context).previousFocus();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667EEA).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _handleOTPConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 16 : 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Confirm Entry',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: isSmallScreen ? 56 : 64,
                            height: isSmallScreen ? 56 : 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF43E97B).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleQRScan,
                                borderRadius: BorderRadius.circular(16),
                                child: const Center(
                                  child: Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorGrid(bool isSmallScreen, bool isEnabled) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !isEnabled,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildVisitorTypeCard(
              'Guest Entry',
              Icons.person_rounded,
              [Color(0xFFFA709A), Color(0xFFFF8C94)],
              isSmallScreen,
            ),
            _buildVisitorTypeCard(
              'Cab Entry',
              Icons.local_taxi_rounded,
              [Color(0xFFFEAC5E), Color(0xFFFFC371)],
              isSmallScreen,
            ),
            _buildVisitorTypeCard(
              'Delivery Entry',
              Icons.delivery_dining_rounded,
              [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              isSmallScreen,
            ),
            _buildVisitorTypeCard(
              'Service Entry',
              Icons.build_circle_rounded,
              [Color(0xFF43E97B), Color(0xFF38F9D7)],
              isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorTypeCard(
    String title,
    IconData icon,
    List<Color> gradientColors,
    bool isSmallScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToEntryPage(title),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient circle decoration
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // gradient: RadialGradient(
                    //   colors: [
                    //     gradientColors[0].withOpacity(0.15),
                    //     Colors.transparent,
                    //   ],
                    // ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isSmallScreen ? 60 : 70,
                      height: isSmallScreen ? 60 : 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: gradientColors[0].withOpacity(0.4),
                        //     blurRadius: 15,
                        //     offset: const Offset(0, 8),
                        //   ),
                        // ],
                      ),
                      child: Icon(
                        icon,
                        size: isSmallScreen ? 32 : 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}