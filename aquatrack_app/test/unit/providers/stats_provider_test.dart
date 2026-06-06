import 'package:flutter_test/flutter_test.dart';

import 'package:aquatrack_app/core/repositories/stats_repository.dart';
import 'package:aquatrack_app/features/stats/providers/stats_provider.dart';

GoalProgressResponse _goals({
  required int goalMl,
  required List<int> dailyEffective,
}) {
  final start = DateTime(2026, 6, 1);
  final daily = <DailyGoalData>[];
  for (var i = 0; i < dailyEffective.length; i++) {
    final ml = dailyEffective[i];
    daily.add(DailyGoalData(
      date: start.add(Duration(days: i)),
      totalEffectiveMl: ml,
      dailyGoalMl: goalMl,
      progressPercentage: goalMl > 0 ? ml / goalMl * 100 : 0,
      goalAchieved: ml >= goalMl,
      logCount: ml > 0 ? 1 : 0,
    ));
  }
  final achieved = daily.where((d) => d.goalAchieved).length;
  return GoalProgressResponse(
    period: '${dailyEffective.length} days',
    goalInfo: GoalInfo(
      dailyGoalMl: goalMl,
      totalDaysAnalyzed: daily.length,
      daysAchieved: achieved,
      achievementRatePercentage:
          daily.isEmpty ? 0 : achieved / daily.length * 100,
    ),
    averages: const {'average_daily_intake_ml': 0},
    dailyData: daily,
  );
}

LiquidTypesResponse _liquids(Map<String, int> volumeByType) {
  final total = volumeByType.values.fold<int>(0, (s, v) => s + v);
  final breakdown = volumeByType.entries
      .map((e) => LiquidTypeBreakdown(
            liquidType: e.key,
            totalVolumeMl: e.value,
            totalEffectiveMl: e.value,
            logCount: 1,
            volumePercentage: total > 0 ? e.value / total * 100 : 0,
            effectivePercentage: total > 0 ? e.value / total * 100 : 0,
            frequencyPercentage: 0,
          ))
      .toList();
  return LiquidTypesResponse(
    period: '7 days',
    totals: {'total_volume_ml': total},
    breakdown: breakdown,
  );
}

void main() {
  group('buildStatsData (real-source mapper)', () {
    test('maps per-day goal progress into chart points with real goal', () {
      final data = buildStatsData(
        goals: _goals(goalMl: 2500, dailyEffective: [2600, 1000, 2500]),
        liquids: _liquids({'water': 700, 'tea': 300}),
        insights: const [],
        currentStreak: 4,
        period: StatsPeriod.week,
      );

      // One chart point per day, value = effective ml, goal = real daily goal
      expect(data.chartData.length, 3);
      expect(data.chartData.first.value, 2600);
      expect(data.chartData.every((p) => p.goal == 2500), isTrue);
      expect(data.dailyGoalMl, 2500);
      expect(data.streakDays, 4);
    });

    test('completion rate comes from achievement rate, not a constant', () {
      // 2 of 3 days hit the 2500 goal -> ~66.7%
      final data = buildStatsData(
        goals: _goals(goalMl: 2500, dailyEffective: [2600, 1000, 2500]),
        liquids: _liquids({'water': 100}),
        insights: const [],
        currentStreak: 0,
        period: StatsPeriod.week,
      );
      expect(data.goalCompletionRate, closeTo(2 / 3, 0.01));
    });

    test('top liquid type is the real highest-volume drink', () {
      final data = buildStatsData(
        goals: _goals(goalMl: 2000, dailyEffective: [2000]),
        liquids: _liquids({'water': 400, 'coffee': 900, 'tea': 200}),
        insights: const [],
        currentStreak: 1,
        period: StatsPeriod.week,
      );
      expect(data.liquidBreakdown.length, 3);
      expect(data.topLiquidType, 'coffee');
    });

    test('carries backend insights through unchanged', () {
      const insight = InsightItem(
        type: 'warning',
        title: 'Cần uống nhiều nước hơn',
        message: 'Trung bình thấp hơn khuyến nghị.',
        priority: 'high',
      );
      final data = buildStatsData(
        goals: _goals(goalMl: 2000, dailyEffective: [1000]),
        liquids: _liquids({'water': 100}),
        insights: const [insight],
        currentStreak: 0,
        period: StatsPeriod.week,
      );
      expect(data.insights.length, 1);
      expect(data.insights.first.title, 'Cần uống nhiều nước hơn');
    });
  });

  group('StatsProvider Tests', () {
    test('StatsPeriod enum has correct values', () {
      expect(StatsPeriod.week, isNotNull);
      expect(StatsPeriod.month, isNotNull);
    });

    test('ChartDataPoint has required properties', () {
      final dataPoint = ChartDataPoint(
        date: DateTime.now(),
        value: 100.0,
        goal: 2000.0,
      );

      expect(dataPoint.date, isA<DateTime>());
      expect(dataPoint.value, 100.0);
      expect(dataPoint.goal, 2000.0);
    });

    test('StatsData model has all required fields', () {
      final statsData = StatsData(
        chartData: const [],
        averageIntake: 1500.0,
        goalCompletionRate: 0.75,
        totalLogs: 10,
        streakDays: 5,
        topLiquidType: 'water',
        period: StatsPeriod.week,
      );

      expect(statsData.averageIntake, 1500.0);
      expect(statsData.goalCompletionRate, 0.75);
      expect(statsData.totalLogs, 10);
      expect(statsData.streakDays, 5);
      expect(statsData.topLiquidType, 'water');
      expect(statsData.period, StatsPeriod.week);
    });

    test('Goal completion rate calculation logic', () {
      // Test data with 2 out of 3 goals met
      final chartData = [
        ChartDataPoint(
          date: DateTime.now(),
          value: 2500,
          goal: 2000,
        ), // Goal met
        ChartDataPoint(
          date: DateTime.now(),
          value: 1800,
          goal: 2000,
        ), // Goal not met
        ChartDataPoint(
          date: DateTime.now(),
          value: 2200,
          goal: 2000,
        ), // Goal met
      ];

      final completedDays =
          chartData.where((point) => point.value >= point.goal).length;
      final completionRate = completedDays / chartData.length;

      expect(completionRate, closeTo(0.67, 0.01)); // 2/3 ≈ 0.67
    });
  });
}
