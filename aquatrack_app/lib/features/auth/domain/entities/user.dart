/// User domain entity
///
/// Represents the core user model trong domain layer. Không có dependencies
/// trên bất kỳ external libraries nào (pure domain model).
class User {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarId;

  // Level & XP
  final int currentLevel;
  final int totalXp;

  // Health Goals
  final int dailyGoalMl;
  final int calculatedDailyGoalMl;

  // Streaks
  final int currentStreak;
  final int longestStreak;

  // Statistics
  final int totalLogsCount;
  final int totalVolumeMl;

  // Settings
  final bool notificationsEnabled;
  final String? themePreference;
  final String? languagePreference;
  final bool soundEnabled;
  final String? timezone;

  // Body Information
  final String? gender;
  final int? age;
  final int? height; // cm
  final double? weight; // kg
  final String? activityLevel;
  final String? jobType;
  final List<String>? healthConditions;
  final int? coffeeCupsPerDay;
  final int? alcoholUnitsPerDay;

  // Metadata
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final bool isActive;
  final bool profileComplete;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.avatarId,
    this.currentLevel = 1,
    this.totalXp = 0,
    this.dailyGoalMl = 2000,
    this.calculatedDailyGoalMl = 2000,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalLogsCount = 0,
    this.totalVolumeMl = 0,
    this.notificationsEnabled = true,
    this.themePreference,
    this.languagePreference,
    this.soundEnabled = true,
    this.timezone,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.jobType,
    this.healthConditions,
    this.coffeeCupsPerDay,
    this.alcoholUnitsPerDay,
    this.createdAt,
    this.lastActiveAt,
    this.isActive = true,
    this.profileComplete = false,
  });

  /// Create copy với updated fields
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarId,
    int? currentLevel,
    int? totalXp,
    int? dailyGoalMl,
    int? calculatedDailyGoalMl,
    int? currentStreak,
    int? longestStreak,
    int? totalLogsCount,
    int? totalVolumeMl,
    bool? notificationsEnabled,
    String? themePreference,
    String? languagePreference,
    bool? soundEnabled,
    String? timezone,
    String? gender,
    int? age,
    int? height,
    double? weight,
    String? activityLevel,
    String? jobType,
    List<String>? healthConditions,
    int? coffeeCupsPerDay,
    int? alcoholUnitsPerDay,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isActive,
    bool? profileComplete,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarId: avatarId ?? this.avatarId,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXp: totalXp ?? this.totalXp,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      calculatedDailyGoalMl: calculatedDailyGoalMl ?? this.calculatedDailyGoalMl,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalLogsCount: totalLogsCount ?? this.totalLogsCount,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      timezone: timezone ?? this.timezone,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      jobType: jobType ?? this.jobType,
      healthConditions: healthConditions ?? this.healthConditions,
      coffeeCupsPerDay: coffeeCupsPerDay ?? this.coffeeCupsPerDay,
      alcoholUnitsPerDay: alcoholUnitsPerDay ?? this.alcoholUnitsPerDay,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  /// Check if user has completed profile setup
  bool get hasCompletedProfile {
    return fullName != null &&
           fullName!.isNotEmpty &&
           gender != null &&
           age != null &&
           height != null &&
           weight != null &&
           activityLevel != null;
  }

  /// Get display name (full name fallback to username)
  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;

  /// Get initials for avatar
  String get initials {
    if (fullName?.isNotEmpty == true) {
      final names = fullName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names.first[0]}${names.last[0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }

  /// Calculate BMI if height và weight available
  double? get bmi {
    if (height == null || weight == null || height == 0) return null;
    final heightM = height! / 100.0; // Convert cm to m
    return weight! / (heightM * heightM);
  }

  /// Get BMI category
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;

    if (bmiValue < 18.5) return 'Thiếu cân';
    if (bmiValue < 25.0) return 'Bình thường';
    if (bmiValue < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  /// Check if user is a new user (created less than 7 days ago)
  bool get isNewUser {
    if (createdAt == null) return false;
    final daysSinceCreated = DateTime.now().difference(createdAt!).inDays;
    return daysSinceCreated < 7;
  }

  /// Get level progress (0.0 to 1.0)
  double get levelProgress {
    // Simple leveling system: each level requires 1000 * level XP
    final currentLevelXp = 1000 * currentLevel;
    final nextLevelXp = 1000 * (currentLevel + 1);
    final xpInCurrentLevel = totalXp - (currentLevelXp - 1000);
    final xpNeededForNextLevel = nextLevelXp - currentLevelXp;

    if (xpNeededForNextLevel == 0) return 1.0;
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ username.hashCode;

  @override
  String toString() => 'User(id: $id, email: $email, username: $username)';
}