import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Achievement definition
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredValue;
  final AchievementType type;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.type,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

enum AchievementType {
  dailyGoal,
  streak,
  totalVolume,
  level,
  frequency,
}

/// Achievement badges grid hiển thị tất cả achievements với unlock status
class AchievementBadgesGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final Function(Achievement)? onAchievementTap;

  const AchievementBadgesGrid({
    super.key,
    required this.achievements,
    this.onAchievementTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.military_tech,
                color: AppColors.xpPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Thành tựu',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.xpPurple,
                ),
              ),
              const Spacer(),
              _ProgressIndicator(achievements: achievements),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _AchievementBadge(
                achievement: achievement,
                onTap: () => onAchievementTap?.call(achievement),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final List<Achievement> achievements;

  const _ProgressIndicator({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.xpPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.xpPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '$unlockedCount/$totalCount',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.xpPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const _AchievementBadge({
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? AppColors.xpPurple.withValues(alpha: 0.4)
                : AppColors.textHint.withValues(alpha: 0.2),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.xpPurple.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon với unlock state
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.xpPurple.withValues(alpha: 0.2)
                    : AppColors.textHint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? achievement.icon : Icons.lock,
                color: isUnlocked ? AppColors.xpPurple : AppColors.textHint,
                size: 24,
              ),
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              achievement.title,
              style: AppTextStyles.caption.copyWith(
                color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
                fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (isUnlocked) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate(target: isUnlocked ? 1 : 0)
        .shimmer(
          duration: 2.seconds,
          color: AppColors.xpPurple.withValues(alpha: 0.3),
        );
  }
}

/// Default achievements cho AquaTrack
class DefaultAchievements {
  static List<Achievement> getAll({
    int totalLogs = 0,
    int currentStreak = 0,
    int totalVolume = 0,
    int currentLevel = 1,
    int daysWithGoal = 0,
  }) {
    return [
      // Streak achievements
      Achievement(
        id: 'streak_3',
        title: 'Khởi đầu',
        description: 'Log nước 3 ngày liên tiếp',
        icon: Icons.local_fire_department,
        requiredValue: 3,
        type: AchievementType.streak,
        isUnlocked: currentStreak >= 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Một tuần',
        description: 'Log nước 7 ngày liên tiếp',
        icon: Icons.calendar_view_week,
        requiredValue: 7,
        type: AchievementType.streak,
        isUnlocked: currentStreak >= 7,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Tháng vàng',
        description: 'Log nước 30 ngày liên tiếp',
        icon: Icons.emoji_events,
        requiredValue: 30,
        type: AchievementType.streak,
        isUnlocked: currentStreak >= 30,
      ),

      // Volume achievements
      Achievement(
        id: 'volume_10l',
        title: 'Thùng nước',
        description: 'Tổng cộng 10L nước',
        icon: Icons.water_drop,
        requiredValue: 10000,
        type: AchievementType.totalVolume,
        isUnlocked: totalVolume >= 10000,
      ),
      Achievement(
        id: 'volume_100l',
        title: 'Biển nước',
        description: 'Tổng cộng 100L nước',
        icon: Icons.waves,
        requiredValue: 100000,
        type: AchievementType.totalVolume,
        isUnlocked: totalVolume >= 100000,
      ),

      // Level achievements
      Achievement(
        id: 'level_5',
        title: 'Aqua Novice',
        description: 'Đạt level 5',
        icon: Icons.star,
        requiredValue: 5,
        type: AchievementType.level,
        isUnlocked: currentLevel >= 5,
      ),
      Achievement(
        id: 'level_10',
        title: 'Aqua Master',
        description: 'Đạt level 10',
        icon: Icons.star_purple500,
        requiredValue: 10,
        type: AchievementType.level,
        isUnlocked: currentLevel >= 10,
      ),

      // Goal achievements
      Achievement(
        id: 'goal_10',
        title: 'Hoàn thành',
        description: 'Đạt goal 10 ngày',
        icon: Icons.check_circle,
        requiredValue: 10,
        type: AchievementType.dailyGoal,
        isUnlocked: daysWithGoal >= 10,
      ),
      Achievement(
        id: 'first_log',
        title: 'Bước đầu',
        description: 'Log lần đầu tiên',
        icon: Icons.celebration,
        requiredValue: 1,
        type: AchievementType.frequency,
        isUnlocked: totalLogs >= 1,
      ),
    ];
  }
}