import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// App theme configuration
class AppTheme {
  AppTheme._();

  /// Dark theme for AquaTrack
  static ThemeData get darkTheme {
    return ThemeData(
      // Base configuration
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: AppColors.primarySwatch,
      primaryColor: AppColors.cyanAccent,
      scaffoldBackgroundColor: AppColors.primaryBackground,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.cyanAccent,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.purpleXP,
        onSecondary: AppColors.textPrimary,
        tertiary: AppColors.cyanLight,
        onTertiary: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textPrimary,
        surface: AppColors.surfaceColor,
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderColor,
        outlineVariant: AppColors.dividerColor,
      ),

      // Typography theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        titleTextStyle: AppTextStyles.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.navIconActive,
        unselectedItemColor: AppColors.navIconInactive,
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle: AppTextStyles.navLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceColor,
        elevation: 2,
        shadowColor: AppColors.overlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyanAccent,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          shadowColor: AppColors.overlay,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonTextMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      // Outlined Button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cyanAccent,
          side: const BorderSide(color: AppColors.borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonTextMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      // Text Button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cyanAccent,
          textStyle: AppTextStyles.buttonTextMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input Decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceColor,
        hintStyle: AppTextStyles.inputHint,
        labelStyle: AppTextStyles.inputLabel,
        errorStyle: AppTextStyles.errorText,
        helperStyle: AppTextStyles.helperText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyanAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cyanAccent,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Chip theme
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceColor,
        deleteIconColor: AppColors.textTertiary,
        disabledColor: AppColors.textDisabled,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelSmall,
        brightness: Brightness.dark,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceColor,
        elevation: 8,
        shadowColor: AppColors.overlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // Bottom Sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceColor,
        elevation: 8,
        modalBackgroundColor: AppColors.surfaceColor,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Snackbar theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionTextColor: AppColors.cyanAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cyanAccent;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cyanAccent.withValues(alpha: 0.3);
          }
          return AppColors.borderColor;
        }),
      ),

      // Slider theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.cyanAccent,
        inactiveTrackColor: AppColors.borderColor,
        thumbColor: AppColors.cyanAccent,
        overlayColor: AppColors.cyanLight,
        valueIndicatorColor: AppColors.cyanAccent,
        valueIndicatorTextStyle: AppTextStyles.labelMedium,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cyanAccent,
        linearTrackColor: AppColors.borderColor,
        circularTrackColor: AppColors.borderColor,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

      // Primary Icon theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.cyanAccent,
        size: 24,
      ),

      // List Tile theme
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.surfaceColor,
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  /// System UI overlay style for status bar
  static const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.navBarBackground,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
