import 'package:flutter/material.dart';

/// App color constants based on design prototype
class AppColors {
  AppColors._();

  // Primary Colors (Exact from atoms.jsx)
  static const Color primary = Color(0xFF0EA5E9); // primary
  static const Color glow = Color(0xFF38BDF8); // glow
  static const Color deep = Color(0xFF0284C7); // deep
  static const Color heroDeep = Color(0xFF0C4A80); // heroDeep
  static const Color heroDeeper = Color(0xFF082F5C); // heroDeeper
  static const Color nightBase = Color(
    0xFF0B1120,
  ); // nightBase - main background
  static const Color nightSurface = Color(0xFF0F1A2E); // nightSurface - surface
  static const Color nightCard = Color(0xFF1E293B); // nightCard
  static const Color nightCardSoft = Color(0xFF172033); // nightCardSoft

  // Legacy compatibility
  static const Color primaryBackground = nightBase;
  static const Color secondaryBackground = nightSurface;
  static const Color surfaceColor = nightCard;
  static const Color surfaceColorSoft = nightCardSoft;

  // Accent Colors (Exact from atoms.jsx)
  static const Color cyanAccent = glow; // Using glow as cyan accent
  static const Color cyanLight = Color(0xFF7DD3FC); // Lighter cyan
  static const Color cyanDark = deep; // Using deep as dark cyan
  static const Color cyanDeep = heroDeep; // Hero section deep
  static const Color cyanDeeper = heroDeeper; // Deepest cyan shade

  // XP & Gamification (Exact from atoms.jsx)
  static const Color purpleXP = Color(0xFF818CF8); // purple
  static const Color purpleDeep = Color(0xFF4F46E5); // purpleDeep
  static const Color green = Color(0xFF059669); // green
  static const Color amber = Color(0xFFF59E0B); // amber

  // Status Colors
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFEAB308); // Yellow
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Text Colors (Exact from atoms.jsx)
  static const Color textPrimary = Color(0xFFF1F5F9); // textPrimary
  static const Color textSecondary = Color(0xFF94A3B8); // textSecondary
  static const Color textMuted = Color(0xFF64748B); // textMuted
  static const Color textBright = Color(0xFFBAE6FD); // textBright
  static const Color textTertiary = textMuted; // Legacy compatibility

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
  static const Color navBarBackground = Color(
    0xFF253347,
  ); // Nav bar matching surface
  static const Color navIconActive = cyanAccent; // Active cyan
  static const Color navIconInactive = Color(0xFF7A8B9A); // Inactive muted

  // Overlays & Borders (Exact from atoms.jsx)
  static const Color overlay = Color(0x80000000); // Black overlay
  static const Color border = Color(
    0x2638BDF8,
  ); // rgba(56,189,248,0.15) from atoms.jsx
  static const Color borderColor = Color(0xFF3A4B5C); // Subtle border
  static const Color borderActive = glow; // Active cyan border using glow
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
