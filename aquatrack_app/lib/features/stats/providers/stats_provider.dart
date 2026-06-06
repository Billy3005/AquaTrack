import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/repositories/stats_repository.dart';

part 'stats_provider.g.dart';

/// Provider for StatsRepository dependency injection
@riverpod
StatsRepository statsRepository(ref) {
  return StatsRepository();
}

/// Chart data point for wave visualization
class ChartDataPoint {
  final DateTime date;
  final double value;
  final double goal;

  const ChartDataPoint({
    required this.date,
    required this.value,
    required this.goal,
  });
}

/// Stats period enum (see CONTEXT.md "Stats Period")
enum StatsPeriod { week, month }

extension StatsPeriodX on StatsPeriod {
  int get days => this == StatsPeriod.week ? 7 : 30;
}

/// Currently selected [StatsPeriod]. The toggle writes here; [StatsNotifier]
/// watches it and refetches, so the header and chart stay in sync.
final statsPeriodProvider =
    StateProvider<StatsPeriod>((ref) => StatsPeriod.week);

/// Stats data model for display — sourced entirely from real backend data.
class StatsData {
  final List<ChartDataPoint> chartData;
  final double averageIntake;
  final double goalCompletionRate;
  final int totalLogs;
  final int streakDays;
  final String topLiquidType;
  final StatsPeriod period;

  /// Real per-period Daily Goal (ml) from the backend, never a hardcoded value.
  final int dailyGoalMl;

  /// Liquid Breakdown for the period (share per drink type).
  final List<LiquidTypeBreakdown> liquidBreakdown;

  /// Insights computed by the backend `/stats/insights` endpoint.
  final List<InsightItem> insights;

  const StatsData({
    required this.chartData,
    required this.averageIntake,
    required this.goalCompletionRate,
    required this.totalLogs,
    required this.streakDays,
    required this.topLiquidType,
    required this.period,
    this.dailyGoalMl = 0,
    this.liquidBreakdown = const [],
    this.insights = const [],
  });

  /// Total effective volume across the period (ml).
  double get totalVolumeMl =>
      chartData.fold(0.0, (sum, point) => sum + point.value);
}

/// Pure mapper: turn real backend responses into the UI [StatsData].
///
/// Kept free of Riverpod/IO so it is unit-testable in isolation. The chart is
/// built from `/stats/goals/progress` (carries the real per-day Daily Goal),
/// the breakdown from `/stats/liquid-types`, and insights from
/// `/stats/insights`. Streak comes from the dashboard.
StatsData buildStatsData({
  required GoalProgressResponse goals,
  LiquidTypesResponse? liquids,
  List<InsightItem> insights = const [],
  required int currentStreak,
  required StatsPeriod period,
}) {
  final chartData = goals.dailyData
      .map((d) => ChartDataPoint(
            date: d.date,
            value: d.totalEffectiveMl.toDouble(),
            goal: d.dailyGoalMl.toDouble(),
          ))
      .toList();

  final totalLogs = goals.dailyData.fold<int>(0, (sum, d) => sum + d.logCount);
  final completion = goals.goalInfo.achievementRatePercentage / 100.0;

  final avg = goals.averages['average_daily_intake_ml'] ??
      (chartData.isEmpty
          ? 0.0
          : chartData.fold(0.0, (s, p) => s + p.value) / chartData.length);

  final breakdown = liquids?.breakdown ?? const <LiquidTypeBreakdown>[];
  String topType = 'water';
  if (breakdown.isNotEmpty) {
    topType = breakdown
        .reduce((a, b) => a.totalVolumeMl >= b.totalVolumeMl ? a : b)
        .liquidType;
  }

  return StatsData(
    chartData: chartData,
    averageIntake: avg,
    goalCompletionRate: completion,
    totalLogs: totalLogs,
    streakDays: currentStreak,
    topLiquidType: topType,
    period: period,
    dailyGoalMl: goals.goalInfo.dailyGoalMl,
    liquidBreakdown: breakdown,
    insights: insights,
  );
}

/// Stats provider — refetches whenever [statsPeriodProvider] changes.
@riverpod
class StatsNotifier extends _$StatsNotifier {
  @override
  Future<StatsData> build() async {
    final period = ref.watch(statsPeriodProvider);
    return _fetch(period);
  }

  Future<StatsData> _fetch(StatsPeriod period) async {
    final repo = ref.read(statsRepositoryProvider);
    final days = period.days;

    // Fire all requests concurrently, then await.
    final goalsF = repo.getGoalProgress(days: days);
    final liquidsF = repo.getLiquidTypesBreakdown(days: days);
    final insightsF = repo.getInsights(days: days);
    final dashF = repo.getDashboardStats();

    final goalsRes = await goalsF;
    final liquidsRes = await liquidsF;
    final insightsRes = await insightsF;
    final dashRes = await dashF;

    // Goal progress is the canonical chart source — fail loudly if it's missing.
    if (!goalsRes.isSuccess || goalsRes.data == null) {
      throw Exception(goalsRes.error ?? 'Không tải được dữ liệu thống kê');
    }

    // The rest are supplementary; degrade gracefully if they fail.
    final liquids = liquidsRes.isSuccess ? liquidsRes.data : null;
    final insights = insightsRes.isSuccess && insightsRes.data != null
        ? insightsRes.data!.insights
        : const <InsightItem>[];
    final streak = dashRes.isSuccess && dashRes.data != null
        ? dashRes.data!.streaks.currentStreak
        : 0;

    if (!liquidsRes.isSuccess) {
      debugPrint('📊 Stats: liquid-types failed: ${liquidsRes.error}');
    }
    if (!insightsRes.isSuccess) {
      debugPrint('📊 Stats: insights failed: ${insightsRes.error}');
    }

    return buildStatsData(
      goals: goalsRes.data!,
      liquids: liquids,
      insights: insights,
      currentStreak: streak,
      period: period,
    );
  }
}
