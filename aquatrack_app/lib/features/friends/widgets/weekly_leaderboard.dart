import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/friend_model.dart';

/// Weekly leaderboard widget showing top friends
class WeeklyLeaderboard extends StatelessWidget {
  final List<WeeklyLeaderboardEntry> entries;

  const WeeklyLeaderboard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    // Show top 3 friends
    final topThree = entries.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'TUẦN NÀY',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                'Còn ${_getDaysLeft()} ngày',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Top 3 leaderboard
          Row(
            children: topThree.asMap().entries.map((entry) {
              final index = entry.key;
              final leaderboardEntry = entry.value;
              return Expanded(
                child: _buildLeaderboardItem(
                  leaderboardEntry,
                  index,
                  isFirst: index == 0,
                  isLast: index == topThree.length - 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build individual leaderboard item
  Widget _buildLeaderboardItem(
    WeeklyLeaderboardEntry entry,
    int index, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(left: isFirst ? 0 : 4, right: isLast ? 0 : 4),
      child: Column(
        children: [
          // Avatar với rank
          Stack(
            children: [
              // Avatar
              CircleAvatar(
                radius: index == 0 ? 28 : 24,
                backgroundColor: AppColors.cyanAccent.withValues(alpha: 0.1),
                backgroundImage: entry.avatarUrl != null
                    ? NetworkImage(entry.avatarUrl!)
                    : null,
                child: entry.avatarUrl == null
                    ? Text(
                        entry.displayName.isNotEmpty
                            ? entry.displayName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.cyanAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: index == 0 ? 18 : 16,
                        ),
                      )
                    : null,
              ),

              // Crown for #1
              if (index == 0)
                Positioned(
                  top: -4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: AppColors.warning,
                    ),
                  ),
                ),

              // Rank badge
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getRankColor(index),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.rank}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Name
          Text(
            entry.displayName,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Percentage
          Text(
            '${entry.hydrationPercentage.round()}%',
            style: AppTextStyles.labelMedium.copyWith(
              color: _getPercentageColor(entry.hydrationPercentage),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state when no leaderboard data
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            'Tuần này chưa có dữ liệu',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mời thêm bạn bè để thi đấu!',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Get rank color for badge
  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return AppColors.warning; // Gold
      case 1:
        return AppColors.textSecondary; // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.cyanAccent;
    }
  }

  /// Get color for hydration percentage
  Color _getPercentageColor(double percentage) {
    if (percentage >= 100) {
      return AppColors.success;
    } else if (percentage >= 80) {
      return AppColors.cyanAccent;
    } else if (percentage >= 60) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  /// Calculate days left in current week
  int _getDaysLeft() {
    final now = DateTime.now();
    final weekDay = now.weekday; // 1 = Monday, 7 = Sunday
    return 7 - weekDay + 1; // Days until next Monday
  }
}
