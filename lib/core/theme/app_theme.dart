import 'package:flutter/material.dart';

/// The design system.
///
/// The palette descends from CHSHUB_app/lib/app_theme.dart — the brand blue
/// (#2633C5) and its neutrals are carried over so the two apps read as one
/// product. What is added here is the scaffolding a hand-rolled palette lacks:
/// a tint ramp per accent, named elevations, a spacing scale and a radius
/// scale, so screens compose from tokens instead of inventing values.
///
/// CHSHUB names WorkSans as its fontName but never ships the asset (the
/// `fonts:` block in its pubspec is commented out), so it silently renders in
/// the system font. We do the same deliberately — `fontFamily` is left null
/// rather than naming a font that is not bundled.
class AppTheme {
  AppTheme._();

  // ========================================================================
  // BRAND
  // ========================================================================

  /// The CHSHUB blue.
  static const Color primary = Color(0xFF2633C5);
  static const Color primaryDark = Color(0xFF1B2593);
  static const Color primaryLight = Color(0xFF5A66E0);

  /// Very light primary, for selected rows and icon plates on white.
  static const Color primarySurface = Color(0xFFEEF0FE);

  /// Kept for call sites that still name the CHSHUB constant.
  static const Color nearlyDarkBlue = primary;

  // ========================================================================
  // NEUTRALS
  // ========================================================================

  static const Color white = Color(0xFFFFFFFF);
  static const Color nearlyWhite = Color(0xFFFEFEFE);
  static const Color notWhite = Color(0xFFEDF0F2);

  /// Page background. Slightly cool, so white cards lift off it.
  static const Color background = Color(0xFFF6F7FB);
  static const Color cardBackground = white;

  /// Hairlines and card borders.
  static const Color border = Color(0xFFE6E8F0);
  static const Color spacer = Color(0xFFF1F2F6);
  static const Color chipBackground = Color(0xFFEEF1F3);

  static const Color nearlyBlack = Color(0xFF213333);
  static const Color grey = Color(0xFF3A5160);
  static const Color darkGrey = Color(0xFF313A44);
  static const Color dismissibleBackground = Color(0xFF364A54);

  // ========================================================================
  // TEXT
  // ========================================================================

  static const Color darkerText = Color(0xFF17262A);
  static const Color darkText = Color(0xFF253840);
  static const Color lightText = Color(0xFF64748B);
  static const Color deactivatedText = Color(0xFF94A3B8);

  // ========================================================================
  // STATUS
  //
  // Each accent carries a `surface` tint for the chip/plate it sits on. Fixed
  // tints rather than withOpacity at the call site: opacity over a coloured
  // background muddies, and these are read on white and on the page grey.
  // ========================================================================

  static const Color success = Color(0xFF12A150);
  static const Color successSurface = Color(0xFFE7F7EE);

  static const Color warning = Color(0xFFE08700);
  static const Color warningSurface = Color(0xFFFDF3E2);

  static const Color error = Color(0xFFD92D20);
  static const Color errorSurface = Color(0xFFFEECEB);

  static const Color info = Color(0xFF1570EF);
  static const Color infoSurface = Color(0xFFE8F1FE);

  static const Color violet = Color(0xFF7839EE);
  static const Color violetSurface = Color(0xFFF2EBFE);

  static const Color teal = Color(0xFF0E9384);
  static const Color tealSurface = Color(0xFFE3F5F3);

  /// The tint that belongs with an accent. Falls back to a neutral so an
  /// unrecognised colour still renders sensibly.
  static Color surfaceFor(Color accent) {
    if (accent == success) return successSurface;
    if (accent == warning) return warningSurface;
    if (accent == error) return errorSurface;
    if (accent == info) return infoSurface;
    if (accent == violet) return violetSurface;
    if (accent == teal) return tealSurface;
    if (accent == primary) return primarySurface;
    return chipBackground;
  }

  /// Categorical series colours for charts, ordered for contrast when adjacent.
  static const List<Color> chartSeries = [
    primary,
    teal,
    warning,
    violet,
    info,
    success,
  ];

  // ========================================================================
  // GRADIENTS
  // ========================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2633C5), Color(0xFF4E5BE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// For hero panels — deeper, so white text clears AA comfortably.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1B2593), Color(0xFF3D4AD8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Money in — the Collected stat.
  ///
  /// #15803D rather than the lighter `success` swatch: white on #12A150
  /// measures 3.37:1, under the 4.5:1 AA wants. This gives 5.02:1.
  static const LinearGradient collectedGradient = LinearGradient(
    colors: [Color(0xFF12703A), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Money owed — the Due stat, and the defaulters summary.
  ///
  /// #DC2626 carries white at 4.83:1, just clear of AA. Nothing brighter
  /// works: #EF4444 drops to 3.76:1 and the label stops being readable.
  static const LinearGradient duesGradient = LinearGradient(
    colors: [Color(0xFFC81E1E), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary text on a coloured panel.
  ///
  /// Deliberately close to opaque. `Colors.white70` measures about 3.0:1
  /// against the red above — well under the 4.5:1 AA wants for body text —
  /// and even 0.86 only reaches 4.0:1. At 0.94 it clears AA on every gradient
  /// here while still sitting visibly below the pure-white headline.
  static const Color onGradientMuted = Color(0xF0FFFFFF);

  // ========================================================================
  // SPACING & RADIUS
  //
  // A 4pt scale. Screens reference these instead of literals so rhythm stays
  // consistent when a layout is edited.
  // ========================================================================

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusPill = 999;

  // ========================================================================
  // ELEVATION
  //
  // Two soft, layered shadows rather than one hard one — a wide ambient blur
  // plus a tight contact shadow is what reads as depth instead of as a border.
  // ========================================================================

  static List<BoxShadow> get shadowSm => const [
    BoxShadow(color: Color(0x0D101828), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F101828), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> get shadowMd => const [
    BoxShadow(color: Color(0x0F101828), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static List<BoxShadow> get shadowLg => const [
    BoxShadow(color: Color(0x14101828), blurRadius: 24, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 8, offset: Offset(0, 4)),
  ];

  /// Tinted shadow for a coloured panel — a grey shadow under a blue hero
  /// reads as dirt, so the shadow takes the panel's own hue.
  static List<BoxShadow> primaryGlow({double opacity = 0.28}) =>
      glow(primary, opacity: opacity);

  /// The same, for any accent — a blue glow under a crimson panel is the exact
  /// mismatch primaryGlow exists to avoid.
  static List<BoxShadow> glow(Color color, {double opacity = 0.28}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  // ========================================================================
  // TEXT STYLES
  // ========================================================================

  static const TextStyle display1 = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 34,
    letterSpacing: -0.6,
    height: 1.15,
    color: darkerText,
  );

  static const TextStyle headline = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 23,
    letterSpacing: -0.4,
    height: 1.25,
    color: darkerText,
  );

  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: -0.1,
    height: 1.35,
    color: darkerText,
  );

  static const TextStyle subtitle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: -0.05,
    color: darkText,
  );

  static const TextStyle body1 = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.45,
    color: darkText,
  );

  static const TextStyle body2 = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.45,
    color: darkText,
  );

  static const TextStyle caption = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 12.5,
    height: 1.35,
    color: lightText,
  );

  /// Small uppercase label above a figure or section.
  static const TextStyle overline = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 0.6,
    color: lightText,
  );

  /// Figures. Tabular so digits line up column-to-column in a list of money.
  static const TextStyle numeral = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: -0.5,
    height: 1.2,
    color: darkerText,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle numeralSm = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: -0.2,
    color: darkerText,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: display1,
    headlineLarge: headline,
    titleLarge: title,
    labelLarge: subtitle,
    bodyLarge: body1,
    bodyMedium: body2,
    labelMedium: caption,
  );

  // ========================================================================
  // THEME DATA
  // ========================================================================

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: white,
      error: error,
      surface: cardBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: darkerText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: darkerText,
        ),
        iconTheme: IconThemeData(color: darkText, size: 22),
      ),

      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space4,
          vertical: space4,
        ),
        border: _fieldBorder(border),
        enabledBorder: _fieldBorder(border),
        focusedBorder: _fieldBorder(primary, width: 1.6),
        errorBorder: _fieldBorder(error),
        focusedErrorBorder: _fieldBorder(error, width: 1.6),
        labelStyle: const TextStyle(color: lightText, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: deactivatedText, fontSize: 14),
        helperStyle: caption,
        prefixIconColor: lightText,
        suffixIconColor: lightText,
      ),

      // The menu a dropdown drops paints with `canvasColor`, not with any
      // dropdown-specific theme — DropdownButtonFormField reads
      // `dropdownColor ?? Theme.of(context).canvasColor` and ignores
      // dropdownMenuTheme entirely (that one is for the newer DropdownMenu).
      // So the ground colour is set here, and the corners and elevation,
      // which are per-widget only, come from AppDropdown.
      canvasColor: white,

      // The dropdown menu wraps its *selected* row in an InkWell that paints
      // `focusColor` behind whatever the row draws — Material's default is an
      // opaque grey, and it was showing through as a full-width band behind
      // AppDropdown's own tinted pill. Cleared here so the row's plate is the
      // only selected-state marking; the pill and its check carry it.
      focusColor: Colors.transparent,

      // Same reasoning for the pointer states, which matter in the browser
      // build: a grey wash spanning the full row width fought the inset pill.
      // A faint primary tint replaces it, so hovering previews the shape the
      // row takes once chosen.
      hoverColor: primarySurface.withValues(alpha: 0.55),
      highlightColor: Colors.transparent,

      // The popup menus (the ⋮ overflow menus) do read their own theme, so a
      // menu looks like a menu wherever it comes from.
      popupMenuTheme: PopupMenuThemeData(
        color: white,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border),
        ),
        textStyle: body2,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          disabledForegroundColor: white.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: space5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm + 2),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: space5),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm + 2),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 3,
        highlightElevation: 6,
        extendedTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: chipBackground,
        selectedColor: primarySurface,
        labelStyle: caption.copyWith(fontWeight: FontWeight.w500),
        secondaryLabelStyle: caption.copyWith(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: space3, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        side: BorderSide.none,
        showCheckmark: false,
      ),

      dividerTheme: const DividerThemeData(
        color: spacer,
        thickness: 1,
        space: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primarySurface,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? primary
                : deactivatedText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primary
                : deactivatedText,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: white,
        indicatorColor: primarySurface,
        selectedIconTheme: const IconThemeData(color: primary, size: 23),
        unselectedIconTheme: const IconThemeData(
          color: deactivatedText,
          size: 23,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: lightText,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: lightText,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: title.copyWith(fontSize: 18),
        contentTextStyle: body2.copyWith(color: lightText),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLg + 4),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(space4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm + 2),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: white,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: spacer,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: lightText,
        titleTextStyle: body1,
        subtitleTextStyle: caption,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm + 2),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
