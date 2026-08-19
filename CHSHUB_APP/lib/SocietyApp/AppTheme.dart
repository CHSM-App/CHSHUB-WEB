import 'package:flutter/material.dart';

/// Complete Theme System for Community App
/// Based on the modern design patterns from your app screens

class AppTheme {
  // Primary Color Palette
  static const Color primaryBlue = Color(0xFF4A5FBF);
  static const Color primaryDark = Color(0xFF2E3B62);
  static const Color primaryLight = Color(0xFF6B7ED6);
  static const Color primarySurface = Color(0xFFF5F6FA);
  
  // Accent Colors
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFF44336);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentTeal = Color(0xFF009688);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  
  // Background Colors
  static const Color backgroundPrimary = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundSection = Color(0xFFF8F9FB);
  
  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF9CA3AF);
  static const Color borderPrimary = Color(0xFF4A5FBF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2E3B62);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnCard = Color(0xFF2E3B62);
  
  // Shadow Colors
  static final Color shadowLight = Colors.grey.shade300.withOpacity(0.3);
  static final Color shadowMedium = Colors.grey.shade400.withOpacity(0.4);
  static final Color shadowDark = Colors.black.withOpacity(0.1);
  static final Color shadowPrimary = primaryBlue.withOpacity(0.2);
  
  // Border Radius Values
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 50.0;
  
  // Spacing Values
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;
  
  // Typography
  static const String fontFamily = 'Inter'; // You can change this to your preferred font
  
  // Get Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: primaryLight,
        secondary: accentGreen,
        secondaryContainer: successLight,
        surface: backgroundSecondary,
        error: error,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),
      
      // Scaffold Theme
      scaffoldBackgroundColor: backgroundPrimary,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(color: white, size: 24),
      ),
      
      // Card Theme
      // cardTheme: CardTheme(
      //   color: backgroundCard,
      //   elevation: 2,
      //   shadowColor: shadowLight,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(radiusL),
      //   ),
      //   margin: const EdgeInsets.all(spaceS),
      // ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 2,
          shadowColor: shadowPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceXL,
            vertical: spaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: borderLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceXL,
            vertical: spaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceL,
          vertical: spaceL,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 16,
          fontFamily: fontFamily,
        ),
      ),
      
      // Bottom Navigation Theme
      // bottomNavigationBarTheme: const BottomNavigationBarTheme(
      //   backgroundColor: white,
      //   selectedItemColor: primaryBlue,
      //   unselectedItemColor: grey500,
      //   type: BottomNavigationBarType.fixed,
      //   elevation: 8,
      //   selectedLabelStyle: TextStyle(
      //     fontSize: 12,
      //     fontWeight: FontWeight.w600,
      //     fontFamily: fontFamily,
      //   ),
      //   unselectedLabelStyle: TextStyle(
      //     fontSize: 12,
      //     fontWeight: FontWeight.w400,
      //     fontFamily: fontFamily,
      //   ),
      // ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spaceL,
          vertical: spaceS,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
      ),
      
      // Dialog Theme
      // dialogTheme: DialogTheme(
      //   backgroundColor: white,
      //   elevation: 8,
      //   shadowColor: shadowMedium,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(radiusXL),
      //   ),
      //   titleTextStyle: const TextStyle(
      //     color: textPrimary,
      //     fontSize: 20,
      //     fontWeight: FontWeight.w600,
      //     fontFamily: fontFamily,
      //   ),
      //   contentTextStyle: const TextStyle(
      //     color: textSecondary,
      //     fontSize: 16,
      //     fontFamily: fontFamily,
      //   ),
      // ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDark,
        contentTextStyle: const TextStyle(
          color: white,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Custom Widget Extensions for Theme
extension ThemeExtensions on BuildContext {
  // Quick access to theme
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  // Custom colors
  Color get primaryBlue => AppTheme.primaryBlue;
  Color get primaryDark => AppTheme.primaryDark;
  Color get backgroundCard => AppTheme.backgroundCard;
  Color get textSecondary => AppTheme.textSecondary;
  Color get borderLight => AppTheme.borderLight;
}

/// Predefined Component Styles
class ComponentStyles {
  // Card Styles
  static BoxDecoration get primaryCard => BoxDecoration(
    color: AppTheme.backgroundCard,
    borderRadius: BorderRadius.circular(AppTheme.radiusL),
    boxShadow: [
      BoxShadow(
        color: AppTheme.shadowLight,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get accentCard => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.primaryBlue.withOpacity(0.05),
        AppTheme.primaryBlue.withOpacity(0.02),
      ],
    ),
    borderRadius: BorderRadius.circular(AppTheme.radiusL),
    border: Border.all(
      color: AppTheme.primaryBlue.withOpacity(0.1),
      width: 1,
    ),
  );
  
  static BoxDecoration get serviceCard => BoxDecoration(
    color: AppTheme.backgroundCard,
    borderRadius: BorderRadius.circular(AppTheme.radiusL),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade200,
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Icon Container Styles
  static BoxDecoration iconContainer(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
  );
  
  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryBlue,
    foregroundColor: AppTheme.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spaceXL,
      vertical: AppTheme.spaceL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
    ),
    elevation: 2,
    shadowColor: AppTheme.shadowPrimary,
  );
  
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: AppTheme.primaryBlue,
    side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spaceXL,
      vertical: AppTheme.spaceL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
    ),
  );
  
  // Input Field Styles
  static InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: Container(
      margin: const EdgeInsets.all(AppTheme.spaceM),
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: iconContainer(AppTheme.primaryBlue),
      child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
    ),
    filled: true,
    fillColor: AppTheme.grey50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      borderSide: const BorderSide(color: AppTheme.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      borderSide: const BorderSide(color: AppTheme.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spaceL,
      vertical: AppTheme.spaceL,
    ),
  );
}

/// Typography Styles
class AppTypography {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
    height: 1.3,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.textSecondary,
    fontFamily: AppTheme.fontFamily,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppTheme.textTertiary,
    fontFamily: AppTheme.fontFamily,
    height: 1.4,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: AppTheme.fontFamily,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
    fontFamily: AppTheme.fontFamily,
  );
}

/// Service Category Colors
class ServiceColors {
  static const Color plumber = Color(0xFF2196F3);
  static const Color maid = Color(0xFF9E9E9E);
  static const Color milkSupplier = Color(0xFF4CAF50);
  static const Color tvCable = Color(0xFFFF9800);
  static const Color buildingCleaner = Color(0xFF9C27B0);
  static const Color electrician = Color(0xFFFF5722);
  static const Color security = Color(0xFF795548);
  static const Color maintenance = Color(0xFF607D8B);
  static const Color gardening = Color(0xFF8BC34A);
  static const Color laundry = Color(0xFF00BCD4);
  static const Color commiteeMember = Color(0xFF607D8B);
}

/// Usage Example:
/// 
/// In your main.dart:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   // your app
/// )
/// ```
/// 
/// In your widgets:
/// ```dart
/// Container(
///   decoration: ComponentStyles.primaryCard,
///   child: Text(
///     'Hello World',
///     style: AppTypography.heading3,
///   ),
/// )
/// ```