import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/stats_provider.dart';
import '../widgets/wave_chart.dart';
import '../widgets/period_selector.dart';
import '../widgets/insights_cards.dart';

/// Screen 04 — Stats (Wave Chart)
/// Weekly wave chart với AI insights
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncState = ref.watch(statsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('THỐNG KÊ', style: AppTextStyles.headingMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Period selector in app bar (only show when we have data)
          statsAsyncState.when(
            data: (statsData) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: CompactPeriodSelector(
                  selectedPeriod: statsData.period,
                  onPeriodChanged: (period) {
                    ref.read(statsPeriodProvider.notifier).state = period;
                  },
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, stack) => const SizedBox(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh stats data and wait for completion
          ref.invalidate(statsNotifierProvider);
          await ref.read(statsNotifierProvider.future);
        },
        color: AppColors.cyan,
        backgroundColor: AppColors.surface,
        child: statsAsyncState.when(
          data: (statsData) => _buildStatsContent(statsData),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error, ref),
        ),
      ),
    );
  }

  /// Build the main stats content when data is loaded
  Widget _buildStatsContent(StatsData statsData) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section với key metrics
          _buildHeaderSection(statsData),
          const SizedBox(height: 24),

          // Wave chart section
          _buildChartSection(statsData),
          const SizedBox(height: 24),

          // AI insights section
          _buildInsightsSection(statsData),

          // Bottom spacing cho scroll
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải dữ liệu thống kê...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu thống kê',
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Retry loading data
              ref.invalidate(statsNotifierProvider);
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Build header section với key metrics
  Widget _buildHeaderSection(StatsData statsData) {
    final periodName = statsData.period == StatsPeriod.week ? 'tuần' : 'tháng';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan $periodName này',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Key metrics row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Trung bình/ngày',
                value:
                    '${(statsData.averageIntake / 1000).toStringAsFixed(1)}L',
                subtitle: '${statsData.totalLogs} lần ghi nhận',
                icon: Icons.water_drop,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Đạt mục tiêu',
                value: '${(statsData.goalCompletionRate * 100).round()}%',
                subtitle: '${statsData.streakDays} ngày streak',
                icon: Icons.emoji_events,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build metric card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headingLarge.copyWith(
              color: color,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build chart section
  Widget _buildChartSection(StatsData statsData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Biểu đồ sóng hydration',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            // Legend
            Row(
              children: [
                _buildLegendItem('Thực tế', AppColors.cyan),
                const SizedBox(width: 12),
                _buildLegendItem('Mục tiêu', AppColors.textSecondary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Wave chart
        WaveChart(data: statsData.chartData, period: statsData.period),
      ],
    );
  }

  /// Build legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Build insights section
  Widget _buildInsightsSection(StatsData statsData) {
    return InsightsCards(statsData: statsData);
  }
}
