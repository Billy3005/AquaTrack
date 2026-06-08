import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_stats_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/coin_badge.dart';
import '../avatars/avatar_collection_screen.dart';
import '../avatars/data/avatar_catalog.dart';
import '../avatars/widgets/aqua_avatar.dart' show AvatarBubble;
import 'providers/level_data_provider.dart';

/// Level Screen — wired to real backend data (see ADR 0003).
/// XP/achievements from `levelDataProvider`; coins/streak/level name from
/// `userStatsProvider`. No fabricated XP, coins, themes, or avatar emojis.
class LevelScreenRedesign extends ConsumerStatefulWidget {
  const LevelScreenRedesign({super.key});

  @override
  ConsumerState<LevelScreenRedesign> createState() =>
      _LevelScreenRedesignState();
}

class _LevelScreenRedesignState extends ConsumerState<LevelScreenRedesign> {
  /// Achievement ids currently being claimed (per-card spinner).
  final Set<String> _claiming = {};

  static const Map<String, String> _domainLabels = {
    'streak': 'Chuỗi ngày',
    'volume': 'Lượng nước',
    'level': 'Cấp độ',
    'frequency': 'Tần suất',
    'daily_goal': 'Mục tiêu ngày',
    'quest': 'Nhiệm vụ',
    'coach': 'AI Coach',
    'scan': 'Smart Scan',
    'social': 'Bạn bè',
  };

  static const List<String> _domainOrder = [
    'streak',
    'daily_goal',
    'volume',
    'frequency',
    'level',
    'quest',
    'coach',
    'scan',
    'social',
  ];

  Color _tierColor(String tier) {
    switch (tier) {
      case 'rare':
        return const Color(0xFF38BDF8);
      case 'epic':
        return AppColors.purpleXP;
      case 'legendary':
        return const Color(0xFFFBBF24);
      default:
        return AppColors.textSecondary; // common
    }
  }

  Future<void> _claim(LevelAchievement a) async {
    setState(() => _claiming.add(a.id));
    final res = await claimLevelAchievement(ref, a.id);
    if (!mounted) return;
    setState(() => _claiming.remove(a.id));

    final messenger = ScaffoldMessenger.of(context);
    if (res.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã nhận +${a.rewardXp} XP · ${a.title}'),
          backgroundColor: AppColors.purpleXP,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.error ?? 'Không nhận được phần thưởng'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsProvider);
    final levelAsync = ref.watch(levelDataProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: levelAsync.when(
            loading: _buildLoadingState,
            error: (error, _) => _buildErrorState(error),
            data: (level) {
              final stats = statsAsync.valueOrNull;
              return Column(
                children: [
                  _buildHeader(stats?.coins ?? 0),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLevelCard(level, stats),
                          const SizedBox(height: 16),
                          _buildAchievementsSection(level),
                          const SizedBox(height: 18),
                          _buildRewardsSection(stats),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
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
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(levelDataProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyanAccent,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int coins) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HÀNH TRÌNH',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFC7D2FE),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
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
          // Real Coin balance (not XP) — see ADR 0003 decision 6.
          CoinBadge(amount: coins),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LevelData level, UserStatsData? stats) {
    final levelName = stats?.levelName ?? 'Tân binh';
    final xp = level.currentXP;
    final xpMax = level.nextLevelXP;
    final pct = xpMax > 0 ? (xp / xpMax).clamp(0.0, 1.0) : 0.0;
    final remaining = (xpMax - xp).clamp(0, xpMax);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CẤP HIỆN TẠI',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA5B4FC),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      levelName,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Còn $remaining XP để lên Lv ${level.currentLevel + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC7D2FE),
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
                ),
                child: Text(
                  'LV ${level.currentLevel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0E7FF),
                    letterSpacing: 0.04,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // XP bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LV ${level.currentLevel} · $levelName',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFF312E81),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.purpleXP),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(LevelData level) {
    // Group achievements by domain, in a stable display order.
    final byDomain = <String, List<LevelAchievement>>{};
    for (final a in level.achievements) {
      byDomain.putIfAbsent(a.domain, () => []).add(a);
    }
    final domains = [
      ..._domainOrder.where(byDomain.containsKey),
      ...byDomain.keys.where((d) => !_domainOrder.contains(d)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thành tựu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${level.unlockedCount}/${level.totalCount}'
              '${level.claimableCount > 0 ? ' · ${level.claimableCount} chờ nhận' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: level.claimableCount > 0
                    ? const Color(0xFFFBBF24)
                    : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final domain in domains) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(
              (_domainLabels[domain] ?? domain).toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
              ),
            ),
          ),
          ...byDomain[domain]!.map(_buildAchievementCard),
        ],
      ],
    );
  }

  Widget _buildAchievementCard(LevelAchievement a) {
    final tierColor = _tierColor(a.tier);
    final claiming = _claiming.contains(a.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(
          color: a.isClaimable
              ? const Color(0xFFFBBF24)
              : (a.isUnlocked
                  ? tierColor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08)),
          width: a.isClaimable ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Opacity(
        opacity: a.isUnlocked ? 1.0 : 0.6,
        child: Row(
          children: [
            Text(a.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _tierChip(a.tier, tierColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.description,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Progress bar for locked, "+XP" for unlocked.
                  if (!a.isUnlocked) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: a.progressFraction,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${a.progress}/${a.target} · +${a.rewardXp} XP',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ] else
                    Text(
                      '+${a.rewardXp} XP',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFDE68A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _trailing(a, claiming),
          ],
        ),
      ),
    );
  }

  Widget _trailing(LevelAchievement a, bool claiming) {
    if (a.isClaimed) {
      return const Text(
        '✓ Đã nhận',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (a.isClaimable) {
      return SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: claiming ? null : () => _claim(a),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBBF24),
            foregroundColor: const Color(0xFF1A1040),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: claiming
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF1A1040)),
                  ),
                )
              : const Text(
                  'Nhận',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
        ),
      );
    }
    return const Icon(Icons.lock, size: 16, color: AppColors.textMuted);
  }

  Widget _tierChip(String tier, Color color) {
    final label = kAquaTiers[AquaTier.values
            .firstWhere((t) => t.name == tier, orElse: () => AquaTier.common)]
        ?.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label ?? tier,
        style: TextStyle(
          fontSize: 8.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRewardsSection(UserStatsData? stats) {
    final level = stats?.currentLevel ?? 1;
    final longestStreak = stats?.longestStreak ?? 0;

    // Owned avatars derived from the level/streak rails (ADR 0003 decision 5).
    final owned = kAvatarCatalog.where((spec) {
      final u = spec.unlock;
      return spec.isDefault ||
          (u.levelReq != null && level >= u.levelReq!) ||
          (u.streakReq != null && longestStreak >= u.streakReq!);
    }).toList();
    final showcase = owned.take(5).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phần thưởng đã mở khoá',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AvatarCollectionScreen(),
                  ),
                ),
                child: const Text(
                  'Xem tất cả →',
                  style: TextStyle(fontSize: 11, color: AppColors.cyanAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'HÌNH HÀI (${owned.length}/${kAvatarCatalog.length})',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final spec in showcase)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        AvatarBubble(spec: spec, size: 52),
                        const SizedBox(height: 4),
                        Text(
                          spec.name,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'GIAO DIỆN (THEME)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Center(
              child: Text(
                '🎨  Sắp ra mắt',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
