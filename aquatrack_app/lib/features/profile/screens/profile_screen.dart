import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Screen 08 — Profile
/// Avatar collection, themes, stats, settings
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('HỒ SƠ', style: AppTextStyles.headingMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Profile Screen',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Avatar + Themes + Stats\n(Minh Nguyễn · Aqua Warrior)',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
