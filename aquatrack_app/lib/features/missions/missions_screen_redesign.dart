import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/coin_badge.dart';
import 'models/quest.dart';
import 'providers/quests_provider.dart';

/// Missions Screen với Daily & Weekly missions
class MissionsScreenRedesign extends ConsumerStatefulWidget {
  const MissionsScreenRedesign({super.key});

  @override
  ConsumerState<MissionsScreenRedesign> createState() =>
      _MissionsScreenRedesignState();
}

class _MissionsScreenRedesignState extends ConsumerState<MissionsScreenRedesign>
    with SingleTickerProviderStateMixin {
  String _selectedTab = 'daily';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _switchTab(String tab) {
    if (tab != _selectedTab) {
      setState(() {
        _selectedTab = tab;
      });
      _animationController.forward(from: 0.0);
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _claim(String id) async {
    final ok = await ref.read(questsProvider.notifier).claim(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '🎉 Đã nhận thưởng!' : 'Chưa thể nhận thưởng'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questsProvider);
    final data = state.data;

    if (data == null) {
      return Scaffold(
        backgroundColor: AppColors.nightBase,
        body: SafeArea(
          child: Center(
            child: state.isLoading
                ? const CircularProgressIndicator(color: AppColors.glow)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.error ?? 'Không tải được nhiệm vụ',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.read(questsProvider.notifier).load(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    final daily = data.daily.map(_toMission).toList();
    final weekly = data.weekly.map(_toMission).toList();

    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(data.coins, data.currentStreak),
            _buildTabSwitcher(daily, weekly),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: _selectedTab == 'daily'
                    ? _DailyView(
                        missions: daily,
                        onClaim: _claim,
                        resetAt: data.dailyResetAt,
                      )
                    : _WeeklyView(
                        missions: weekly,
                        onClaim: _claim,
                        weekStrip: data.weekStrip,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _isoWeek(DateTime d) {
    final thursday = d.subtract(Duration(days: d.weekday - 4));
    final jan4 = DateTime(thursday.year, 1, 4);
    return 1 + ((thursday.difference(jan4).inDays) ~/ 7);
  }

  Widget _buildHeader(int coins, int streak) {
    final now = DateTime.now();
    final weekdays = [
      'THỨ HAI',
      'THỨ BA',
      'THỨ TƯ',
      'THỨ NĂM',
      'THỨ SÁU',
      'THỨ BẢY',
      'CHỦ NHẬT'
    ];
    final dayLabel =
        '${weekdays[now.weekday - 1]} · ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}';
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekLabel =
        'TUẦN ${_isoWeek(now)} · ${monday.day}—${sunday.day}.${sunday.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTab == 'daily' ? dayLabel : weekLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF7DD3FC),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nhiệm vụ',
                  style: AppTextStyles.headingLarge.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              CoinBadge(amount: coins),
              const SizedBox(width: 6),
              _buildStreakBadge(streak),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.18),
            AppColors.amber.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: AppColors.amber),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.amber,
              fontWeight: FontWeight.w700,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(List<Mission> dailyData, List<Mission> weeklyData) {
    final dailyDone = dailyData.where((m) => m.done).length;
    final weeklyDone = weeklyData.where((m) => m.progress >= m.target).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.nightSurface,
          border: Border.all(color: AppColors.nightCard),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Animated background
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              top: 4,
              bottom: 4,
              left: _selectedTab == 'daily' ? 4 : null,
              right: _selectedTab == 'weekly' ? 4 : null,
              width: (MediaQuery.of(context).size.width - 40) / 2 - 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            // Tabs
            Row(
              children: [
                _buildTabButton(
                  'daily',
                  'Hằng ngày',
                  '$dailyDone/${dailyData.length}',
                ),
                _buildTabButton(
                  'weekly',
                  'Hằng tuần',
                  '$weeklyDone/${weeklyData.length}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, String count) {
    final isSelected = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily View Component
class _DailyView extends StatelessWidget {
  final List<Mission> missions;
  final Future<void> Function(String questId) onClaim;
  final DateTime resetAt;

  const _DailyView({
    required this.missions,
    required this.onClaim,
    required this.resetAt,
  });

  @override
  Widget build(BuildContext context) {
    final dailyDone = missions.where((m) => m.done).length;
    final claimableXP = missions
        .where((m) => m.done && !m.claimed)
        .fold(0, (sum, m) => sum + m.reward);

    final progress =
        missions.isEmpty ? 0 : ((dailyDone / missions.length) * 100).round();

    return Column(
      children: [
        // Summary Card với Progress Ring
        _buildSummaryCard(progress, dailyDone, missions.length, claimableXP),
        const SizedBox(height: 14),

        // Mission Cards
        ...missions.map(
          (mission) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MissionCard(mission: mission, onClaim: onClaim),
          ),
        ),

        // Footer - Refresh Notice
        _buildRefreshNotice(),
      ],
    );
  }

  Widget _buildSummaryCard(int progress, int done, int total, int claimable) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2A4A), Color(0xFF0B1933)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.nightCard),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, -0.9),
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          Row(
            children: [
              // Progress Ring
              _ProgressRing(
                size: 72,
                strokeWidth: 7,
                progress: progress / 100,
                color: const Color(0xFF38BDF8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$done',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '/$total',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIẾN ĐỘ HÔM NAY',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF7DD3FC),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bạn đã làm rất tốt 👏',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Reward Pills
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _RewardPill(
                          icon: Icons.monetization_on,
                          text: '+40 đã nhận',
                          color: const Color(0xFFFDE68A),
                          backgroundColor: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          borderColor: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.35),
                        ),
                        if (claimable > 0)
                          _RewardPill(
                            icon: Icons.monetization_on,
                            text: '+$claimable sẵn sàng nhận',
                            color: const Color(0xFFFDE68A),
                            backgroundColor: const Color(
                              0xFFFBBF24,
                            ).withValues(alpha: 0.18),
                            borderColor: const Color(
                              0xFFFBBF24,
                            ).withValues(alpha: 0.5),
                            pulse: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshNotice() {
    final diff = resetAt.difference(DateTime.now());
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final label =
        diff.isNegative ? 'Đang làm mới...' : 'Làm mới sau ${h}h ${m}p';

    return Container(
      margin: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Weekly View Component
class _WeeklyView extends StatelessWidget {
  final List<Mission> missions;
  final Future<void> Function(String questId) onClaim;
  final List<WeekDayStatus> weekStrip;

  const _WeeklyView({
    required this.missions,
    required this.onClaim,
    required this.weekStrip,
  });

  @override
  Widget build(BuildContext context) {
    final weeklyDone = missions.where((m) => m.progress >= m.target).length;
    final totalReward = missions.fold(0, (sum, m) => sum + m.reward);
    final weekProgress = missions.isEmpty
        ? 0
        : ((missions.fold(
                      0.0,
                      (sum, m) => sum + math.min(1.0, m.progress / m.target),
                    ) /
                    missions.length) *
                100)
            .round();

    return Column(
      children: [
        // Weekly Chest Card
        _buildWeeklyChest(
          weeklyDone,
          missions.length,
          weekProgress,
          totalReward,
        ),
        const SizedBox(height: 14),

        // 7-Day Progress Strip
        _buildWeekStrip(weekStrip),
        const SizedBox(height: 14),

        // Weekly Mission Cards
        ...missions.map(
          (mission) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MissionCard(
              mission: mission,
              isWeekly: true,
              onClaim: onClaim,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChest(int done, int total, int progress, int reward) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF2D1B6B), Color(0xFF0C2A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFA5B4FC).withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, -1.0),
                  colors: [
                    const Color(0xFFFBBF24).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KHO BÁU CUỐI TUẦN',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFFCD34D),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hoàn thành cả tuần để mở khoá',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$done/$total nhiệm vụ · còn 3 ngày',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFC7D2FE),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Progress Bar
                    Column(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFBBF24),
                                    Color(0xFFF59E0B),
                                    Color(0xFFA78BFA),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFBBF24,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$progress% hoàn thành',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFFCD34D),
                                fontWeight: FontWeight.w600,
                                fontSize: 10.5,
                              ),
                            ),
                            Text(
                              '+${reward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} xu · 2 unlock',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Chest Icon
              _ChestIcon(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip(List<WeekDayStatus> days) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(color: AppColors.nightCard),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'TUẦN NÀY',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                fontSize: 10.5,
              ),
            ),
          ),
          Row(
            children:
                days.map((d) => Expanded(child: _WeekDayItem(day: d))).toList(),
          ),
        ],
      ),
    );
  }
}

/// Week Day Item for 7-day strip
class _WeekDayItem extends StatelessWidget {
  final WeekDayStatus day;

  const _WeekDayItem({required this.day});

  @override
  Widget build(BuildContext context) {
    final status = day.status;
    final progress = day.progressPct;

    Color backgroundColor;
    Color? borderColor;
    Color textColor;
    Color subColor;
    bool isDashed = false;

    switch (status) {
      case 'done':
        backgroundColor = const Color(0xFF0EA5E9);
        textColor = Colors.white;
        subColor = const Color(0xFFBAE6FD);
        break;
      case 'partial':
        backgroundColor = const Color(0xFF0EA5E9).withValues(alpha: 0.18);
        textColor = const Color(0xFFBAE6FD);
        subColor = const Color(0xFF7DD3FC);
        break;
      case 'today':
        backgroundColor = const Color(0xFF38BDF8).withValues(alpha: 0.10);
        borderColor = AppColors.glow;
        textColor = Colors.white;
        subColor = const Color(0xFFFBBF24);
        isDashed = true;
        break;
      case 'future':
      default:
        backgroundColor = Colors.white.withValues(alpha: 0.03);
        textColor = AppColors.textMuted;
        subColor = AppColors.textMuted;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: AspectRatio(
        aspectRatio: 0.78,
        child: Container(
          decoration: BoxDecoration(
            color: status == 'done' ? null : backgroundColor,
            gradient: status == 'done'
                ? const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.05),
              width: isDashed ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day.dayLabel,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
              if (status == 'done')
                const Text('✓', style: TextStyle(fontSize: 13))
              else if (progress != null)
                Text(
                  '$progress%',
                  style: AppTextStyles.caption.copyWith(
                    color: subColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                )
              else
                Text(
                  '·',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mission Card Component
class _MissionCard extends StatelessWidget {
  final Mission mission;
  final bool isWeekly;
  final Future<void> Function(String questId) onClaim;

  const _MissionCard({
    required this.mission,
    required this.onClaim,
    this.isWeekly = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = math.min(
      100,
      ((mission.progress / mission.target) * 100).round(),
    );
    final isDone = mission.progress >= mission.target;
    final isClaimable = isDone && !mission.claimed;

    return Container(
      decoration: BoxDecoration(
        // Completed (claimed) missions read as a clear success state — a green
        // tint distinct from both the amber "claimable" glow and the neutral
        // in-progress card, so a finished mission stands out instead of dimming.
        color: mission.claimed
            ? AppColors.success.withValues(alpha: 0.10)
            : isClaimable
                ? const Color(0xFFFBBF24).withValues(alpha: 0.10)
                : AppColors.nightSurface,
        border: Border.all(
          color: mission.claimed
              ? AppColors.success.withValues(alpha: 0.45)
              : isClaimable
                  ? const Color(0xFFFBBF24).withValues(alpha: 0.5)
                  : AppColors.nightCard,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          // Shimmer effect for claimable missions
          if (isClaimable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFBBF24).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.5, 0.7],
                    begin: const Alignment(-1.0, 0.0),
                    end: const Alignment(1.0, 0.0),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

          Row(
            children: [
              // Mission Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [
                      Color(
                        int.parse(mission.glowColor.substring(1), radix: 16) +
                            0x33000000,
                      ),
                      Color(
                        int.parse(mission.glowColor.substring(1), radix: 16) +
                            0x11000000,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: Color(
                      int.parse(mission.glowColor.substring(1), radix: 16) +
                          0x44000000,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mission.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Mission Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Reward
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      mission.name,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: mission.claimed
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        decoration: mission.claimed
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                  if (mission.isContextual) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFA78BFA,
                                        ).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'AI',
                                        style: AppTextStyles.caption.copyWith(
                                          color: const Color(0xFFC4B5FD),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 8.5,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mission.description,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reward Chip
                        _RewardChip(mission: mission),
                      ],
                    ),

                    const SizedBox(height: 9),

                    // Progress Section
                    Column(
                      children: [
                        // Progress Bar
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                // Full bar stays colored when completed (green)
                                // — never a washed-out gray — so a done mission
                                // looks rewarded, not deactivated.
                                color: mission.claimed
                                    ? AppColors.success
                                    : isDone
                                        ? const Color(0xFFFBBF24)
                                        : Color(
                                            int.parse(
                                                  mission.glowColor
                                                      .substring(1),
                                                  radix: 16,
                                                ) +
                                                0xFF000000,
                                          ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: isDone
                                    ? [
                                        BoxShadow(
                                          color: (mission.claimed
                                                  ? AppColors.success
                                                  : const Color(0xFFFBBF24))
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Progress Text and Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatProgress(
                                mission.progress,
                                mission.target,
                                mission.unit,
                              ),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (isClaimable)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onClaim(mission.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFBBF24),
                                        Color(0xFFF59E0B),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'NHẬN',
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFF451A03),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              )
                            else if (mission.claimed)
                              Text(
                                '✓ ĐÃ NHẬN',
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFFA3E635),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  letterSpacing: 0.4,
                                ),
                              )
                            else
                              Text(
                                '$progress%',
                                style: AppTextStyles.caption.copyWith(
                                  color: Color(
                                    int.parse(
                                          mission.glowColor.substring(1),
                                          radix: 16,
                                        ) +
                                        0xFF000000,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                  fontFeatures: [
                                    const FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatProgress(int progress, int target, String unit) {
    final formatNumber = (int n) => target >= 1000
        ? n.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )
        : n.toString();
    return '${formatNumber(progress)}/${formatNumber(target)}${unit.isNotEmpty ? ' $unit' : ''}';
  }
}

/// Reward Chip Component
class _RewardChip extends StatelessWidget {
  final Mission mission;

  const _RewardChip({required this.mission});

  @override
  Widget build(BuildContext context) {
    if (mission.rewardType == 'coin') {
      return Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFBBF24).withValues(alpha: 0.18),
              const Color(0xFFF59E0B).withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: Color(0xFFFBBF24),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                size: 8,
                color: Color(0xFF451A03),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '+${mission.reward}',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFFDE68A),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    if (mission.rewardType == 'xp') {
      return Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
        decoration: BoxDecoration(
          color: const Color(0xFF818CF8).withValues(alpha: 0.15),
          border: Border.all(
            color: const Color(0xFF818CF8).withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 10, color: const Color(0xFFA5B4FC)),
            const SizedBox(width: 4),
            Text(
              '+${mission.reward}',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFC7D2FE),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    // unlock type
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔓', style: TextStyle(fontSize: 9)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              mission.unlockReward ?? '',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFFDE68A),
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress Ring Component
class _ProgressRing extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double progress;
  final Color color;
  final Widget child;

  const _ProgressRing({
    required this.size,
    required this.strokeWidth,
    required this.progress,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              strokeWidth: strokeWidth,
              color: color.withValues(alpha: 0.12),
              progress: 1.0,
            ),
          ),
          // Progress circle
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              strokeWidth: strokeWidth,
              color: color,
              progress: progress,
            ),
          ),
          // Content
          Center(child: child),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double progress;

  _CirclePainter({
    required this.strokeWidth,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Reward Pill Component
class _RewardPill extends StatefulWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final bool pulse;

  const _RewardPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    this.pulse = false,
  });

  @override
  State<_RewardPill> createState() => _RewardPillState();
}

class _RewardPillState extends State<_RewardPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1800),
        vsync: this,
      )..repeat();
      _animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    if (widget.pulse) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 11, color: widget.color),
          const SizedBox(width: 5),
          Text(
            widget.text,
            style: AppTextStyles.caption.copyWith(
              color: widget.color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    if (!widget.pulse) return pill;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF38BDF8,
                ).withValues(alpha: 0.5 * (1 - _animation.value)),
                blurRadius: 8 * _animation.value,
                spreadRadius: 0,
              ),
            ],
          ),
          child: pill,
        );
      },
    );
  }
}

/// Chest Icon Component
class _ChestIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            const Color(0xFFFBBF24).withValues(alpha: 0.35),
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Chest SVG
          Center(
            child: CustomPaint(
              size: const Size(38, 38),
              painter: _ChestPainter(),
            ),
          ),
          // Sparkle
          const Positioned(
            top: -4,
            right: -4,
            child: Text('✨', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _ChestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Chest bottom
    paint.color = const Color(0xFF92400E);
    canvas.drawRRect(
      RRect.fromLTRBR(
        2,
        10,
        size.width - 2,
        size.height - 2,
        const Radius.circular(2),
      ),
      paint,
    );

    // Chest top
    paint.color = const Color(0xFFB45309);
    canvas.drawRRect(
      RRect.fromLTRBR(2, 5, size.width - 2, 15, const Radius.circular(6)),
      paint,
    );

    // Lock area
    paint.color = const Color(0xFFFBBF24);
    canvas.drawRRect(
      RRect.fromLTRBR(
        size.width / 2 - 4,
        11,
        size.width / 2 + 4,
        23,
        const Radius.circular(1),
      ),
      paint,
    );

    // Keyhole
    paint.color = const Color(0xFF78350F);
    canvas.drawCircle(Offset(size.width / 2, 15.5), 1.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mission Data Model
class Mission {
  final String id;
  final String icon;
  final String glowColor;
  final String name;
  final String description;
  final int progress;
  final int target;
  final String unit;
  final int reward;
  final String rewardType;
  final String? unlockReward;
  final bool done;
  final bool claimed;
  final bool isContextual;
  final int? bonusXP;
  final int? bonusCoin;

  const Mission({
    required this.id,
    required this.icon,
    required this.glowColor,
    required this.name,
    required this.description,
    required this.progress,
    required this.target,
    this.unit = '',
    required this.reward,
    this.rewardType = 'coin',
    this.unlockReward,
    this.done = false,
    this.claimed = false,
    this.isContextual = false,
    this.bonusXP,
    this.bonusCoin,
  });
}

/// Visual identity (icon + glow) per quest id, kept on the client so the
/// existing card design is preserved while data comes from the backend.
const Map<String, ({String icon, String glow})> _questVisuals = {
  // Daily
  'breakthrough_hydration': (icon: '🎯', glow: '#F472B6'),
  'smart_scan': (icon: '📷', glow: '#38BDF8'),
  'friend_reminder': (icon: '🤝', glow: '#C084FC'),
  'ai_companion': (icon: '🤖', glow: '#A78BFA'),
  'daily_bonus': (icon: '🎁', glow: '#FBBF24'),
  // Weekly
  'persistence_week': (icon: '🔥', glow: '#F97316'),
  'hydration_warrior': (icon: '💪', glow: '#38BDF8'),
  'water_scientist': (icon: '🧪', glow: '#A3E635'),
  'hydration_ambassador': (icon: '📣', glow: '#C084FC'),
  'weekly_bonus': (icon: '🎁', glow: '#FBBF24'),
};

/// Map a backend [Quest] onto the existing [Mission] UI model.
Mission _toMission(Quest q) {
  final visual = _questVisuals[q.id] ?? (icon: '💧', glow: '#0EA5E9');

  // The lucky chest shows an "unlock" style chip; everything else shows coins.
  final isUnlock = q.isChest;

  return Mission(
    id: q.id,
    icon: visual.icon,
    glowColor: visual.glow,
    name: q.name,
    description: q.description,
    progress: q.progress,
    target: q.target == 0 ? 1 : q.target,
    unit: q.unit,
    reward: q.rewardCoin,
    rewardType: isUnlock ? 'unlock' : 'coin',
    unlockReward: isUnlock ? 'Rương may mắn' : null,
    done: q.done,
    claimed: q.claimed,
    bonusXP: q.rewardXp,
    bonusCoin: q.rewardCoin,
  );
}
