import 'package:flutter/material.dart';

class AppTheme {
  // Modern Enterprise Executive Palette
  static const Color primary = Color(0xFF0F172A);       // Slate 900 (Deep Navy / Charcoal)
  static const Color primaryDark = Color(0xFF020617);   // Slate 950 (True Obsidian)
  static const Color primaryLight = Color(0xFF1E293B);  // Slate 800
  static const Color accent = Color(0xFF2563EB);        // Electric Royal Blue 600
  static const Color accentHover = Color(0xFF1D4ED8);   // Blue 700
  static const Color accentIndigo = Color(0xFF4F46E5);  // Indigo 600
  static const Color accentTeal = Color(0xFF0D9488);    // Teal 600

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color successBg = Color(0xFFECFDF5);     // Emerald 50
  static const Color successBorder = Color(0xFFA7F3D0); // Emerald 200
  static const Color successText = Color(0xFF047857);   // Emerald 700

  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color warningBg = Color(0xFFFFFBEB);     // Amber 50
  static const Color warningBorder = Color(0xFFFDE68A); // Amber 200
  static const Color warningText = Color(0xFFB45309);   // Amber 700

  static const Color danger = Color(0xFFEF4444);        // Rose / Red 500
  static const Color dangerBg = Color(0xFFFEF2F2);      // Red 50
  static const Color dangerBorder = Color(0xFFFECACA);  // Red 200
  static const Color dangerText = Color(0xFFB91C1C);    // Red 700

  static const Color info = Color(0xFF3B82F6);          // Blue 500
  static const Color infoBg = Color(0xFFEFF6FF);        // Blue 50
  static const Color infoBorder = Color(0xFFBFDBFE);    // Blue 200
  static const Color infoText = Color(0xFF1D4ED8);      // Blue 700

  static const Color purple = Color(0xFF8B5CF6);        // Purple 500
  static const Color purpleBg = Color(0xFFF5F3FF);      // Purple 50
  static const Color purpleBorder = Color(0xFFDDD6FE);  // Purple 200
  static const Color purpleText = Color(0xFF6D28D9);    // Purple 700

  // Direct Constant Literals for full backward compatibility in const constructors
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);

  // Neutral Surfaces & Card Tokens
  static const Color bgLight = Color(0xFFF8FAFC);       // Slate 50 Neutral Canvas
  static const Color cardBg = Color(0xFFFFFFFF);        // Crisp White Surface
  static const Color surfaceSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceMuted = Color(0xFFE2E8F0);  // Slate 200
  static const Color borderSubtle = Color(0xFFE2E8F0);  // Slate 200
  static const Color borderStrong = Color(0xFFCBD5E1);  // Slate 300

  // Text Hierarchy
  static const Color textMain = Color(0xFF0F172A);      // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF64748B);     // Slate 500
  static const Color textLight = Color(0xFF94A3B8);     // Slate 400
  static const Color textInverse = Colors.white;

  // Soft Modern Box Shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: cardBg,
        surfaceContainerHighest: surfaceSubtle,
        onSurface: textMain,
        outline: borderSubtle,
      ),
      scaffoldBackgroundColor: bgLight,
      
      // Modern AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: textMain, size: 22),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textInverse,
          elevation: 0,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          side: const BorderSide(color: borderSubtle, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Form Controls Theme (Prevents Overflows with clean insets)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSubtle,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textLight, fontSize: 13),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),

      // Chips Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSubtle,
        side: const BorderSide(color: borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      // TabBar Theme
      tabBarTheme: const TabBarTheme(
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: primary,
        unselectedLabelColor: textMuted,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: borderSubtle,
      ),

      // BottomSheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: textMain,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
