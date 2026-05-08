import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              _buildAppBar(context),

              // Content
              Expanded(child: _buildContent(context, logState, ref)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text('Ghi nhận thức uống', style: AppTextStyles.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogDrinkState logState,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drink Type Selection
          Text('Loại thức uống', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),
          DrinkTypeChips(
            selectedType: logState.selectedDrinkType,
            onTypeSelected: (type) {
              ref.read(logDrinkNotifierProvider.notifier).selectDrinkType(type);
            },
          ),

          const SizedBox(height: 32),

          // Amount Selection
          Text('Lượng nước', style: AppTextStyles.headlineMedium),
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

          const SizedBox(height: 40),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: logState.amountMl > 0 && !logState.isLoading
                  ? () => _logDrink(context, ref)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanAccent,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: logState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.textPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Ghi nhận ${logState.amountMl}ml',
                      style: AppTextStyles.buttonTextLarge.copyWith(
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
    );
  }

  Future<void> _logDrink(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(logDrinkNotifierProvider.notifier).submitLog();

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã ghi nhận thành công!'),
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
