import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/storage/hive_storage_service.dart';
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

  const ProfileState({
    required this.userName,
    required this.selectedAvatar,
    required this.dailyGoalMl,
    this.notificationsEnabled = true,
    this.selectedTheme = 'dark',
    this.soundEnabled = true,
    this.language = 'vi',
  });

  ProfileState copyWith({
    String? userName,
    String? selectedAvatar,
    int? dailyGoalMl,
    bool? notificationsEnabled,
    String? selectedTheme,
    bool? soundEnabled,
    String? language,
  }) {
    return ProfileState(
      userName: userName ?? this.userName,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      language: language ?? this.language,
    );
  }
}

/// Profile provider for user settings and preferences
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  ProfileState build() {
    _loadProfile();
    return const ProfileState(
      userName: 'Aqua Warrior',
      selectedAvatar: 'avatar_1',
      dailyGoalMl: 2000,
    );
  }

  /// Load profile from storage
  Future<void> _loadProfile() async {
    try {
      final storage = HiveStorageService.instance;
      final profileData = storage.loadSetting<Map>('user_profile');

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

  /// Update daily goal
  Future<void> updateDailyGoal(int goalMl) async {
    state = state.copyWith(dailyGoalMl: goalMl);
    await _saveProfile();

    // TODO: Integrate with home provider when updateDailyGoal method is available
  }

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

  /// Get user stats summary
  ProfileStats getStats() {
    final homeState = ref.read(homeNotifierProvider);
    final levelState = ref.read(levelNotifierProvider);

    return homeState.when(
      data: (summary) {
        return ProfileStats(
          currentLevel: levelState.currentLevel,
          totalXP: levelState.currentXP,
          currentStreak: levelState.currentStreak,
          totalDrinks: _calculateTotalDrinks(),
          averageDaily: _calculateAverageDaily(),
          achievementsCount:
              levelState.achievements.where((a) => a.isUnlocked).length,
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
