import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/intake_log.dart';
import '../../../shared/storage/hive_storage_service.dart';

part 'stats_provider.g.dart';

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

/// Stats period enum
enum StatsPeriod { week, month }

/// Stats data model for display
class StatsData {
  final List<ChartDataPoint> chartData;
  final double averageIntake;
  final double goalCompletionRate;
  final int totalLogs;
  final int streakDays;
  final String topLiquidType;
  final StatsPeriod period;

  const StatsData({
    required this.chartData,
    required this.averageIntake,
    required this.goalCompletionRate,
    required this.totalLogs,
    required this.streakDays,
    required this.topLiquidType,
    required this.period,
  });
}

/// Stats provider with period selection
@riverpod
class StatsNotifier extends _$StatsNotifier {
  StatsPeriod _currentPeriod = StatsPeriod.week;

  @override
  StatsData build() {
    return _loadStatsData(_currentPeriod);
  }

  /// Change stats period (week/month)
  void setPeriod(StatsPeriod period) {
    _currentPeriod = period;
    state = _loadStatsData(period);
  }

  /// Load and aggregate stats data based on period (with backend fallback)
  StatsData _loadStatsData(StatsPeriod period) {
    final now = DateTime.now();
    final startDate = period == StatsPeriod.week
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    List<IntakeLog> periodLogs = [];
    final storage = HiveStorageService.instance;

    try {
      // For now, use local storage since we need synchronous operation
      // TODO: Implement proper async data loading in future iteration
      debugPrint(
          '📊 StatsProvider: Loading data from local storage (backend integration pending)');

      final allLogs = storage.loadAllIntakeLogs();
      periodLogs = allLogs
          .where((log) =>
              log.loggedAt.isAfter(startDate) && log.loggedAt.isBefore(now))
          .toList();
    } catch (e) {
      debugPrint('📊 StatsProvider: Error loading data: $e');
      periodLogs = []; // Return empty data on error
    }

    // Generate chart data points
    final chartData = _generateChartData(periodLogs, startDate, now, period);

    // Calculate analytics
    final totalEffectiveVolume =
        periodLogs.fold<int>(0, (sum, log) => sum + log.effectiveVolumeMl);
    final averageIntake = periodLogs.isEmpty
        ? 0.0
        : totalEffectiveVolume / _getDaysInPeriod(period);

    final goalCompletionRate = _calculateGoalCompletionRate(chartData);
    final topLiquidType = _getTopLiquidType(periodLogs);
    final streakDays = _calculateStreakDays(storage);

    return StatsData(
      chartData: chartData,
      averageIntake: averageIntake,
      goalCompletionRate: goalCompletionRate,
      totalLogs: periodLogs.length,
      streakDays: streakDays,
      topLiquidType: topLiquidType,
      period: period,
    );
  }

  /// Generate chart data points for wave visualization
  List<ChartDataPoint> _generateChartData(
      List<IntakeLog> logs, DateTime start, DateTime end, StatsPeriod period) {
    final points = <ChartDataPoint>[];
    const dailyGoal = 2500.0; // Default daily goal, should come from settings

    final duration = end.difference(start).inDays;

    for (int i = 0; i <= duration; i++) {
      final date = start.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Get logs for this specific day
      final dayLogs = logs
          .where((log) =>
              log.loggedAt.isAfter(dayStart) && log.loggedAt.isBefore(dayEnd))
          .toList();

      // Calculate total effective volume for the day
      final totalVolume = dayLogs
          .fold<int>(0, (sum, log) => sum + log.effectiveVolumeMl)
          .toDouble();

      points.add(ChartDataPoint(
        date: dayStart,
        value: totalVolume,
        goal: dailyGoal,
      ));
    }

    return points;
  }

  /// Calculate goal completion rate from chart data
  double _calculateGoalCompletionRate(List<ChartDataPoint> data) {
    if (data.isEmpty) return 0.0;

    final completedDays =
        data.where((point) => point.value >= point.goal).length;
    return completedDays / data.length;
  }

  /// Get most frequent liquid type
  String _getTopLiquidType(List<IntakeLog> logs) {
    if (logs.isEmpty) return 'Nước';

    final typeCount = <String, int>{};
    for (final log in logs) {
      typeCount[log.liquidType] = (typeCount[log.liquidType] ?? 0) + 1;
    }

    return typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Calculate current streak days
  int _calculateStreakDays(HiveStorageService storage) {
    // For now, return a placeholder
    // This should integrate with the existing streak calculation logic
    // In production, this would calculate actual streak from daily summaries
    return storage.loadSetting<int>('current_streak') ?? 0;
  }

  /// Get number of days in period
  int _getDaysInPeriod(StatsPeriod period) {
    return period == StatsPeriod.week ? 7 : 30;
  }
}
