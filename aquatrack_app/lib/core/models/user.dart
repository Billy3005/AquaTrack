/// User model for AquaTrack application
class User {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarId;
  final int level;
  final int totalXp;
  final int dailyGoalMl;
  final bool notificationsEnabled;
  final String themePreference;
  final String languagePreference;
  final bool soundEnabled;
  final String? timezone;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatarId,
    required this.level,
    required this.totalXp,
    required this.dailyGoalMl,
    required this.notificationsEnabled,
    required this.themePreference,
    required this.languagePreference,
    required this.soundEnabled,
    this.timezone,
    required this.createdAt,
    this.lastActiveAt,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarId: json['avatar_id'] as String?,
      level: json['level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      dailyGoalMl: json['daily_goal_ml'] as int? ?? 2000,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      themePreference: json['theme_preference'] as String? ?? 'auto',
      languagePreference: json['language_preference'] as String? ?? 'vi',
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      timezone: json['timezone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
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
      'total_xp': totalXp,
      'daily_goal_ml': dailyGoalMl,
      'notifications_enabled': notificationsEnabled,
      'theme_preference': themePreference,
      'language_preference': languagePreference,
      'sound_enabled': soundEnabled,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
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
    int? dailyGoalMl,
    bool? notificationsEnabled,
    String? themePreference,
    String? languagePreference,
    bool? soundEnabled,
    String? timezone,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarId: avatarId ?? this.avatarId,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
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
