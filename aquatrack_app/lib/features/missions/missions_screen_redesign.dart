import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Missions Screen với Daily & Weekly missions
class MissionsScreenRedesign extends StatefulWidget {
  const MissionsScreenRedesign({super.key});

  @override
  State<MissionsScreenRedesign> createState() => _MissionsScreenRedesignState();
}

class _MissionsScreenRedesignState extends State<MissionsScreenRedesign>
    with SingleTickerProviderStateMixin {
  String _selectedTab = 'daily';
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabSwitcher(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: _selectedTab == 'daily'
                    ? const _DailyView()
                    : const _WeeklyView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  _selectedTab == 'daily'
                      ? 'THỨ HAI · 11.05'
                      : 'TUẦN 19 · 11—17.05',
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
              _buildCoinBadge(),
              const SizedBox(width: 6),
              _buildStreakBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinBadge() {
    return GestureDetector(
      onTap: () {
        // Navigate to shop
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFBBF24).withValues(alpha: 0.18),
              const Color(0xFFF59E0B).withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFFBBF24),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                size: 12,
                color: Color(0xFF451A03),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '1,240',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFFDE68A),
                fontWeight: FontWeight.w700,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
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
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: AppColors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            '12',
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

  Widget _buildTabSwitcher() {
    final dailyData = _getDailyMissions();
    final weeklyData = _getWeeklyMissions();

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
  const _DailyView();

  @override
  Widget build(BuildContext context) {
    final missions = _getDailyMissions();
    final dailyDone = missions.where((m) => m.done).length;
    final claimableXP = missions
        .where((m) => m.done && !m.claimed)
        .fold(0, (sum, m) => sum + m.reward);

    final progress = ((dailyDone / missions.length) * 100).round();

    return Column(
      children: [
        // Summary Card với Progress Ring
        _buildSummaryCard(progress, dailyDone, missions.length, claimableXP),
        const SizedBox(height: 14),

        // Mission Cards
        ...missions.map((mission) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MissionCard(mission: mission),
            )),

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
                          backgroundColor:
                              const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderColor:
                              const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        ),
                        if (claimable > 0)
                          _RewardPill(
                            icon: Icons.monetization_on,
                            text: '+$claimable sẵn sàng nhận',
                            color: const Color(0xFFFDE68A),
                            backgroundColor:
                                const Color(0xFFFBBF24).withValues(alpha: 0.18),
                            borderColor:
                                const Color(0xFFFBBF24).withValues(alpha: 0.5),
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
    return Container(
      margin: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 12,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            'Làm mới sau 11h 24p',
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
  const _WeeklyView();

  @override
  Widget build(BuildContext context) {
    final missions = _getWeeklyMissions();
    final weeklyDone = missions.where((m) => m.progress >= m.target).length;
    final totalReward = missions.fold(0, (sum, m) => sum + m.reward);
    final weekProgress = ((missions.fold(0.0,
                    (sum, m) => sum + math.min(1.0, m.progress / m.target)) /
                missions.length) *
            100)
        .round();

    return Column(
      children: [
        // Weekly Chest Card
        _buildWeeklyChest(
            weeklyDone, missions.length, weekProgress, totalReward),
        const SizedBox(height: 14),

        // 7-Day Progress Strip
        _buildWeekStrip(),
        const SizedBox(height: 14),

        // Weekly Mission Cards
        ...missions.map((mission) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MissionCard(mission: mission, isWeekly: true),
            )),
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
                                    Color(0xFFA78BFA)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFBBF24)
                                        .withValues(alpha: 0.5),
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
                                  const FontFeature.tabularFigures()
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

  Widget _buildWeekStrip() {
    final days = [
      {'day': 'T2', 'status': 'done', 'progress': 100},
      {'day': 'T3', 'status': 'done', 'progress': 100},
      {'day': 'T4', 'status': 'partial', 'progress': 78},
      {'day': 'T5', 'status': 'done', 'progress': 100},
      {'day': 'T6', 'status': 'today', 'progress': 58},
      {'day': 'T7', 'status': 'future'},
      {'day': 'CN', 'status': 'future'},
    ];

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
            children: days.map((day) {
              return Expanded(
                child: _WeekDayItem(day: day),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Week Day Item for 7-day strip
class _WeekDayItem extends StatelessWidget {
  final Map<String, dynamic> day;

  const _WeekDayItem({required this.day});

  @override
  Widget build(BuildContext context) {
    final status = day['status'] as String;
    final progress = day['progress'] as int?;

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
                day['day'] as String,
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
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
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

  const _MissionCard({
    required this.mission,
    this.isWeekly = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        math.min(100, ((mission.progress / mission.target) * 100).round());
    final isDone = mission.progress >= mission.target;
    final isClaimable = isDone && !mission.claimed;

    return Container(
      decoration: BoxDecoration(
        color: mission.claimed
            ? const Color(0xFF0F1A2E).withValues(alpha: 0.5)
            : isClaimable
                ? const Color(0xFFFBBF24).withValues(alpha: 0.10)
                : AppColors.nightSurface,
        border: Border.all(
          color: mission.claimed
              ? Colors.white.withValues(alpha: 0.08)
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
                              0x33000000),
                      Color(
                          int.parse(mission.glowColor.substring(1), radix: 16) +
                              0x11000000),
                    ],
                  ),
                  border: Border.all(
                    color: Color(
                        int.parse(mission.glowColor.substring(1), radix: 16) +
                            0x44000000),
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
                                        color: const Color(0xFFA78BFA)
                                            .withValues(alpha: 0.18),
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
                                color: mission.claimed
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : isDone
                                        ? const Color(0xFFFBBF24)
                                        : Color(int.parse(
                                                mission.glowColor.substring(1),
                                                radix: 16) +
                                            0xFF000000),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: isDone && !mission.claimed
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFBBF24)
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
                              _formatProgress(mission.progress, mission.target,
                                  mission.unit),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                fontFeatures: [
                                  const FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            if (isClaimable)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  // Handle claim action
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
                                        Color(0xFFF59E0B)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.4),
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
                                  color: Color(int.parse(
                                          mission.glowColor.substring(1),
                                          radix: 16) +
                                      0xFF000000),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                  fontFeatures: [
                                    const FontFeature.tabularFigures()
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
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')
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
            Icon(
              Icons.bolt,
              size: 10,
              color: const Color(0xFFA5B4FC),
            ),
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
      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
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
          Icon(
            widget.icon,
            size: 11,
            color: widget.color,
          ),
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
                color: const Color(0xFF38BDF8)
                    .withValues(alpha: 0.5 * (1 - _animation.value)),
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
          2, 10, size.width - 2, size.height - 2, const Radius.circular(2)),
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
      RRect.fromLTRBR(size.width / 2 - 4, 11, size.width / 2 + 4, 23,
          const Radius.circular(1)),
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

/// Sample Data
List<Mission> _getDailyMissions() {
  return [
    const Mission(
      id: 'd1',
      icon: '🌅',
      glowColor: '#FBBF24',
      name: 'Khởi đầu tươi mới',
      description: 'Uống 250ml trong 30 phút sau khi thức dậy',
      progress: 250,
      target: 250,
      unit: 'ml',
      reward: 15,
      done: true,
      claimed: true,
    ),
    const Mission(
      id: 'd2',
      icon: '☀️',
      glowColor: '#38BDF8',
      name: 'Nửa ngày — nửa bình',
      description: 'Đạt 50% mục tiêu trước 12:00',
      progress: 1250,
      target: 1250,
      unit: 'ml',
      reward: 25,
      done: true,
      claimed: false,
    ),
    const Mission(
      id: 'd3',
      icon: '💧',
      glowColor: '#0EA5E9',
      name: 'Đều đặn cả ngày',
      description: 'Log nước ít nhất 5 lần',
      progress: 3,
      target: 5,
      unit: 'lần',
      reward: 20,
    ),
    const Mission(
      id: 'd4',
      icon: '🏃',
      glowColor: '#A78BFA',
      name: 'Bù nước sau vận động',
      description: 'Uống 500ml trong 1h sau khi tập',
      progress: 0,
      target: 500,
      unit: 'ml',
      reward: 30,
      isContextual: true,
    ),
    const Mission(
      id: 'd5',
      icon: '🎯',
      glowColor: '#F472B6',
      name: 'Cán đích hôm nay',
      description: 'Đạt 100% mục tiêu 2,500ml',
      progress: 1450,
      target: 2500,
      unit: 'ml',
      reward: 50,
    ),
  ];
}

List<Mission> _getWeeklyMissions() {
  return [
    const Mission(
      id: 'w1',
      icon: '🔥',
      glowColor: '#F97316',
      name: 'Tuần lễ kiên trì',
      description: 'Streak 7 ngày liên tiếp',
      progress: 5,
      target: 7,
      unit: 'ngày',
      reward: 150,
      rewardType: 'unlock',
      unlockReward: 'Avatar Frame · Ocean',
      bonusXP: 150,
      bonusCoin: 250,
    ),
    const Mission(
      id: 'w2',
      icon: '🌊',
      glowColor: '#38BDF8',
      name: 'Đại dương 14 lít',
      description: 'Tổng 14,000ml trong tuần',
      progress: 9850,
      target: 14000,
      unit: 'ml',
      reward: 200,
    ),
    const Mission(
      id: 'w3',
      icon: '⭐',
      glowColor: '#FBBF24',
      name: 'Hoàn thành 5/7',
      description: 'Đạt mục tiêu ngày trong 5 ngày',
      progress: 4,
      target: 5,
      unit: 'ngày',
      reward: 120,
      rewardType: 'unlock',
      unlockReward: 'Theme Forest Rain',
      bonusXP: 120,
      bonusCoin: 180,
    ),
    const Mission(
      id: 'w4',
      icon: '🍵',
      glowColor: '#A3E635',
      name: 'Đa dạng hoá',
      description: 'Thử log 4 loại đồ uống khác nhau',
      progress: 3,
      target: 4,
      unit: 'loại',
      reward: 80,
    ),
    const Mission(
      id: 'w5',
      icon: '🤝',
      glowColor: '#C084FC',
      name: 'Cùng nhau hydrate',
      description: 'Mời 1 bạn tham gia AquaTrack',
      progress: 0,
      target: 1,
      unit: 'bạn',
      reward: 120,
    ),
  ];
}
