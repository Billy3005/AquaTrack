import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/living_drop.dart';
import '../../core/providers/user_stats_provider.dart';
import '../../shared/widgets/coin_badge.dart';
import '../level/providers/level_provider.dart';
import 'providers/home_provider.dart';

/// Home Screen - Complete redesign matching aquatrack/project/components/home.jsx
class HomeScreenRedesign extends ConsumerStatefulWidget {
  const HomeScreenRedesign({super.key});

  @override
  ConsumerState<HomeScreenRedesign> createState() => _HomeScreenRedesignState();
}

class _HomeScreenRedesignState extends ConsumerState<HomeScreenRedesign>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _xpController;
  late Animation<double> _xpAnimation;
  int _activeChip = 250;
  bool _showXpPopup = false;
  bool _hasRefreshedThisBuild = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _xpAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _xpController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _xpController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Reset refresh flag khi user navigate away
    _hasRefreshedThisBuild = false;
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh user stats when app becomes active
    if (state == AppLifecycleState.resumed) {
      _refreshUserStats();
    }
  }

  /// Refresh user stats when returning to home screen
  void _refreshUserStats() {
    try {
      // Refresh home provider data từ server
      ref.read(homeNotifierProvider.notifier).refresh();

      // Refresh user stats counter
      final refreshNotifier = ref.read(userStatsRefreshProvider.notifier);
      refreshNotifier.state++;

      debugPrint('🏠 HomeScreen: Triggered data refresh');
    } catch (e) {
      debugPrint('❌ HomeScreen: Error refreshing data: $e');
    }
  }

  /// Get level name from level number
  String _getLevelName(int level) {
    if (level >= 50) return 'Thần nước';
    if (level >= 40) return 'Chuyên gia hydration';
    if (level >= 30) return 'Bậc thầy nước';
    if (level >= 20) return 'Ninja hydration';
    if (level >= 10) return 'Chiến binh nước';
    if (level >= 5) return 'Người uống nước';
    return 'Tân binh';
  }

  /// Show XP popup animation
  void _showXpAnimation(int amount) {
    setState(() {
      _showXpPopup = true;
    });

    _xpController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showXpPopup = false;
        });
        _xpController.reset();
      }
    });
  }

  /// Quick log water with XP animation
  Future<void> _handleQuickLog(int amount) async {
    setState(() {
      _activeChip = amount;
    });

    HapticFeedback.lightImpact();

    try {
      // Log water
      await ref.read(homeNotifierProvider.notifier).quickLog(amount);

      // Show XP popup animation
      _showXpAnimation(20);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã log ${amount}ml nước! +20 XP 💧',
              style: AppTextStyles.bodyMedium,
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi log nước: $e',
              style: AppTextStyles.bodyMedium,
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeSummaryAsync = ref.watch(homeNotifierProvider);
    final levelStateAsync = ref.watch(levelNotifierProvider);

    // Refresh data when screen comes into focus after navigation (once per build)
    if (!_hasRefreshedThisBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshUserStats();
      });
      _hasRefreshedThisBuild = true;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: homeSummaryAsync.when(
            data: (summary) => levelStateAsync.when(
              data: (levelState) =>
                  _buildMainContent(summary, null, levelState),
              loading: () => _buildMainContent(summary, null, null),
              error: (error, stack) => _buildMainContent(summary, null, null),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ),
      floatingActionButton: _buildSmartScanFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMainContent(
      dynamic summary, UserStatsData? userStats, LevelState? levelState) {
    final current = (summary?.totalEffectiveMl ?? 0).toDouble();
    final goal = (summary?.dailyGoalMl ?? 2000)
        .toDouble(); // Use goal from summary or default
    final percent = ((current / goal) * 100.0).clamp(0.0, 100.0);

    // Determine state based on current data
    final isGoal = percent >= 80.0;
    final isLow = percent < 31.0;
    final hot = false; // Could be determined by weather API
    final isNight = DateTime.now().hour >= 22 || DateTime.now().hour < 6;

    return Column(
      children: [
        // Hero section
        _buildHeroSection(summary, userStats, levelState, percent, isGoal,
            isLow, isNight, hot),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickTapRow(),
                const SizedBox(height: 22),
                _buildAquaAICard(hot, isLow, isGoal, isNight),
                const SizedBox(height: 18),
                _buildTodayLogSection(current.round()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(
    dynamic summary,
    UserStatsData? userStats,
    LevelState? levelState,
    double percent,
    bool isGoal,
    bool isLow,
    bool isNight,
    bool hot,
  ) {
    final current = summary?.totalEffectiveMl ?? 0;
    final goal = userStats?.dailyGoalMl ?? summary?.dailyGoalMl ?? 2000;

    // Hero background based on state
    Gradient heroBg;
    if (isGoal) {
      heroBg = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0C4A80), Color(0xFF1E6FA8), Color(0xFF0EA5E9)],
      );
    } else if (isLow) {
      heroBg = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF061830), Color(0xFF0A2545)],
      );
    } else if (hot) {
      heroBg = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A0A00), Color(0xFF0C2A48)],
      );
    } else if (isNight) {
      heroBg = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050B18), Color(0xFF0B1933)],
      );
    } else {
      heroBg = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A3460), Color(0xFF0C4A80)],
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: heroBg),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
      child: Column(
        children: [
          // Top context row
          _buildTopContextRow(summary, userStats, levelState, hot, isNight),
          const SizedBox(height: 8),

          // Greeting
          _buildGreeting(isLow, isGoal, isNight),
          const SizedBox(height: 20),

          // Living Drop with XP popup
          Stack(
            alignment: Alignment.center,
            children: [
              LivingDrop(
                percent: percent,
                size: 200,
                label: '${percent.round()}%',
                sublabel: '${current.round()} / ${goal.round()} ml',
                showGlow: isGoal,
              ),

              // XP popup animation
              if (_showXpPopup)
                AnimatedBuilder(
                  animation: _xpAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: 180 - (_xpAnimation.value * 60),
                      child: Opacity(
                        opacity: _xpAnimation.value < 0.8
                            ? _xpAnimation.value * 1.25
                            : (1.0 - _xpAnimation.value) * 5,
                        child: Text(
                          '+20 XP',
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFDE68A),
                            shadows: [
                              Shadow(
                                color: const Color(
                                  0xFFFBBF24,
                                ).withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // XP bar in hero
          _buildXPBar(summary, userStats, levelState),
        ],
      ),
    );
  }

  Widget _buildTopContextRow(dynamic summary, UserStatsData? userStats,
      LevelState? levelState, bool hot, bool isNight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Weather info
        Row(
          children: [
            Icon(
              hot
                  ? Icons.wb_sunny
                  : isNight
                      ? Icons.nightlight_round
                      : Icons.water_drop,
              size: 14,
              color: hot ? const Color(0xFFFBBF24) : const Color(0xFF7DD3FC),
            ),
            const SizedBox(width: 6),
            Text(
              hot
                  ? 'HCMC · 34°C'
                  : isNight
                      ? 'Đêm · 22°C'
                      : 'HCMC · 28°C',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFBAE6FD).withValues(alpha: 0.85),
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),

        // Coin and streak badges - use data from level state
        Row(
          children: [
            CoinBadge(amount: levelState?.currentXP ?? 0),
            const SizedBox(width: 6),
            _buildStreakBadge(levelState?.currentStreak ?? 0),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakBadge(int days) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: const Color(0x26F97316), // rgba(249,115,22,0.15)
        border: Border.all(
          color: const Color(0x59F97316), // rgba(249,115,22,0.35)
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
              ),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Chuỗi $days ngày',
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFED7AA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(bool isLow, bool isGoal, bool isNight) {
    String greetingTime;
    String greetingText;

    if (isNight) {
      greetingTime = 'Tối muộn · ${TimeOfDay.now().format(context)}';
    } else {
      greetingTime = 'Chào buổi sáng';
    }

    if (isLow) {
      greetingText = 'Cơ thể bạn đang khát';
    } else if (isGoal) {
      greetingText = 'Tuyệt vời, gần đủ rồi!';
    } else if (isNight) {
      greetingText = 'Một ngụm trước khi ngủ?';
    } else {
      greetingText = 'Hãy cùng giữ nhịp uống nước';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greetingTime,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFFBAE6FD).withValues(alpha: 0.7),
            letterSpacing: 0.04,
            fontWeight: FontWeight.w500,
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          greetingText,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.02,
          ),
        ),
      ],
    );
  }

  Widget _buildXPBar(
      dynamic summary, UserStatsData? userStats, LevelState? levelState) {
    final xp = (levelState?.currentXP ?? 0).toDouble();
    final level = levelState?.currentLevel ?? 1;
    final levelName = _getLevelName(level);

    // Use next level XP from level state
    final xpMax = (levelState?.nextLevelXP ?? level * 100).toDouble();
    final pct = xpMax > 0 ? (xp / xpMax * 100.0).clamp(0.0, 100.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x80081E38), // rgba(8,30,56,0.5)
        border: Border.all(
          color: const Color(0x2E38BDF8), // rgba(56,189,248,0.18)
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
        ],
      ),
      child: Column(
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
                '${xp.round()} / ${xpMax.round()} XP',
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
              widthFactor: (pct / 100.0).clamp(0.0, 1.0),
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
      ),
    );
  }

  Widget _buildQuickTapRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ghi nhanh',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.01,
                fontFamily: 'SF Pro Text',
              ),
            ),
            Text(
              'Giữ để nạp liên tục',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildQuickChip(100)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuickChip(250)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuickChip(500)),
            const SizedBox(width: 8),
            Expanded(child: _buildCustomChip()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickChip(int amount) {
    final isActive = _activeChip == amount;

    return GestureDetector(
      onTap: () => _handleQuickLog(amount),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive
                ? AppColors.borderActive
                : const Color(0x2E38BDF8), // rgba(56,189,248,0.18)
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isActive
              ? const Color(0xFF0C3F6A)
              : const Color(0x990F1A2E), // rgba(15,26,46,0.6)
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0x1F38BDF8), // rgba(56,189,248,0.12)
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.04),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color:
                    isActive ? const Color(0xFFE0F2FE) : AppColors.textPrimary,
                fontFamily: 'SF Pro Rounded',
                letterSpacing: -0.01,
              ),
            ),
            Text(
              'ml',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    return GestureDetector(
      onTap: () => context.push('/log-drink'),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0x2E38BDF8), // rgba(56,189,248,0.18)
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0x990F1A2E), // rgba(15,26,46,0.6)
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.04),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.textSecondary, size: 14),
            const SizedBox(height: 4),
            Text(
              'Khác',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Rounded',
                letterSpacing: -0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAquaAICard(bool hot, bool isLow, bool isGoal, bool isNight) {
    String message;
    if (hot) {
      message =
          'Trời HCMC đang 34°C — uống thêm +300ml so với bình thường nhé.';
    } else if (isLow) {
      message = 'Đã 14h mà mới đạt 28%. Uống 300ml ngay để theo kịp nhé!';
    } else if (isGoal) {
      message = 'Bạn đang trên đà streak 13 ngày — chỉ còn 380ml nữa thôi!';
    } else {
      message =
          'Cà phê bạn vừa log có tính lợi tiểu — cần thêm +250ml để bù lại.';
    }

    return GestureDetector(
      onTap: () => context.push('/coach'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(1.35, -1.35),
            end: Alignment(-1.35, 1.35),
            colors: [
              Color(0x2438BDF8), // rgba(56,189,248,0.14)
              Color(0x19818CF8), // rgba(129,140,248,0.10)
            ],
          ),
          border: Border.all(
            color: const Color(0x4038BDF8), // rgba(56,189,248,0.25)
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // AI Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(0.3, 0.3),
                  colors: [Color(0xFF7DD3FC), Color(0xFF0EA5E9)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x8038BDF8), // rgba(56,189,248,0.5)
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AQUA AI',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textBright,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.04,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLogSection(int currentMl) {
    final todayEntries = [
      {'type': 'water', 'amt': 250, 'time': '13:20', 'label': 'Nước lọc'},
      {'type': 'coffee', 'amt': 180, 'time': '10:45', 'label': 'Cà phê đá'},
      {'type': 'tea', 'amt': 200, 'time': '09:10', 'label': 'Trà sen'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hôm nay',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Text',
              ),
            ),
            Text(
              '${todayEntries.length} lần · ${currentMl}ml',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.nightSurface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: todayEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == todayEntries.length - 1;

              return Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    _buildDrinkIcon(item['type'] as String),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item['time'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '${item['amt']}',
                        style: const TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        children: [
                          TextSpan(
                            text: ' ml',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDrinkIcon(String type) {
    final iconMap = {
      'water': {'color': const Color(0xFF38BDF8), 'icon': Icons.water_drop},
      'tea': {'color': const Color(0xFFA3E635), 'icon': Icons.local_cafe},
      'coffee': {'color': const Color(0xFFA78BFA), 'icon': Icons.coffee},
      'juice': {'color': const Color(0xFFFB923C), 'icon': Icons.local_drink},
      'smoothie': {'color': const Color(0xFFF472B6), 'icon': Icons.local_drink},
    };

    final config = iconMap[type] ?? iconMap['water']!;
    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.27)),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildSmartScanFAB() {
    return FloatingActionButton(
      onPressed: () => context.push('/smart-scan'),
      backgroundColor: AppColors.glow,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-1.35, -1.35),
            end: Alignment(1.35, 1.35),
            colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x800EA5E9), // rgba(14,165,233,0.5)
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Có lỗi xảy ra khi tải dữ liệu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(homeNotifierProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
