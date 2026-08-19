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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasShownCheckInMessage = false;
  
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    _initPushNotifications();
    Future.microtask(() async {
      debugPrint(ref.read(securitymodelProvider).userId.toString());
    });
  }

  Future<void> _initPushNotifications() async {
    NotificationSettings settings = await ref
        .read(firebaseMessagingProvider)
        .requestPermission();

    await ref.read(visitormodelProvider.notifier).insertToken(ref.read(securitymodelProvider).userId != null ? int.parse( ref.read(securitymodelProvider).userId!): 0);
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

  void _clearOTPFields() {
  // Clear all text controllers
  setState(() {
    for (var controller in _codeControllers) {
      controller.clear();
    }
  });
  
  // Unfocus current field first
  FocusScope.of(context).unfocus();
  
  // Focus on the first field after a brief delay
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      // Request focus for the first text field
      FocusScope.of(context).requestFocus(FocusNode());
      // The first field will automatically get focus when user taps
    }
  });
}

  Future<Map<String, dynamic>?> _validateOTPAndGetDetails(
    String otpCode,
  ) async {
    try {
      ref
          .read(visitormodelProvider.notifier)
          .getVisitorList(ref.read(securitymodelProvider).SocietyId ?? '');
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

    return visitors.maybeWhen(
      data: (list) {
        final v = list.firstWhereOrNull(
          (x) => x.gateOtp?.toString() == otpCode,
        );

        if (v == null) return null;
        _clearOTPFields();
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
    String enteredCode = _codeControllers
        .map((controller) => controller.text)
        .join();

    if (enteredCode.length == 6) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2E3B62),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Validating OTP...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      try {
        Map<String, dynamic>? visitorDetails = await _validateOTPAndGetDetails(
          enteredCode,
        );
        Navigator.of(context).pop();

        if (visitorDetails != null) {
          DateTime validUntil = visitorDetails['validUntil'];
          if (DateTime.now().isAfter(validUntil)) {
            _showErrorDialog('OTP has expired. Please generate a new one.');
            return;
          }

          String entryType =
              visitorDetails['entryType'] ??
              _determineEntryTypeFromOTP(enteredCode);

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
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please enter a complete 6-digit code',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red[600],
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3B62),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
          Map<String, dynamic>? visitorDetails =
              await _validateOTPAndGetDetails(otp);

          if (visitorDetails != null) {
            visitorDetails.addAll({'scannedName': name, 'scannedFlat': flat});
            String entryType =
                visitorDetails['entryType'] ?? _determineEntryTypeFromOTP(otp);

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
            _showErrorDialog(
              'Invalid QR code. The OTP may have expired or is incorrect.',
            );
          }
        } else {
          _showErrorDialog(
            'Invalid QR code format. Please scan a valid visitor QR code.',
          );
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
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;
                  
                  // More granular screen size detection
                  final isExtraSmall = screenWidth < 320;
                  final isUltraSmall = screenWidth < 360;
                  final isSmallScreen = screenWidth < 400 || screenHeight < 700;
                  
                  // Tighter padding for smaller screens
                  double padding;
                  if (screenWidth < 320) {
                    padding = 6.0;
                  } else if (screenWidth < 340) {
                    padding = 8.0;
                  } else if (screenWidth < 360) {
                    padding = 10.0;
                  } else if (screenWidth < 380) {
                    padding = 12.0;
                  } else if (isSmallScreen) {
                    padding = 16.0;
                  } else {
                    padding = 20.0;
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVisitorEntrySection(
                          context,
                          isSmallScreen,
                          isUltraSmall,
                          isExtraSmall,
                          isCheckedIn,
                          screenWidth,
                        ),
                        SizedBox(height: padding * 1.2),
                        _buildAddVisitorSection(isSmallScreen, isUltraSmall, isExtraSmall),
                        SizedBox(height: padding * 1.2),
                        _buildVisitorGrid(
                          isSmallScreen,
                          isUltraSmall,
                          isExtraSmall,
                          isCheckedIn,
                          screenWidth,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (!isCheckedIn)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Please check in to access visitor entry features',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E3B62),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Check in Required',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E3B62).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                backgroundColor: const Color(0xFF2E3B62),
                mini: MediaQuery.of(context).size.width < 340,
                elevation: 0,
                child: Icon(
                  Icons.security,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width < 340 ? 20 : 24,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildVisitorEntrySection(
    BuildContext context,
    bool isSmallScreen,
    bool isUltraSmall,
    bool isExtraSmall,
    bool isEnabled,
    double screenWidth,
  ) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !isEnabled,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, const Color(0xFFF0F4FF)],
            ),
            borderRadius: BorderRadius.circular(isExtraSmall ? 12 : (isUltraSmall ? 16 : 20)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E3B62).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF2E3B62).withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isExtraSmall ? 12 : (isUltraSmall ? 16 : 20)),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2E3B62).withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(isExtraSmall ? 12 : (isUltraSmall ? 16 : (isSmallScreen ? 20 : 24))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isExtraSmall ? 6 : 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E3B62).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_pin_circle_outlined,
                              color: const Color(0xFF2E3B62),
                              size: isExtraSmall ? 16 : (isUltraSmall ? 20 : 24),
                            ),
                          ),
                          SizedBox(width: isExtraSmall ? 6 : (isUltraSmall ? 10 : 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visitor Entry',
                                  style: TextStyle(
                                    fontSize: isExtraSmall ? 16 : (isUltraSmall ? 20 : (isSmallScreen ? 22 : 26)),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E3B62),
                                  ),
                                ),
                                Text(
                                  isExtraSmall ? 'Enter code' : (isUltraSmall ? 'Enter or scan' : 'Enter code or scan QR'),
                                  style: TextStyle(
                                    fontSize: isExtraSmall ? 11 : (isUltraSmall ? 13 : (isSmallScreen ? 14 : 16)),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isExtraSmall ? 12 : (isUltraSmall ? 16 : (isSmallScreen ? 18 : 24))),

                      // OTP Input Fields - FULLY RESPONSIVE FOR ALL MOBILE SCREENS
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate available width with safety margin
                          final availableWidth = constraints.maxWidth - 8; // 8px safety margin
                          
                          // Calculate optimal box size to fit perfectly
                          // Formula: (availableWidth - totalSpacing) / 6 boxes
                          // We want minimum 3px spacing between boxes
                          final minSpacing = 3.0;
                          final totalMinSpacing = minSpacing * 5; // 5 gaps
                          
                          // Calculate max possible box size
                          double calculatedBoxSize = (availableWidth - totalMinSpacing) / 6;
                          
                          // Clamp between reasonable sizes
                          double boxSize = calculatedBoxSize.clamp(30.0, 48.0);
                          
                          // Recalculate spacing based on actual box size
                          final totalBoxWidth = boxSize * 6;
                          final remainingSpace = availableWidth - totalBoxWidth;
                          final spacing = (remainingSpace / 5).clamp(2.0, 8.0);
                          
                          // Dynamic font size based on box size
                          double fontSize;
                          if (boxSize < 34) {
                            fontSize = 13.0;
                          } else if (boxSize < 38) {
                            fontSize = 15.0;
                          } else if (boxSize < 42) {
                            fontSize = 17.0;
                          } else {
                            fontSize = 20.0;
                          }
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              6,
                              (index) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: boxSize,
                                      height: boxSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _codeControllers[index].text.isNotEmpty
                                              ? const Color(0xFF2E3B62)
                                              : Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                        boxShadow: _codeControllers[index].text.isNotEmpty
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF2E3B62).withOpacity(0.1),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: TextField(
                                        controller: _codeControllers[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E3B62),
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
                                    if (index < 5) SizedBox(width: spacing),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isExtraSmall ? 12 : (isUltraSmall ? 16 : (isSmallScreen ? 18 : 24))),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleOTPConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E3B62),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isUltraSmall ? 12 : (isSmallScreen ? 14 : 16),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                shadowColor: const Color(
                                  0xFF2E3B62,
                                ).withOpacity(0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: isExtraSmall ? 14 : (isUltraSmall ? 16 : 18),
                                  ),
                                  SizedBox(width: isExtraSmall ? 4 : (isUltraSmall ? 6 : 8)),
                                  Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontSize: isExtraSmall ? 13 : (isUltraSmall ? 15 : (isSmallScreen ? 16 : 18)),
                          
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: isExtraSmall ? 6 : (isUltraSmall ? 8 : 12)),
                          Container(
                            width: isExtraSmall ? 40 : (isUltraSmall ? 44 : (isSmallScreen ? 48 : 56)),
                            height: isExtraSmall ? 40 : (isUltraSmall ? 44 : (isSmallScreen ? 48 : 56)),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A5F8C), Color(0xFF2E3B62)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2E3B62,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleQRScan,
                                borderRadius: BorderRadius.circular(12),
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Colors.white,
                                                                    size: isExtraSmall ? 18 : (isUltraSmall ? 20 : (isSmallScreen ? 22 : 26)),
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

  Widget _buildAddVisitorSection(bool isSmallScreen, bool isUltraSmall, bool isExtraSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isExtraSmall ? 4 : (isUltraSmall ? 5 : 6)),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3B62).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_add_outlined,
              size: isExtraSmall ? 14 : (isUltraSmall ? 16 : 20),
              color: const Color(0xFF2E3B62),
            ),
          ),
          SizedBox(width: isExtraSmall ? 6 : (isUltraSmall ? 8 : 10)),
          Flexible(
            child: Text(
              'Add New Visitor',
              style: TextStyle(
                fontSize: isExtraSmall ? 16 : (isUltraSmall ? 18 : (isSmallScreen ? 20 : 24)),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E3B62),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorGrid(
    bool isSmallScreen,
    bool isUltraSmall,
    bool isExtraSmall,
    bool isEnabled,
    double screenWidth,
  ) {
    // Dynamic spacing - tighter for smaller screens
    double crossAxisSpacing;
    double mainAxisSpacing;
    
    if (screenWidth < 340) {
      crossAxisSpacing = 6.0;
      mainAxisSpacing = 6.0;
    } else if (screenWidth < 360) {
      crossAxisSpacing = 8.0;
      mainAxisSpacing = 8.0;
    } else if (screenWidth < 400) {
      crossAxisSpacing = 10.0;
      mainAxisSpacing = 10.0;
    } else {
      crossAxisSpacing = 12.0;
      mainAxisSpacing = 12.0;
    }
    
    // More aggressive aspect ratio - makes cards shorter/wider
    double aspectRatio;
    if (screenWidth < 320) {
      aspectRatio = 2.2; // Very short cards
    } else if (screenWidth < 340) {
      aspectRatio = 2.0; // Short cards for 320-340px
    } else if (screenWidth < 360) {
      aspectRatio = 1.8;
    } else if (screenWidth < 380) {
      aspectRatio = 1.6;
    } else if (screenWidth < 400) {
      aspectRatio = 1.45;
    } else if (isSmallScreen) {
      aspectRatio = 1.35;
    } else {
      aspectRatio = 1.25;
    }

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !isEnabled,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: aspectRatio,
          children: [
            _buildVisitorTypeCard(
              'Guest Entry',
              Icons.person_outline,
              Colors.green.shade600,
              isSmallScreen,
              isUltraSmall,
              isExtraSmall,
              screenWidth,
            ),
            _buildVisitorTypeCard(
              'Cab Entry',
              Icons.local_taxi_outlined,
              Colors.orange.shade600,
              isSmallScreen,
              isUltraSmall,
              isExtraSmall,
              screenWidth,
            ),
            _buildVisitorTypeCard(
              'Delivery Entry',
              Icons.delivery_dining_outlined,
              Colors.red.shade600,
              isSmallScreen,
              isUltraSmall,
              isExtraSmall,
              screenWidth,
            ),
            _buildVisitorTypeCard(
              'Service Entry',
              Icons.build_outlined,
              Colors.blue.shade600,
              isSmallScreen,
              isUltraSmall,
              isExtraSmall,
              screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorTypeCard(
    String title,
    IconData icon,
    Color statusColor,
    bool isSmallScreen,
    bool isUltraSmall,
    bool isExtraSmall,
    double screenWidth,
  ) {
    // More aggressive size reduction for small screens
    double iconRadius;
    double iconSize;
    double fontSize;
    double horizontalPadding;
    double verticalPadding;
    double spacingBetween;
    
    if (screenWidth < 320) {
      iconRadius = 16;
      iconSize = 25;
      fontSize = 9;
      horizontalPadding = 4;
      verticalPadding = 6;
      spacingBetween = 3;
    } else if (screenWidth < 340) {
      iconRadius = 18;
      iconSize = 18;
      fontSize = 10;
      horizontalPadding = 6;
      verticalPadding = 8;
      spacingBetween = 4;
    } else if (screenWidth < 360) {
      iconRadius = 20;
      iconSize = 20;
      fontSize = 11;
      horizontalPadding = 8;
      verticalPadding = 10;
      spacingBetween = 5;
    } else if (screenWidth < 380) {
      iconRadius = 22;
      iconSize = 22;
      fontSize = 12;
      horizontalPadding = 10;
      verticalPadding = 12;
      spacingBetween = 6;
    } else if (isSmallScreen) {
      iconRadius = 24;
      iconSize = 24;
      fontSize = 13;
      horizontalPadding = 10;
      verticalPadding = 12;
      spacingBetween = 7;
    } else {
      iconRadius = 28;
      iconSize = 28;
      fontSize = 15;
      horizontalPadding = 12;
      verticalPadding = 14;
      spacingBetween = 8;
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToEntryPage(title),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.15),
                    radius: iconRadius,
                    child: Icon(
                      icon,
                      color: statusColor,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: spacingBetween),
                  
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
