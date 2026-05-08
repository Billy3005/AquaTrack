import 'package:flutter/material.dart';

/// App color constants based on design prototype
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryBackground = Color(0xFF0D1B2A); // Dark navy
  static const Color secondaryBackground = Color(0xFF1B2951); // Lighter navy
  static const Color surfaceColor = Color(0xFF2A3B5C); // Card surfaces

  // Accent Colors
  static const Color cyanAccent = Color(0xFF00B4D8); // Main accent
  static const Color cyanLight = Color(0xFF33C5E8); // Lighter cyan
  static const Color cyanDark = Color(0xFF0094B8); // Darker cyan

  // XP & Gamification
  static const Color purpleXP = Color(0xFF7B5EA7); // XP color
  static const Color purpleLight = Color(0xFF9B7EC7); // Light purple
  static const Color purpleDark = Color(0xFF5B3E87); // Dark purple

  // Status Colors
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFEAB308); // Yellow
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFE2E8F0); // Light gray
  static const Color textTertiary = Color(0xFF94A3B8); // Medium gray
  static const Color textDisabled = Color(0xFF64748B); // Dark gray

  // Water Drop Colors
  static const Color dropEmpty = Color(0xFF334155); // Empty drop
  static const Color dropFilled = cyanAccent; // Filled drop
  static const Color dropGradientStart = Color(0xFF00B4D8); // Gradient start
  static const Color dropGradientEnd = Color(0xFF0284C7); // Gradient end

  // Liquid Type Colors
  static const Color waterColor = cyanAccent;
  static const Color teaColor = Color(0xFF92C5F7); // Light blue
  static const Color coffeeColor = Color(0xFF8B4513); // Brown
  static const Color juiceColor = Color(0xFFFFA500); // Orange
  static const Color sportsColor = Color(0xFF32CD32); // Lime green

  // Navigation
  static const Color navBarBackground = Color(0xFF1E293B); // Nav bar
  static const Color navIconActive = cyanAccent; // Active icon
  static const Color navIconInactive = Color(0xFF64748B); // Inactive icon

  // Overlays & Borders
  static const Color overlay = Color(0x80000000); // Black overlay
  static const Color borderColor = Color(0xFF475569); // Border
  static const Color dividerColor = Color(0xFF374151); // Divider

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [dropGradientStart, dropGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [purpleXP, purpleLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [primaryBackground, secondaryBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Material Color Swatch for ThemeData
  static const MaterialColor primarySwatch =
      MaterialColor(0xFF00B4D8, <int, Color>{
        50: Color(0xFFE0F7FF),
        100: Color(0xFFB3ECFF),
        200: Color(0xFF80E0FF),
        300: Color(0xFF4DD4FF),
        400: Color(0xFF26CAFF),
        500: Color(0xFF00B4D8),
        600: Color(0xFF00A7D3),
        700: Color(0xFF0097CC),
        800: Color(0xFF0088C4),
        900: Color(0xFF0070B8),
      });
}
