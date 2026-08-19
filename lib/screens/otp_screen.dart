import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/token_response.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/presentation/viewModels/auth_model.dart';
import 'package:security_app/screens/mainScreen.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String mobileNumber;

  const OTPVerificationScreen({
    super.key,
    required this.mobileNumber
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 30;

  // Modern Color Palette matching CHS Hub
  static const Color primaryBlue = Color(0xFF4A5FBF);
  static const Color darkBlue = Color(0xFF2E3F7F);
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color warningRed = Color(0xFFE53E3E);
  static const Color successGreen = Color(0xFF38A169);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // More granular screen size detection
    final isExtraSmall = screenWidth < 340;
    final isSmallScreen = screenWidth < 380 || screenHeight < 700;
    final isVerySmallScreen = screenHeight < 650;
    final isTinyScreen = screenHeight < 600;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryBlue,
              darkBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button - Fixed height
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 320 ? 12.0 : (screenWidth < 340 ? 14.0 : (screenWidth < 360 ? 18.0 : 24.0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isTinyScreen ? 8 : (isVerySmallScreen ? 12 : (isSmallScreen ? 20 : 32))),
                        
                        // Header Section
                        _buildHeaderSection(
                          isSmallScreen, 
                          isVerySmallScreen, 
                          isTinyScreen, 
                          isExtraSmall,
                          screenWidth,
                        ),
                        
                        SizedBox(height: isTinyScreen ? 16 : (isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 32))),
                        
                        // OTP Form Card
                        _buildOTPCard(
                          isSmallScreen, 
                          isVerySmallScreen, 
                          isTinyScreen, 
                          isExtraSmall,
                          screenWidth,
                        ),
                        
                        SizedBox(height: isTinyScreen ? 16 : (isVerySmallScreen ? 20 : 28)),
                      ],
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

  Widget _buildHeaderSection(
    bool isSmallScreen, 
    bool isVerySmallScreen, 
    bool isTinyScreen, 
    bool isExtraSmall,
    double screenWidth,
  ) {
    final iconSize = isTinyScreen ? 48.0 : (isVerySmallScreen ? 56.0 : (isExtraSmall ? 64.0 : (isSmallScreen ? 72.0 : 88.0)));
    final iconInnerSize = isTinyScreen ? 24.0 : (isVerySmallScreen ? 28.0 : (isExtraSmall ? 32.0 : (isSmallScreen ? 36.0 : 44.0)));
    
    return Column(
      children: [
        // Message Icon
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(isTinyScreen ? 12 : (isVerySmallScreen ? 14 : 18)),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.sms_rounded,
              size: iconInnerSize,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        SizedBox(height: isTinyScreen ? 8 : (isVerySmallScreen ? 10 : (isExtraSmall ? 12 : (isSmallScreen ? 14 : 18)))),
        
        // Title
        Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: isTinyScreen ? 20 : (isVerySmallScreen ? 22 : (isExtraSmall ? 24 : (isSmallScreen ? 26 : 30))),
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isTinyScreen ? 6 : (isVerySmallScreen ? 7 : (isExtraSmall ? 8 : (isSmallScreen ? 9 : 12)))),
        
        // Phone Number Display
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTinyScreen ? 10 : (isVerySmallScreen ? 12 : (isExtraSmall ? 14 : (isSmallScreen ? 16 : 20))), 
            vertical: isTinyScreen ? 6 : (isVerySmallScreen ? 7 : (isExtraSmall ? 8 : 10)),
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Text(
            'Code sent to +91${widget.mobileNumber}',
            style: TextStyle(
              fontSize: isTinyScreen ? 10 : (isVerySmallScreen ? 11 : (isExtraSmall ? 12 : (isSmallScreen ? 13 : 14))),
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPCard(
    bool isSmallScreen, 
    bool isVerySmallScreen, 
    bool isTinyScreen, 
    bool isExtraSmall,
    double screenWidth,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 320 ? 14 : (screenWidth < 340 ? 16 : (screenWidth < 360 ? 18 : 20)),
        vertical: isTinyScreen ? 16 : (isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 24)),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTinyScreen ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Enter Verification Code',
            style: TextStyle(
              fontSize: isTinyScreen ? 14 : (isVerySmallScreen ? 15 : (isExtraSmall ? 16 : (isSmallScreen ? 17 : 20))),
              fontWeight: FontWeight.w700,
              color: darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTinyScreen ? 3 : (isVerySmallScreen ? 4 : (isExtraSmall ? 5 : 6))),
          
          // Subtitle
          Text(
            'Code will be verified automatically',
            style: TextStyle(
              fontSize: isTinyScreen ? 9 : (isVerySmallScreen ? 10 : (isExtraSmall ? 11 : (isSmallScreen ? 12 : 13))),
              fontWeight: FontWeight.w400,
              color: textLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTinyScreen ? 16 : (isVerySmallScreen ? 18 : (isExtraSmall ? 20 : (isSmallScreen ? 22 : 26)))),
          
          // OTP Input Fields
          _buildOTPInputFields(
            isSmallScreen, 
            isVerySmallScreen, 
            isTinyScreen, 
            isExtraSmall,
            screenWidth,
          ),
          
          SizedBox(height: isTinyScreen ? 16 : (isVerySmallScreen ? 18 : (isExtraSmall ? 20 : (isSmallScreen ? 22 : 24)))),
          
          // Verify Button
          _buildVerifyButton(isSmallScreen, isVerySmallScreen, isTinyScreen, isExtraSmall),
          
          SizedBox(height: isTinyScreen ? 10 : (isVerySmallScreen ? 11 : (isExtraSmall ? 12 : (isSmallScreen ? 14 : 16)))),
          
          // Resend Timer
          _buildResendSection(isSmallScreen, isVerySmallScreen, isTinyScreen, isExtraSmall),
          
          SizedBox(height: isTinyScreen ? 6 : (isVerySmallScreen ? 7 : (isExtraSmall ? 8 : (isSmallScreen ? 10 : 12)))),
          
          // Change Mobile Number
          _buildChangeMobileButton(isSmallScreen, isVerySmallScreen, isTinyScreen, isExtraSmall),
        ],
      ),
    );
  }

  Widget _buildOTPInputFields(
    bool isSmallScreen, 
    bool isVerySmallScreen, 
    bool isTinyScreen, 
    bool isExtraSmall,
    double screenWidth,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get card's available width with safety margin
        final availableWidth = constraints.maxWidth - 16; // 16px safety margin
        
        // Calculate optimal spacing based on screen size
        double spacing;
        if (screenWidth < 320) {
          spacing = 3.0;
        } else if (screenWidth < 340) {
          spacing = 4.0;
        } else if (screenWidth < 360) {
          spacing = 5.0;
        } else if (screenWidth < 380) {
          spacing = 6.0;
        } else {
          spacing = 8.0;
        }
        
        final totalSpacing = 5 * spacing; // 5 gaps between 6 boxes
        
        // Calculate box size dynamically
        final calculatedBoxSize = (availableWidth - totalSpacing) / 6;
        
        // Clamp box size with appropriate min/max values
        final minBoxSize = screenWidth < 320 ? 32.0 : (screenWidth < 340 ? 34.0 : (screenWidth < 360 ? 36.0 : 38.0));
        final maxBoxSize = 50.0;
        final boxSize = calculatedBoxSize.clamp(minBoxSize, maxBoxSize);
        
        // Adjust box height based on box size and screen
        final boxHeight = boxSize + (isTinyScreen ? 2.0 : (isVerySmallScreen ? 4.0 : (isExtraSmall ? 6.0 : 8.0)));
        
        // Dynamic font size based on box size
        final fontSize = (boxSize * 0.42).clamp(13.0, 20.0);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: boxSize,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _focusNodes[index].hasFocus 
                        ? primaryBlue 
                        : Colors.grey[300]!,
                      width: _focusNodes[index].hasFocus ? 2 : 1.5,
                    ),
                    color: lightBg,
                  ),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      
                      // Auto-verify when all fields are filled
                      if (index == 5 && value.isNotEmpty) {
                        String otp = _otpControllers.map((c) => c.text).join();
                        if (otp.length == 6) {
                          _handleVerifyOTP();
                        }
                      }
                    },
                  ),
                ),
                if (index < 5) SizedBox(width: spacing),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildVerifyButton(
    bool isSmallScreen, 
    bool isVerySmallScreen, 
    bool isTinyScreen, 
    bool isExtraSmall,
  ) {
    return Container(
      height: isTinyScreen ? 42 : (isVerySmallScreen ? 44 : (isExtraSmall ? 46 : (isSmallScreen ? 48 : 50))),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleVerifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: isTinyScreen ? 16 : (isVerySmallScreen ? 18 : 20),
                width: isTinyScreen ? 16 : (isVerySmallScreen ? 18 : 20),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'VERIFY & LOGIN',
                style: TextStyle(
                  fontSize: isTinyScreen ? 11 : (isVerySmallScreen ? 12 : (isExtraSmall ? 13 : (isSmallScreen ? 14 : 15))),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
      ),
    );
  }

  Widget _buildResendSection(
    bool isSmallScreen, 
    bool isVerySmallScreen, 
    bool isTinyScreen, 
    bool isExtraSmall,
  ) {
    return Center(
      child: _resendTimer > 0
          ? Text(
              'Resend OTP in ${_resendTimer}s',
              style: TextStyle(
                fontSize: isTinyScreen ? 10 : (isVerySmallScreen ? 11 : (isExtraSmall ? 12 : (isSmallScreen ? 13 : 14))),
                fontWeight: FontWeight.w500,
                color: textLight,
              ),
            )
          : TextButton(
              onPressed: _isResending ? null : _handleResendOTP,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _isResending
                  ? SizedBox(
                      width: isTinyScreen ? 14 : (isVerySmallScreen ? 16 : 18),
                      height: isTinyScreen ? 14 : (isVerySmallScreen ? 16 : 18),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: isTinyScreen ? 10 : (isVerySmallScreen ? 11 : (isExtraSmall ? 12 : (isSmallScreen ? 13 : 14))),
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
            ),
    );
  }

  Widget _buildChangeMobileButton(
    bool isSmallScreen, 
    bool isVerySmallScreen, 
    bool isTinyScreen, 
    bool isExtraSmall,
  ) {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(
          Icons.edit_rounded,
          size: isTinyScreen ? 12 : (isVerySmallScreen ? 13 : (isExtraSmall ? 14 : (isSmallScreen ? 15 : 16))),
          color: textLight,
        ),
        label: Text(
          'Change Mobile Number',
          style: TextStyle(
            fontSize: isTinyScreen ? 9 : (isVerySmallScreen ? 10 : (isExtraSmall ? 11 : (isSmallScreen ? 12 : 13))),
            fontWeight: FontWeight.w500,
            color: textLight,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _handleVerifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      _showErrorSnackBar('Please enter complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // For demo, accept any 6-digit OTP
    if (otp.length == 6) {
      HapticFeedback.lightImpact();
      await ref.read(authViewModelProvider.notifier).login(TokenResponse(mobile: widget.mobileNumber));
      await ref.read(securitymodelProvider.notifier).fetchLogin(widget.mobileNumber);
              
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainTabScreen()
        ),
      );
    } else {
      _showErrorSnackBar('Invalid OTP. Please try again.');
    }
  }

  void _handleResendOTP() async {
    setState(() {
      _isResending = true;
    });

    // Simulate resending OTP
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isResending = false;
      _resendTimer = 30;
    });

    _startResendTimer();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'OTP sent successfully!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: warningRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}