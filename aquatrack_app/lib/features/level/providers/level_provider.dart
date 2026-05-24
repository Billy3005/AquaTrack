import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/storage/hive_storage_service.dart';
import '../../../core/repositories/level_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/providers/auth_state_provider.dart';
import '../../../core/sync/level_sync_repository.dart';
import '../widgets/achievement_badges_grid.dart';
import '../widgets/avatar_collection_showcase.dart';

part 'level_provider.g.dart';

/// Provider for LevelRepository dependency injection
@riverpod
LevelRepository levelRepository(Ref ref) {
  return LevelRepository();
}

/// Provider for Level Sync Repository dependency injection
/// Returns null to indicate sync is not available - app works offline-only
@riverpod
LevelSyncRepository? levelSyncRepositoryNullable(Ref ref) {
  // Sync not configured - app works in offline-only mode
  debugPrint('⚠️ Level sync not configured, running offline-only mode');
  return null;
}

/// Level system state
class LevelState {
  final int currentLevel;
  final int currentXP;
  final int nextLevelXP;
  final List<Achievement> achievements;
  final List<AvatarItem> avatars;
  final String selectedAvatarId;
  final bool isLevelingUp;
  final int totalLogsCount;
  final int currentStreak;
  final int totalVolume;
  final int daysWithGoal;

  const LevelState({
    required this.currentLevel,
    required this.currentXP,
    required this.nextLevelXP,
    required this.achievements,
    required this.avatars,
    required this.selectedAvatarId,
    required this.isLevelingUp,
    required this.totalLogsCount,
    required this.currentStreak,
    required this.totalVolume,
    required this.daysWithGoal,
  });

  LevelState copyWith({
    int? currentLevel,
    int? currentXP,
    int? nextLevelXP,
    List<Achievement>? achievements,
    List<AvatarItem>? avatars,
    String? selectedAvatarId,
    bool? isLevelingUp,
    int? totalLogsCount,
    int? currentStreak,
    int? totalVolume,
    int? daysWithGoal,
  }) {
    return LevelState(
      currentLevel: currentLevel ?? this.currentLevel,
      currentXP: currentXP ?? this.currentXP,
      nextLevelXP: nextLevelXP ?? this.nextLevelXP,
      achievements: achievements ?? this.achievements,
      avatars: avatars ?? this.avatars,
      selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
      isLevelingUp: isLevelingUp ?? this.isLevelingUp,
      totalLogsCount: totalLogsCount ?? this.totalLogsCount,
      currentStreak: currentStreak ?? this.currentStreak,
      totalVolume: totalVolume ?? this.totalVolume,
      daysWithGoal: daysWithGoal ?? this.daysWithGoal,
    );
  }
}

/// Level system notifier với enhanced offline-first sync
@riverpod
class LevelNotifier extends _$LevelNotifier {
  LevelRepository? _levelRepository;
  LevelSyncRepository? _levelSyncRepository;

  @override
  Future<LevelState> build() async {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      return await _loadInitialStateAsync();
    }

    // Initialize repositories via dependency injection (only if not already initialized)
    _levelRepository ??= ref.read(levelRepositoryProvider);

    // Get sync repository (null if not configured)
    _levelSyncRepository = ref.read(levelSyncRepositoryNullableProvider);
    if (_levelSyncRepository == null) {
      debugPrint('💾 LevelProvider: Running in offline-only mode');
    }

    // Load data and trigger background sync
    final levelState = await _loadLevelDataFromApi();
    _triggerBackgroundLevelSync();

    return levelState;
  }

  /// Load level data from API with fallback to local storage
  Future<LevelState> _loadLevelDataFromApi() async {
    try {
      // Ensure repository is initialized
      final repository = _levelRepository!;

      // Fetch data from API in parallel for better performance
      final results = await Future.wait([
        repository.getCurrentLevel(),
        repository.getAchievements(),
        repository.getUnlockedAvatars(),
        repository.getLevelStats(),
        UserRepository().getUserStats(),
      ]);

      final levelInfoResponse = results[0] as LevelApiResponse<LevelInfo>;
      final achievementsResponse =
          results[1] as LevelApiResponse<List<AchievementProgress>>;
      final avatarsResponse = results[2] as LevelApiResponse<List<String>>;
      final statsResponse = results[3] as LevelApiResponse<LevelStats>;
      final userStats = results[4] as UserStats;

      // Check for any API errors
      if (!levelInfoResponse.isSuccess) {
        throw Exception(levelInfoResponse.error ?? 'Failed to load level info');
      }
      if (!achievementsResponse.isSuccess) {
        throw Exception(
          achievementsResponse.error ?? 'Failed to load achievements',
        );
      }
      if (!avatarsResponse.isSuccess) {
        throw Exception(avatarsResponse.error ?? 'Failed to load avatars');
      }
      if (!statsResponse.isSuccess) {
        throw Exception(statsResponse.error ?? 'Failed to load stats');
      }

      // Convert API responses to local LevelState format
      return _convertApiDataToLevelState(
        levelInfoResponse.data!,
        achievementsResponse.data!,
        avatarsResponse.data!,
        statsResponse.data!,
        userStats,
      );
    } catch (e) {
      debugPrint('❌ Failed to load level data from API: $e');

      // Only fallback to local storage for genuine connectivity issues
      final isConnectivityError = e.toString().contains('SocketException') ||
          e.toString().contains('HttpException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('No route to host');

      if (isConnectivityError) {
        debugPrint(
          '🌐 Network connectivity issue detected, falling back to local storage',
        );
        return _loadLevelDataFromLocal();
      } else {
        // Re-throw API errors for proper error handling in UI
        debugPrint('🚨 API error (not connectivity), exposing to UI: $e');
        rethrow;
      }
    }
  }

  /// Convert API response data to local LevelState format
  LevelState _convertApiDataToLevelState(
    LevelInfo levelInfo,
    List<AchievementProgress> achievementsData,
    List<String> unlockedAvatarIds,
    LevelStats stats,
    UserStats userStats,
  ) {
    // Convert API achievements to local Achievement format
    final achievements = achievementsData.map((apiAchievement) {
      return Achievement(
        id: apiAchievement.id,
        title: apiAchievement.title,
        description: apiAchievement.description,
        icon: _getIconFromString(apiAchievement.icon),
        type: _getAchievementTypeFromString(apiAchievement.type),
        requiredValue: apiAchievement.requiredValue,
        isUnlocked: apiAchievement.isUnlocked,
        unlockedAt: apiAchievement.isUnlocked ? DateTime.now() : null,
      );
    }).toList();

    // Generate avatars based on unlocked avatar IDs
    final avatars = _generateAvatarsFromUnlockedIds(
      unlockedAvatarIds,
      levelInfo.currentLevel,
    );

    // Use default avatar for now, async loading will update later
    final savedAvatarId = 'water_drop';

    return LevelState(
      currentLevel: levelInfo.currentLevel,
      currentXP: levelInfo.currentXP,
      nextLevelXP: levelInfo.xpForNextLevel,
      achievements: achievements,
      avatars: avatars,
      selectedAvatarId: savedAvatarId,
      isLevelingUp: false,
      totalLogsCount: userStats.totalLogsCount,
      currentStreak: userStats.currentStreak,
      totalVolume: userStats.totalVolumeMl,
      daysWithGoal: stats.achievements.unlocked,
    );
  }

  /// Generate avatars list from unlocked avatar IDs
  List<AvatarItem> _generateAvatarsFromUnlockedIds(
    List<String> unlockedIds,
    int currentLevel,
  ) {
    // Use the existing DefaultAvatars logic but filter by unlocked IDs
    final allAvatars = DefaultAvatars.getAll(
      currentLevel: currentLevel,
      selectedAvatarId:
          unlockedIds.isNotEmpty ? unlockedIds.first : 'water_drop',
    );

    // Filter avatars to only show unlocked ones
    return allAvatars.map((avatar) {
      final isUnlocked =
          unlockedIds.contains(avatar.id) || avatar.id == 'water_drop';
      return avatar.copyWith(isUnlocked: isUnlocked);
    }).toList();
  }

  /// Convert string icon to IconData
  IconData _getIconFromString(String iconString) {
    // Simple mapping, could be expanded
    switch (iconString) {
      case 'first_day':
        return Icons.star;
      case 'week_warrior':
        return Icons.military_tech;
      case 'month_master':
        return Icons.emoji_events;
      case 'first_liter':
        return Icons.water_drop;
      case 'hydration_hero':
        return Icons.local_fire_department;
      case 'level_5':
      case 'level_20':
        return Icons.trending_up;
      case 'frequent_drinker':
        return Icons.repeat;
      default:
        return Icons.star;
    }
  }

  /// Convert string achievement type to enum
  AchievementType _getAchievementTypeFromString(String typeString) {
    switch (typeString) {
      case 'streak':
        return AchievementType.streak;
      case 'total_volume':
        return AchievementType.totalVolume;
      case 'level':
        return AchievementType.level;
      case 'daily_goal':
        return AchievementType.dailyGoal;
      case 'frequency':
        return AchievementType.frequency;
      default:
        return AchievementType.frequency;
    }
  }

  /// Fallback to local storage if API fails
  LevelState _loadLevelDataFromLocal() {
    return _loadInitialState();
  }

  /// Load initial state từ storage async
  Future<LevelState> _loadInitialStateAsync() async {
    // Load saved values from storage with fallback to defaults
    final storage = HiveStorageService.instance;

    try {
      final savedLevel = await storage.loadSetting<int>('current_level') ?? 1;
      final savedXP = await storage.loadSetting<int>('current_xp') ?? 0;
      final savedAvatarId =
          await storage.loadSetting<String>('selected_avatar') ?? 'water_drop';
      final totalLogsCount =
          await storage.loadSetting<int>('total_logs_count') ?? 0;
      final currentStreak =
          await storage.loadSetting<int>('current_streak') ?? 0;
      final totalVolume = await storage.loadSetting<int>('total_volume') ?? 0;
      final daysWithGoal =
          await storage.loadSetting<int>('days_with_goal') ?? 0;

      // Calculate next level XP requirement
      final nextLevelXP = _calculateNextLevelXP(savedLevel);

      // Generate achievements với current stats
      final achievements = DefaultAchievements.getAll(
        totalLogs: totalLogsCount,
        currentStreak: currentStreak,
        totalVolume: totalVolume,
        currentLevel: savedLevel,
        daysWithGoal: daysWithGoal,
      );

      // Generate avatars
      final avatars = DefaultAvatars.getAll(
        currentLevel: savedLevel,
        selectedAvatarId: savedAvatarId,
      );

      debugPrint(
          '💾 LevelProvider: Loaded from storage - Level: $savedLevel, XP: $savedXP, Streak: $currentStreak');

      return LevelState(
        currentLevel: savedLevel,
        currentXP: savedXP,
        nextLevelXP: nextLevelXP,
        achievements: achievements,
        avatars: avatars,
        selectedAvatarId: savedAvatarId,
        isLevelingUp: false,
        totalLogsCount: totalLogsCount,
        currentStreak: currentStreak,
        totalVolume: totalVolume,
        daysWithGoal: daysWithGoal,
      );
    } catch (e) {
      debugPrint('❌ LevelProvider: Error loading from storage: $e');
      return _loadInitialState();
    }
  }

  /// Load initial state từ storage (sync fallback)
  LevelState _loadInitialState() {
    // Fallback to default values if async loading fails
    final savedLevel = 1;
    final savedXP = 0;
    final savedAvatarId = 'water_drop';
    final totalLogsCount = 0;
    final currentStreak = 0;
    final totalVolume = 0;
    final daysWithGoal = 0;

    // Calculate next level XP requirement
    final nextLevelXP = _calculateNextLevelXP(savedLevel);

    // Generate achievements với current stats
    final achievements = DefaultAchievements.getAll(
      totalLogs: totalLogsCount,
      currentStreak: currentStreak,
      totalVolume: totalVolume,
      currentLevel: savedLevel,
      daysWithGoal: daysWithGoal,
    );

    // Generate avatars
    final avatars = DefaultAvatars.getAll(
      currentLevel: savedLevel,
      selectedAvatarId: savedAvatarId,
    );

    return LevelState(
      currentLevel: savedLevel,
      currentXP: savedXP,
      nextLevelXP: nextLevelXP,
      achievements: achievements,
      avatars: avatars,
      selectedAvatarId: savedAvatarId,
      isLevelingUp: false,
      totalLogsCount: totalLogsCount,
      currentStreak: currentStreak,
      totalVolume: totalVolume,
      daysWithGoal: daysWithGoal,
    );
  }

  /// Add XP và check for level up
  Future<bool> addXP(int xpAmount) async {
    try {
      final currentState = await future;

      // In production, this should call API to add XP
      // For now, simulate local XP addition
      final newXP = currentState.currentXP + xpAmount;
      var newLevel = currentState.currentLevel;
      var remainingXP = newXP;
      bool hasLeveledUp = false;

      // Check for level up (có thể level up nhiều lần)
      while (remainingXP >= _calculateNextLevelXP(newLevel)) {
        remainingXP -= _calculateNextLevelXP(newLevel);
        newLevel++;
        hasLeveledUp = true;
      }

      // Update state
      final updatedState = currentState.copyWith(
        currentLevel: newLevel,
        currentXP: remainingXP,
        nextLevelXP: _calculateNextLevelXP(newLevel),
        isLevelingUp: hasLeveledUp,
      );

      final finalState = _updateAchievementsAndAvatars(updatedState);
      state = AsyncValue.data(finalState);

      // Save to storage
      await _saveToStorage();

      return hasLeveledUp;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Update stats (được gọi khi user log drinks)
  Future<void> updateStats({
    int? additionalLogs,
    int? additionalVolume,
    int? newStreak,
    bool? achievedGoalToday,
  }) async {
    try {
      final currentState = await future;

      final updatedState = currentState.copyWith(
        totalLogsCount: additionalLogs != null
            ? currentState.totalLogsCount + additionalLogs
            : currentState.totalLogsCount,
        totalVolume: additionalVolume != null
            ? currentState.totalVolume + additionalVolume
            : currentState.totalVolume,
        currentStreak: newStreak ?? currentState.currentStreak,
        daysWithGoal: achievedGoalToday == true
            ? currentState.daysWithGoal + 1
            : currentState.daysWithGoal,
      );

      final finalState = _updateAchievementsAndAvatars(updatedState);
      state = AsyncValue.data(finalState);
      await _saveToStorage();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Select avatar
  Future<void> selectAvatar(String avatarId) async {
    try {
      final currentState = await future;
      final updatedAvatars = currentState.avatars.map((avatar) {
        return avatar.copyWith(isSelected: avatar.id == avatarId);
      }).toList();

      final updatedState = currentState.copyWith(
        selectedAvatarId: avatarId,
        avatars: updatedAvatars,
      );

      state = AsyncValue.data(updatedState);
      await _saveToStorage();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear level up animation state
  Future<void> clearLevelUpState() async {
    try {
      final currentState = await future;
      final updatedState = currentState.copyWith(isLevelingUp: false);
      state = AsyncValue.data(updatedState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update achievements và avatars dựa trên current stats
  LevelState _updateAchievementsAndAvatars(LevelState currentState) {
    final updatedAchievements = DefaultAchievements.getAll(
      totalLogs: currentState.totalLogsCount,
      currentStreak: currentState.currentStreak,
      totalVolume: currentState.totalVolume,
      currentLevel: currentState.currentLevel,
      daysWithGoal: currentState.daysWithGoal,
    );

    final updatedAvatars = DefaultAvatars.getAll(
      currentLevel: currentState.currentLevel,
      selectedAvatarId: currentState.selectedAvatarId,
    );

    return currentState.copyWith(
      achievements: updatedAchievements,
      avatars: updatedAvatars,
    );
  }

  /// Calculate XP required for next level (exponential growth)
  int _calculateNextLevelXP(int level) {
    // Base XP cần cho level tiếp theo
    // Level 1→2: 100XP, Level 2→3: 150XP, Level 3→4: 225XP, etc.
    return (100 * (level * 1.5)).round();
  }

  /// Save state to storage
  Future<void> _saveToStorage() async {
    try {
      final storage = HiveStorageService.instance;
      final currentState = await future;

      await storage.saveSetting('current_level', currentState.currentLevel);
      await storage.saveSetting('current_xp', currentState.currentXP);
      await storage.saveSetting(
        'selected_avatar',
        currentState.selectedAvatarId,
      );
      await storage.saveSetting(
        'total_logs_count',
        currentState.totalLogsCount,
      );
      await storage.saveSetting('current_streak', currentState.currentStreak);
      await storage.saveSetting('total_volume', currentState.totalVolume);
      await storage.saveSetting('days_with_goal', currentState.daysWithGoal);

      debugPrint(
          '💾 LevelProvider: Saved to storage - Level: ${currentState.currentLevel}, XP: ${currentState.currentXP}, Streak: ${currentState.currentStreak}');
    } catch (e) {
      debugPrint('❌ Failed to save level state to storage: $e');
    }
  }

  /// Get current selected avatar (async)
  Future<AvatarItem?> getSelectedAvatar() async {
    try {
      final currentState = await future;
      return currentState.avatars.firstWhere(
        (avatar) => avatar.isSelected,
        orElse: () => currentState.avatars.first,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get unlocked achievements count (async)
  Future<int> getUnlockedAchievementsCount() async {
    try {
      final currentState = await future;
      return currentState.achievements
          .where((achievement) => achievement.isUnlocked)
          .length;
    } catch (e) {
      return 0;
    }
  }

  /// Get progress to next level (0.0 → 1.0) (async)
  Future<double> getNextLevelProgress() async {
    try {
      final currentState = await future;
      if (currentState.nextLevelXP == 0) return 1.0;
      return (currentState.currentXP / currentState.nextLevelXP).clamp(
        0.0,
        1.0,
      );
    } catch (e) {
      return 0.0;
    }
  }

  /// Reset all progress (for testing/admin)
  Future<void> resetProgress() async {
    try {
      final storage = HiveStorageService.instance;

      // Clear saved settings
      await storage.saveSetting('current_level', 1);
      await storage.saveSetting('current_xp', 0);
      await storage.saveSetting('selected_avatar', 'water_drop');
      await storage.saveSetting('total_logs_count', 0);
      await storage.saveSetting('current_streak', 0);
      await storage.saveSetting('total_volume', 0);
      await storage.saveSetting('days_with_goal', 0);

      // Reload state from API
      final newState = await _loadLevelDataFromApi();
      state = AsyncValue.data(newState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Trigger background level sync
  void _triggerBackgroundLevelSync() {
    if (_levelSyncRepository != null) {
      // Sync level data in background
      Future.microtask(() async {
        try {
          await _levelSyncRepository!.syncUserLevel();
          await _levelSyncRepository!.syncAchievements();
          debugPrint('✅ LevelNotifier: Background sync completed');
        } catch (e) {
          debugPrint('⚠️ LevelNotifier: Background sync failed: $e');
        }
      });
    }
  }
}
