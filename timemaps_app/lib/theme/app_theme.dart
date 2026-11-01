import 'package:flutter/material.dart';

class AppTheme {
  // Swiss International Style Palette (Light Mode Exclusive)
  static const Color primary = Color(0xFF1A1A17);       // Swiss Dark Stone
  static const Color primaryDark = Color(0xFF0F0F0D);   // Pure Header Charcoal
  static const Color accent = Color(0xFF1E40AF);        // Swiss Royal Blue
  static const Color accentAmber = Color(0xFFD97706);   // Drop Amber
  static const Color accentEmerald = Color(0xFF059669); // Active Emerald
  static const Color accentRose = Color(0xFFE11D48);    // Campaign Rose

  // Semantic Indicators
  static const Color success = Color(0xFF059669);       // Active / On-Duty
  static const Color warning = Color(0xFFD97706);       // Pending / Due
  static const Color danger = Color(0xFFDC2626);        // Alert / Absent

  // Neutral Surfaces (Warm Stone System)
  static const Color bgLight = Color(0xFFF9F9F8);       // Stone 50 Page Background
  static const Color cardBg = Color(0xFFFFFFFF);        // Pure White Surface
  static const Color surfaceSubtle = Color(0xFFF3F3F1); // Stone 100 Subtle Fill
  static const Color borderSubtle = Color(0xFFE4E4DF);  // Stone 200 Border
  static const Color borderStrong = Color(0xFFD1D1C8);  // Stone 300 Divider
  
  // Text Colors (Opacity and Hierarchy)
  static const Color textMain = Color(0xFF1A1A17);      // Stone 900 Primary
  static const Color textSecondary = Color(0xFF525248); // Stone 600 Secondary
  static const Color textMuted = Color(0xFF737367);     // Stone 500 Tertiary
  static const Color textInverse = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textMain,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textMain),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textInverse,
          elevation: 0,
          minimumSize: const Size(44, 48), // 44dp+ minimum touch target
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
          side: const BorderSide(color: borderSubtle, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSubtle,
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
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
