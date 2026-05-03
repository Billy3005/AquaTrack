import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/home_state.dart';
import '../providers/home_provider.dart';
import '../widgets/living_drop.dart';

/// Screen 01 — Home (Living Drop)
/// Main screen với Living Drop widget, quick log, AI coach card
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeNotifierProvider);
    final homeState = ref.watch(homeStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const _HomeLoadingSkeleton(),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                const Text('Có lỗi xảy ra', style: AppTextStyles.headingMedium),
                const SizedBox(height: 8),
                Text(error.toString(), style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(homeNotifierProvider.notifier).refresh(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (summary) => RefreshIndicator(
            onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với location + streak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _LocationPill(
                          summary.location, summary.temperatureCelsius),
                      _StreakBadge(summary.streakDays),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Greeting với dynamic headline
                  Text(
                    _getGreeting(),
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    HomeStateHelper.getHeadline(homeState),
                    style: AppTextStyles.headingLarge,
                  ),

                  const SizedBox(height: 40),

                  // Living Drop widget (CORE!)
                  Center(
                    child: LivingDrop(
                      progress: summary.progress,
                      state: homeState,
                      currentMl: summary.totalEffectiveMl,
                      goalMl: summary.dailyGoalMl,
                      onTap: () {
                        // TODO: Show drop detail modal
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // XP Bar
                  _XpBar(summary.xpToday, summary.currentLevel),

                  const SizedBox(height: 32),

                  // Quick log buttons
                  const Text(
                    'Quick Log',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: AppConstants.quickLogAmounts
                        .map((amount) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: amount ==
                                          AppConstants.quickLogAmounts.last
                                      ? 0
                                      : 12,
                                ),
                                child: _QuickLogButton(
                                  '${amount}ml',
                                  onTap: () => _quickLog(ref, amount),
                                ),
                              ),
                            ))
                        .toList()
                      ..add(
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _QuickLogButton(
                              '+ Khác',
                              onTap: () => context.push('/log-drink'),
                            ),
                          ),
                        ),
                      ),
                  ),

                  const SizedBox(height: 32),

                  // AQUA AI Card
                  _AquaAiCard(),

                  const SizedBox(height: 24),

                  // Today summary
                  Text(
                    'Hôm nay  ${summary.logCount} lần · ${summary.totalEffectiveMl}ml',
                    style: AppTextStyles.bodyMedium,
                  ),

                  // Add bottom padding for better scrolling
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'CHÀO BUỔI SÁNG';
    if (hour < 17) return 'CHÀO BUỔI CHIỀU';
    return 'CHÀO BUỔI TỐI';
  }

  Future<void> _quickLog(WidgetRef ref, int amount) async {
    HapticFeedback.mediumImpact();
    await ref.read(homeNotifierProvider.notifier).quickLog(amount);

    // Success feedback
    HapticFeedback.lightImpact();
  }
}

class _LocationPill extends StatelessWidget {
  final String location;
  final double temperature;

  const _LocationPill(this.location, this.temperature);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$location · ${temperature.round()}°C',
        style: AppTextStyles.caption,
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streakDays;

  const _StreakBadge(this.streakDays);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.streakOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🔥 Streak $streakDays ngày',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final int xpToday;
  final int currentLevel;

  const _XpBar(this.xpToday, this.currentLevel);

  @override
  Widget build(BuildContext context) {
    // Simplified XP calculation for mock
    final maxXp = currentLevel * 200;
    final currentXp = (currentLevel - 1) * 200 + xpToday;
    final progress = (currentXp % maxXp) / maxXp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LV $currentLevel · Aqua Warrior',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.xpPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.xpPurple,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currentXp / $maxXp XP',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickLogButton(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AquaAiCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tiến độ tốt! Nhớ uống thêm vào buổi chiều nhé.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading state for home screen
class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBox(width: 120, height: 30),
              _SkeletonBox(width: 100, height: 30),
            ],
          ),

          const SizedBox(height: 32),

          // Greeting skeleton
          const _SkeletonBox(width: 200, height: 16),
          const SizedBox(height: 8),
          const _SkeletonBox(width: 250, height: 28),

          const SizedBox(height: 40),

          // Drop skeleton (circular)
          const Center(
            child: _SkeletonCircle(radius: 120),
          ),

          const SizedBox(height: 40),

          // XP bar skeleton
          const _SkeletonBox(width: double.infinity, height: 20),

          const SizedBox(height: 32),

          // Quick log skeleton
          const _SkeletonBox(width: 120, height: 20),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
                  child: const _SkeletonBox(width: double.infinity, height: 48),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // AI card skeleton
          const _SkeletonBox(width: double.infinity, height: 80),
        ],
      ),
    );
  }
}

/// Skeleton box widget
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1200.ms,
          color: AppColors.cyan.withValues(alpha: 0.1),
        );
  }
}

/// Skeleton circle widget
class _SkeletonCircle extends StatelessWidget {
  final double radius;

  const _SkeletonCircle({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1200.ms,
          color: AppColors.cyan.withValues(alpha: 0.1),
        );
  }
}
