import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Amount stepper với [−] ML [+] + presets
class AmountStepper extends StatelessWidget {
  final int currentAmount;
  final Function(int) onAmountChanged;

  const AmountStepper({
    super.key,
    required this.currentAmount,
    required this.onAmountChanged,
  });

  static const presets = [100, 250, 500, 750];
  static const stepAmount = 50;
  static const minAmount = 50;
  static const maxAmount = 2000;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main stepper row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepperButton(
              icon: Icons.remove,
              onTap: () {
                final newAmount = (currentAmount - stepAmount).clamp(minAmount, maxAmount);
                onAmountChanged(newAmount);
              },
              enabled: currentAmount > minAmount,
            ),

            const SizedBox(width: 24),

            // Amount display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '$currentAmount',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'ML',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            _StepperButton(
              icon: Icons.add,
              onTap: () {
                final newAmount = (currentAmount + stepAmount).clamp(minAmount, maxAmount);
                onAmountChanged(newAmount);
              },
              enabled: currentAmount < maxAmount,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Quick presets
        Text(
          'Presets',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: presets.map((preset) {
            final isSelected = currentAmount == preset;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _PresetButton(
                amount: preset,
                isSelected: isSelected,
                onTap: () => onAmountChanged(preset),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enabled ? AppColors.cyan : AppColors.textHint,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.cyan : AppColors.textHint,
          size: 24,
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final int amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          '${amount}ml',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}