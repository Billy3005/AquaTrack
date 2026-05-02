import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Screen 02 — AI Coach
/// Chat UI với context-aware AI coach
class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Aqua AI', style: AppTextStyles.headingMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('online', style: AppTextStyles.caption),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'AI Coach Screen\n(Chat UI)',
          style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}