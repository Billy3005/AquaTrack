import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/stats_provider.dart';

/// Wave chart component cho hydration visualization
class WaveChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final StatsPeriod period;

  const WaveChart({
    super.key,
    required this.data,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan.withValues(alpha: 0.1),
            AppColors.xpPurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: LineChart(
        _buildLineChartData(),
      ),
    );
  }

  /// Build empty state when no data
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 4),
            Text(
              'Bắt đầu ghi nhận để xem biểu đồ',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  /// Build line chart data configuration
  LineChartData _buildLineChartData() {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final goalSpots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.goal);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 500,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: 500,
            getTitlesWidget: _buildLeftTitle,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: _buildBottomTitle,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // Actual intake line (wave-like curve)
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.cyan,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cyan.withValues(alpha: 0.3),
                AppColors.cyan.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Goal line (dashed)
        LineChartBarData(
          spots: goalSpots,
          isCurved: false,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          barWidth: 2,
          dashArray: [8, 4],
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surface.withValues(alpha: 0.95),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: _buildTooltipItems,
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          // Add haptic feedback on touch
          if (event is FlTapUpEvent && touchResponse != null) {
            // HapticFeedback.lightImpact();
          }
        },
      ),
    );
  }

  /// Build left axis title (volume labels)
  Widget _buildLeftTitle(double value, TitleMeta meta) {
    if (value == meta.max || value == meta.min) {
      return const SizedBox.shrink();
    }

    String text;
    if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(1)}L';
    } else {
      text = '${value.toInt()}ml';
    }

    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
        fontSize: 10,
      ),
    );
  }

  /// Build bottom axis title (dates)
  Widget _buildBottomTitle(double value, TitleMeta meta) {
    if (value.toInt() >= data.length) {
      return const SizedBox.shrink();
    }

    final date = data[value.toInt()].date;
    String text;

    if (period == StatsPeriod.week) {
      // Show day of week for weekly view
      const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      text = days[date.weekday % 7];
    } else {
      // Show day of month for monthly view
      text = date.day.toString();
    }

    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
        fontSize: 10,
      ),
    );
  }

  /// Build tooltip items for touch interactions
  List<LineTooltipItem> _buildTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((spot) {
      final date = data[spot.x.toInt()].date;
      final value = spot.y;

      String dateStr;
      if (period == StatsPeriod.week) {
        const days = [
          'Chủ Nhật',
          'Thứ 2',
          'Thứ 3',
          'Thứ 4',
          'Thứ 5',
          'Thứ 6',
          'Thứ 7'
        ];
        dateStr = days[date.weekday % 7];
      } else {
        dateStr = '${date.day}/${date.month}';
      }

      String valueStr;
      if (value >= 1000) {
        valueStr = '${(value / 1000).toStringAsFixed(1)}L';
      } else {
        valueStr = '${value.toInt()}ml';
      }

      return LineTooltipItem(
        '$dateStr\n$valueStr',
        AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();
  }
}
