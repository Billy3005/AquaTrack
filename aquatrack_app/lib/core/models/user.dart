/// User model for AquaTrack application
class User {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarId;
  final int level;
  final int totalXp;
  final int coins; // Spendable currency (real backend balance)
  final int dailyGoalMl;
  final bool notificationsEnabled;
  final String themePreference;
  final String languagePreference;
  final bool soundEnabled;
  final String? timezone;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  // Body info fields from backend UserResponse
  final String? gender;
  final int? age;
  final int? height; // cm
  final double? weight; // kg
  final String? activityLevel;
  final String? jobType;
  final List<String>? healthConditions;
  final String? veggieIntake;
  final int? coffeeCupsPerDay;
  final int? alcoholUnitsPerDay;

  // Additional fields
  final int? calculatedDailyGoalMl;
  final bool? profileComplete;
  final int? currentStreak;
  final int? longestStreak;
  final int? totalLogsCount;
  final int? totalVolumeMl;
  final bool? isActive;
  final bool? isVerified;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatarId,
    required this.level,
    required this.totalXp,
    this.coins = 0,
    required this.dailyGoalMl,
    required this.notificationsEnabled,
    required this.themePreference,
    required this.languagePreference,
    required this.soundEnabled,
    this.timezone,
    required this.createdAt,
    this.lastActiveAt,
    // Body info
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.jobType,
    this.healthConditions,
    this.veggieIntake,
    this.coffeeCupsPerDay,
    this.alcoholUnitsPerDay,
    // Additional
    this.calculatedDailyGoalMl,
    this.profileComplete,
    this.currentStreak,
    this.longestStreak,
    this.totalLogsCount,
    this.totalVolumeMl,
    this.isActive,
    this.isVerified,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarId: json['avatar_id'] as String?,
      level: json['level'] as int? ?? json['current_level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      dailyGoalMl: json['daily_goal_ml'] as int? ?? 2000,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      themePreference: json['theme_preference'] as String? ?? 'auto',
      languagePreference: json['language_preference'] as String? ?? 'vi',
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      timezone: json['timezone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: json['last_active_at'] != null || json['last_login'] != null
          ? DateTime.parse(
              (json['last_active_at'] ?? json['last_login']) as String)
          : null,
      // Body info fields
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      height: json['height'] as int?,
      weight: json['weight']?.toDouble(),
      activityLevel: json['activity_level'] as String?,
      jobType: json['job_type'] as String?,
      healthConditions: json['health_conditions'] != null
          ? List<String>.from(json['health_conditions'])
          : null,
      veggieIntake: json['veggie_intake'] as String?,
      coffeeCupsPerDay: json['coffee_cups_per_day'] as int?,
      alcoholUnitsPerDay: json['alcohol_units_per_day'] as int?,
      // Additional fields
      calculatedDailyGoalMl: json['calculated_daily_goal_ml'] as int?,
      profileComplete: json['profile_complete'] as bool?,
      currentStreak: json['current_streak'] as int?,
      longestStreak: json['longest_streak'] as int?,
      totalLogsCount: json['total_logs_count'] as int?,
      totalVolumeMl: json['total_volume_ml'] as int?,
      isActive: json['is_active'] as bool?,
      isVerified: json['is_verified'] as bool?,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_id': avatarId,
      'level': level,
      'current_level': level,
      'total_xp': totalXp,
      'coins': coins,
      'daily_goal_ml': dailyGoalMl,
      'notifications_enabled': notificationsEnabled,
      'theme_preference': themePreference,
      'language_preference': languagePreference,
      'sound_enabled': soundEnabled,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      // Body info
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (jobType != null) 'job_type': jobType,
      if (healthConditions != null) 'health_conditions': healthConditions,
      if (veggieIntake != null) 'veggie_intake': veggieIntake,
      if (coffeeCupsPerDay != null) 'coffee_cups_per_day': coffeeCupsPerDay,
      if (alcoholUnitsPerDay != null)
        'alcohol_units_per_day': alcoholUnitsPerDay,
      // Additional
      if (calculatedDailyGoalMl != null)
        'calculated_daily_goal_ml': calculatedDailyGoalMl,
      if (profileComplete != null) 'profile_complete': profileComplete,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (totalLogsCount != null) 'total_logs_count': totalLogsCount,
      if (totalVolumeMl != null) 'total_volume_ml': totalVolumeMl,
      if (isActive != null) 'is_active': isActive,
      if (isVerified != null) 'is_verified': isVerified,
    };
  }

  /// Create copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarId,
    int? level,
    int? totalXp,
    int? coins,
    int? dailyGoalMl,
    bool? notificationsEnabled,
    String? themePreference,
    String? languagePreference,
    bool? soundEnabled,
    String? timezone,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    // Body info
    String? gender,
    int? age,
    int? height,
    double? weight,
    String? activityLevel,
    String? jobType,
    List<String>? healthConditions,
    String? veggieIntake,
    int? coffeeCupsPerDay,
    int? alcoholUnitsPerDay,
    // Additional
    int? calculatedDailyGoalMl,
    bool? profileComplete,
    int? currentStreak,
    int? longestStreak,
    int? totalLogsCount,
    int? totalVolumeMl,
    bool? isActive,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarId: avatarId ?? this.avatarId,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      coins: coins ?? this.coins,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      // Body info
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      jobType: jobType ?? this.jobType,
      healthConditions: healthConditions ?? this.healthConditions,
      veggieIntake: veggieIntake ?? this.veggieIntake,
      coffeeCupsPerDay: coffeeCupsPerDay ?? this.coffeeCupsPerDay,
      alcoholUnitsPerDay: alcoholUnitsPerDay ?? this.alcoholUnitsPerDay,
      // Additional
      calculatedDailyGoalMl:
          calculatedDailyGoalMl ?? this.calculatedDailyGoalMl,
      profileComplete: profileComplete ?? this.profileComplete,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalLogsCount: totalLogsCount ?? this.totalLogsCount,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, level: $level)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// User creation request model
class UserCreateRequest {
  final String email;
  final String password;
  final String? username;
  final String? fullName;

  const UserCreateRequest({
    required this.email,
    required this.password,
    this.username,
    this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (username != null) 'username': username,
      if (fullName != null) 'full_name': fullName,
    };
  }
}

/// User update request model
class UserUpdateRequest {
  final String? username;
  final String? fullName;
  final String? avatarId;
  final int? dailyGoalMl;
  final bool? notificationsEnabled;
  final String? themePreference;
  final String? languagePreference;
  final bool? soundEnabled;
  final String? timezone;

  const UserUpdateRequest({
    this.username,
    this.fullName,
    this.avatarId,
    this.dailyGoalMl,
    this.notificationsEnabled,
    this.themePreference,
    this.languagePreference,
    this.soundEnabled,
    this.timezone,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (username != null) json['username'] = username;
    if (fullName != null) json['full_name'] = fullName;
    if (avatarId != null) json['avatar_id'] = avatarId;
    if (dailyGoalMl != null) json['daily_goal_ml'] = dailyGoalMl;
    if (notificationsEnabled != null)
      json['notifications_enabled'] = notificationsEnabled;
    if (themePreference != null) json['theme_preference'] = themePreference;
    if (languagePreference != null)
      json['language_preference'] = languagePreference;
    if (soundEnabled != null) json['sound_enabled'] = soundEnabled;
    if (timezone != null) json['timezone'] = timezone;

    return json;
  }
}
