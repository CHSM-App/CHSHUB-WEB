// CHS Hub Security Login Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/screens/otp_screen.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class MobileNumberScreen extends ConsumerStatefulWidget {
  const MobileNumberScreen({super.key});

  @override
  ConsumerState<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends ConsumerState<MobileNumberScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Modern Color Palette matching CHS Hub
  static const Color primaryBlue = Color(0xFF4A5FBF); // Main blue
  static const Color darkBlue = Color(0xFF2E3F7F); // Dark blue for gradient
  static const Color lightBg = Color(0xFFF5F5F5); // Light background
  static const Color warningRed = Color(0xFFE53E3E);
  static const Color successGreen = Color(0xFF38A169);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFF718096);

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securitymodelProvider);
      return PopScope(
    canPop: false,
    onPopInvoked: (didPop) async {
      if (didPop) return;
      // Always exit the app when back button is pressed on login page
      SystemNavigator.pop();
    },
    child:  Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBlue, darkBlue],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Security Icon Section
                  _buildHeaderSection(),

                  const SizedBox(height: 40),

                  // Login Form Card
                  _buildLoginCard(state),
                ],
              ),
            ),
          ),
        ),
      ),
    ),);
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Security Icon/Badge
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Icon(
              Icons.shield_outlined,
              size: 40,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // App Title - CHS HUB
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, Colors.white70],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Stack(
            children: [
              Text(
                "CHS HUB ",
                style: TextStyle(
                  fontSize: 58,
                  letterSpacing: 2,

                  fontWeight: FontWeight.bold,

                  color: Colors.white,
                ),
              ),
              Positioned(
                left: 5,

                child: Text(
                  "CHS HUB",
                  style: TextStyle(
                    fontSize: 58,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Security Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user,
                size: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 5),
              Text(
                'Security Access Portal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(dynamic state) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Text
            const Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: textLight,
              ),
            ),
            const SizedBox(height: 3),

            // Sign in Title
            const Text(
              'Sign in to continue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 24),

            // Phone Number Label
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),

            // Phone Number Input Field
            _buildPhoneNumberField(),

            const SizedBox(height: 20),

            // Continue Button
            _buildContinueButton(state),

            const SizedBox(height: 12),

            // Info Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: textLight),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'SMS verification required',
                    style: TextStyle(fontSize: 12, color: textLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Country Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: const Text(
              '+91',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),

          // Phone Number Input
          Expanded(
            child: TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
              decoration: InputDecoration(
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mobile number is required';
                }
                if (value.length != 10) {
                  return 'Enter a valid 10-digit mobile number';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Mobile number should contain only digits';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(dynamic state) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
        onPressed: state.isLoading ? null : _handleSendOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: state.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }

  void _handleSendOTP() async {
    if (_formKey.currentState!.validate()) {
      String phone = _mobileController.text.trim();

      if (phone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phone)) {
        final securityNotifier = ref.read(securitymodelProvider.notifier);
        await securityNotifier.checkUser(phone);

        final state = ref.watch(securitymodelProvider);

        state.checkUserdata.when(
          loading: () {
            // Loading state handled by isLoading flag
          },
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(getErrorMessage(error)),
                backgroundColor: warningRed,
              ),
            );
          },
          data: (loginDetails) {
            if (loginDetails.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("OTP Sent Successfully"),
                  backgroundColor: successGreen,
                ),
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OTPVerificationScreen(mobileNumber: phone),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "No User Found! Please Enter Valid Mobile Number",
                  ),
                  backgroundColor: warningRed,
                ),
              );
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number.'),
            backgroundColor: warningRed,
          ),
        );
      }
    }
  }
}
