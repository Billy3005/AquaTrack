import 'package:hive/hive.dart';

part 'daily_summary.g.dart';

/// Daily hydration summary model
@HiveType(typeId: 1)
class DailySummary {
  @HiveField(0)
  final int dailyGoalMl;

  @HiveField(1)
  final int totalEffectiveMl;

  @HiveField(2)
  final int logCount;

  @HiveField(3)
  final double progress; // 0.0 → 1.0

  @HiveField(4)
  final int remainingMl;

  @HiveField(5)
  final int streakDays;

  @HiveField(6)
  final int xpToday;

  @HiveField(7)
  final int currentLevel;

  @HiveField(8)
  final String location;

  @HiveField(9)
  final double temperatureCelsius;

  @HiveField(10)
  final DateTime lastUpdated;

  const DailySummary({
    required this.dailyGoalMl,
    required this.totalEffectiveMl,
    required this.logCount,
    required this.progress,
    required this.remainingMl,
    required this.streakDays,
    required this.xpToday,
    required this.currentLevel,
    required this.location,
    required this.temperatureCelsius,
    required this.lastUpdated,
  });

  DailySummary copyWith({
    int? dailyGoalMl,
    int? totalEffectiveMl,
    int? logCount,
    double? progress,
    int? remainingMl,
    int? streakDays,
    int? xpToday,
    int? currentLevel,
    String? location,
    double? temperatureCelsius,
    DateTime? lastUpdated,
  }) {
    return DailySummary(
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      totalEffectiveMl: totalEffectiveMl ?? this.totalEffectiveMl,
      logCount: logCount ?? this.logCount,
      progress: progress ?? this.progress,
      remainingMl: remainingMl ?? this.remainingMl,
      streakDays: streakDays ?? this.streakDays,
      xpToday: xpToday ?? this.xpToday,
      currentLevel: currentLevel ?? this.currentLevel,
      location: location ?? this.location,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Create mock data for development
  factory DailySummary.mock() {
    return DailySummary(
      dailyGoalMl: 2500,
      totalEffectiveMl: 1450,
      logCount: 5,
      progress: 0.58,
      remainingMl: 1050,
      streakDays: 12,
      xpToday: 50,
      currentLevel: 7,
      location: 'HCMC',
      temperatureCelsius: 28.0,
      lastUpdated: DateTime.now(),
    );
  }
}
