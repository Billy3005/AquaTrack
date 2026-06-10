import '../../domain/entities/user.dart';

/// Data models cho auth layer
///
/// Handles JSON serialization/deserialization cho API communication.
/// Convert giữa API responses và domain entities.

/// Login request model
class LoginRequestModel {
  final String email;
  final String password;

  const LoginRequestModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Register request model
class RegisterRequestModel {
  final String email;
  final String password;
  final String username;
  final String? fullName;
  final int? dailyGoalMl;

  const RegisterRequestModel({
    required this.email,
    required this.password,
    required this.username,
    this.fullName,
    this.dailyGoalMl,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'username': username,
      if (fullName != null) 'full_name': fullName,
      if (dailyGoalMl != null) 'daily_goal_ml': dailyGoalMl,
    };
  }
}

/// Token refresh request model
class TokenRefreshRequestModel {
  final String refreshToken;

  const TokenRefreshRequestModel({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }
}

/// Auth response model từ backend
class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }

  /// Convert to domain entity
  User toDomainEntity() => user.toDomainEntity();
}

/// Token refresh response model
class TokenRefreshResponseModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;

  const TokenRefreshResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
  });

  factory TokenRefreshResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponseModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
      refreshToken: json['refresh_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      if (refreshToken != null) 'refresh_token': refreshToken,
    };
  }
}

/// User data model từ API responses
class UserModel {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarId;
  final int currentLevel;
  final int totalXp;
  final int dailyGoalMl;
  final int calculatedDailyGoalMl;
  final int currentStreak;
  final int longestStreak;
  final int totalLogsCount;
  final int totalVolumeMl;
  final bool notificationsEnabled;
  final String? themePreference;
  final String? languagePreference;
  final bool soundEnabled;
  final String? timezone;
  final String? gender;
  final int? age;
  final int? height;
  final double? weight;
  final String? activityLevel;
  final String? jobType;
  final List<String>? healthConditions;
  final int? coffeeCupsPerDay;
  final int? alcoholUnitsPerDay;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final bool isActive;
  final bool profileComplete;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarId: json['avatar_id'] as String?,
      currentLevel: json['level'] as int? ?? json['current_level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      dailyGoalMl: json['daily_goal_ml'] as int? ?? 2000,
      calculatedDailyGoalMl: json['calculated_daily_goal_ml'] as int? ?? 2000,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      totalLogsCount: json['total_logs_count'] as int? ?? 0,
      totalVolumeMl: json['total_volume_ml'] as int? ?? 0,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      themePreference: json['theme_preference'] as String?,
      languagePreference: json['language_preference'] as String?,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      timezone: json['timezone'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      height: json['height'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      activityLevel: json['activity_level'] as String?,
      jobType: json['job_type'] as String?,
      healthConditions: (json['health_conditions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      coffeeCupsPerDay: json['coffee_cups_per_day'] as int?,
      alcoholUnitsPerDay: json['alcohol_units_per_day'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      profileComplete: json['profile_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_id': avatarId,
      'level': currentLevel,
      'total_xp': totalXp,
      'daily_goal_ml': dailyGoalMl,
      'calculated_daily_goal_ml': calculatedDailyGoalMl,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_logs_count': totalLogsCount,
      'total_volume_ml': totalVolumeMl,
      'notifications_enabled': notificationsEnabled,
      'theme_preference': themePreference,
      'language_preference': languagePreference,
      'sound_enabled': soundEnabled,
      'timezone': timezone,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activity_level': activityLevel,
      'job_type': jobType,
      'health_conditions': healthConditions,
      'coffee_cups_per_day': coffeeCupsPerDay,
      'alcohol_units_per_day': alcoholUnitsPerDay,
      'created_at': createdAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'is_active': isActive,
      'profile_complete': profileComplete,
    };
  }

  /// Convert to domain entity
  User toDomainEntity() {
    return User(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      avatarId: avatarId,
      currentLevel: currentLevel,
      totalXp: totalXp,
      dailyGoalMl: dailyGoalMl,
      calculatedDailyGoalMl: calculatedDailyGoalMl,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalLogsCount: totalLogsCount,
      totalVolumeMl: totalVolumeMl,
      notificationsEnabled: notificationsEnabled,
      themePreference: themePreference,
      languagePreference: languagePreference,
      soundEnabled: soundEnabled,
      timezone: timezone,
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      jobType: jobType,
      healthConditions: healthConditions,
      coffeeCupsPerDay: coffeeCupsPerDay,
      alcoholUnitsPerDay: alcoholUnitsPerDay,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      isActive: isActive,
      profileComplete: profileComplete,
    );
  }

  /// Create từ domain entity
  factory UserModel.fromDomainEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      username: user.username,
      fullName: user.fullName,
      avatarId: user.avatarId,
      currentLevel: user.currentLevel,
      totalXp: user.totalXp,
      dailyGoalMl: user.dailyGoalMl,
      calculatedDailyGoalMl: user.calculatedDailyGoalMl,
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
      totalLogsCount: user.totalLogsCount,
      totalVolumeMl: user.totalVolumeMl,
      notificationsEnabled: user.notificationsEnabled,
      themePreference: user.themePreference,
      languagePreference: user.languagePreference,
      soundEnabled: user.soundEnabled,
      timezone: user.timezone,
      gender: user.gender,
      age: user.age,
      height: user.height,
      weight: user.weight,
      activityLevel: user.activityLevel,
      jobType: user.jobType,
      healthConditions: user.healthConditions,
      coffeeCupsPerDay: user.coffeeCupsPerDay,
      alcoholUnitsPerDay: user.alcoholUnitsPerDay,
      createdAt: user.createdAt,
      lastActiveAt: user.lastActiveAt,
      isActive: user.isActive,
      profileComplete: user.profileComplete,
    );
  }
}
