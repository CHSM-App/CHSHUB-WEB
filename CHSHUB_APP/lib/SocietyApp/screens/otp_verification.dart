
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_device_id_plus/platform_device_id.dart';

import 'package:society_app/SocietyApp/navigation_home_screen.dart';
import 'package:society_app/domain/models/basicinfo.dart';
import 'package:society_app/domain/models/token_response.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class OTPVerification extends ConsumerStatefulWidget {
  final String mobileNumber;

  const OTPVerification({super.key, required this.mobileNumber});

  @override
  ConsumerState<OTPVerification> createState() => _OTPVerificationState();
}

class _OTPVerificationState extends ConsumerState<OTPVerification>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  bool _autoVerifying = false;
  bool _isError = false;
  bool _isSuccess = false;
  int _resendTimer = 30;

  late AnimationController _animationController;

  static const Color primaryDark = Color(0xFF1A237E);
  static const Color primaryMedium = Color(0xFF3949AB);
  static const Color primaryLight = Color(0xFFF3F4FF);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color warningRed = Color(0xFFE53E3E);
  static const Color successGreen = Color(0xFF38A169);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
    _startResendTimer();
    // Ask the server to send the code as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  Future<void> _sendOtp() async {
    final error =
        await ref.read(authViewModelProvider.notifier).requestOtp(widget.mobileNumber);
    if (error != null && mounted) _showErrorSnackBar(error);
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendTimer--);
        return _resendTimer > 0;
      }
      return false;
    });
  }

  void _checkAndAutoVerify() {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6 && !_autoVerifying && !_isLoading) {
      setState(() => _autoVerifying = true);
      Future.delayed(const Duration(milliseconds: 500), () => _onSubmit());
    }
  }

  String _getOTP() => _otpControllers.map((c) => c.text).join();

  Future<void> _onSubmit() async {
    final otp = _getOTP();
    if (otp.length != 6) {
      _showErrorSnackBar("Please enter complete 6-digit OTP");
      return;
    }
    // The server verifies the code inside POST /login/Createlogin (authVM.login)
    // below. A wrong, expired or reused code makes that call fail and is handled
    // in the catch. There is no client-side code check any more.
    setState(() {
      _isLoading = true;
      _isError = false;
      _autoVerifying = true;
    });

    try {
      final authVM = ref.read(authViewModelProvider.notifier);
      final userVM = ref.read(basicInfoViewModelProvider.notifier);
      

      final flats = await userVM.checkUser(widget.mobileNumber);
     
      if (flats == null || flats.isEmpty) {
        setState(() => _isError = true);
        _showErrorSnackBar("No flats found for this number");
        return;
      }

      // ✅ OTP is correct
      setState(() => _isSuccess = true);

      if (flats.length == 1) {
        // Single flat → continue normal flow
        final loginResponse = await authVM.login(TokenResponse(mobile:widget.mobileNumber,deviceDetails: await getUniqueId(), otp: otp));
      if (loginResponse == null || loginResponse.isEmpty) {
        setState(() => _isError = true);
        _showErrorSnackBar("Login failed. Please try again.");
        return;
      }
        await userVM.selectFlat(
          widget.mobileNumber,
          flats.first.flatId,
          flats.first.ownerId,
          ref,
          "otp",
        );
        final basicInfoState = ref.watch(basicInfoViewModelProvider);

        if (basicInfoState.mobile != null && basicInfoState.flatId != null) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AnimatedBottomNavScreen()),
            (route) => false,
          );
        } else {
          _showErrorSnackBar(" Please try again.");
          setState(() {
            _isError = true;
            _isSuccess = false;
          });
        }
      } else {
        // 🔹 Multiple flats → stop loading BEFORE dialog
        setState(() {
          _isLoading = false;
          _autoVerifying = false;
        });

        // show flat selection
        await _showFlatSelectionDialog(flats, otp);
        return;
      }
      
    } catch (e) {
      _showErrorSnackBar("Something went wrong. Please try again.");
      setState(() => _isError = true);
    } finally {
      // Only run when not returned early
      if (mounted) {
        setState(() {
          _isLoading = false;
          _autoVerifying = false;
        });
      }
    }
  }


Future<String?> getUniqueId() async {
  return await PlatformDeviceId.getDeviceId;
}

  Future<void> _showFlatSelectionDialog(List<BasicInfo> flats, String otp) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 241, 244, 247),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade600, Colors.indigo.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const Text(
            "Select Your Flat",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: flats.length,
            itemBuilder: (context, index) {
              final flat = flats[index];
              return GestureDetector(
                onTap: () async {
                  final loginResponse = await ref.read(authViewModelProvider.notifier).login(TokenResponse(mobile: widget.mobileNumber, deviceDetails: await getUniqueId(), otp: otp));
      if (loginResponse == null || loginResponse.isEmpty) {
        setState(() => _isError = true);
        _showErrorSnackBar("Login failed. Please try again.");
        return;
      }
                  await ref
                      .read(basicInfoViewModelProvider.notifier)
                      .selectFlat(
                        widget.mobileNumber,
                        flat.flatId,
                        flat.ownerId,
                        ref,
                        "otp",
                      );
                  final basicInfoState = ref.watch(basicInfoViewModelProvider);
                  if (basicInfoState.mobile != null &&
                      basicInfoState.flatId != null) {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnimatedBottomNavScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: Card(
                  color: Colors.white,
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flat.name ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.apartment,
                                color: Colors.indigo.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${flat.societyName} | ${flat.buildName}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "Flat No: ",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                                TextSpan(
                                  text: flat.flatNo,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.indigo.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: warningRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleResendOTP() async {
    setState(() {
      _isResending = true;
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _autoVerifying = false;
    });

    // Re-request through the same server endpoint (rate-limited server-side).
    final error =
        await ref.read(authViewModelProvider.notifier).requestOtp(widget.mobileNumber);

    setState(() {
      _isResending = false;
      _resendTimer = 30;
    });

    if (error != null && mounted) {
      _showErrorSnackBar(error);
      return;
    }

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'New OTP sent successfully!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Helper method to get responsive values
  double _getResponsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return mobile;
    if (screenWidth < 1200) return tablet;
    return desktop;
  }

  // Helper method to check if device is tablet or larger
  bool _isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Prevent automatic resize
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
                 Colors.indigo,
              Color(0xFF3B4A73),
              Color(0xFF2E3B62),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
            
                  left: _getResponsiveValue(
                    context,
                    mobile: 20,
                    tablet: 40,
                    desktop: 60,
                  ),
                  right: _getResponsiveValue(
                    context,
                    mobile: 20,
                    tablet: 40,
                    desktop: 60,
                  ),
                  bottom: keyboardHeight > 0
                      ? keyboardHeight + 20
                      : 40, // Add bottom padding
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: _isTabletOrLarger(context)
                        ? 500
                        : double.infinity, // Limit width on larger screens
                  ),
                  child: Center(
                    // Center content on larger screens
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(
                            height: _getResponsiveValue(
                              context,
                              mobile: 20,
                              tablet: 30,
                              desktop: 40,
                            ),
                          ),
                          _buildBackButton(),
                          SizedBox(
                            height: _getResponsiveValue(
                              context,
                              mobile: 20,
                              tablet: 30,
                              desktop: 40,
                            ),
                          ),
                          _buildHeader(),
                          SizedBox(
                            height: isSmallScreen
                                ? 30
                                : _getResponsiveValue(
                                    context,
                                    mobile: 50,
                                    tablet: 60,
                                    desktop: 80,
                                  ),
                          ),
                          _buildOTPForm(),
                          SizedBox(
                            height: _getResponsiveValue(
                              context,
                              mobile: 30,
                              tablet: 40,
                              desktop: 50,
                            ),
                          ), // Space between form and bottom
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: _getResponsiveValue(
              context,
              mobile: 24,
              tablet: 28,
              desktop: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          Container(
            width: _getResponsiveValue(
              context,
              mobile: 100,
              tablet: 120,
              desktop: 140,
            ),
            height: _getResponsiveValue(
              context,
              mobile: 100,
              tablet: 120,
              desktop: 140,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.sms_outlined,
              size: _getResponsiveValue(
                context,
                mobile: 60,
                tablet: 80,
                desktop: 100,
              ),
              color: const Color.fromARGB(255, 207, 45, 33),
            ),
          ),
          SizedBox(
            height: _getResponsiveValue(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
          ),
          Text(
            'Verify OTP',
            style: TextStyle(
              fontSize: _getResponsiveValue(
                context,
                mobile: 28,
                tablet: 32,
                desktop: 36,
              ),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(
            height: _getResponsiveValue(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveValue(
                context,
                mobile: 20,
                tablet: 24,
                desktop: 28,
              ),
              vertical: _getResponsiveValue(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'Code sent to +91${widget.mobileNumber}',
              style: TextStyle(
                fontSize: _getResponsiveValue(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: _getResponsiveValue(
            context,
            mobile: 8,
            tablet: 16,
            desktop: 24,
          ),
        ),
        padding: EdgeInsets.all(
          _getResponsiveValue(context, mobile: 24, tablet: 32, desktop: 40),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: _getResponsiveValue(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 28,
                ),
                fontWeight: FontWeight.w800,
                color: primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _autoVerifying
                  ? 'Auto-verifying your code...'
                  : 'Code will be verified automatically',
              style: TextStyle(
                fontSize: _getResponsiveValue(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                fontWeight: FontWeight.w400,
                color: _autoVerifying ? primaryMedium : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: _getResponsiveValue(
                context,
                mobile: 30,
                tablet: 40,
                desktop: 50,
              ),
            ),
            _buildOTPInputFields(),
            SizedBox(
              height: _getResponsiveValue(
                context,
                mobile: 28,
                tablet: 32,
                desktop: 36,
              ),
            ),
            if (_autoVerifying || _isLoading)
              Container(
                height: _getResponsiveValue(
                  context,
                  mobile: 52,
                  tablet: 56,
                  desktop: 60,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: primaryLight,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Verifying...',
                        style: TextStyle(
                          fontSize: _getResponsiveValue(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          fontWeight: FontWeight.w600,
                          color: primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildPrimaryButton(
                onPressed: _isLoading ? null : _onSubmit,
                text: 'VERIFY & LOGIN',
                isLoading: _isLoading,
                backgroundColor: primaryMedium,
              ),
            SizedBox(
              height: _getResponsiveValue(
                context,
                mobile: 20,
                tablet: 24,
                desktop: 28,
              ),
            ),
            if (!_autoVerifying && !_isLoading) _buildResendSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPInputFields() {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth =
        screenWidth -
        (2 *
            _getResponsiveValue(context, mobile: 20, tablet: 40, desktop: 60)) -
        (2 *
            _getResponsiveValue(
              context,
              mobile: 32,
              tablet: 40,
              desktop: 48,
            )); // Account for screen padding and container padding

    // Calculate optimal size to fit all 6 boxes in one row
    final spacing = _getResponsiveValue(
      context,
      mobile: 6,
      tablet: 8,
      desktop: 10,
    );
    final totalSpacing = spacing * 5; // 5 gaps between 6 boxes
    final maxBoxWidth = (availableWidth - totalSpacing) / 6;

    // Set reasonable limits for box size
    final otpFieldSize = maxBoxWidth.clamp(35.0, 50.0);
    final otpFieldHeight = otpFieldSize + 8; // Slightly taller than width

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Container(
          width: otpFieldSize,
          height: otpFieldHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isError
                  ? warningRed
                  : _isSuccess
                  ? successGreen
                  : _focusNodes[index].hasFocus
                  ? primaryMedium
                  : const Color(0xFFBDBCBC),
              width: _isError || _isSuccess
                  ? 2
                  : _focusNodes[index].hasFocus
                  ? 2
                  : 1,
            ),
            color: _isError
                ? const Color(0xFFFFEBEE)
                : _isSuccess
                ? const Color.fromARGB(255, 232, 245, 233)
                : Colors.grey[50],
          ),
          child: Center(
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              enabled: !_autoVerifying && !_isLoading,
              style: TextStyle(
                fontSize: (otpFieldSize * 0.45).clamp(
                  16.0,
                  22.0,
                ), // Responsive font size based on box size
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: _isError
                    ? warningRed
                    : _isSuccess
                    ? successGreen
                    : primaryDark,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
              ),
              onChanged: (value) {
                setState(() {
                  _isError = false;
                  _isSuccess = false;
                });
                if (value.isNotEmpty && index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
                _checkAndAutoVerify();
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        if (_resendTimer > 0)
          Text(
            'Resend OTP in ${_resendTimer}s',
            style: TextStyle(
              fontSize: _getResponsiveValue(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
              color: Colors.grey[600],
            ),
          )
        else
          TextButton(
            onPressed: _isResending ? null : _handleResendOTP,
            child: _isResending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontSize: _getResponsiveValue(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.w600,
                      color: primaryMedium,
                    ),
                  ),
          ),
        SizedBox(
          height: _getResponsiveValue(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.edit_rounded,
            size: _getResponsiveValue(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: Colors.grey[600],
          ),
          label: Text(
            'Change Mobile Number',
            style: TextStyle(
              fontSize: _getResponsiveValue(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
              color: Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String text,
    required Color backgroundColor,
    bool isLoading = false,
  }) {
    final buttonHeight = _getResponsiveValue(
      context,
      mobile: 52,
      tablet: 56,
      desktop: 60,
    );

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: _getResponsiveValue(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }
}
