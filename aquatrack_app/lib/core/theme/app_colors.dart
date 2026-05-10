import 'package:flutter/material.dart';

/// App color constants based on design prototype
class AppColors {
  AppColors._();

  // Primary Colors (Exact prototype match)
  static const Color primaryBackground =
      Color(0xFF0D1B2A); // Exact prototype navy
  static const Color secondaryBackground =
      Color(0xFF1B2C47); // Lighter navy gradient
  static const Color surfaceColor = Color(0xFF253347); // Card surfaces
  static const Color surfaceColorSoft = Color(0xFF1F3049); // Soft card variant

  // Accent Colors (Exact prototype match)
  static const Color cyanAccent = Color(0xFF00B4D8); // Prototype primary cyan
  static const Color cyanLight = Color(0xFF89CCDB); // Light cyan glow
  static const Color cyanDark = Color(0xFF0081A7); // Deep cyan
  static const Color cyanDeep = Color(0xFF003459); // Hero section deep
  static const Color cyanDeeper = Color(0xFF001D2E); // Deepest cyan shade

  // XP & Gamification (Updated to match design prototype)
  static const Color purpleXP = Color(0xFF818CF8); // purple
  static const Color purpleDeep = Color(0xFF4F46E5); // purpleDeep
  static const Color green = Color(0xFF059669); // green
  static const Color amber = Color(0xFFF59E0B); // amber

  // Status Colors
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFEAB308); // Yellow
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Text Colors (Exact prototype match)
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white for headings
  static const Color textSecondary = Color(0xFFB8C5D1); // Medium gray-blue
  static const Color textTertiary = Color(0xFF7A8B9A); // Muted text
  static const Color textBright = Color(0xFF89CCDB); // Cyan-tinted bright text

  // Water Drop Colors (Updated to match design prototype)
  static const Color dropEmpty = Color(0xFF1E3A5F); // Empty drop (low state)
  static const Color dropFilled = cyanAccent; // Filled drop
  static const Color dropGradientStart = cyanLight; // Gradient start (glow)
  static const Color dropGradientEnd = cyanAccent; // Gradient end (primary)

  // Liquid Type Colors
  static const Color waterColor = cyanAccent;
  static const Color teaColor = Color(0xFF92C5F7); // Light blue
  static const Color coffeeColor = Color(0xFF8B4513); // Brown
  static const Color juiceColor = Color(0xFFFFA500); // Orange
  static const Color sportsColor = Color(0xFF32CD32); // Lime green

  // Navigation (Exact prototype match)
  static const Color navBarBackground =
      Color(0xFF253347); // Nav bar matching surface
  static const Color navIconActive = cyanAccent; // Active cyan
  static const Color navIconInactive = Color(0xFF7A8B9A); // Inactive muted

  // Overlays & Borders (Exact prototype match)
  static const Color overlay = Color(0x80000000); // Black overlay
  static const Color border =
      Color(0x1A00B4D8); // Subtle cyan border (10% opacity)
  static const Color borderColor = Color(0xFF3A4B5C); // Subtle border
  static const Color borderActive = cyanLight; // Active cyan border
  static const Color dividerColor = Color(0xFF2A3B4C); // Subtle divider

  // Additional Colors
  static const Color textDisabled = Color(0xFF5A6B7C); // Disabled text
  static const Color purpleLight = Color(0xFFA78BFA); // Light purple for XP

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [dropGradientStart, dropGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [purpleXP, purpleDeep],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [primaryBackground, secondaryBackground, surfaceColor],
    stops: [0.0, 0.6, 1.0],
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
