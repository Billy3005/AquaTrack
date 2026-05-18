import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Level Screen - Complete redesign matching aquatrack/project/components/level.jsx
class LevelScreenRedesign extends ConsumerStatefulWidget {
  const LevelScreenRedesign({super.key});

  @override
  ConsumerState<LevelScreenRedesign> createState() =>
      _LevelScreenRedesignState();
}

class _LevelScreenRedesignState extends ConsumerState<LevelScreenRedesign> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level card
                      _buildLevelCard(),
                      const SizedBox(height: 16),

                      // Achievements
                      _buildAchievementsSection(),
                      const SizedBox(height: 18),

                      // Rewards
                      _buildRewardsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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

          // Coin badge
          _buildCoinBadge(1240),
        ],
      ),
    );
  }

  Widget _buildCoinBadge(int amount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 9, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x2DFBBF24), // rgba(251,191,36,0.18)
            Color(0x0FF59E0B), // rgba(245,158,11,0.06)
          ],
        ),
        border: Border.all(
          color: const Color(0x73FBBF24), // rgba(251,191,36,0.45)
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.06),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCoinIcon(13),
          const SizedBox(width: 5),
          Text(
            amount.toString(),
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFDE68A),
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 0.01,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.35, 0.3),
          radius: 0.75,
          colors: [
            Color(0xFFFEF3C7), // 0%
            Color(0xFFFBBF24), // 55%
            Color(0xFFB45309), // 100%
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF78350F),
          width: 0.6,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner circle
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFDE68A).withValues(alpha: 0.7),
                width: 0.8,
              ),
            ),
          ),
          // Dollar sign
          Text(
            '\$',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
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
                        const Text(
                          'Chiến binh Nước',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.02,
                            fontFamily: 'SF Pro Rounded',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Còn 760 XP để lên Lv 8',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFFC7D2FE),
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
                    child: const Text(
                      'LV 7',
                      style: TextStyle(
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
              _buildXPBar(),
              const SizedBox(height: 14),

              // Level ladder
              _buildLevelLadder(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar() {
    const xp = 1240;
    const xpMax = 2000;
    const level = 7;
    const levelName = 'Chiến binh Nước';
    final pct = (xp / xpMax * 100).clamp(0, 100);

    return Column(
      children: [
        // XP info row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'LV 7',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleXP,
                    fontFamily: 'SF Pro Rounded',
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '· Chiến binh Nước',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Text(
              '1240 / 2000 XP',
              style: TextStyle(
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

  Widget _buildLevelLadder() {
    final levels = [
      LevelInfo(lv: 5, name: 'Hiệp sĩ Nước', isCurrent: false),
      LevelInfo(lv: 7, name: 'Chiến binh Nước', isCurrent: true),
      LevelInfo(lv: 10, name: 'Bậc thầy Đại dương', isCurrent: false),
      LevelInfo(lv: 15, name: 'Huyền thoại Hydrate', isCurrent: false),
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

  Widget _buildAchievementsSection() {
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            _buildAchievementCard(
              icon: '🔥',
              name: 'Streak 7 ngày',
              condition: 'Streak 7 ngày liên tiếp',
              reward: '+50 XP',
              unlocked: true,
            ),
            _buildAchievementCard(
              icon: '⭐',
              name: 'Đủ nước 5 lần',
              condition: '5× đạt mục tiêu',
              reward: 'Mở khoá theme',
              unlocked: true,
            ),
            _buildAchievementCard(
              icon: '🌊',
              name: 'Tuần 14L',
              condition: '2.000ml × 7 ngày',
              reward: 'Khung avatar',
              unlocked: false,
            ),
            _buildAchievementCard(
              icon: '🏆',
              name: 'Top 10% tuần',
              condition: 'Bảng xếp hạng',
              reward: 'Huy hiệu đặc biệt',
              unlocked: false,
            ),
          ],
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

  Widget _buildRewardsSection() {
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
          _buildAvatarGrid(),
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

  Widget _buildAvatarGrid() {
    final avatars = [
      AvatarInfo(color: const Color(0xFF38BDF8), name: 'Drop', unlocked: true),
      AvatarInfo(color: const Color(0xFF0EA5E9), name: 'Wave', unlocked: true),
      AvatarInfo(
          color: const Color(0xFF0284C7), name: 'Ocean', unlocked: false),
      AvatarInfo(
          color: const Color(0xFFA78BFA), name: 'Glacier', unlocked: false),
      AvatarInfo(
          color: const Color(0xFF94A3B8), name: 'Cloud', unlocked: false),
    ];

    return Row(
      children: avatars.map((avatar) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: avatar.unlocked
                          ? RadialGradient(
                              center: const Alignment(0.3, 0.3),
                              colors: [
                                avatar.color.withValues(alpha: 0.87),
                                avatar.color.withValues(alpha: 0.4),
                              ],
                            )
                          : null,
                      color: avatar.unlocked
                          ? null
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: avatar.unlocked
                          ? Border.all(
                              color: avatar.color.withValues(alpha: 0.53),
                            )
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              style: BorderStyle.solid,
                            ),
                      boxShadow: avatar.unlocked
                          ? [
                              BoxShadow(
                                color: avatar.color.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: avatar.unlocked
                          ? const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
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
                        ? Border.all(
                            color: const Color(0xFFFBBF24),
                            width: 2,
                          )
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                  ),
                  child: theme.locked
                      ? const Center(
                          child: Text(
                            '🔒',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
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

  LevelInfo({
    required this.lv,
    required this.name,
    required this.isCurrent,
  });
}

class AvatarInfo {
  final Color color;
  final String name;
  final bool unlocked;

  AvatarInfo({
    required this.color,
    required this.name,
    required this.unlocked,
  });
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
