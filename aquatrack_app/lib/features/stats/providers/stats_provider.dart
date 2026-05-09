import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/repositories/stats_repository.dart';
import '../../../shared/models/intake_log.dart';
import '../../../shared/storage/hive_storage_service.dart';

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
  late final StatsRepository _statsRepository;

  @override
  Future<StatsData> build() async {
    // Initialize repository via dependency injection
    _statsRepository = ref.read(statsRepositoryProvider);
    return _loadStatsDataFromApi(_currentPeriod);
  }

  /// Change stats period (week/month)
  Future<void> setPeriod(StatsPeriod period) async {
    // Prevent race conditions by checking if period actually changed
    if (_currentPeriod == period) return;

    _currentPeriod = period;
    state = const AsyncValue.loading();

    try {
      final newData = await _loadStatsDataFromApi(period);
      // Only update state if period hasn't changed during the request
      if (_currentPeriod == period) {
        state = AsyncValue.data(newData);
      }
    } catch (error, stackTrace) {
      // Only update state if period hasn't changed during the request
      if (_currentPeriod == period) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Load stats data from API instead of local storage
  Future<StatsData> _loadStatsDataFromApi(StatsPeriod period) async {
    try {
      // Get days count based on period
      final days = period == StatsPeriod.week ? 7 : 30;

      // Fetch data from API in parallel for better performance
      final results = await Future.wait([
        _statsRepository.getDailyTrends(days: days),
        _statsRepository.getDashboardStats(),
        _statsRepository.getLiquidTypesBreakdown(days: days),
        _statsRepository.getGoalProgress(days: days),
      ]);

      final trendsResponse =
          results[0] as StatsApiResponse<DailyTrendsResponse>;
      final dashboardResponse =
          results[1] as StatsApiResponse<DashboardStatsResponse>;
      final liquidResponse =
          results[2] as StatsApiResponse<LiquidTypesResponse>;
      final goalResponse = results[3] as StatsApiResponse<GoalProgressResponse>;

      // Check for any API errors
      if (!trendsResponse.isSuccess) {
        throw Exception(trendsResponse.error ?? 'Failed to load trends data');
      }
      if (!dashboardResponse.isSuccess) {
        throw Exception(
          dashboardResponse.error ?? 'Failed to load dashboard data',
        );
      }
      if (!liquidResponse.isSuccess) {
        throw Exception(liquidResponse.error ?? 'Failed to load liquid data');
      }
      if (!goalResponse.isSuccess) {
        throw Exception(goalResponse.error ?? 'Failed to load goal data');
      }

      // Convert API responses to local StatsData format
      return _convertApiDataToStatsData(
        trendsResponse.data!,
        dashboardResponse.data!,
        liquidResponse.data!,
        goalResponse.data!,
        period,
      );
    } catch (e) {
      debugPrint('❌ Failed to load stats from API: $e');

      // Only fallback to local storage for genuine connectivity issues
      // Other API errors (auth, validation, etc.) should be exposed to user
      final isConnectivityError = e.toString().contains('SocketException') ||
          e.toString().contains('HttpException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('No route to host');

      if (isConnectivityError) {
        debugPrint(
          '🌐 Network connectivity issue detected, falling back to local storage',
        );
        return _loadStatsDataFromLocal(period);
      } else {
        // Re-throw API errors for proper error handling in UI
        debugPrint('🚨 API error (not connectivity), exposing to UI: $e');
        rethrow;
      }
    }
  }

  /// Convert API response data to local StatsData format
  StatsData _convertApiDataToStatsData(
    DailyTrendsResponse trendsData,
    DashboardStatsResponse dashboardData,
    LiquidTypesResponse liquidData,
    GoalProgressResponse goalData,
    StatsPeriod period,
  ) {
    // Convert daily trends to chart data points
    final chartData = trendsData.data.map((day) {
      return ChartDataPoint(
        date: day.date,
        value: day.totalEffectiveMl.toDouble(),
        goal: 2500.0, // Default goal, should come from user settings
      );
    }).toList();

    // Get period stats from dashboard
    final periodStats =
        period == StatsPeriod.week ? dashboardData.week : dashboardData.month;

    // Get top liquid type from breakdown
    String topLiquidType = 'Nước';
    if (liquidData.breakdown.isNotEmpty) {
      final topLiquid = liquidData.breakdown.reduce(
        (a, b) => a.logCount > b.logCount ? a : b,
      );
      topLiquidType = _getDisplayName(topLiquid.liquidType);
    }

    return StatsData(
      chartData: chartData,
      averageIntake: periodStats.averageDailyMl,
      goalCompletionRate: goalData.goalInfo.achievementRatePercentage / 100.0,
      totalLogs: periodStats.logCount,
      streakDays: dashboardData.streaks.currentStreak,
      topLiquidType: topLiquidType,
      period: period,
    );
  }

  /// Convert liquid type to Vietnamese display name
  String _getDisplayName(String liquidType) {
    const nameMap = {
      'water': 'Nước lọc',
      'tea': 'Trà',
      'coffee': 'Cà phê',
      'juice': 'Nước trái cây',
      'smoothie': 'Sinh tố',
    };
    return nameMap[liquidType] ?? liquidType;
  }

  /// Fallback to local storage if API fails
  StatsData _loadStatsDataFromLocal(StatsPeriod period) {
    return _loadStatsData(period);
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
        '📊 StatsProvider: Loading data from local storage (backend integration pending)',
      );

      final allLogs = storage.loadAllIntakeLogs();
      periodLogs = allLogs
          .where(
            (log) =>
                log.loggedAt.isAfter(startDate) && log.loggedAt.isBefore(now),
          )
          .toList();
    } catch (e) {
      debugPrint('📊 StatsProvider: Error loading data: $e');
      periodLogs = []; // Return empty data on error
    }

    // Generate chart data points
    final chartData = _generateChartData(periodLogs, startDate, now, period);

    // Calculate analytics
    final totalEffectiveVolume = periodLogs.fold<int>(
      0,
      (sum, log) => sum + log.effectiveVolumeMl,
    );
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
    List<IntakeLog> logs,
    DateTime start,
    DateTime end,
    StatsPeriod period,
  ) {
    final points = <ChartDataPoint>[];
    const dailyGoal = 2500.0; // Default daily goal, should come from settings

    final duration = end.difference(start).inDays;

    for (int i = 0; i <= duration; i++) {
      final date = start.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Get logs for this specific day
      final dayLogs = logs
          .where(
            (log) =>
                log.loggedAt.isAfter(dayStart) && log.loggedAt.isBefore(dayEnd),
          )
          .toList();

      // Calculate total effective volume for the day
      final totalVolume = dayLogs
          .fold<int>(0, (sum, log) => sum + log.effectiveVolumeMl)
          .toDouble();

      points.add(
        ChartDataPoint(date: dayStart, value: totalVolume, goal: dailyGoal),
      );
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
