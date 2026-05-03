import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// XP Progress Bar với current level và progress to next level
class XPProgressBar extends StatelessWidget {
  final int currentLevel;
  final int currentXP;
  final int nextLevelXP;
  final bool isAnimating;

  const XPProgressBar({
    super.key,
    required this.currentLevel,
    required this.currentXP,
    required this.nextLevelXP,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        nextLevelXP > 0 ? (currentXP / nextLevelXP).clamp(0.0, 1.0) : 1.0;
    final remainingXP = nextLevelXP - currentXP;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.xpPurple.withValues(alpha: 0.2),
            AppColors.cyan.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnimating
              ? AppColors.xpPurple
              : AppColors.xpPurple.withValues(alpha: 0.3),
          width: isAnimating ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Level Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LevelBadge(level: currentLevel, isAnimating: isAnimating),
              if (remainingXP > 0)
                Text(
                  'Còn ${remainingXP}XP để lên level',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAnimating ? AppColors.xpPurple : AppColors.cyan,
                ),
              ).animate(target: isAnimating ? 1 : 0).shimmer(
                    duration: 1.5.seconds,
                    color: AppColors.xpPurple.withValues(alpha: 0.5),
                  ),
            ),
          ),

          const SizedBox(height: 12),

          // XP Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentXP}XP',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                progress >= 1.0 ? 'MAX LEVEL' : '${nextLevelXP}XP',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(target: isAnimating ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 0.3.seconds,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.05, 1.05),
          end: const Offset(1.0, 1.0),
          duration: 0.3.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final bool isAnimating;

  const _LevelBadge({
    required this.level,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAnimating
              ? [AppColors.xpPurple, AppColors.cyan]
              : [AppColors.xpPurple.withValues(alpha: 0.8), AppColors.xpPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isAnimating
            ? [
                BoxShadow(
                  color: AppColors.xpPurple.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars,
            color: AppColors.textPrimary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'LV $level',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    )
        .animate(target: isAnimating ? 1 : 0)
        .shimmer(
          duration: 1.seconds,
          color: AppColors.cyan.withValues(alpha: 0.6),
        )
        .then()
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.2, 1.2),
          duration: 0.2.seconds,
        )
        .then()
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(1.0, 1.0),
          duration: 0.2.seconds,
        );
  }
}
