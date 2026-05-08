import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/level_provider.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/achievement_badges_grid.dart';
import '../widgets/avatar_collection_showcase.dart';
import '../widgets/level_up_celebration.dart';

/// Screen 05 — Level & Achievements
/// XP bar, level progression, achievements grid, avatar collection
class LevelScreen extends ConsumerWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsyncState = ref.watch(levelNotifierProvider);
    final levelNotifier = ref.read(levelNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'CẤP ĐỘ & THÀNH TỰU',
          style: AppTextStyles.headingMedium,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Debug: Add XP button (chỉ để test)
          if (true) // Set to false for production
            IconButton(
              onPressed: () async {
                await levelNotifier.addXP(50);
              },
              icon: const Icon(Icons.add, color: AppColors.textSecondary),
              tooltip: 'Add 50 XP (Debug)',
            ),
          // Refresh button
          levelAsyncState.when(
            data: (_) => IconButton(
              onPressed: () {
                ref.invalidate(levelNotifierProvider);
              },
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, stack) => const SizedBox(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(levelNotifierProvider);
          await ref.read(levelNotifierProvider.future);
        },
        color: AppColors.cyan,
        backgroundColor: AppColors.surface,
        child: levelAsyncState.when(
          data: (levelState) =>
              _buildLevelContent(context, levelState, levelNotifier),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error, ref),
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải dữ liệu level...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu level',
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Retry loading data
              ref.invalidate(levelNotifierProvider);
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Build the main level content when data is loaded
  Widget _buildLevelContent(
    BuildContext context,
    LevelState levelState,
    dynamic levelNotifier,
  ) {
    // Show level-up celebration nếu có
    if (levelState.isLevelingUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final selectedAvatar = await levelNotifier.getSelectedAvatar();
        if (selectedAvatar != null && context.mounted) {
          LevelUpCelebrationManager.show(
            context,
            newLevel: levelState.currentLevel,
            avatarEmoji: selectedAvatar.emoji,
            onComplete: () {
              levelNotifier.clearLevelUpState();
            },
          );
        }
      });
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // XP Progress Bar
          XPProgressBar(
            currentLevel: levelState.currentLevel,
            currentXP: levelState.currentXP,
            nextLevelXP: levelState.nextLevelXP,
            isAnimating: levelState.isLevelingUp,
          ),

          const SizedBox(height: 32),

          // Current Avatar Display
          AvatarCollectionShowcase(
            avatars: levelState.avatars,
            currentLevel: levelState.currentLevel,
            onAvatarSelect: (avatar) {
              levelNotifier.selectAvatar(avatar.id);
            },
          ),

          const SizedBox(height: 32),

          // Achievement Badges Grid
          AchievementBadgesGrid(
            achievements: levelState.achievements,
            onAchievementTap: (achievement) {
              _showAchievementDetails(context, achievement);
            },
          ),

          const SizedBox(height: 32),

          // Stats Summary Card
          _StatsSummaryCard(levelState: levelState),

          // Bottom padding
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Show achievement details dialog
  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              achievement.isUnlocked ? achievement.icon : Icons.lock,
              color: achievement.isUnlocked
                  ? AppColors.xpPurple
                  : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.title,
                style: AppTextStyles.headingMedium.copyWith(
                  color: achievement.isUnlocked
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.isUnlocked
                  ? '✅ Đã hoàn thành'
                  : 'Yêu cầu: ${achievement.requiredValue} ${_getRequirementUnit(achievement.type)}',
              style: AppTextStyles.caption.copyWith(
                color: achievement.isUnlocked
                    ? AppColors.success
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  String _getRequirementUnit(AchievementType type) {
    switch (type) {
      case AchievementType.streak:
        return 'ngày streak';
      case AchievementType.totalVolume:
        return 'ml nước';
      case AchievementType.level:
        return 'level';
      case AchievementType.dailyGoal:
        return 'ngày đạt goal';
      case AchievementType.frequency:
        return 'lần log';
    }
  }
}

/// Stats summary card hiển thị tổng quan progress
class _StatsSummaryCard extends StatelessWidget {
  final LevelState levelState;

  const _StatsSummaryCard({required this.levelState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thống kê tổng quan',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Tổng logs',
                  value: '${levelState.totalLogsCount}',
                  icon: Icons.water_drop,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Streak hiện tại',
                  value: '${levelState.currentStreak}',
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Tổng nước (L)',
                  value: (levelState.totalVolume / 1000).toStringAsFixed(1),
                  icon: Icons.waves,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Thành tựu',
                  value:
                      '${levelState.achievements.where((a) => a.isUnlocked).length}/${levelState.achievements.length}',
                  icon: Icons.military_tech,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
