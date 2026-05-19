import 'package:flutter_test/flutter_test.dart';

import 'package:aquatrack_app/features/stats/providers/stats_provider.dart';

void main() {
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

      final completedDays = chartData
          .where((point) => point.value >= point.goal)
          .length;
      final completionRate = completedDays / chartData.length;

      expect(completionRate, closeTo(0.67, 0.01)); // 2/3 ≈ 0.67
    });
  });
}
