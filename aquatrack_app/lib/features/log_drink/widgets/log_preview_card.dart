import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../home/providers/home_provider.dart';

/// Preview card "SAU KHI LOG" theo design spec
class LogPreviewCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeNotifierProvider);

    return summaryAsync.when(
      loading: () => const _LoadingCard(),
      error: (_, __) => const _ErrorCard(),
      data: (summary) {
        final newTotal = summary.totalEffectiveMl + effectiveAmount;
        final newProgress = (newTotal / summary.dailyGoalMl).clamp(0.0, 1.0);
        final remainingMl =
            (summary.dailyGoalMl - newTotal).clamp(0, summary.dailyGoalMl);
        final hydrationCoeff = AppConstants.hydrationCoeff[drinkType] ?? 1.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'SAU KHI LOG',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 16),

              // Effective amount info (if hydration coeff != 1.0)
              if (hydrationCoeff != 1.0) ...[
                Row(
                  children: [
                    Text(
                      '${amountMl}ml ${_getDrinkLabel(drinkType)}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '→ ${effectiveAmount}ml hiệu quả',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // New total
              Row(
                children: [
                  Text(
                    'Tổng mới:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '$newTotal / ${summary.dailyGoalMl}ml',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: newProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Progress percentage
              Text(
                '${(newProgress * 100).round()}% hoàn thành',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.cyan,
                ),
              ),

              const SizedBox(height: 16),

              // XP gained and remaining
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.xpPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$xpGained XP',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.xpPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remainingMl > 0
                          ? 'còn ${remainingMl}ml để đạt goal'
                          : '🎉 Goal đã hoàn thành!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: remainingMl > 0
                            ? AppColors.textSecondary
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDrinkLabel(String drinkType) {
    const labels = {
      'water': 'nước lọc',
      'tea': 'trà',
      'coffee': 'cà phê',
      'juice': 'nước trái cây',
      'smoothie': 'sinh tố',
    };
    return labels[drinkType] ?? drinkType;
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.cyan,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Text(
            'Không thể load preview',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
