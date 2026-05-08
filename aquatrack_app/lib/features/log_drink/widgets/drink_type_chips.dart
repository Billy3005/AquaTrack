import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/drink_type.dart';

/// Drink type selection chips với icons theo design spec
class DrinkTypeChips extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const DrinkTypeChips({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: DrinkType.values.map((drinkType) {
        final isSelected = selectedType == drinkType.id;
        return _DrinkChip(
          drinkType: drinkType,
          isSelected: isSelected,
          onTap: () => onTypeSelected(drinkType.id),
        );
      }).toList(),
    );
  }
}

class _DrinkChip extends StatelessWidget {
  final DrinkType drinkType;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrinkChip({
    required this.drinkType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanAccent : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.cyanAccent
                : AppColors.borderColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textPrimary.withValues(alpha: 0.2)
                    : AppColors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                drinkType.icon,
                size: 16,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.cyanAccent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              drinkType.displayName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            // Hydration coefficient indicator
            if (drinkType.hydrationCoeff < 1.0) ...[
              const SizedBox(width: 4),
              Text(
                '${(drinkType.hydrationCoeff * 100).round()}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
