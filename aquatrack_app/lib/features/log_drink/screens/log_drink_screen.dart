import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/log_drink_provider.dart';
import '../widgets/drink_type_chips.dart';
import '../widgets/amount_stepper.dart';
import '../widgets/log_preview_card.dart';

/// Screen 06 — Log Drink
/// Drink type chips + amount stepper + preview card + CTA
class LogDrinkScreen extends ConsumerWidget {
  const LogDrinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logDrinkNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            '← Huỷ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        leadingWidth: 80,
        title: const Text(
          'Log thức uống',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drink Type Selection
            const Text(
              'Loại thức uống',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 16),
            DrinkTypeChips(
              selectedType: logState.selectedDrinkType,
              onTypeSelected: (type) {
                ref
                    .read(logDrinkNotifierProvider.notifier)
                    .selectDrinkType(type);
              },
            ),

            const SizedBox(height: 32),

            // Amount Selection
            const Text(
              'Lượng nước',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 16),
            AmountStepper(
              currentAmount: logState.amountMl,
              onAmountChanged: (amount) {
                ref.read(logDrinkNotifierProvider.notifier).setAmount(amount);
              },
            ),

            const SizedBox(height: 32),

            // Preview Card
            LogPreviewCard(
              amountMl: logState.amountMl,
              drinkType: logState.selectedDrinkType,
              effectiveAmount: logState.effectiveAmountMl,
              xpGained: logState.xpGained,
            ),

            const Spacer(),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: logState.amountMl > 0
                    ? () => _logDrink(context, ref)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Log ${logState.amountMl}ml',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: logState.amountMl > 0
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _logDrink(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(logDrinkNotifierProvider.notifier).submitLog();

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã log thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Close screen and return to home
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
