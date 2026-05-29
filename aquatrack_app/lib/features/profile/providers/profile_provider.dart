import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/storage/hive_storage_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user.dart';
import '../../home/providers/home_provider.dart';
import '../../level/providers/level_provider.dart';

part 'profile_provider.g.dart';

/// Profile state class
class ProfileState {
  final String userName;
  final String selectedAvatar;
  final int dailyGoalMl;
  final bool notificationsEnabled;
  final String selectedTheme;
  final bool soundEnabled;
  final String language;
  // Level & XP system
  final int currentLevel;
  final int totalXP;
  final int maxXP; // Computed based on level
  final int currentStreak;
  final int longestStreak;
  // Statistics
  final int totalLogsCount;
  final int totalVolumeMl;
  final String createdAt;
  // Body information
  final String? gender;
  final int? age;
  final int? height; // cm
  final double? weight; // kg
  final String? activityLevel;
  final String? jobType;
  final List<String>? healthConditions;
  final int? coffeeCupsPerDay;
  final int? alcoholUnitsPerDay;
  // Computed properties
  final int coins; // Use total_xp as coins for simplicity

  const ProfileState({
    required this.userName,
    required this.selectedAvatar,
    required this.dailyGoalMl,
    this.notificationsEnabled = true,
    this.selectedTheme = 'dark',
    this.soundEnabled = true,
    this.language = 'vi',
    // Level system defaults
    this.currentLevel = 1,
    this.totalXP = 0,
    this.maxXP = 2000,
    this.currentStreak = 0,
    this.longestStreak = 0,
    // Statistics defaults
    this.totalLogsCount = 0,
    this.totalVolumeMl = 0,
    this.createdAt = '',
    // Body information defaults
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.jobType,
    this.healthConditions,
    this.coffeeCupsPerDay,
    this.alcoholUnitsPerDay,
    this.coins = 0,
  });

  ProfileState copyWith({
    String? userName,
    String? selectedAvatar,
    int? dailyGoalMl,
    bool? notificationsEnabled,
    String? selectedTheme,
    bool? soundEnabled,
    String? language,
    int? currentLevel,
    int? totalXP,
    int? maxXP,
    int? currentStreak,
    int? longestStreak,
    int? totalLogsCount,
    int? totalVolumeMl,
    String? createdAt,
    String? gender,
    int? age,
    int? height,
    double? weight,
    String? activityLevel,
    String? jobType,
    List<String>? healthConditions,
    int? coffeeCupsPerDay,
    int? alcoholUnitsPerDay,
    int? coins,
  }) {
    return ProfileState(
      userName: userName ?? this.userName,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      language: language ?? this.language,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXP: totalXP ?? this.totalXP,
      maxXP: maxXP ?? this.maxXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalLogsCount: totalLogsCount ?? this.totalLogsCount,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      jobType: jobType ?? this.jobType,
      healthConditions: healthConditions ?? this.healthConditions,
      coffeeCupsPerDay: coffeeCupsPerDay ?? this.coffeeCupsPerDay,
      alcoholUnitsPerDay: alcoholUnitsPerDay ?? this.alcoholUnitsPerDay,
      coins: coins ?? this.coins,
    );
  }

  // Computed properties for UI display
  /// Format total volume as liters (e.g., "284L")
  String get totalVolumeLiters {
    if (totalVolumeMl == 0) return '0L';
    final liters = totalVolumeMl / 1000;
    return '${liters.toStringAsFixed(0)}L';
  }

  /// Calculate days since joined
  int get daysSinceJoined {
    if (createdAt.isEmpty) return 0;
    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(createdDate).inDays +
          1; // +1 because counting day 1
    } catch (e) {
      return 0;
    }
  }

  /// Format level display (e.g., "LV 7")
  String get levelDisplay => 'LV $currentLevel';

  /// Format XP progress (e.g., "1240 / 2000 XP")
  String get xpProgressDisplay => '$totalXP / $maxXP XP';

  /// Calculate XP progress percentage (0-100)
  double get xpProgress =>
      maxXP > 0 ? (totalXP / maxXP * 100).clamp(0, 100) : 0;

  /// Format coins display (e.g., "1.2K" for 1240)
  String get coinsDisplay {
    if (coins < 1000) return coins.toString();
    final k = coins / 1000;
    return '${k.toStringAsFixed(1)}K';
  }

  // Body information computed properties
  /// Format weight and height display (e.g., "62 kg · 168 cm")
  String get weightHeightDisplay {
    final weightStr = weight?.toStringAsFixed(0) ?? '--';
    final heightStr = height?.toString() ?? '--';
    return '$weightStr kg · $heightStr cm';
  }

  /// Format gender and age display (e.g., "Nam · 28")
  String get genderAgeDisplay {
    final genderStr = _formatGender(gender);
    final ageStr = age?.toString() ?? '--';
    return '$genderStr · $ageStr';
  }

  /// Format activity level display (e.g., "Vừa phải")
  String get activityLevelDisplay {
    return _formatActivityLevel(activityLevel);
  }

  /// Format job type display (e.g., "Văn phòng")
  String get jobTypeDisplay {
    return _formatJobType(jobType);
  }

  /// Format health conditions display (e.g., "Không có")
  String get healthConditionsDisplay {
    if (healthConditions == null || healthConditions!.isEmpty) {
      return 'Không có';
    }
    if (healthConditions!.contains('none')) {
      return 'Không có';
    }
    return healthConditions!.join(', ');
  }

  /// Format coffee and alcohol display (e.g., "1 cốc · 0 đơn vị")
  String get coffeealcoholDisplay {
    final coffeeStr = coffeeCupsPerDay?.toString() ?? '0';
    final alcoholStr = alcoholUnitsPerDay?.toString() ?? '0';
    return '$coffeeStr cốc · $alcoholStr đơn vị';
  }

  String _formatGender(String? gender) {
    if (gender == null) return '--';
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return '--';
    }
  }

  String _formatActivityLevel(String? level) {
    if (level == null) return '--';
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 'Ít vận động';
      case 'light':
        return 'Nhẹ nhàng';
      case 'moderate':
        return 'Vừa phải';
      case 'active':
        return 'Tích cực';
      case 'very_active':
        return 'Rất tích cực';
      default:
        return '--';
    }
  }

  String _formatJobType(String? jobType) {
    if (jobType == null) return '--';
    switch (jobType.toLowerCase()) {
      case 'office':
        return 'Văn phòng';
      case 'mixed':
        return 'Hỗn hợp';
      case 'outdoor':
        return 'Ngoài trời';
      case 'manual':
        return 'Thể lực';
      default:
        return '--';
    }
  }
}

/// Profile provider for user settings and preferences
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  ProfileState build() {
    debugPrint('🔄 ProfileNotifier: build() called - starting profile load');
    _loadProfile();
    return const ProfileState(
      userName: 'Aqua Warrior',
      selectedAvatar: 'avatar_1',
      dailyGoalMl: 2000,
      // Default level & progression
      currentLevel: 1,
      totalXP: 0,
      maxXP: 1000,
      currentStreak: 0,
      longestStreak: 0,
      // Default statistics
      totalLogsCount: 0,
      totalVolumeMl: 0,
      createdAt: '',
      coins: 0,
    );
  }

  /// Fetch fresh user data from backend API
  Future<Map<String, dynamic>?> _fetchUserDataFromBackend() async {
    try {
      // Use existing ApiService to call /users/profile for complete user data
      final apiService = ApiService();
      debugPrint('🌐 ProfileProvider: Calling API endpoint...');
      final response = await apiService.get('/users/profile');
      debugPrint(
          '🌐 ProfileProvider: API response received: status=${response.statusCode}, data type=${response.data.runtimeType}');

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data!;
        debugPrint(
            '✅ ProfileProvider: Fresh backend data loaded - ${userData['username'] ?? userData['email']}');
        debugPrint('📊 Raw API Response: $userData');
        debugPrint(
            '📊 Body data: weight=${userData['weight']}, height=${userData['height']}, gender=${userData['gender']}, activity=${userData['activity_level']}');
        debugPrint(
            '☕ Diet data: coffee=${userData['coffee_cups_per_day']}, alcohol=${userData['alcohol_units_per_day']}');

        // Also update local cache with fresh data
        final authService = AuthService();
        await authService.storeUserData(userData);

        return userData;
      } else {
        debugPrint(
            '❌ ProfileProvider: Backend API failed: ${response.statusCode} or null data');
        if (response.data == null) {
          debugPrint('❌ ProfileProvider: Response data is null!');
        }
        return null;
      }
    } catch (e) {
      debugPrint('❌ ProfileProvider: Error fetching backend data: $e');
      return null;
    }
  }

  /// Load profile from backend with Hive fallback
  Future<void> _loadProfile() async {
    try {
      // First, try to get fresh data from backend API
      Map<String, dynamic>? userData = await _fetchUserDataFromBackend();

      // If backend fails, fallback to cached data
      if (userData == null) {
        final authService = AuthService();
        userData = await authService.getUserData();
      }

      if (userData != null) {
        debugPrint(
            '📥 ProfileProvider: Backend data received: ${userData.keys}');

        // Parse userData into User model to handle all fields properly
        try {
          final user = User.fromJson(userData);
          debugPrint('👤 User: ${user.username}, Email: ${user.email}');
          debugPrint(
              '📊 Body: gender=${user.gender}, age=${user.age}, height=${user.height}, weight=${user.weight}');
          debugPrint(
              '🏃 Activity: ${user.activityLevel}, Job: ${user.jobType}');
          debugPrint(
              '☕ Diet: coffee=${user.coffeeCupsPerDay}, alcohol=${user.alcoholUnitsPerDay}');

          final level = user.level;
          final totalXP = user.totalXp;
          final maxXP = _calculateMaxXPForLevel(level);

          state = ProfileState(
            userName: user.username ?? user.email.split('@')[0],
            selectedAvatar: user.avatarId ?? 'avatar_1',
            // Use calculated goal from Water Formula, fallback to daily_goal_ml
            dailyGoalMl: user.calculatedDailyGoalMl ?? user.dailyGoalMl,
            notificationsEnabled: user.notificationsEnabled,
            selectedTheme: user.themePreference,
            soundEnabled: user.soundEnabled,
            language: user.languagePreference,
            // Level & progression
            currentLevel: level,
            totalXP: totalXP,
            maxXP: maxXP,
            currentStreak: user.currentStreak ?? 0,
            longestStreak: user.longestStreak ?? 0,
            // Statistics
            totalLogsCount: user.totalLogsCount ?? 0,
            totalVolumeMl: user.totalVolumeMl ?? 0,
            createdAt: user.createdAt.toIso8601String(),
            // Body information from User model
            gender: user.gender,
            age: user.age,
            height: user.height,
            weight: user.weight,
            activityLevel: user.activityLevel,
            jobType: user.jobType,
            healthConditions: user.healthConditions,
            coffeeCupsPerDay: user.coffeeCupsPerDay,
            alcoholUnitsPerDay: user.alcoholUnitsPerDay,
            // Use XP as coins for simplicity
            coins: totalXP,
          );

          // Sync to local storage for offline fallback
          await _saveProfile();
          debugPrint(
              '✅ ProfileProvider: Loaded from backend via User model - ${state.userName}');
          debugPrint(
              '✅ Body info loaded: ${state.gender}, ${state.age}y, ${state.height}cm, ${state.weight}kg');
          return;
        } catch (e) {
          debugPrint('❌ ProfileProvider: Error parsing User model: $e');
          // Fallback to direct parsing if User model fails
          debugPrint('🔄 ProfileProvider: Attempting direct JSON parsing...');
          try {
            // Parse directly from JSON without User model
            state = ProfileState(
              userName: userData['username']?.toString() ??
                  userData['email']?.split('@')[0] ??
                  'Aqua Warrior',
              selectedAvatar: userData['avatar_id']?.toString() ?? 'avatar_1',
              dailyGoalMl: userData['calculated_daily_goal_ml'] as int? ??
                  userData['daily_goal_ml'] as int? ??
                  2000,
              notificationsEnabled:
                  userData['notifications_enabled'] as bool? ?? true,
              selectedTheme: userData['theme_preference']?.toString() ?? 'dark',
              soundEnabled: userData['sound_enabled'] as bool? ?? true,
              language: userData['language_preference']?.toString() ?? 'vi',
              // Level & progression
              currentLevel: userData['current_level'] as int? ??
                  userData['level'] as int? ??
                  1,
              totalXP: userData['total_xp'] as int? ?? 0,
              maxXP: _calculateMaxXPForLevel(
                  userData['current_level'] as int? ??
                      userData['level'] as int? ??
                      1),
              currentStreak: userData['current_streak'] as int? ?? 0,
              longestStreak: userData['longest_streak'] as int? ?? 0,
              // Statistics
              totalLogsCount: userData['total_logs_count'] as int? ?? 0,
              totalVolumeMl: userData['total_volume_ml'] as int? ?? 0,
              createdAt: userData['created_at']?.toString() ??
                  DateTime.now().toIso8601String(),
              // Body information - direct from JSON
              gender: userData['gender']?.toString(),
              age: userData['age'] as int?,
              height: userData['height'] as int?,
              weight: userData['weight']?.toDouble(),
              activityLevel: userData['activity_level']?.toString(),
              jobType: userData['job_type']?.toString(),
              healthConditions: userData['health_conditions'] != null
                  ? List<String>.from(userData['health_conditions'])
                  : null,
              coffeeCupsPerDay: userData['coffee_cups_per_day'] as int?,
              alcoholUnitsPerDay: userData['alcohol_units_per_day'] as int?,
              // Coins
              coins: userData['total_xp'] as int? ?? 0,
            );

            await _saveProfile();
            debugPrint('✅ ProfileProvider: Loaded via direct JSON parsing');
            debugPrint(
                '✅ Body info: gender=${state.gender}, age=${state.age}, height=${state.height}, weight=${state.weight}');
            return;
          } catch (parseError) {
            debugPrint(
                '❌ ProfileProvider: Direct parsing also failed: $parseError');
          }
        }
      }

      // Fallback to local storage if no backend data
      final storage = HiveStorageService.instance;
      final profileData = await storage.loadSetting<Map>('user_profile');

      if (profileData != null) {
        final data = Map<String, dynamic>.from(profileData);
        state = ProfileState(
          userName: data['userName'] ?? 'Aqua Warrior',
          selectedAvatar: data['selectedAvatar'] ?? 'avatar_1',
          dailyGoalMl: data['dailyGoalMl'] ?? 2000,
          notificationsEnabled: data['notificationsEnabled'] ?? true,
          selectedTheme: data['selectedTheme'] ?? 'dark',
          soundEnabled: data['soundEnabled'] ?? true,
          language: data['language'] ?? 'vi',
        );
        debugPrint('✅ ProfileProvider: Loaded from local storage fallback');
      }
    } catch (e) {
      debugPrint('❌ ProfileProvider: Error loading profile: $e');
    }
  }

  /// Save profile to storage
  Future<void> _saveProfile() async {
    try {
      final storage = HiveStorageService.instance;
      await storage.saveSetting('user_profile', {
        'userName': state.userName,
        'selectedAvatar': state.selectedAvatar,
        'dailyGoalMl': state.dailyGoalMl,
        'notificationsEnabled': state.notificationsEnabled,
        'selectedTheme': state.selectedTheme,
        'soundEnabled': state.soundEnabled,
        'language': state.language,
      });
    } catch (e) {
      debugPrint('❌ ProfileProvider: Error saving profile: $e');
    }
  }

  /// Update user name
  Future<void> updateUserName(String name) async {
    state = state.copyWith(userName: name);
    await _saveProfile();
  }

  /// Update selected avatar
  Future<void> updateAvatar(String avatarKey) async {
    state = state.copyWith(selectedAvatar: avatarKey);
    await _saveProfile();
  }

  /// Daily goal is computed-only via Water Formula
  /// Cannot be manually updated - use backend profile sync instead

  /// Update notifications setting
  Future<void> updateNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveProfile();
  }

  /// Update theme setting
  Future<void> updateTheme(String theme) async {
    state = state.copyWith(selectedTheme: theme);
    await _saveProfile();
  }

  /// Update sound setting
  Future<void> updateSound(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _saveProfile();
  }

  /// Update language setting
  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveProfile();
  }

  /// Refresh profile data from backend (call after onboarding completion)
  Future<void> refreshProfile() async {
    debugPrint(
        '🔄 ProfileNotifier: refreshProfile() called - reloading from backend');
    await _loadProfile();
  }

  /// Update body information (body profile editing)
  Future<void> updateBodyInfo({
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
  }) async {
    debugPrint('🔄 ProfileNotifier: updateBodyInfo() called');

    try {
      // Prepare update data
      final updateData = <String, dynamic>{};
      if (gender != null) updateData['gender'] = gender;
      if (age != null) updateData['age'] = age;
      if (height != null) updateData['height'] = height;
      if (weight != null) updateData['weight'] = weight;
      if (activityLevel != null) updateData['activity_level'] = activityLevel;
      if (jobType != null) updateData['job_type'] = jobType;
      if (healthConditions != null)
        updateData['health_conditions'] = healthConditions;
      if (veggieIntake != null) updateData['veggie_intake'] = veggieIntake;
      if (coffeeCupsPerDay != null)
        updateData['coffee_cups_per_day'] = coffeeCupsPerDay;
      if (alcoholUnitsPerDay != null)
        updateData['alcohol_units_per_day'] = alcoholUnitsPerDay;

      debugPrint('📤 ProfileNotifier: Sending body update: $updateData');

      // Call API to update profile
      final apiService = ApiService();
      final response = await apiService.put('/users/profile', data: updateData);

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ ProfileNotifier: Body info updated successfully');

        // Refresh profile data to get updated calculated goal
        await refreshProfile();
      } else {
        throw Exception('Failed to update body info: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Error updating body info: $e');
      rethrow;
    }
  }

  /// Get user stats summary
  ProfileStats getStats() {
    final homeState = ref.read(homeNotifierProvider);
    final levelState = ref.read(levelNotifierProvider);

    return homeState.when(
      data: (summary) {
        return levelState.when(
          data: (level) => ProfileStats(
            currentLevel: level.currentLevel,
            totalXP: level.currentXP,
            currentStreak: level.currentStreak,
            totalDrinks: _calculateTotalDrinks(),
            averageDaily: _calculateAverageDaily(),
            achievementsCount:
                level.achievements.where((a) => a.isUnlocked).length,
          ),
          loading: () => ProfileStats.empty(),
          error: (_, __) => ProfileStats.empty(),
        );
      },
      loading: () => ProfileStats.empty(),
      error: (_, __) => ProfileStats.empty(),
    );
  }

  /// Calculate total drinks logged
  int _calculateTotalDrinks() {
    // This would ideally read from intake logs history
    // For now, return a placeholder
    return 156; // Placeholder
  }

  /// Calculate average daily intake
  double _calculateAverageDaily() {
    // This would calculate from historical data
    // For now, return a placeholder
    return 1850.0; // Placeholder
  }

  /// Calculate max XP required for a level (progression system)
  int _calculateMaxXPForLevel(int level) {
    // Progressive XP requirements: Level 1: 1000, Level 2: 1500, Level 3: 2000, etc.
    return 1000 + ((level - 1) * 500);
  }

  /// Calculate days since user joined
  int _calculateDaysSinceJoined(String createdAtIso) {
    if (createdAtIso.isEmpty) return 0;
    try {
      final createdAt = DateTime.parse(createdAtIso);
      final now = DateTime.now();
      return now.difference(createdAt).inDays + 1; // +1 because counting day 1
    } catch (e) {
      return 0;
    }
  }

  /// Convert total volume from ml to liters for display
  String _formatTotalVolumeAsLiters(int volumeMl) {
    if (volumeMl == 0) return '0L';
    final liters = volumeMl / 1000;
    return '${liters.toStringAsFixed(0)}L';
  }
}

/// Profile stats summary
class ProfileStats {
  final int currentLevel;
  final int totalXP;
  final int currentStreak;
  final int totalDrinks;
  final double averageDaily;
  final int achievementsCount;

  const ProfileStats({
    required this.currentLevel,
    required this.totalXP,
    required this.currentStreak,
    required this.totalDrinks,
    required this.averageDaily,
    required this.achievementsCount,
  });

  factory ProfileStats.empty() => const ProfileStats(
        currentLevel: 1,
        totalXP: 0,
        currentStreak: 0,
        totalDrinks: 0,
        averageDaily: 0.0,
        achievementsCount: 0,
      );
}
