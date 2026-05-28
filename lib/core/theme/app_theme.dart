import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// App Theme System
/// Comprehensive Material 3 theme with TOL branding
/// Ensures visual consistency across all components
class AppTheme {
  // ============================================
  // COLOR SCHEMES
  // ============================================

  /// Light mode color scheme
  static ColorScheme get _lightColorScheme {
    return const ColorScheme(
      brightness: Brightness.light,
      // Primary colors (Navy brand)
      primary: AppColors.primaryNavy,
      onPrimary: AppColors.white,
      primaryContainer: Color(0xFFD1E4FF),
      onPrimaryContainer: Color(0xFF001D35),
      // Secondary colors (Cyan accent)
      secondary: AppColors.accentCyan,
      onSecondary: AppColors.white,
      secondaryContainer: Color(0xFFD0E4FF),
      onSecondaryContainer: Color(0xFF001D36),
      // Tertiary colors (Teal)
      tertiary: AppColors.tertiaryTeal,
      onTertiary: AppColors.white,
      tertiaryContainer: Color(0xFF97F0FF),
      onTertiaryContainer: Color(0xFF001F24),
      // Error colors
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      // Background colors
      surface: AppColors.white,
      onSurface: Color(0xFF1A1C1E),
      surfaceContainerHighest: AppColors.surfaceLight,
      onSurfaceVariant: AppColors.supportMedium,
      // Outline colors
      outline: Color(0xFF74777F),
      outlineVariant: Color(0xFFC4C7CF),
      // Other
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      inversePrimary: Color(0xFF9ECAFF),
    );
  }

  /// Dark mode color scheme
  static ColorScheme get _darkColorScheme {
    return const ColorScheme(
      brightness: Brightness.dark,
      // Primary colors (Navy brand - mantener)
      primary: AppColors
          .accentCyan, // En dark, primary se vuelve más claro para contraste
      onPrimary: AppColors.baseDark,
      primaryContainer: AppColors.primaryNavy,
      onPrimaryContainer: Color(0xFFD1E4FF),
      // Secondary colors (Cyan accent - mantener)
      secondary: AppColors.accentCyan,
      onSecondary: AppColors.baseDark,
      secondaryContainer: Color(0xFF004D68),
      onSecondaryContainer: Color(0xFFD0E4FF),
      // Tertiary colors (Teal - mantener para glow)
      tertiary: Color(0xFF79D1E8),
      onTertiary: AppColors.baseDark,
      tertiaryContainer: AppColors.tertiaryTeal,
      onTertiaryContainer: Color(0xFF97F0FF),
      // Error colors
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      // Background colors - Blue-tinted darks (no negro puro)
      surface: AppColors.baseDark, // #021024 - fondo scaffold
      onSurface: Color(0xFFE8EDF3), // Casi blanco azulado
      surfaceContainerHighest:
          AppColors.surfaceDarkElevated, // Cards/surfaces elevadas
      onSurfaceVariant: Color(0xFFB0BAC4), // Texto secundario más apagado
      // Outline colors - Blue-gray borders
      outline: AppColors.borderDark, // Bordes azul-gris
      outlineVariant: AppColors.borderDarkSubtle, // Bordes sutiles
      // Other
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE8EDF3),
      onInverseSurface: Color(0xFF0A1420),
      inversePrimary: AppColors.primaryNavy,
    );
  }

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      fontFamily: AppTypography.fontFamily,

      // Scaffold - Using gradient for depth in light mode
      scaffoldBackgroundColor: AppColors.surfaceLight,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: _lightColorScheme.onSurface,
        titleTextStyle: AppTypography.screenTitle.copyWith(
          color: _lightColorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: _lightColorScheme.onSurface,
          size: AppSpacing.mediumIcon,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppSpacing.lowElevation,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(
            color: AppColors.supportLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Navigation Bar Theme (Bottom Navigation)
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavHeight,
        elevation: AppSpacing.lowElevation,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.accentCyan.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelMedium.copyWith(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelMedium.copyWith(
            color: AppColors.supportMedium,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryNavy, size: 24);
          }
          return const IconThemeData(color: AppColors.supportMedium, size: 24);
        }),
      ),

      // Navigation Drawer Theme
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        indicatorColor: AppColors.accentCyan.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelLarge.copyWith(
              color: AppColors.primaryNavy,
            );
          }
          return AppTypography.labelLarge.copyWith(
            color: AppColors.supportMedium,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryNavy);
          }
          return const IconThemeData(color: AppColors.supportMedium);
        }),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.smallPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        iconColor: AppColors.supportMedium,
        textColor: _lightColorScheme.onSurface,
      ),

      // Filled Button Theme (Primary CTAs)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.largePadding,
            vertical: AppSpacing.cardPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.button,
          elevation: AppSpacing.lowElevation,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.largePadding,
            vertical: AppSpacing.cardPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          side: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
          textStyle: AppTypography.button,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: AppColors.white,
        elevation: AppSpacing.mediumElevation,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.cardPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.supportMedium,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.supportMedium.withValues(alpha: 0.6),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLight,
        thickness: 1,
        space: AppSpacing.mediumGap,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smallPadding,
          vertical: AppSpacing.tinyGap,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: AppSpacing.highElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.largeRadius),
        ),
        titleTextStyle: AppTypography.titleLarge,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        elevation: AppSpacing.highElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.largeRadius),
          ),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentCyan,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentCyan;
          }
          return AppColors.supportMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentCyan.withValues(alpha: 0.5);
          }
          return AppColors.surfaceLight;
        }),
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      fontFamily: AppTypography.fontFamily,

      // Scaffold
      scaffoldBackgroundColor:
          AppColors.baseDark, // Restored opaque background for stability

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: _darkColorScheme.onSurface,
        titleTextStyle: AppTypography.screenTitle.copyWith(
          color: _darkColorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: _darkColorScheme.onSurface,
          size: AppSpacing.mediumIcon,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppSpacing.lowElevation,
        color: AppColors.surfaceDark, // Blue-tinted dark surface
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavHeight,
        elevation: AppSpacing.lowElevation,
        backgroundColor: AppColors.surfaceDark, // Blue-tinted dark
        indicatorColor: AppColors.accentCyan.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelMedium.copyWith(
              color: AppColors.accentCyan,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelMedium.copyWith(
            color: AppColors.supportMedium,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accentCyan, size: 24);
          }
          return const IconThemeData(color: AppColors.supportMedium, size: 24);
        }),
      ),

      // Navigation Drawer Theme
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: AppColors.baseDark,
        elevation: 0,
        indicatorColor: AppColors.accentCyan.withValues(alpha: 0.2),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelLarge.copyWith(
              color: AppColors.accentCyan,
            );
          }
          return AppTypography.labelLarge.copyWith(
            color: AppColors.supportMedium,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accentCyan);
          }
          return const IconThemeData(color: AppColors.supportMedium);
        }),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.smallPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        iconColor: AppColors.supportMedium,
        textColor: _darkColorScheme.onSurface,
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentCyan,
          foregroundColor: AppColors.baseDark,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.largePadding,
            vertical: AppSpacing.cardPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.button,
          elevation: AppSpacing.lowElevation,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.largePadding,
            vertical: AppSpacing.cardPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          side: const BorderSide(color: AppColors.accentCyan, width: 1.5),
          textStyle: AppTypography.button,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentCyan,
        foregroundColor: AppColors.baseDark,
        elevation: AppSpacing.mediumElevation,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors
            .surfaceDarkElevated, // Slightly lighter blue-tinted surface
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.cardPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(color: _darkColorScheme.error, width: 1.5),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.supportMedium,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.supportMedium.withValues(alpha: 0.6),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDarkSubtle, // Blue-tinted border
        thickness: 1,
        space: AppSpacing.mediumGap,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDarkElevated, // Blue-tinted surface
        selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: _darkColorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smallPadding,
          vertical: AppSpacing.tinyGap,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDarkElevated, // Blue-tinted surface
        elevation: AppSpacing.highElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.largeRadius),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: _darkColorScheme.onSurface,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: _darkColorScheme.onSurface,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundLight, // Blue-tinted surface
        elevation: AppSpacing.highElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.largeRadius),
          ),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentCyan,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentCyan;
          }
          return AppColors.supportMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentCyan.withValues(alpha: 0.5);
          }
          return AppColors.surfaceDarkElevated; // Blue-tinted surface
        }),
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
