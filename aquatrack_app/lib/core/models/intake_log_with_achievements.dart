import 'intake_log.dart';

/// Achievement unlocked response model
class AchievementUnlocked {
  final String achievementId;
  final String achievementKey;
  final String achievementType;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final DateTime unlockedAt;

  const AchievementUnlocked({
    required this.achievementId,
    required this.achievementKey,
    required this.achievementType,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.unlockedAt,
  });

  factory AchievementUnlocked.fromJson(Map<String, dynamic> json) {
    return AchievementUnlocked(
      achievementId: json['achievement_id'] as String,
      achievementKey: json['achievement_key'] as String,
      achievementType: json['achievement_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      xpReward: json['xp_reward'] as int,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievement_id': achievementId,
      'achievement_key': achievementKey,
      'achievement_type': achievementType,
      'title': title,
      'description': description,
      'icon': icon,
      'xp_reward': xpReward,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}

/// Level progress information
class LevelProgress {
  final int currentLevel;
  final int currentXp;
  final int xpForNextLevel;
  final double progressPercent;
  final int currentStreak;
  final int longestStreak;
  final bool goalAchievedToday;
  final int todayTotalMl;
  final int dailyGoalMl;

  const LevelProgress({
    required this.currentLevel,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.progressPercent,
    required this.currentStreak,
    required this.longestStreak,
    required this.goalAchievedToday,
    required this.todayTotalMl,
    required this.dailyGoalMl,
  });

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      currentLevel: json['current_level'] as int? ?? 1,
      currentXp: json['current_xp'] as int? ?? 0,
      xpForNextLevel: json['xp_for_next_level'] as int? ?? 100,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      goalAchievedToday: json['goal_achieved_today'] as bool? ?? false,
      todayTotalMl: json['today_total_ml'] as int? ?? 0,
      dailyGoalMl: json['daily_goal_ml'] as int? ?? 2000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_level': currentLevel,
      'current_xp': currentXp,
      'xp_for_next_level': xpForNextLevel,
      'progress_percent': progressPercent,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'goal_achieved_today': goalAchievedToday,
      'today_total_ml': todayTotalMl,
      'daily_goal_ml': dailyGoalMl,
    };
  }
}

/// Complete intake log response with achievements and level progress
class IntakeLogWithAchievements {
  final IntakeLog intakeLog;
  final List<AchievementUnlocked> achievements;
  final LevelProgress? levelProgress;

  const IntakeLogWithAchievements({
    required this.intakeLog,
    required this.achievements,
    this.levelProgress,
  });

  factory IntakeLogWithAchievements.fromJson(Map<String, dynamic> json) {
    final achievementsList = json['achievements'] as List? ?? [];

    return IntakeLogWithAchievements(
      intakeLog: IntakeLog.fromJson(json['intake_log'] as Map<String, dynamic>),
      achievements: achievementsList
          .map((item) =>
              AchievementUnlocked.fromJson(item as Map<String, dynamic>))
          .toList(),
      levelProgress: json['level_progress'] != null
          ? LevelProgress.fromJson(
              json['level_progress'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intake_log': intakeLog.toJson(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'level_progress': levelProgress?.toJson(),
    };
  }

  /// Helper to check if any achievements were unlocked
  bool get hasAchievements => achievements.isNotEmpty;

  /// Helper to check if user leveled up
  bool get hasLeveledUp =>
      levelProgress != null &&
      achievements.any((a) => a.achievementType == 'level');
}
