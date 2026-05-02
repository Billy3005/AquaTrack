import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Drink type selection chips với icons theo design spec
class DrinkTypeChips extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const DrinkTypeChips({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  static const drinkTypes = [
    {'id': 'water', 'emoji': '💧', 'label': 'Nước lọc'},
    {'id': 'tea', 'emoji': '🍵', 'label': 'Trà'},
    {'id': 'coffee', 'emoji': '☕', 'label': 'Cà phê'},
    {'id': 'juice', 'emoji': '🍊', 'label': 'Trái cây'},
    {'id': 'smoothie', 'emoji': '🥤', 'label': 'Sinh tố'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: drinkTypes.map((drink) {
        final isSelected = selectedType == drink['id'];
        return _DrinkChip(
          emoji: drink['emoji']!,
          label: drink['label']!,
          isSelected: isSelected,
          onTap: () => onTypeSelected(drink['id']!),
        );
      }).toList(),
    );
  }
}

class _DrinkChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrinkChip({
    required this.emoji,
    required this.label,
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
          color: isSelected ? AppColors.cyan : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}