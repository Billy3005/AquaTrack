import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Avatar selection widget for profile customization
class AvatarSelector extends StatelessWidget {
  final String selectedAvatar;
  final Set<String> unlockedAvatars;
  final Function(String)? onAvatarSelected;

  const AvatarSelector({
    super.key,
    required this.selectedAvatar,
    required this.unlockedAvatars,
    this.onAvatarSelected,
  });

  /// Available avatars with unlock levels
  static const Map<String, int> _avatarUnlockLevels = {
    'avatar_1': 1, // Default avatar
    'avatar_2': 3,
    'avatar_3': 5,
    'avatar_4': 8,
    'avatar_5': 12,
    'avatar_6': 15,
    'avatar_7': 20,
    'avatar_8': 25,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                color: AppColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Chọn Avatar',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Avatar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _avatarUnlockLevels.length,
            itemBuilder: (context, index) {
              final avatarKey = _avatarUnlockLevels.keys.elementAt(index);
              return _buildAvatarItem(avatarKey);
            },
          ),
        ],
      ),
    );
  }

  /// Build individual avatar item
  Widget _buildAvatarItem(String avatarKey) {
    final isUnlocked = unlockedAvatars.contains(avatarKey);
    final isSelected = selectedAvatar == avatarKey;
    final requiredLevel = _avatarUnlockLevels[avatarKey] ?? 1;

    return GestureDetector(
      onTap: isUnlocked ? () => onAvatarSelected?.call(avatarKey) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : isUnlocked
                    ? AppColors.surface.withValues(alpha: 0.5)
                    : AppColors.textSecondary.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.2),
                    AppColors.xpPurple.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: !isSelected ? AppColors.surface.withValues(alpha: 0.1) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Avatar display
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isUnlocked
                      ? _getAvatarColor(avatarKey)
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                child: Icon(
                  _getAvatarIcon(avatarKey),
                  color: isUnlocked ? Colors.white : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),

            // Lock overlay for locked avatars
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.background.withValues(alpha: 0.7),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lv.$requiredLevel',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate(
            delay: Duration(
                milliseconds: 100 *
                    (_avatarUnlockLevels.keys.toList().indexOf(avatarKey))))
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
        );
  }

  /// Get avatar color based on key
  Color _getAvatarColor(String avatarKey) {
    switch (avatarKey) {
      case 'avatar_1':
        return AppColors.cyan;
      case 'avatar_2':
        return const Color(0xFF4CAF50); // Green
      case 'avatar_3':
        return const Color(0xFF9C27B0); // Purple
      case 'avatar_4':
        return const Color(0xFFFF9800); // Orange
      case 'avatar_5':
        return const Color(0xFFF44336); // Red
      case 'avatar_6':
        return const Color(0xFF2196F3); // Blue
      case 'avatar_7':
        return const Color(0xFFFFEB3B); // Yellow
      case 'avatar_8':
        return AppColors.xpPurple; // Premium purple
      default:
        return AppColors.cyan;
    }
  }

  /// Get avatar icon based on key
  IconData _getAvatarIcon(String avatarKey) {
    switch (avatarKey) {
      case 'avatar_1':
        return Icons.water_drop;
      case 'avatar_2':
        return Icons.local_florist;
      case 'avatar_3':
        return Icons.star;
      case 'avatar_4':
        return Icons.whatshot;
      case 'avatar_5':
        return Icons.favorite;
      case 'avatar_6':
        return Icons.bolt;
      case 'avatar_7':
        return Icons.emoji_events;
      case 'avatar_8':
        return Icons.diamond;
      default:
        return Icons.person;
    }
  }
}
