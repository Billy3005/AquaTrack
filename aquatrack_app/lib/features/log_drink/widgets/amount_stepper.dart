import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Amount stepper với [−] ML [+] + presets
class AmountStepper extends StatelessWidget {
  final int currentAmount;
  final Function(int) onAmountChanged;

  const AmountStepper({
    super.key,
    required this.currentAmount,
    required this.onAmountChanged,
  });

  static const presets = [150, 250, 350];
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
                HapticFeedback.lightImpact();
                final newAmount = (currentAmount - stepAmount).clamp(
                  minAmount,
                  maxAmount,
                );
                onAmountChanged(newAmount);
              },
              enabled: currentAmount > minAmount,
            ),

            const SizedBox(width: 24),

            // Amount display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                children: [
                  Text(
                    '$currentAmount',
                    style: AppTextStyles.waterAmount.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'ML',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            _StepperButton(
              icon: Icons.add,
              onTap: () {
                HapticFeedback.lightImpact();
                final newAmount = (currentAmount + stepAmount).clamp(
                  minAmount,
                  maxAmount,
                );
                onAmountChanged(newAmount);
              },
              enabled: currentAmount < maxAmount,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Quick presets
        Text(
          'Lượng thường dùng',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        // Row + Expanded so all four presets share the width on a single line
        // (a Wrap dropped 500ml to a lonely second row).
        Row(
          children: [
            for (int i = 0; i < presets.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _PresetButton(
                  amount: presets[i],
                  isSelected: currentAmount == presets[i],
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAmountChanged(presets[i]);
                  },
                ),
              ),
            ],
          ],
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
          color: enabled
              ? AppColors.surfaceColor
              : AppColors.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enabled
                ? AppColors.cyanAccent
                : AppColors.borderColor.withValues(alpha: 0.3),
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.cyanAccent.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.cyanAccent : AppColors.textTertiary,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanAccent : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.cyanAccent
                : AppColors.borderColor.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyanAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          '${amount}ml',
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
