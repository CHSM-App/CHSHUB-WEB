
import 'package:flutter/material.dart';
class SocietyAppTheme {
  static const String _fontFamily = 'WorkSans';

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: _fontFamily),
      displayMedium: base.displayMedium?.copyWith(fontFamily: _fontFamily),
      displaySmall: base.displaySmall?.copyWith(fontFamily: _fontFamily),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: _fontFamily),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: _fontFamily),
      titleLarge: base.titleLarge?.copyWith(fontFamily: _fontFamily),
      labelLarge: base.labelLarge?.copyWith(fontFamily: _fontFamily),
      bodySmall: base.bodySmall?.copyWith(fontFamily: _fontFamily),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: _fontFamily),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: _fontFamily),
      titleMedium: base.titleMedium?.copyWith(fontFamily: _fontFamily),
      titleSmall: base.titleSmall?.copyWith(fontFamily: _fontFamily),
      labelSmall: base.labelSmall?.copyWith(fontFamily: _fontFamily),
    );
  }

  static ThemeData buildLightTheme() {
    final Color primaryColor = const Color(0xFF0D6EFD); // Bootstrap Primary
    final Color secondaryColor = const Color(0xFF6C757D); // Bootstrap Secondary
    final Color successColor = const Color(0xFF198754); // Bootstrap Success
    final Color backgroundColor = const Color(0xFFF8F9FA); // NiceAdmin BG
    final Color cardColor = Colors.white30;
    final Color borderColor = const Color(0xFFE0E0E0);

    final ColorScheme colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: cardColor,
      error: const Color(0xFFDC3545),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
    );

    final ThemeData base = ThemeData.light();

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      shadowColor: Colors.grey.withOpacity(0.2),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      buttonTheme: ButtonThemeData(
        colorScheme: colorScheme,
        textTheme: ButtonTextTheme.primary,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme:   CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin:  EdgeInsets.all(8),
        shadowColor: Colors.black12,
        color: cardColor,
      ),
      dividerColor: borderColor,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(fontFamily: _fontFamily),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    final Color primaryColor = const Color(0xFF0D6EFD);
    final Color backgroundColor = const Color(0xFF121212);
    final Color cardColor = const Color(0xFF1E1E1E);
    final Color borderColor = const Color(0xFF2C2C2C);

    final ColorScheme colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: const Color(0xFF6C757D),
      surface: cardColor,
      error: const Color(0xFFDC3545),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    );

    final ThemeData base = ThemeData.dark();

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      shadowColor: Colors.black54,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: _buildTextTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shadowColor: Colors.black26,
        color: cardColor,
      ),
      dividerColor: borderColor,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white),
      ),
    );
  }
}
