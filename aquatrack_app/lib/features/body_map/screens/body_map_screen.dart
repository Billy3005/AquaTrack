import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Screen 03 — Ecosystem (Body Map)
/// SVG body với organ bubbles thay đổi màu theo hydration state
class BodyMapScreen extends StatelessWidget {
  const BodyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('HỆ SINH THÁI CƠ THỂ', style: AppTextStyles.headingMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Body Map Screen',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'SVG body + organ bubbles\n(3 states: khô hạn → phục hồi → nở rộ)',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
