import 'package:flutter/material.dart';

/// AquaTrack Design System - Color Palette
/// Dark navy theme với Living Drop metaphor
class AppColors {
  // Background
  static const background = Color(0xFF0D1B2A); // dark navy
  static const surface = Color(0xFF112236); // card background
  static const surfaceLight = Color(0xFF1A3050); // elevated card

  // Accent
  static const cyan = Color(0xFF00B4D8); // primary CTA, drop fill
  static const cyanLight = Color(0xFF90E0EF); // drop highlight
  static const cyanDark = Color(0xFF0077B6); // drop shadow

  // Gamification
  static const xpPurple = Color(0xFF7B5EA7); // XP bar, level badge
  static const xpPurpleLight = Color(0xFFB8A0D4);

  // Streak
  static const streakOrange = Color(0xFFFF6B35); // streak badge

  // Status / organs
  static const organBrain = Color(0xFF4CAF50); // green — healthy
  static const organKidney = Color(0xFF00B4D8); // cyan
  static const organHeart = Color(0xFFE53935); // red
  static const organSkin = Color(0xFF9C27B0); // purple

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8FA8C8);
  static const textHint = Color(0xFF4A6080);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE53935);

  // Drop state colors (from HomeState logic)
  static const dropDehydrated = Color(0xFF1A2A3A); // dark empty
  static const dropLow = Color(0xFF1A4A7A); // navy-blue
  static const dropNormalCool = cyan; // bright cyan
  static const dropNormalHot = Color(0xFFFF6B35); // orange tint
  static const dropNearGoal = cyanLight; // bright
}