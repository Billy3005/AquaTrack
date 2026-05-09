import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/friend_model.dart';
import '../providers/friends_provider.dart';

/// Friend card widget for friends list
class FriendCard extends ConsumerWidget {
  final Friend friend;
  final VoidCallback? onTap;

  const FriendCard({
    super.key,
    required this.friend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar với status indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.cyanAccent.withOpacity(0.1),
                      backgroundImage: friend.avatarUrl != null
                          ? NetworkImage(friend.avatarUrl!)
                          : null,
                      child: friend.avatarUrl == null
                          ? Text(
                              friend.displayName.isNotEmpty
                                  ? friend.displayName[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.cyanAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    // Status indicator
                    if (friend.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Friend info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            friend.displayName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (friend.weeklyRank != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyanAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${friend.weeklyRank}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primaryBackground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            friend.status.displayName,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Color(int.parse(
                                  '0xff${friend.status.colorHex.substring(1)}')),
                            ),
                          ),
                          if (friend.currentStreak > 0) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${friend.currentStreak} ngày',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress circle và actions
                Column(
                  children: [
                    // Progress circle
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        children: [
                          // Background circle
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 4,
                            color: AppColors.borderColor.withOpacity(0.2),
                          ),
                          // Progress circle
                          CircularProgressIndicator(
                            value: friend.dailyProgress.clamp(0.0, 1.0),
                            strokeWidth: 4,
                            color: _getProgressColor(),
                            backgroundColor: Colors.transparent,
                          ),
                          // Percentage text
                          Center(
                            child: Text(
                              '${(friend.dailyProgress * 100).round()}%',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Remind button
                    SizedBox(
                      width: 80,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () => _sendReminder(ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.cyanAccent.withOpacity(0.1),
                          foregroundColor: AppColors.cyanAccent,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Nhắc',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get status indicator color
  Color _getStatusColor() {
    switch (friend.status) {
      case FriendStatus.normal:
        return AppColors.success;
      case FriendStatus.thirsty:
        return AppColors.error;
      case FriendStatus.stressed:
        return AppColors.warning;
      case FriendStatus.offline:
        return AppColors.textSecondary;
    }
  }

  /// Get progress circle color
  Color _getProgressColor() {
    if (friend.dailyProgress >= 1.0) {
      return AppColors.success;
    } else if (friend.dailyProgress >= 0.7) {
      return AppColors.cyanAccent;
    } else if (friend.dailyProgress >= 0.4) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  /// Send hydration reminder to friend
  void _sendReminder(WidgetRef ref) async {
    try {
      final notifier = ref.read(friendsNotifierProvider.notifier);
      final success = await notifier.sendHydrationReminder(friend.id);

      if (success) {
        // Show success feedback (you might want to add a snackbar or toast)
        debugPrint('✅ Sent reminder to ${friend.displayName}');
      }
    } catch (e) {
      debugPrint('❌ Failed to send reminder: $e');
    }
  }
}
