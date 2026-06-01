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

  static Color _color(Color dark, Color light) => isDarkMode ? dark : light;

  // Brand Colors
  static Color get primary => _color(const Color(0xFFB4C5FF), const Color(0xFF2563EB));
  static Color get primaryLight => _color(const Color(0xFFEEEFFF), const Color(0xFFEBF0FF));
  static Color get primaryDark => _color(const Color(0xFF2563EB), const Color(0xFF1D4ED8));
  static Color get primaryContainer => _color(const Color(0xFF2563EB), const Color(0xFFDBEAFE));
  static Color get onPrimary => _color(const Color(0xFF002A78), const Color(0xFFFFFFFF));
  static Color get onPrimaryContainer => _color(const Color(0xFFEEEFFF), const Color(0xFF1E40AF));
  
  static Color get secondary => _color(const Color(0xFFD0BCFF), const Color(0xFF7C3AED));
  static Color get secondaryContainer => _color(const Color(0xFF571BC1), const Color(0xFFF3E8FF));
  static Color get onSecondary => _color(const Color(0xFF3C0091), const Color(0xFFFFFFFF));
  static Color get onSecondaryContainer => _color(const Color(0xFFC4ABFF), const Color(0xFF6B21A8));

  static Color get tertiary => _color(const Color(0xFFFFB596), const Color(0xFFD97706));
  static Color get tertiaryContainer => _color(const Color(0xFFBC4800), const Color(0xFFFEF3C7));
  static Color get onTertiary => _color(const Color(0xFF581E00), const Color(0xFFFFFFFF));
  static Color get onTertiaryContainer => _color(const Color(0xFFFFEDE6), const Color(0xFF92400E));

  // Background & Surface
  static Color get darkBg => _color(const Color(0xFF0D0D1A), const Color(0xFFF8FAFC));
  static Color get darkSurface => _color(const Color(0xFF12121F), const Color(0xFFFFFFFF));
  static Color get darkCard => _color(const Color(0xFF1E1E2C), const Color(0xFFFFFFFF));
  static Color get darkBorder => _color(const Color(0xFF434655), const Color(0xFFE2E8F0));
  static Color get surfaceVariant => _color(const Color(0xFF343342), const Color(0xFFF1F5F9));
  static Color get outline => _color(const Color(0xFF8D90A0), const Color(0xFF94A3B8));

  // Status Colors
  static Color get overdue => _color(const Color(0xFFFFB4AB), const Color(0xFFDC2626));
  static Color get pending => _color(const Color(0xFFFFB596), const Color(0xFFD97706));
  static Color get paid => _color(const Color(0xFFB4C5FF), const Color(0xFF2563EB));
  static Color get success => _color(const Color(0xFFB4F0C5), const Color(0xFF16A34A));
  static Color get onSuccess => _color(const Color(0xFF00391A), const Color(0xFFFFFFFF));
  static Color get error => _color(const Color(0xFFFFB4AB), const Color(0xFFDC2626));
  static Color get onError => _color(const Color(0xFF690005), const Color(0xFFFFFFFF));
  static Color get errorContainer => _color(const Color(0xFF93000A), const Color(0xFFFEE2E2));
  static Color get onErrorContainer => _color(const Color(0xFFFFDAD6), const Color(0xFF991B1B));

  // Text Colors
  static Color get textPrimary => _color(const Color(0xFFE3E0F4), const Color(0xFF0F172A));
  static Color get textSecondary => _color(const Color(0xFFC3C6D7), const Color(0xFF475569));
  static Color get textTertiary => _color(const Color(0xFF8D90A0), const Color(0xFF64748B));
  static Color get textHint => _color(const Color(0xFF6B7280), const Color(0xFF94A3B8));

  // Surface elevation colors from design
  static Color get surfaceBright => _color(const Color(0xFF383847), const Color(0xFFE2E8F0));
  static Color get surfaceContainerLow => _color(const Color(0xFF1A1A28), const Color(0xFFF8FAFC));
  static Color get surfaceContainer => _color(const Color(0xFF1E1E2C), const Color(0xFFFFFFFF));
  static Color get surfaceContainerHigh => _color(const Color(0xFF292937), const Color(0xFFF1F5F9));
  static Color get surfaceContainerHighest => _color(const Color(0xFF343342), const Color(0xFFE2E8F0));
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
      colorScheme: ColorScheme.dark(
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
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(
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
      colorScheme: ColorScheme.light(
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
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(
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