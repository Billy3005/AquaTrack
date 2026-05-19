import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/coin_badge.dart';
import 'providers/level_provider.dart';
import 'widgets/achievement_badges_grid.dart';
import 'widgets/avatar_collection_showcase.dart';

/// Level Screen - Complete redesign matching aquatrack/project/components/level.jsx
class LevelScreenRedesign extends ConsumerStatefulWidget {
  const LevelScreenRedesign({super.key});

  @override
  ConsumerState<LevelScreenRedesign> createState() =>
      _LevelScreenRedesignState();
}

class _LevelScreenRedesignState extends ConsumerState<LevelScreenRedesign> {
  /// Get level name from level number
  String _getLevelName(int level) {
    if (level >= 15) return 'Huyền thoại Hydrate';
    if (level >= 10) return 'Bậc thầy Đại dương';
    if (level >= 7) return 'Chiến binh Nước';
    if (level >= 5) return 'Hiệp sĩ Nước';
    if (level >= 3) return 'Người bắt đầu';
    return 'Giọt nước nhỏ';
  }

  /// Convert IconData to emoji string for achievement display
  String _getAchievementIcon(IconData icon) {
    if (icon == Icons.star) return '⭐';
    if (icon == Icons.military_tech) return '🔥';
    if (icon == Icons.emoji_events) return '🏆';
    if (icon == Icons.water_drop) return '💧';
    if (icon == Icons.local_fire_department) return '🔥';
    if (icon == Icons.trending_up) return '📈';
    if (icon == Icons.repeat) return '🔄';
    return '🎖️'; // Default achievement icon
  }

  /// Get color for avatar based on its id
  Color _getAvatarColor(String avatarId) {
    switch (avatarId) {
      case 'water_drop':
        return const Color(0xFF38BDF8);
      case 'wave':
        return const Color(0xFF0EA5E9);
      case 'ocean':
        return const Color(0xFF0284C7);
      case 'glacier':
        return const Color(0xFFA78BFA);
      case 'cloud':
        return const Color(0xFF94A3B8);
      case 'rain':
        return const Color(0xFF60A5FA);
      case 'storm':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF38BDF8); // Default blue color
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelState = ref.watch(levelNotifierProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: levelState.when(
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error),
            data: (levelData) => Column(
              children: [
                // Header
                _buildHeader(levelData),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level card
                        _buildLevelCard(levelData),
                        const SizedBox(height: 16),

                        // Achievements
                        _buildAchievementsSection(levelData),
                        const SizedBox(height: 18),

                        // Rewards
                        _buildRewardsSection(levelData),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyanAccent),
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu cấp độ...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Có lỗi khi tải dữ liệu',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(levelNotifierProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyanAccent,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LevelState levelData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Title section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HÀNH TRÌNH',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFC7D2FE),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  fontFamily: 'SF Pro Text',
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Cấp độ & Thành tựu',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.02,
                ),
              ),
            ],
          ),

          // Coin badge - use XP as coins for now
          CoinBadge(amount: levelData.currentXP),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LevelState levelData) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1.35, -1.35),
          end: Alignment(1.35, 1.35),
          colors: [Color(0xFF1A1040), Color(0xFF2D1B6B)],
        ),
        border: Border.all(color: const Color(0xFF4F46E5)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Shimmer effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(0.8, -0.8),
                  radius: 1.0,
                  colors: [
                    Color(0x40A5B4FC), // rgba(165,180,252,0.25)
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CẤP HIỆN TẠI',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFA5B4FC),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.08,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getLevelName(levelData.currentLevel),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.02,
                            fontFamily: 'SF Pro Rounded',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Còn ${levelData.nextLevelXP - levelData.currentXP} XP để lên Lv ${levelData.currentLevel + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC7D2FE),
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x804F46E5), // rgba(79,70,229,0.5)
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'LV ${levelData.currentLevel}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E7FF),
                        fontFamily: 'SF Pro Rounded',
                        letterSpacing: 0.04,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // XP Bar
              _buildXPBar(levelData),
              const SizedBox(height: 14),

              // Level ladder
              _buildLevelLadder(levelData),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar(LevelState levelData) {
    final xp = levelData.currentXP;
    final xpMax = levelData.nextLevelXP;
    final level = levelData.currentLevel;
    final levelName = _getLevelName(level);
    final pct = xpMax > 0 ? (xp / xpMax * 100).clamp(0, 100) : 0.0;

    return Column(
      children: [
        // XP info row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'LV $level',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleXP,
                    fontFamily: 'SF Pro Rounded',
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· $levelName',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              '$xp / $xpMax XP',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF312E81),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct / 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purpleXP, Color(0xFFA5B4FC)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleXP.withValues(alpha: 0.53),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelLadder(LevelState levelData) {
    final currentLevel = levelData.currentLevel;
    final levels = [
      LevelInfo(
        lv: currentLevel - 2 > 0 ? currentLevel - 2 : 1,
        name: _getLevelName(currentLevel - 2 > 0 ? currentLevel - 2 : 1),
        isCurrent: false,
      ),
      LevelInfo(
        lv: currentLevel,
        name: _getLevelName(currentLevel),
        isCurrent: true,
      ),
      LevelInfo(
        lv: currentLevel + 3,
        name: _getLevelName(currentLevel + 3),
        isCurrent: false,
      ),
      LevelInfo(
        lv: currentLevel + 8,
        name: _getLevelName(currentLevel + 8),
        isCurrent: false,
      ),
    ];

    return Row(
      children: levels.map((levelInfo) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Text(
                  'LV ${levelInfo.lv}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: levelInfo.isCurrent
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFA5B4FC),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  levelInfo.name,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: levelInfo.isCurrent
                        ? Colors.white
                        : const Color(0x80C7D2FE), // rgba(199,210,254,0.5)
                    fontFamily: 'SF Pro Rounded',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementsSection(LevelState levelData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thành tựu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: levelData.achievements.length,
          itemBuilder: (context, index) {
            final achievement = levelData.achievements[index];
            return _buildAchievementCard(
              icon: _getAchievementIcon(achievement.icon),
              name: achievement.title,
              condition: achievement.description,
              reward: '+${achievement.requiredValue ~/ 10} XP',
              unlocked: achievement.isUnlocked,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required String icon,
    required String name,
    required String condition,
    required String reward,
    required bool unlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: unlocked
            ? const LinearGradient(
                begin: Alignment(-1.35, -1.35),
                end: Alignment(1.35, 1.35),
                colors: [
                  Color(0x19818CF8), // rgba(129,140,248,0.10)
                  Color(0x0F38BDF8), // rgba(56,189,248,0.06)
                ],
              )
            : null,
        color: unlocked ? null : AppColors.nightSurface,
        border: unlocked
            ? Border.all(
                color: const Color(0x66818CF8), // rgba(129,140,248,0.4)
              )
            : Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                style: BorderStyle.solid,
              ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 22,
                color: unlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Text',
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              condition,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontFamily: 'SF Pro Text',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unlocked ? '✓ $reward' : reward,
              style: TextStyle(
                fontSize: 10,
                color: unlocked ? const Color(0xFFFDE68A) : AppColors.textMuted,
                fontFamily: 'SF Pro Rounded',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection(LevelState levelData) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phần thưởng đã mở khoá',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(height: 10),

          // Avatars section
          Text(
            'AVATARS',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 8),
          _buildAvatarGrid(levelData),
          const SizedBox(height: 14),

          // Themes section
          Text(
            'THEMES',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 8),
          _buildThemeGrid(),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid(LevelState levelData) {
    // Take first 5 avatars from levelData or show all if less than 5
    final avatars = levelData.avatars.take(5).toList();

    return Row(
      children: avatars.map((avatar) {
        final avatarColor = _getAvatarColor(avatar.id);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: avatar.isUnlocked
                          ? RadialGradient(
                              center: const Alignment(0.3, 0.3),
                              colors: [
                                avatarColor.withValues(alpha: 0.87),
                                avatarColor.withValues(alpha: 0.4),
                              ],
                            )
                          : null,
                      color: avatar.isUnlocked
                          ? null
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: avatar.isUnlocked
                          ? Border.all(
                              color: avatarColor.withValues(alpha: 0.53),
                            )
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              style: BorderStyle.solid,
                            ),
                      boxShadow: avatar.isUnlocked
                          ? [
                              BoxShadow(
                                color: avatarColor.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: avatar.isUnlocked
                          ? Text(
                              avatar.emoji,
                              style: const TextStyle(fontSize: 18),
                            )
                          : const Text(
                              '🔒',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  avatar.name,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Rounded',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeGrid() {
    final themes = [
      ThemeInfo(
        name: 'Đêm Đại dương',
        gradient: const LinearGradient(
          begin: Alignment(-1.35, -1.35),
          end: Alignment(1.35, 1.35),
          colors: [Color(0xFF0C4A80), Color(0xFF082F5C)],
        ),
        current: true,
        locked: false,
      ),
      ThemeInfo(
        name: 'Xanh mặc định',
        gradient: const LinearGradient(
          begin: Alignment(-1.35, -1.35),
          end: Alignment(1.35, 1.35),
          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
        ),
        current: false,
        locked: false,
      ),
      ThemeInfo(
        name: 'Sa mạc',
        gradient: const LinearGradient(
          begin: Alignment(-1.35, -1.35),
          end: Alignment(1.35, 1.35),
          colors: [Color(0xFFF59E0B), Color(0xFF92400E)],
        ),
        current: false,
        locked: true,
      ),
      ThemeInfo(
        name: 'Mưa rừng',
        gradient: const LinearGradient(
          begin: Alignment(-1.35, -1.35),
          end: Alignment(1.35, 1.35),
          colors: [Color(0xFF059669), Color(0xFF064E3B)],
        ),
        current: false,
        locked: true,
      ),
    ];

    return Row(
      children: themes.map((theme) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: theme.gradient,
                    borderRadius: BorderRadius.circular(8),
                    border: theme.current
                        ? Border.all(color: const Color(0xFFFBBF24), width: 2)
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                  ),
                  child: theme.locked
                      ? const Center(
                          child: Text(
                            '🔒',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  theme.name,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Rounded',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class LevelInfo {
  final int lv;
  final String name;
  final bool isCurrent;

  LevelInfo({required this.lv, required this.name, required this.isCurrent});
}

class AvatarInfo {
  final Color color;
  final String name;
  final bool unlocked;

  AvatarInfo({required this.color, required this.name, required this.unlocked});
}

class ThemeInfo {
  final String name;
  final LinearGradient gradient;
  final bool current;
  final bool locked;

  ThemeInfo({
    required this.name,
    required this.gradient,
    required this.current,
    required this.locked,
  });
}
