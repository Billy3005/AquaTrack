import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/storage/hive_storage_service.dart';
import '../widgets/achievement_badges_grid.dart';
import '../widgets/avatar_collection_showcase.dart';

part 'level_provider.g.dart';

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

/// Level system notifier với XP, achievements, avatars
@riverpod
class LevelNotifier extends _$LevelNotifier {
  @override
  LevelState build() {
    return _loadInitialState();
  }

  /// Load initial state từ storage
  LevelState _loadInitialState() {
    final storage = HiveStorageService.instance;

    // Load saved data hoặc dùng defaults
    final savedLevel = storage.loadSetting<int>('current_level') ?? 1;
    final savedXP = storage.loadSetting<int>('current_xp') ?? 0;
    final savedAvatarId = storage.loadSetting<String>('selected_avatar') ?? 'water_drop';
    final totalLogsCount = storage.loadSetting<int>('total_logs_count') ?? 0;
    final currentStreak = storage.loadSetting<int>('current_streak') ?? 0;
    final totalVolume = storage.loadSetting<int>('total_volume') ?? 0;
    final daysWithGoal = storage.loadSetting<int>('days_with_goal') ?? 0;

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
    final currentState = state;
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

    state = _updateAchievementsAndAvatars(updatedState);

    // Save to storage
    await _saveToStorage();

    return hasLeveledUp;
  }

  /// Update stats (được gọi khi user log drinks)
  Future<void> updateStats({
    int? additionalLogs,
    int? additionalVolume,
    int? newStreak,
    bool? achievedGoalToday,
  }) async {
    final currentState = state;

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

    state = _updateAchievementsAndAvatars(updatedState);
    await _saveToStorage();
  }

  /// Select avatar
  Future<void> selectAvatar(String avatarId) async {
    final currentState = state;
    final updatedAvatars = currentState.avatars.map((avatar) {
      return avatar.copyWith(
        isSelected: avatar.id == avatarId,
      );
    }).toList();

    state = currentState.copyWith(
      selectedAvatarId: avatarId,
      avatars: updatedAvatars,
    );

    await _saveToStorage();
  }

  /// Clear level up animation state
  void clearLevelUpState() {
    state = state.copyWith(isLevelingUp: false);
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
    final storage = HiveStorageService.instance;
    final currentState = state;

    await storage.saveSetting('current_level', currentState.currentLevel);
    await storage.saveSetting('current_xp', currentState.currentXP);
    await storage.saveSetting('selected_avatar', currentState.selectedAvatarId);
    await storage.saveSetting('total_logs_count', currentState.totalLogsCount);
    await storage.saveSetting('current_streak', currentState.currentStreak);
    await storage.saveSetting('total_volume', currentState.totalVolume);
    await storage.saveSetting('days_with_goal', currentState.daysWithGoal);
  }

  /// Get current selected avatar
  AvatarItem get selectedAvatar {
    return state.avatars.firstWhere(
      (avatar) => avatar.isSelected,
      orElse: () => state.avatars.first,
    );
  }

  /// Get unlocked achievements count
  int get unlockedAchievementsCount {
    return state.achievements.where((achievement) => achievement.isUnlocked).length;
  }

  /// Get progress to next level (0.0 → 1.0)
  double get nextLevelProgress {
    if (state.nextLevelXP == 0) return 1.0;
    return (state.currentXP / state.nextLevelXP).clamp(0.0, 1.0);
  }

  /// Reset all progress (for testing/admin)
  Future<void> resetProgress() async {
    final storage = HiveStorageService.instance;

    // Clear saved settings
    await storage.saveSetting('current_level', 1);
    await storage.saveSetting('current_xp', 0);
    await storage.saveSetting('selected_avatar', 'water_drop');
    await storage.saveSetting('total_logs_count', 0);
    await storage.saveSetting('current_streak', 0);
    await storage.saveSetting('total_volume', 0);
    await storage.saveSetting('days_with_goal', 0);

    // Reload state
    state = _loadInitialState();
  }
}