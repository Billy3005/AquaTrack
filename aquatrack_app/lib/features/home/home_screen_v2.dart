import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/living_drop.dart';
import 'providers/home_provider.dart';

/// Home Screen - Real data with API integration
class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  @override
  void initState() {
    super.initState();
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(summary),
                  const SizedBox(height: 24),
                  _buildLivingDrop(summary),
                  const SizedBox(height: 40),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  _buildTodayStats(summary),
                  const SizedBox(height: 32),
                  _buildAquaCoachCard(),
                  const SizedBox(height: 32),
                  _buildAuthMessage(),
                  const SizedBox(height: 20),
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

  /// Header with greeting and level - Enhanced prototype styling
  Widget _buildHeader(dynamic summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào Demo User! 👋',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purpleXP.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.purpleXP.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.purpleXP,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Level ${summary?.currentLevel ?? 1} • ${summary?.xpToday ?? 0}XP',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.purpleXP,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
                const Icon(
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
      ),
    );
  }

  /// Living Drop với beautiful wave animation
  Widget _buildLivingDrop(dynamic summary) {
    final hydrationPercentage = summary != null
        ? (summary.totalEffectiveMl / summary.dailyGoalMl).clamp(0.0, 1.0) * 100
        : 0.0;

    final totalMl = summary?.totalEffectiveMl ?? 0;
    final goalMl = summary?.dailyGoalMl ?? 2000;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceColor.withValues(alpha: 0.4),
            AppColors.surfaceColorSoft.withValues(alpha: 0.6),
            AppColors.primaryBackground.withValues(alpha: 0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanDeep.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Living Drop
          LivingDrop(
            percent: hydrationPercentage,
            size: 200,
            label: '${hydrationPercentage.round()}%',
            sublabel: '${totalMl}ml / ${goalMl}ml',
            showGlow: hydrationPercentage >= 70,
          ),

          const SizedBox(height: 16),

          // Enhanced progress indicator
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surfaceColorSoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: hydrationPercentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.cyanLight, AppColors.cyanAccent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyanAccent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Status text
          Text(
            _getHydrationStatus(hydrationPercentage),
            style: AppTextStyles.bodyMedium.copyWith(
              color: _getStatusColor(hydrationPercentage),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getHydrationStatus(double percentage) {
    if (percentage >= 100)
      return '🎉 Xuất sắc! Bạn đã hoàn thành mục tiêu hôm nay';
    if (percentage >= 80) return '💧 Tuyệt vời! Sắp đạt mục tiêu rồi';
    if (percentage >= 50) return '✨ Đang tiến bộ tốt, tiếp tục nào!';
    if (percentage >= 25) return '💪 Hãy uống thêm nước nhé';
    return '🚨 Cơ thể bạn cần nước ngay!';
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 80) return AppColors.green;
    if (percentage >= 50) return AppColors.cyanAccent;
    if (percentage >= 25) return AppColors.amber;
    return AppColors.error;
  }

  /// Quick action buttons - Enhanced prototype styling
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Log',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildQuickLogButton(150)),
            const SizedBox(width: 16),
            Expanded(child: _buildQuickLogButton(250)),
            const SizedBox(width: 16),
            Expanded(child: _buildQuickLogButton(350)),
          ],
        ),
        const SizedBox(height: 20),
        // Enhanced Smart Scan button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purpleXP.withValues(alpha: 0.15),
                AppColors.purpleDeep.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.purpleXP.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/smart-scan'),
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: Text(
              '📸 Smart Scan - Tự động đo thể tích',
              style: AppTextStyles.buttonTextMedium.copyWith(
                color: AppColors.purpleXP,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.purpleXP,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLogButton(int amountMl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceColor.withValues(alpha: 0.6),
            AppColors.surfaceColorSoft.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _quickLogWater(amountMl),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_rounded,
              color: AppColors.cyanAccent,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              '${amountMl}ml',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
