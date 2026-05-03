import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/drink_type.dart';

/// Preview card "SAU KHI LOG" theo design spec
class LogPreviewCard extends StatelessWidget {
  final int amountMl;
  final String drinkType;
  final int effectiveAmount;
  final int xpGained;

  const LogPreviewCard({
    super.key,
    required this.amountMl,
    required this.drinkType,
    required this.effectiveAmount,
    required this.xpGained,
  });

  @override
  Widget build(BuildContext context) {
    final drinkTypeEnum = DrinkType.fromId(drinkType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyanAccent.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.preview,
                color: AppColors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'PREVIEW',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Drink info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.borderColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    drinkTypeEnum.icon,
                    color: AppColors.cyanAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${amountMl}ml ${drinkTypeEnum.displayName}',
                        style: AppTextStyles.titleMedium,
                      ),
                      if (drinkTypeEnum.hydrationCoeff != 1.0)
                        Text(
                          '→ ${effectiveAmount}ml hiệu quả (${(drinkTypeEnum.hydrationCoeff * 100).round()}%)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.cyanAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // XP and rewards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.purpleXP.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.purpleXP.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purpleXP.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+$xpGained XP',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.purpleXP,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tích lũy điểm kinh nghiệm',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.purpleXP,
                  size: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Motivation message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.water_drop,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tuyệt vời! Bạn đang duy trì thói quen hydration tốt.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
