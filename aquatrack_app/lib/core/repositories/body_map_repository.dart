import '../network/api_client.dart';
import '../network/default_api_client.dart';
import '../utils/logger.dart';

/// Repository for body map and hydration API calls
class BodyMapRepository {
  static const String _tag = 'BodyMapRepository';

  final ApiClient _apiService;

  BodyMapRepository({ApiClient? apiClient})
      : _apiService = apiClient ?? defaultApiClient;

  /// Get current hydration status for body map
  Future<BodyMapApiResponse<HydrationStatus>> getHydrationStatus() async {
    AppLogger.info(_tag, 'Getting current hydration status');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final hydrationStatus = HydrationStatus.fromDashboard(response.data!);
      return BodyMapApiResponse.success(hydrationStatus);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get hydration status', e);
      return BodyMapApiResponse.error('Failed to load hydration status: $e');
    }
  }

  /// Get detailed hydration trends for organ calculations
  Future<BodyMapApiResponse<List<DailyHydrationData>>> getHydrationTrends({
    int days = 7,
  }) async {
    AppLogger.info(_tag, 'Getting hydration trends for $days days');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/trends/daily',
        queryParams: {'days': days},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final trendsData = response.data!['data'] as List<dynamic>;
      final hydrationTrends =
          trendsData.map((item) => DailyHydrationData.fromJson(item)).toList();

      return BodyMapApiResponse.success(hydrationTrends);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get hydration trends', e);
      return BodyMapApiResponse.error('Failed to load hydration trends: $e');
    }
  }

  /// Get goal progress data for hydration calculation
  Future<BodyMapApiResponse<GoalProgressData>> getGoalProgress({
    int days = 7,
  }) async {
    AppLogger.info(_tag, 'Getting goal progress for $days days');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/goals/progress',
        queryParams: {'days': days},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final goalProgress = GoalProgressData.fromJson(response.data!);
      return BodyMapApiResponse.success(goalProgress);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get goal progress', e);
      return BodyMapApiResponse.error('Failed to load goal progress: $e');
    }
  }

  /// Get liquid types breakdown for organ-specific effects
  Future<BodyMapApiResponse<LiquidTypesData>> getLiquidTypesBreakdown({
    int days = 7,
  }) async {
    AppLogger.info(_tag, 'Getting liquid types breakdown for $days days');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/liquid-types',
        queryParams: {'days': days},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final liquidTypes = LiquidTypesData.fromJson(response.data!);
      return BodyMapApiResponse.success(liquidTypes);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get liquid types breakdown', e);
      return BodyMapApiResponse.error('Failed to load liquid types: $e');
    }
  }
}

/// Generic API response wrapper for body map data
class BodyMapApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  const BodyMapApiResponse._({required this.isSuccess, this.data, this.error});

  factory BodyMapApiResponse.success(T data) =>
      BodyMapApiResponse._(isSuccess: true, data: data);

  factory BodyMapApiResponse.error(String error) =>
      BodyMapApiResponse._(isSuccess: false, error: error);
}

/// Hydration status model from dashboard stats
class HydrationStatus {
  final double todayProgressPercentage;
  final double weeklyAverageML;
  final double monthlyAverageML;
  final int currentStreak;
  final int todayLogCount;
  final int todayEffectiveML;

  const HydrationStatus({
    required this.todayProgressPercentage,
    required this.weeklyAverageML,
    required this.monthlyAverageML,
    required this.currentStreak,
    required this.todayLogCount,
    required this.todayEffectiveML,
  });

  factory HydrationStatus.fromDashboard(Map<String, dynamic> json) {
    final today = json['today'] ?? {};
    final week = json['week'] ?? {};
    final month = json['month'] ?? {};
    final streaks = json['streaks'] ?? {};

    return HydrationStatus(
      todayProgressPercentage: (today['progress_percentage'] ?? 0).toDouble(),
      weeklyAverageML: (week['average_daily_ml'] ?? 0).toDouble(),
      monthlyAverageML: (month['average_daily_ml'] ?? 0).toDouble(),
      currentStreak: streaks['current_streak'] ?? 0,
      todayLogCount: today['log_count'] ?? 0,
      todayEffectiveML: today['total_effective_ml'] ?? 0,
    );
  }

  /// Calculate overall hydration level (0.0-1.0) for organ calculations
  double get overallHydrationLevel {
    // Use today's progress as primary indicator
    double todayWeight = 0.6;
    double weekWeight = 0.3;
    double streakWeight = 0.1;

    double todayScore = (todayProgressPercentage / 100.0).clamp(0.0, 1.0);
    double weekScore = (weeklyAverageML / 2500.0).clamp(
      0.0,
      1.0,
    ); // Target 2.5L daily
    double streakScore = (currentStreak / 7.0).clamp(
      0.0,
      1.0,
    ); // Max bonus at 7 days

    return (todayScore * todayWeight) +
        (weekScore * weekWeight) +
        (streakScore * streakWeight);
  }
}

/// Daily hydration data for trend analysis
class DailyHydrationData {
  final DateTime date;
  final int totalEffectiveML;
  final int logCount;
  final int totalXPEarned;
  final double averageVolumeML;

  const DailyHydrationData({
    required this.date,
    required this.totalEffectiveML,
    required this.logCount,
    required this.totalXPEarned,
    required this.averageVolumeML,
  });

  factory DailyHydrationData.fromJson(Map<String, dynamic> json) {
    return DailyHydrationData(
      date: DateTime.parse(json['date']),
      totalEffectiveML: json['total_effective_ml'] ?? 0,
      logCount: json['log_count'] ?? 0,
      totalXPEarned: json['total_xp_earned'] ?? 0,
      averageVolumeML: (json['average_volume_ml'] ?? 0).toDouble(),
    );
  }
}

/// Goal progress data for hydration assessment
class GoalProgressData {
  final int dailyGoalML;
  final int daysAchieved;
  final int totalDaysAnalyzed;
  final double achievementRatePercentage;
  final double averageProgressPercentage;
  final double averageDailyIntakeML;
  final List<DailyGoalProgress> dailyData;

  const GoalProgressData({
    required this.dailyGoalML,
    required this.daysAchieved,
    required this.totalDaysAnalyzed,
    required this.achievementRatePercentage,
    required this.averageProgressPercentage,
    required this.averageDailyIntakeML,
    required this.dailyData,
  });

  factory GoalProgressData.fromJson(Map<String, dynamic> json) {
    final goalInfo = json['goal_info'] ?? {};
    final averages = json['averages'] ?? {};
    final dailyDataList = json['daily_data'] as List<dynamic>? ?? [];

    return GoalProgressData(
      dailyGoalML: goalInfo['daily_goal_ml'] ?? 2000,
      daysAchieved: goalInfo['days_achieved'] ?? 0,
      totalDaysAnalyzed: goalInfo['total_days_analyzed'] ?? 0,
      achievementRatePercentage:
          (goalInfo['achievement_rate_percentage'] ?? 0).toDouble(),
      averageProgressPercentage:
          (averages['average_progress_percentage'] ?? 0).toDouble(),
      averageDailyIntakeML:
          (averages['average_daily_intake_ml'] ?? 0).toDouble(),
      dailyData: dailyDataList
          .map((item) => DailyGoalProgress.fromJson(item))
          .toList(),
    );
  }
}

/// Daily goal progress item
class DailyGoalProgress {
  final DateTime date;
  final int totalEffectiveML;
  final int dailyGoalML;
  final double progressPercentage;
  final bool goalAchieved;
  final int logCount;

  const DailyGoalProgress({
    required this.date,
    required this.totalEffectiveML,
    required this.dailyGoalML,
    required this.progressPercentage,
    required this.goalAchieved,
    required this.logCount,
  });

  factory DailyGoalProgress.fromJson(Map<String, dynamic> json) {
    return DailyGoalProgress(
      date: DateTime.parse(json['date']),
      totalEffectiveML: json['total_effective_ml'] ?? 0,
      dailyGoalML: json['daily_goal_ml'] ?? 2000,
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
      goalAchieved: json['goal_achieved'] ?? false,
      logCount: json['log_count'] ?? 0,
    );
  }
}

/// Liquid types breakdown for organ-specific calculations
class LiquidTypesData {
  final int totalVolumeML;
  final int totalEffectiveML;
  final int totalLogs;
  final List<LiquidTypeBreakdown> breakdown;

  const LiquidTypesData({
    required this.totalVolumeML,
    required this.totalEffectiveML,
    required this.totalLogs,
    required this.breakdown,
  });

  factory LiquidTypesData.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] ?? {};
    final breakdownList = json['breakdown'] as List<dynamic>? ?? [];

    return LiquidTypesData(
      totalVolumeML: totals['total_volume_ml'] ?? 0,
      totalEffectiveML: totals['total_effective_ml'] ?? 0,
      totalLogs: totals['total_logs'] ?? 0,
      breakdown: breakdownList
          .map((item) => LiquidTypeBreakdown.fromJson(item))
          .toList(),
    );
  }

  /// Get liquid effectiveness ratio (beneficial liquids vs total)
  double get liquidEffectivenessRatio {
    if (totalLogs == 0) return 1.0;

    // Water, tea and juice are beneficial for hydration
    final beneficialLogs = breakdown
        .where((item) => ['water', 'tea', 'juice'].contains(item.liquidType))
        .fold(0, (sum, item) => sum + item.logCount);

    return (beneficialLogs / totalLogs).clamp(0.0, 1.0);
  }
}

/// Individual liquid type breakdown
class LiquidTypeBreakdown {
  final String liquidType;
  final int totalVolumeML;
  final int totalEffectiveML;
  final int logCount;
  final double volumePercentage;
  final double effectivePercentage;
  final double frequencyPercentage;
  final double averageVolumeML;

  const LiquidTypeBreakdown({
    required this.liquidType,
    required this.totalVolumeML,
    required this.totalEffectiveML,
    required this.logCount,
    required this.volumePercentage,
    required this.effectivePercentage,
    required this.frequencyPercentage,
    required this.averageVolumeML,
  });

  factory LiquidTypeBreakdown.fromJson(Map<String, dynamic> json) {
    return LiquidTypeBreakdown(
      liquidType: json['liquid_type'] ?? '',
      totalVolumeML: json['total_volume_ml'] ?? 0,
      totalEffectiveML: json['total_effective_ml'] ?? 0,
      logCount: json['log_count'] ?? 0,
      volumePercentage: (json['volume_percentage'] ?? 0).toDouble(),
      effectivePercentage: (json['effective_percentage'] ?? 0).toDouble(),
      frequencyPercentage: (json['frequency_percentage'] ?? 0).toDouble(),
      averageVolumeML: (json['average_volume_ml'] ?? 0).toDouble(),
    );
  }
}
