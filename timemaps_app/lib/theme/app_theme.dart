import 'package:flutter/material.dart';

/// IML Operations Platform Enterprise Native Design System
/// Inspired by top-tier native mobile interfaces (Linear, Airbnb, Revolut, Phantom).
/// Implements 60/30/10 color hierarchy, 8-pt spacing, organic depth, and thumb-zone ergonomics.
class AppTheme {
  // Brand Primary & Canvas Tokens (60% Neutral Base)
  static const Color canvasBg = Color(0xFFF8FAFC);       // Slate 50 Neutral Canvas
  static const Color bgLight = Color(0xFFF8FAFC);        // Backward compatibility
  static const Color surfaceWhite = Color(0xFFFFFFFF);   // Pure Crisp Surface
  static const Color cardBg = Color(0xFFFFFFFF);         // Backward compatibility
  static const Color surfaceSubtle = Color(0xFFF1F5F9);  // Slate 100 Subtle Fill
  static const Color surfaceMuted = Color(0xFFE2E8F0);   // Slate 200 Card Dividers
  static const Color borderSubtle = Color(0xFFE2E8F0);   // Hairline Card Border
  static const Color borderStrong = Color(0xFFCBD5E1);   // Slate 300 Interactive Border

  // Deep Obsidian & Enterprise Executives (30% Structural Depth)
  static const Color primaryDark = Color(0xFF070D18);    // Deepest Obsidian Space
  static const Color primary = Color(0xFF0F172A);        // Slate 900 Enterprise Charcoal
  static const Color primaryLight = Color(0xFF1E293B);   // Slate 800 Elevated Dark
  static const Color primarySlate = Color(0xFF334155);   // Slate 700 Accent

  // Accent & Jewel Highlights (10% Intentional Spark)
  static const Color accent = Color(0xFF2563EB);         // Electric Royal Cobalt 600
  static const Color accentHover = Color(0xFF1D4ED8);    // Deep Cobalt 700
  static const Color accentGlow = Color(0xFF60A5FA);     // Cobalt Light 400
  static const Color accentIndigo = Color(0xFF4F46E5);   // Electric Indigo
  static const Color accentTeal = Color(0xFF0D9488);     // Sea Teal

  // Semantic Status Colorway
  static const Color success = Color(0xFF10B981);        // Vivid Emerald 500
  static const Color successBg = Color(0xFFECFDF5);      // Emerald 50 Tint
  static const Color successBorder = Color(0xFFA7F3D0);  // Emerald 200
  static const Color successText = Color(0xFF047857);    // Emerald 700

  static const Color warning = Color(0xFFF59E0B);        // Radiant Amber 500
  static const Color warningBg = Color(0xFFFFFBEB);      // Amber 50 Tint
  static const Color warningBorder = Color(0xFFFDE68A);  // Amber 200
  static const Color warningText = Color(0xFFB45309);    // Amber 700

  static const Color danger = Color(0xFFEF4444);         // Rose Crimson 500
  static const Color dangerBg = Color(0xFFFEF2F2);       // Rose 50 Tint
  static const Color dangerBorder = Color(0xFFFECACA);   // Rose 200
  static const Color dangerText = Color(0xFFB91C1C);     // Rose 700

  static const Color info = Color(0xFF3B82F6);           // Sky Blue 500
  static const Color infoBg = Color(0xFFEFF6FF);         // Blue 50 Tint
  static const Color infoBorder = Color(0xFFBFDBFE);     // Blue 200
  static const Color infoText = Color(0xFF1D4ED8);       // Blue 700

  static const Color purple = Color(0xFF8B5CF6);         // Violet 500
  static const Color purpleBg = Color(0xFFF5F3FF);       // Violet 50 Tint
  static const Color purpleBorder = Color(0xFFDDD6FE);   // Violet 200
  static const Color purpleText = Color(0xFF6D28D9);     // Violet 700

  // Direct Constant Literals
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);

  // Typography Hierarchy Tokens
  static const Color textMain = Color(0xFF0F172A);       // 100% Dark Headings
  static const Color textSecondary = Color(0xFF475569);  // 80% Body Slate
  static const Color textMuted = Color(0xFF64748B);      // 60% Caption Slate
  static const Color textLight = Color(0xFF94A3B8);      // 40% Placeholder Slate
  static const Color textInverse = Colors.white;

  // Spacing Tokens (Strict 8-Point Grid)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Corner Radius Tokens
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 22.0;
  static const double radiusExtraLarge = 28.0;
  static const double radiusPill = 999.0;

  // iOS Liquid Glassmorphic Design Tokens (Cross-Platform)
  static const double glassBlur = 22.0;
  static const double glassOpacity = 0.72;
  static Color get glassTintLight => Colors.white.withOpacity(0.72);
  static Color get glassTintDark => const Color(0xFF070D18).withOpacity(0.78);

  static LinearGradient get glassBorderGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.75), // Top-left specular catch
      Colors.white.withOpacity(0.35), // Mid reflection
      Colors.white.withOpacity(0.12), // Bottom-right shadow fade
    ],
    stops: const [0.0, 0.45, 1.0],
  );

  static List<BoxShadow> get glassShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: primaryDark.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Soft Organic Tinted Shadows (Never Pure Gray/Black)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.025),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.015),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.12),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: accent.withOpacity(0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowBlue => [
    BoxShadow(
      color: accent.withOpacity(0.35),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get glowEmerald => [
    BoxShadow(
      color: success.withOpacity(0.35),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  // Tabular Monospace TextStyle for Numbers, Codes & Timestamps
  static const TextStyle monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.2,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: surfaceWhite,
        surfaceContainerHighest: surfaceSubtle,
        onSurface: textMain,
        outline: borderSubtle,
      ),
      scaffoldBackgroundColor: canvasBg,
      
      // Native-Style Glass / Flat AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: primary, size: 22),
      ),

      // Card Theme with Soft Precision Borders
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),

      // Tactile Primary Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textInverse,
          elevation: 0,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.15,
          ),
        ),
      ),

      // Secondary Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          minimumSize: const Size(40, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          side: const BorderSide(color: borderSubtle, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),

      // Native Input Fields (Comfortable Tap Insets, Rounded 14px)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSubtle,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: textLight, fontSize: 13, fontWeight: FontWeight.w400),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),

      // Segment & Filter Chips
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSubtle,
        side: const BorderSide(color: borderSubtle, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        labelStyle: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: textMain,
          letterSpacing: -0.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Segmented TabBar
      tabBarTheme: const TabBarTheme(
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: primary,
        unselectedLabelColor: textMuted,
        labelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: -0.15),
        unselectedLabelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
        dividerColor: borderSubtle,
      ),

      // BottomSheet Theme with Modern Organic Radius
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusExtraLarge)),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusExtraLarge),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.3,
        ),
      ),

      // SnackBar Theme (Floating Pill)
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
