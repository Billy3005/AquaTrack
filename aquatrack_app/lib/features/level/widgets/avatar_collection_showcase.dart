import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Avatar definition
class AvatarItem {
  final String id;
  final String name;
  final String emoji;
  final int unlockLevel;
  final bool isSelected;
  final bool isUnlocked;
  final String description;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.unlockLevel,
    required this.isSelected,
    required this.isUnlocked,
    required this.description,
  });

  AvatarItem copyWith({
    String? id,
    String? name,
    String? emoji,
    int? unlockLevel,
    bool? isSelected,
    bool? isUnlocked,
    String? description,
  }) {
    return AvatarItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      unlockLevel: unlockLevel ?? this.unlockLevel,
      isSelected: isSelected ?? this.isSelected,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      description: description ?? this.description,
    );
  }
}

/// Avatar collection showcase hiển thị tất cả avatars với unlock status
class AvatarCollectionShowcase extends StatelessWidget {
  final List<AvatarItem> avatars;
  final Function(AvatarItem)? onAvatarSelect;
  final int currentLevel;

  const AvatarCollectionShowcase({
    super.key,
    required this.avatars,
    required this.currentLevel,
    this.onAvatarSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selectedAvatar = avatars.firstWhere(
      (avatar) => avatar.isSelected,
      orElse: () => avatars.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với current avatar
          Row(
            children: [
              Icon(
                Icons.face_retouching_natural,
                color: AppColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Avatar Collection',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current Selected Avatar Display
          _CurrentAvatarDisplay(avatar: selectedAvatar),

          const SizedBox(height: 24),

          // Avatar Grid
          Text(
            'Tất cả Avatar',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              return _AvatarGridItem(
                avatar: avatar,
                currentLevel: currentLevel,
                onTap: avatar.isUnlocked
                    ? () => onAvatarSelect?.call(avatar)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CurrentAvatarDisplay extends StatelessWidget {
  final AvatarItem avatar;

  const _CurrentAvatarDisplay({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.1),
            AppColors.xpPurple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Large Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cyan,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                avatar.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.05, 1.05),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),

          const SizedBox(width: 20),

          // Avatar Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  avatar.name,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  avatar.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Đang sử dụng',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarGridItem extends StatelessWidget {
  final AvatarItem avatar;
  final int currentLevel;
  final VoidCallback? onTap;

  const _AvatarGridItem({
    required this.avatar,
    required this.currentLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = avatar.isUnlocked;
    final isSelected = avatar.isSelected;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.surface : AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : isUnlocked
                    ? AppColors.surfaceLight
                    : AppColors.textHint.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar Emoji hoặc Lock
            if (isUnlocked)
              Text(
                avatar.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.8),
                ),
              )
            else
              Icon(
                Icons.lock,
                color: AppColors.textHint,
                size: 24,
              ),

            const SizedBox(height: 4),

            // Level requirement cho locked avatars
            if (!isUnlocked)
              Text(
                'LV ${avatar.unlockLevel}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 0.2.seconds,
        );
  }
}

/// Default avatars cho AquaTrack
class DefaultAvatars {
  static List<AvatarItem> getAll({
    int currentLevel = 1,
    String selectedAvatarId = 'water_drop',
  }) {
    final avatars = [
      AvatarItem(
        id: 'water_drop',
        name: 'Giọt nước',
        emoji: '💧',
        unlockLevel: 1,
        description: 'Avatar khởi đầu cho mọi người',
        isUnlocked: true,
        isSelected: selectedAvatarId == 'water_drop',
      ),
      AvatarItem(
        id: 'ocean_wave',
        name: 'Sóng biển',
        emoji: '🌊',
        unlockLevel: 3,
        description: 'Sức mạnh của đại dương',
        isUnlocked: currentLevel >= 3,
        isSelected: selectedAvatarId == 'ocean_wave',
      ),
      AvatarItem(
        id: 'water_glass',
        name: 'Ly nước',
        emoji: '🥛',
        unlockLevel: 5,
        description: 'Đơn giản mà hiệu quả',
        isUnlocked: currentLevel >= 5,
        isSelected: selectedAvatarId == 'water_glass',
      ),
      AvatarItem(
        id: 'bottle',
        name: 'Chai nước',
        emoji: '🍶',
        unlockLevel: 7,
        description: 'Luôn mang theo bên mình',
        isUnlocked: currentLevel >= 7,
        isSelected: selectedAvatarId == 'bottle',
      ),
      AvatarItem(
        id: 'fountain',
        name: 'Đài phun nước',
        emoji: '⛲',
        unlockLevel: 10,
        description: 'Nguồn nước vô tận',
        isUnlocked: currentLevel >= 10,
        isSelected: selectedAvatarId == 'fountain',
      ),
      AvatarItem(
        id: 'crystal',
        name: 'Pha lê nước',
        emoji: '💎',
        unlockLevel: 15,
        description: 'Tinh khiết như pha lê',
        isUnlocked: currentLevel >= 15,
        isSelected: selectedAvatarId == 'crystal',
      ),
      AvatarItem(
        id: 'aqua_master',
        name: 'Aqua Master',
        emoji: '🧙‍♂️',
        unlockLevel: 20,
        description: 'Bậc thầy về hydration',
        isUnlocked: currentLevel >= 20,
        isSelected: selectedAvatarId == 'aqua_master',
      ),
      AvatarItem(
        id: 'water_god',
        name: 'Thần nước',
        emoji: '🔱',
        unlockLevel: 25,
        description: 'Chúa tể của các đại dương',
        isUnlocked: currentLevel >= 25,
        isSelected: selectedAvatarId == 'water_god',
      ),
    ];

    return avatars;
  }
}