import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A custom Color implementation that resolves dynamically at runtime 
/// based on the active theme mode. This keeps the color references as compile-time
/// constants while supporting dynamic themes.
class ThemeColor extends Color {
  final Color darkColor;
  final Color lightColor;

  const ThemeColor(this.darkColor, this.lightColor) : super(0);

  @override
  int get value => AppColors.isDarkMode ? darkColor.value : lightColor.value;

  @override
  int toARGB32() => value;
}

/// FeeSync Color Palette (Stitch Design System - Midnight Obsidian / Light Slate)
class AppColors {
  static bool isDarkMode = true;

  // Brand Colors
  static const Color primary = ThemeColor(Color(0xFFB4C5FF), Color(0xFF2563EB));
  static const Color primaryLight = ThemeColor(Color(0xFFEEEFFF), Color(0xFFEBF0FF));
  static const Color primaryDark = ThemeColor(Color(0xFF2563EB), Color(0xFF1D4ED8));
  static const Color primaryContainer = ThemeColor(Color(0xFF2563EB), Color(0xFFDBEAFE));
  static const Color onPrimary = ThemeColor(Color(0xFF002A78), Color(0xFFFFFFFF));
  static const Color onPrimaryContainer = ThemeColor(Color(0xFFEEEFFF), Color(0xFF1E40AF));
  
  static const Color secondary = ThemeColor(Color(0xFFD0BCFF), Color(0xFF7C3AED));
  static const Color secondaryContainer = ThemeColor(Color(0xFF571BC1), Color(0xFFF3E8FF));
  static const Color onSecondary = ThemeColor(Color(0xFF3C0091), Color(0xFFFFFFFF));
  static const Color onSecondaryContainer = ThemeColor(Color(0xFFC4ABFF), Color(0xFF6B21A8));

  static const Color tertiary = ThemeColor(Color(0xFFFFB596), Color(0xFFD97706));
  static const Color tertiaryContainer = ThemeColor(Color(0xFFBC4800), Color(0xFFFEF3C7));
  static const Color onTertiary = ThemeColor(Color(0xFF581E00), Color(0xFFFFFFFF));
  static const Color onTertiaryContainer = ThemeColor(Color(0xFFFFEDE6), Color(0xFF92400E));

  // Background & Surface
  static const Color darkBg = ThemeColor(Color(0xFF0D0D1A), Color(0xFFF8FAFC));
  static const Color darkSurface = ThemeColor(Color(0xFF12121F), Color(0xFFFFFFFF));
  static const Color darkCard = ThemeColor(Color(0xFF1E1E2C), Color(0xFFFFFFFF));
  static const Color darkBorder = ThemeColor(Color(0xFF434655), Color(0xFFE2E8F0));
  static const Color surfaceVariant = ThemeColor(Color(0xFF343342), Color(0xFFF1F5F9));
  static const Color outline = ThemeColor(Color(0xFF8D90A0), Color(0xFF94A3B8));

  // Status Colors
  static const Color overdue = ThemeColor(Color(0xFFFFB4AB), Color(0xFFDC2626));
  static const Color pending = ThemeColor(Color(0xFFFFB596), Color(0xFFD97706));
  static const Color paid = ThemeColor(Color(0xFFB4C5FF), Color(0xFF2563EB));
  static const Color success = ThemeColor(Color(0xFFB4F0C5), Color(0xFF16A34A));
  static const Color onSuccess = ThemeColor(Color(0xFF00391A), Color(0xFFFFFFFF));
  static const Color error = ThemeColor(Color(0xFFFFB4AB), Color(0xFFDC2626));
  static const Color onError = ThemeColor(Color(0xFF690005), Color(0xFFFFFFFF));
  static const Color errorContainer = ThemeColor(Color(0xFF93000A), Color(0xFFFEE2E2));
  static const Color onErrorContainer = ThemeColor(Color(0xFFFFDAD6), Color(0xFF991B1B));

  // Text Colors
  static const Color textPrimary = ThemeColor(Color(0xFFE3E0F4), Color(0xFF0F172A));
  static const Color textSecondary = ThemeColor(Color(0xFFC3C6D7), Color(0xFF475569));
  static const Color textTertiary = ThemeColor(Color(0xFF8D90A0), Color(0xFF64748B));
  static const Color textHint = ThemeColor(Color(0xFF6B7280), Color(0xFF94A3B8));

  // Surface elevation colors from design
  static const Color surfaceBright = ThemeColor(Color(0xFF383847), Color(0xFFE2E8F0));
  static const Color surfaceContainerLow = ThemeColor(Color(0xFF1A1A28), Color(0xFFF8FAFC));
  static const Color surfaceContainer = ThemeColor(Color(0xFF1E1E2C), Color(0xFFFFFFFF));
  static const Color surfaceContainerHigh = ThemeColor(Color(0xFF292937), Color(0xFFF1F5F9));
  static const Color surfaceContainerHighest = ThemeColor(Color(0xFF343342), Color(0xFFE2E8F0));
}

/// Gradients from Stitch design
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A2563EB),
      Colors.transparent,
    ],
  );
}

/// FeeSync Theme
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.primary,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.darkSurface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.outline,
      ),

      // Typography
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w800),
          displayMedium: TextStyle(fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.2),
          labelMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.1),
          labelSmall: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.0),
        ),
      ).apply(
        bodyColor: AppColors.textSecondary,
        displayColor: AppColors.textPrimary,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.8),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: const CircleBorder(),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.primary,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.darkSurface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.outline,
      ),

      // Typography
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w800),
          displayMedium: TextStyle(fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.2),
          labelMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.1),
          labelSmall: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.0),
        ),
      ).apply(
        bodyColor: AppColors.textSecondary,
        displayColor: AppColors.textPrimary,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.8),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
    );
  }
}
