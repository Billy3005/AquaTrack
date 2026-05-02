import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Screen 04 — Stats (Wave Chart)
/// Weekly wave chart với AI insights
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('THỐNG KÊ', style: AppTextStyles.headingMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Stats Screen',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Wave Chart + AI Insights\n(Toggle: Tuần/Tháng)',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
