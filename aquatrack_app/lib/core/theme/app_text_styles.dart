import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography styles based on design prototype using SF Pro fonts
class AppTextStyles {
  AppTextStyles._();

  // SF Pro font families (with fallbacks)
  static const String _fontDisplay = 'SF Pro Display';
  static const String _fontText = 'SF Pro Text';
  static const String _fontRounded = 'SF Pro Rounded';

  // Display Styles (Hero headings) - Using SF Pro Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // Headline Styles - Section headers using SF Pro Display
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Title Styles - Using SF Pro Text
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Body Styles - Reading text using SF Pro Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontText,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontText,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontText,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  // Label Styles - Using SF Pro Rounded
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontRounded,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontRounded,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontRounded,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );

  // Special App-Specific Styles

  // Water amount display - Hero number using SF Pro Display
  static const TextStyle waterAmount = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 0.9,
    color: AppColors.cyanAccent,
    letterSpacing: -1.5,
  );

  // XP and level styles - Using SF Pro Rounded for gamification
  static const TextStyle xpText = TextStyle(
    fontFamily: _fontRounded,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.purpleXP,
  );

  static const TextStyle levelText = TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.purpleLight,
  );

  // Navigation label
  static const TextStyle navLabel = TextStyle(
    fontFamily: _fontRounded,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.4,
  );

  // Button text styles - SF Pro Text for buttons
  static const TextStyle buttonTextLarge = TextStyle(
    fontFamily: _fontText,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonTextMedium = TextStyle(
    fontFamily: _fontText,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonTextSmall = TextStyle(
    fontFamily: _fontText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  // Input field styles
  static const TextStyle inputText = TextStyle(
    fontFamily: _fontText,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: _fontText,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  static const TextStyle inputLabel = TextStyle(
    fontFamily: _fontText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Error and helper text
  static const TextStyle errorText = TextStyle(
    fontFamily: _fontText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.error,
  );

  static const TextStyle helperText = TextStyle(
    fontFamily: _fontText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  // Chat styles for AI Coach
  static const TextStyle chatMessage = TextStyle(
    fontFamily: _fontText,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle chatTime = TextStyle(
    fontFamily: _fontText,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textTertiary,
  );
}
