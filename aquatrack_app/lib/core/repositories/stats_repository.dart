import '../services/api_service.dart';
import '../utils/logger.dart';

/// Repository for stats API calls
class StatsRepository {
  static const String _tag = 'StatsRepository';

  final ApiService _apiService;

  StatsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Get daily trends data for charts
  Future<StatsApiResponse<DailyTrendsResponse>> getDailyTrends({
    int days = 7,
  }) async {
    AppLogger.info(_tag, 'Getting daily trends for $days days');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/trends/daily',
        queryParams: {'days': days},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final trendsData = DailyTrendsResponse.fromJson(response.data!);
      return StatsApiResponse.success(trendsData);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get daily trends', e);
      return StatsApiResponse.error('Failed to load daily trends: $e');
    }
  }

  /// Get dashboard stats (today, week, month, streaks)
  Future<StatsApiResponse<DashboardStatsResponse>> getDashboardStats() async {
    AppLogger.info(_tag, 'Getting dashboard stats');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final dashboardData = DashboardStatsResponse.fromJson(response.data!);
      return StatsApiResponse.success(dashboardData);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get dashboard stats', e);
      return StatsApiResponse.error('Failed to load dashboard stats: $e');
    }
  }

  /// Get liquid types breakdown
  Future<StatsApiResponse<LiquidTypesResponse>> getLiquidTypesBreakdown({
    int days = 30,
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

      final liquidData = LiquidTypesResponse.fromJson(response.data!);
      return StatsApiResponse.success(liquidData);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get liquid types breakdown', e);
      return StatsApiResponse.error('Failed to load liquid types: $e');
    }
  }

  /// Get goal progress data
  Future<StatsApiResponse<GoalProgressResponse>> getGoalProgress({
    int days = 30,
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

      final goalData = GoalProgressResponse.fromJson(response.data!);
      return StatsApiResponse.success(goalData);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get goal progress', e);
      return StatsApiResponse.error('Failed to load goal progress: $e');
    }
  }

  /// Get streak analytics
  Future<StatsApiResponse<StreakAnalyticsResponse>> getStreakAnalytics() async {
    AppLogger.info(_tag, 'Getting streak analytics');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/streaks',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final streakData = StreakAnalyticsResponse.fromJson(response.data!);
      return StatsApiResponse.success(streakData);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get streak analytics', e);
      return StatsApiResponse.error('Failed to load streak analytics: $e');
    }
  }

  /// Get AI insights
  Future<StatsApiResponse<InsightsResponse>> getInsights({int days = 7}) async {
    AppLogger.info(_tag, 'Getting AI insights for $days days');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/stats/insights',
        queryParams: {'days': days},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final insightsData = InsightsResponse.fromJson(response.data!);
      return StatsApiResponse.success(insightsData);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get insights', e);
      return StatsApiResponse.error('Failed to load insights: $e');
    }
  }
}

/// Generic API response wrapper for stats data
class StatsApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  const StatsApiResponse._({required this.isSuccess, this.data, this.error});

  factory StatsApiResponse.success(T data) =>
      StatsApiResponse._(isSuccess: true, data: data);

  factory StatsApiResponse.error(String error) =>
      StatsApiResponse._(isSuccess: false, error: error);
}

/// Daily trends API response model
class DailyTrendsResponse {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyTrendData> data;

  const DailyTrendsResponse({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.data,
  });

  factory DailyTrendsResponse.fromJson(Map<String, dynamic> json) {
    return DailyTrendsResponse(
      period: json['period'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => DailyTrendData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class DailyTrendData {
  final DateTime date;
  final int logCount;
  final int totalVolumeMl;
  final int totalEffectiveMl;
  final int totalXpEarned;
  final double averageVolumeMl;

  const DailyTrendData({
    required this.date,
    required this.logCount,
    required this.totalVolumeMl,
    required this.totalEffectiveMl,
    required this.totalXpEarned,
    required this.averageVolumeMl,
  });

  factory DailyTrendData.fromJson(Map<String, dynamic> json) {
    return DailyTrendData(
      date: DateTime.parse(json['date']),
      logCount: json['log_count'] ?? 0,
      totalVolumeMl: json['total_volume_ml'] ?? 0,
      totalEffectiveMl: json['total_effective_ml'] ?? 0,
      totalXpEarned: json['total_xp_earned'] ?? 0,
      averageVolumeMl: (json['average_volume_ml'] ?? 0).toDouble(),
    );
  }
}

/// Dashboard stats API response model
class DashboardStatsResponse {
  final DayStats today;
  final PeriodStats week;
  final PeriodStats month;
  final StreakStats streaks;

  const DashboardStatsResponse({
    required this.today,
    required this.week,
    required this.month,
    required this.streaks,
  });

  factory DashboardStatsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardStatsResponse(
      today: DayStats.fromJson(json['today']),
      week: PeriodStats.fromJson(json['week']),
      month: PeriodStats.fromJson(json['month']),
      streaks: StreakStats.fromJson(json['streaks']),
    );
  }
}

class DayStats {
  final int totalEffectiveMl;
  final int logCount;
  final int totalXpEarned;
  final double progressPercentage;

  const DayStats({
    required this.totalEffectiveMl,
    required this.logCount,
    required this.totalXpEarned,
    required this.progressPercentage,
  });

  factory DayStats.fromJson(Map<String, dynamic> json) {
    return DayStats(
      totalEffectiveMl: json['total_effective_ml'] ?? 0,
      logCount: json['log_count'] ?? 0,
      totalXpEarned: json['total_xp_earned'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
    );
  }
}

class PeriodStats {
  final int totalEffectiveMl;
  final int logCount;
  final double averageDailyMl;
  final int daysWithIntake;

  const PeriodStats({
    required this.totalEffectiveMl,
    required this.logCount,
    required this.averageDailyMl,
    required this.daysWithIntake,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      totalEffectiveMl: json['total_effective_ml'] ?? 0,
      logCount: json['log_count'] ?? 0,
      averageDailyMl: (json['average_daily_ml'] ?? 0).toDouble(),
      daysWithIntake: json['days_with_intake'] ?? 0,
    );
  }
}

class StreakStats {
  final int currentStreak;
  final int longestStreak;

  const StreakStats({required this.currentStreak, required this.longestStreak});

  factory StreakStats.fromJson(Map<String, dynamic> json) {
    return StreakStats(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
    );
  }
}

/// Liquid types breakdown response
class LiquidTypesResponse {
  final String period;
  final Map<String, int> totals;
  final List<LiquidTypeBreakdown> breakdown;

  const LiquidTypesResponse({
    required this.period,
    required this.totals,
    required this.breakdown,
  });

  factory LiquidTypesResponse.fromJson(Map<String, dynamic> json) {
    return LiquidTypesResponse(
      period: json['period'] ?? '',
      totals: Map<String, int>.from(json['totals'] ?? {}),
      breakdown:
          (json['breakdown'] as List<dynamic>?)
              ?.map((item) => LiquidTypeBreakdown.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class LiquidTypeBreakdown {
  final String liquidType;
  final int totalVolumeMl;
  final int totalEffectiveMl;
  final int logCount;
  final double volumePercentage;
  final double effectivePercentage;
  final double frequencyPercentage;

  const LiquidTypeBreakdown({
    required this.liquidType,
    required this.totalVolumeMl,
    required this.totalEffectiveMl,
    required this.logCount,
    required this.volumePercentage,
    required this.effectivePercentage,
    required this.frequencyPercentage,
  });

  factory LiquidTypeBreakdown.fromJson(Map<String, dynamic> json) {
    return LiquidTypeBreakdown(
      liquidType: json['liquid_type'] ?? '',
      totalVolumeMl: json['total_volume_ml'] ?? 0,
      totalEffectiveMl: json['total_effective_ml'] ?? 0,
      logCount: json['log_count'] ?? 0,
      volumePercentage: (json['volume_percentage'] ?? 0).toDouble(),
      effectivePercentage: (json['effective_percentage'] ?? 0).toDouble(),
      frequencyPercentage: (json['frequency_percentage'] ?? 0).toDouble(),
    );
  }
}

/// Goal progress response
class GoalProgressResponse {
  final String period;
  final GoalInfo goalInfo;
  final Map<String, double> averages;
  final List<DailyGoalData> dailyData;

  const GoalProgressResponse({
    required this.period,
    required this.goalInfo,
    required this.averages,
    required this.dailyData,
  });

  factory GoalProgressResponse.fromJson(Map<String, dynamic> json) {
    return GoalProgressResponse(
      period: json['period'] ?? '',
      goalInfo: GoalInfo.fromJson(json['goal_info']),
      averages: Map<String, double>.from(
        json['averages']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {},
      ),
      dailyData:
          (json['daily_data'] as List<dynamic>?)
              ?.map((item) => DailyGoalData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class GoalInfo {
  final int dailyGoalMl;
  final int totalDaysAnalyzed;
  final int daysAchieved;
  final double achievementRatePercentage;

  const GoalInfo({
    required this.dailyGoalMl,
    required this.totalDaysAnalyzed,
    required this.daysAchieved,
    required this.achievementRatePercentage,
  });

  factory GoalInfo.fromJson(Map<String, dynamic> json) {
    return GoalInfo(
      dailyGoalMl: json['daily_goal_ml'] ?? 2000,
      totalDaysAnalyzed: json['total_days_analyzed'] ?? 0,
      daysAchieved: json['days_achieved'] ?? 0,
      achievementRatePercentage: (json['achievement_rate_percentage'] ?? 0)
          .toDouble(),
    );
  }
}

class DailyGoalData {
  final DateTime date;
  final int totalEffectiveMl;
  final int dailyGoalMl;
  final double progressPercentage;
  final bool goalAchieved;
  final int logCount;

  const DailyGoalData({
    required this.date,
    required this.totalEffectiveMl,
    required this.dailyGoalMl,
    required this.progressPercentage,
    required this.goalAchieved,
    required this.logCount,
  });

  factory DailyGoalData.fromJson(Map<String, dynamic> json) {
    return DailyGoalData(
      date: DateTime.parse(json['date']),
      totalEffectiveMl: json['total_effective_ml'] ?? 0,
      dailyGoalMl: json['daily_goal_ml'] ?? 2000,
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
      goalAchieved: json['goal_achieved'] ?? false,
      logCount: json['log_count'] ?? 0,
    );
  }
}

/// Streak analytics response
class StreakAnalyticsResponse {
  final int currentStreak;
  final int longestStreak;
  final int streaksThisMonth;
  final List<dynamic> streakHistory; // TODO: Define StreakHistoryItem

  const StreakAnalyticsResponse({
    required this.currentStreak,
    required this.longestStreak,
    required this.streaksThisMonth,
    required this.streakHistory,
  });

  factory StreakAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return StreakAnalyticsResponse(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      streaksThisMonth: json['streaks_this_month'] ?? 0,
      streakHistory: json['streak_history'] ?? [],
    );
  }
}

/// AI insights response
class InsightsResponse {
  final List<InsightItem> insights;

  const InsightsResponse({required this.insights});

  factory InsightsResponse.fromJson(Map<String, dynamic> json) {
    return InsightsResponse(
      insights:
          (json['insights'] as List<dynamic>?)
              ?.map((item) => InsightItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class InsightItem {
  final String type;
  final String title;
  final String message;
  final String priority;

  const InsightItem({
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
  });

  factory InsightItem.fromJson(Map<String, dynamic> json) {
    return InsightItem(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'low',
    );
  }
}
