import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'providers/home_provider.dart';

/// Home Screen - Real data with API integration
class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _breathingController.repeat(reverse: true);
  }

  /// Quick log water intake using provider
  Future<void> _quickLogWater(int amountMl) async {
    HapticFeedback.lightImpact();

    try {
      // Use home provider to log water
      await ref.read(homeNotifierProvider.notifier).quickLog(amountMl);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã log ${amountMl}ml nước! 💧',
              style: AppTextStyles.bodyMedium,
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: homeSummaryAsync.when(
            data: (summary) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(summary),
                  const SizedBox(height: 32),
                  _buildLivingDrop(summary),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildTodayStats(summary),
                  const SizedBox(height: 24),
                  _buildAquaCoachCard(),
                  const SizedBox(height: 24),
                  _buildAuthMessage(),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra khi tải dữ liệu',
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(homeNotifierProvider),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildQuickLogFAB(),
    );
  }

  /// Header with greeting and level
  Widget _buildHeader(dynamic summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào Demo User! 👋', style: AppTextStyles.displayMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: AppColors.purpleXP),
                const SizedBox(width: 4),
                Text(
                  'Level ${summary?.currentLevel ?? 1} • ${summary?.xpToday ?? 0}XP',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cyanAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyanAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: AppColors.juiceColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${summary?.streakDays ?? 0} ngày',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Living Drop với breathing animation
  Widget _buildLivingDrop(dynamic summary) {
    final hydrationPercentage = summary != null
        ? (summary.totalEffectiveMl / summary.dailyGoalMl).clamp(0.0, 1.0)
        : 0.0;
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _breathingAnimation.value,
          child: Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Drop shape với fill level
                Container(
                  width: 160,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.dropEmpty,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(80),
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Filled portion
                      Container(
                        height: 200.0 * hydrationPercentage,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.dropGradientStart,
                              AppColors.dropGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: const Radius.circular(80),
                            top: hydrationPercentage > 0.9
                                ? const Radius.circular(20)
                                : Radius.zero,
                          ),
                        ),
                      ),
                      // Water level indicator
                      if (hydrationPercentage > 0)
                        Positioned(
                          bottom: 200.0 * hydrationPercentage - 2,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.cyanLight,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyanAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Progress text overlay
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(hydrationPercentage * 100).round()}%',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: hydrationPercentage > 0.5
                            ? AppColors.textPrimary
                            : AppColors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${summary?.totalEffectiveMl ?? 0}ml / ${summary?.dailyGoalMl ?? 2000}ml',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: hydrationPercentage > 0.5
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Quick action buttons
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Log', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildQuickLogButton(150)),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickLogButton(250)),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickLogButton(350)),
          ],
        ),
        const SizedBox(height: 16),
        // Smart Scan button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/smart-scan'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('📸 Smart Scan - Tự động đo thể tích'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.purpleXP.withValues(alpha: 0.2),
              foregroundColor: AppColors.purpleXP,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.purpleXP.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLogButton(int amountMl) {
    return ElevatedButton(
      onPressed: () => _quickLogWater(amountMl),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(Icons.water_drop, color: AppColors.cyanAccent, size: 24),
          const SizedBox(height: 4),
          Text(
            '${amountMl}ml',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Today's stats summary
  Widget _buildTodayStats(dynamic summary) {
    final todayIntake = summary?.totalEffectiveMl ?? 0;
    final dailyGoal = summary?.dailyGoalMl ?? 2000;
    final hydrationPercentage = (todayIntake / dailyGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_outlined, color: AppColors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hôm nay',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Đã uống',
                '${todayIntake}ml',
                Icons.water_drop,
                AppColors.cyanAccent,
              ),
              _buildStatItem(
                'Còn lại',
                '${(dailyGoal - todayIntake).clamp(0, dailyGoal)}ml',
                Icons.flag_outlined,
                AppColors.warning,
              ),
              _buildStatItem(
                'Tiến độ',
                '${(hydrationPercentage * 100).round()}%',
                Icons.trending_up,
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// AQUA Coach AI card
  Widget _buildAquaCoachCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purpleXP.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.purpleXP,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AQUA Coach',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.purpleXP,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'AI Personal Hydration Assistant',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn đang làm rất tốt! Hãy tiếp tục duy trì thói quen uống nước đều đặn. Tôi khuyên bạn nên uống thêm 200ml vào lúc 3PM.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/coach'),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Chat với AQUA Coach'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleXP.withValues(alpha: 0.2),
              foregroundColor: AppColors.purpleXP,
            ),
          ),
        ],
      ),
    );
  }

  /// Authentication status message
  Widget _buildAuthMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyanAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user,
            color: AppColors.cyanAccent,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Đã đăng nhập thành công',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.cyanAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dữ liệu đang được đồng bộ với server',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.cyanAccent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Floating Action Button for quick log
  Widget _buildQuickLogFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/log-drink'),
      backgroundColor: AppColors.cyanAccent,
      foregroundColor: AppColors.textPrimary,
      icon: const Icon(Icons.add),
      label: const Text('Log Drink'),
    );
  }
}
