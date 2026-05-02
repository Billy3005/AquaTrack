import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/stats_provider.dart';

/// Period selector widget cho Week/Month toggle
class PeriodSelector extends StatelessWidget {
  final StatsPeriod selectedPeriod;
  final ValueChanged<StatsPeriod> onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton(
            period: StatsPeriod.week,
            label: 'TUẦN',
            isSelected: selectedPeriod == StatsPeriod.week,
          ),
          _buildPeriodButton(
            period: StatsPeriod.month,
            label: 'THÁNG',
            isSelected: selectedPeriod == StatsPeriod.month,
          ),
        ],
      ),
    );
  }

  /// Build individual period button
  Widget _buildPeriodButton({
    required StatsPeriod period,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.4),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon for visual appeal
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                period == StatsPeriod.week
                    ? Icons.calendar_view_week_outlined
                    : Icons.calendar_month_outlined,
                size: 16,
                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            // Label text
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version of period selector for smaller spaces
class CompactPeriodSelector extends StatelessWidget {
  final StatsPeriod selectedPeriod;
  final ValueChanged<StatsPeriod> onPeriodChanged;

  const CompactPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactButton(
            period: StatsPeriod.week,
            label: '7D',
            isSelected: selectedPeriod == StatsPeriod.week,
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          _buildCompactButton(
            period: StatsPeriod.month,
            label: '30D',
            isSelected: selectedPeriod == StatsPeriod.month,
          ),
        ],
      ),
    );
  }

  /// Build compact period button
  Widget _buildCompactButton({
    required StatsPeriod period,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.cyan : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 11,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
