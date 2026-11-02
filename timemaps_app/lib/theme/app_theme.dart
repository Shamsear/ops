import 'package:flutter/material.dart';

// =============================================================================
// 1. DESIGN SYSTEM TOKENS (MyWisdom Healthcare Aesthetic)
// =============================================================================

/// 1.1 Color Tokens
abstract final class AppColors {
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color primary = Color(0xFF1E1B4B); // Deep Indigo
  static const Color primarySoft = Color(0xFFEEF2FF);

  static const Color accent = Color(0xFF2563EB);
  static const Color accentSoft = Color(0xFFEFF6FF);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFE11D48);
  static const Color dangerSoft = Color(0xFFFFF1F2);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);

  // Status border helper (20% opacity of status foreground)
  static Color statusBorder(Color foreground) => foreground.withOpacity(0.20);

  // Retailer chain branding map (Background Soft, Foreground)
  static (Color, Color) retailerColors(String chain) {
    final lower = chain.toLowerCase();
    if (lower.contains('lulu')) {
      return (const Color(0xFFECFDF5), const Color(0xFF059669)); // Emerald
    } else if (lower.contains('carrefour')) {
      return (const Color(0xFFEFF6FF), const Color(0xFF2563EB)); // Cobalt Blue
    } else if (lower.contains('spinneys')) {
      return (const Color(0xFFF0FDF4), const Color(0xFF15803D)); // Forest Green
    } else if (lower.contains('union coop') || lower.contains('unioncoop')) {
      return (const Color(0xFFFFF7ED), const Color(0xFFEA580C)); // Warm Amber
    } else if (lower.contains('choithrams')) {
      return (const Color(0xFFFEF2F2), const Color(0xFFDC2626)); // Crimson
    } else if (lower.contains('al maya')) {
      return (const Color(0xFFF5F3FF), const Color(0xFF7C3AED)); // Violet
    }
    return (surfaceMuted, textSecondary);
  }
}

/// 1.2 Typography Tokens (Compact MyWisdom Scale)
abstract final class AppText {
  static const TextStyle micro = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.35,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle title = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle display = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.2,
  );
}

/// 1.3 Spacing Tokens
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  static const double screenH = 16.0; // horizontal page gutter
  static const double cardPadCompact = 14.0;
  static const double cardPad = 16.0;
  static const double sectionGap = 20.0;
  static const double itemGap = 10.0;

  // Nav Clearance: accounts for LiquidGlassNavBar height + margin + breathing room
  static const double navClearance = 76.0;
}

/// 1.4 Radius Tokens
abstract final class AppRadius {
  static const double card = 18.0;
  static const double inner = 12.0;
  static const double input = 14.0;
  static const double iconBox = 11.0;
  static const double pill = 999.0;
  static const double sheet = 24.0;
}

/// 1.5 Shadow Tokens (Dual Ambient Depth)
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 2,
      offset: Offset(0, -1),
    ),
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 24,
      offset: Offset(0, -4),
    ),
  ];
}

// =============================================================================
// BACKWARD COMPATIBILITY ALIASES & THEMEDATA
// =============================================================================

class AppTheme {
  // Aliases for AppColors
  static const Color canvasBg = AppColors.canvas;

  static const Color bgLight = AppColors.canvas;

  static const Color surfaceWhite = AppColors.surface;

  static const Color cardBg = AppColors.surface;

  static const Color surfaceSubtle = AppColors.surfaceMuted;

  static const Color borderSubtle = AppColors.borderSubtle;

  static const Color borderStrong = AppColors.borderStrong;

  static const Color surfaceMuted = AppColors.surfaceMuted;

  static const Color primary = AppColors.primary;

  static const Color primaryDark = AppColors.primary;

  static const Color primaryLight = Color(0xFF1E293B);

  static const Color primarySlate = Color(0xFF334155);

  static const Color accent = AppColors.accent;

  static const Color accentHover = Color(0xFF1D4ED8);

  static const Color accentGlow = Color(0xFF60A5FA);

  static const Color accentIndigo = Color(0xFF4F46E5);

  static const Color accentTeal = Color(0xFF0D9488);

  // Status aliases
  static const Color success = AppColors.success;

  static const Color successBg = AppColors.successSoft;

  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color successText = AppColors.success;

  static const Color warning = AppColors.warning;

  static const Color warningBg = AppColors.warningSoft;

  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color warningText = AppColors.warning;

  static const Color danger = AppColors.danger;

  static const Color dangerBg = AppColors.dangerSoft;

  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color dangerText = AppColors.danger;

  static const Color info = AppColors.accent;

  static const Color infoBg = AppColors.accentSoft;

  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color infoText = AppColors.accent;

  static const Color purple = AppColors.purple;

  static const Color purpleBg = AppColors.purpleSoft;

  static const Color purpleBorder = Color(0xFFDDD6FE);

  static const Color purpleText = AppColors.purple;

  static const Color accentEmerald = AppColors.success;

  static const Color accentAmber = AppColors.warning;

  static const Color accentRose = AppColors.danger;

  // Text aliases
  static const Color textMain = AppColors.textPrimary;

  static const Color textSecondary = AppColors.textSecondary;

  static const Color textMuted = AppColors.textMuted;

  static const Color textLight = AppColors.textMuted;

  static const Color textInverse = Colors.white;

  // Radius aliases
  static const double radiusSmall = AppRadius.inner;

  static const double radiusMedium = AppRadius.card;

  static const double radiusLarge = AppRadius.card;

  static const double radiusExtraLarge = AppRadius.sheet;

  static const double radiusPill = AppRadius.pill;

  // Shadow aliases
  static List<BoxShadow> get cardShadow => AppShadows.card;

  static List<BoxShadow> get elevatedShadow => AppShadows.card;

  static List<BoxShadow> get floatingShadow => AppShadows.raised;

  static List<BoxShadow> get glassShadow => AppShadows.card;

  // Monospace
  static const TextStyle monoStyle = AppText.mono;

  /// Main Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceMuted,
        outline: AppColors.borderSubtle,
        outlineVariant: AppColors.borderStrong,
      ),
      scaffoldBackgroundColor: AppColors.canvas,

      // Text Theme
      textTheme: const TextTheme(
        labelSmall: AppText.micro,
        bodySmall: AppText.bodySmall,
        bodyMedium: AppText.body,
        bodyLarge: AppText.bodyBold,
        titleMedium: AppText.title,
        titleLarge: AppText.titleLarge,
        headlineSmall: AppText.display,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppText.titleLarge,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 20),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1.0,
        space: 1.0,
      ),

      // BottomSheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: AppText.titleLarge,
        contentTextStyle: AppText.body,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.inner),
        ),
        contentTextStyle: AppText.bodyBold.copyWith(color: Colors.white),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: AppText.bodySmall.copyWith(color: AppColors.textMuted),
        hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
        helperStyle: AppText.caption,
        errorStyle: AppText.caption.copyWith(color: AppColors.danger),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          textStyle: AppText.bodyBold,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          textStyle: AppText.bodyBold,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppText.bodyBold.copyWith(color: AppColors.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.inner),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: AppText.micro,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
    );
  }
}
