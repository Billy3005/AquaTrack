import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/home_state.dart';
import '../../../core/repositories/intake_repository.dart';
import '../../../core/models/intake_log_with_achievements.dart';
import '../../../core/sync/stats_sync_repository.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/providers/user_stats_provider.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../shared/models/daily_summary.dart';
import '../../../shared/models/intake_log.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../../level/providers/level_provider.dart';
import '../../stats/providers/stats_provider.dart';

part 'home_provider.g.dart';

/// Lightweight display row for the home "Hôm nay" list. Decouples the UI from
/// the two different IntakeLog types (server `core` model vs Hive `shared`
/// model) so either source can feed the same list.
class TodayLogEntry {
  final String liquidType;
  final int volumeMl;
  final DateTime loggedAt;

  const TodayLogEntry({
    required this.liquidType,
    required this.volumeMl,
    required this.loggedAt,
  });
}

/// Today's intake logs for the home "Hôm nay" list (real data, no mock).
/// Re-runs whenever the home summary changes (e.g. after a quick log) so the
/// list stays in sync. Server-first with local Hive fallback — mirrors how the
/// home summary itself is loaded.
final todayIntakeLogsProvider =
    FutureProvider<List<TodayLogEntry>>((ref) async {
  // Rebuild together with the daily summary after logging.
  ref.watch(homeNotifierProvider);
  try {
    final logs = await IntakeRepository().getTodayIntakeLogs();
    final entries = logs
        .map((log) => TodayLogEntry(
              liquidType: log.liquidType,
              volumeMl: log.volumeMl,
              loggedAt: log.loggedAt,
            ))
        .toList();
    entries.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return entries;
  } catch (e) {
    debugPrint('🏠 todayIntakeLogs: server failed, using local: $e');
    final local = await HiveStorageService.instance.loadTodaysLogs();
    final entries = local
        .map((log) => TodayLogEntry(
              liquidType: log.liquidType,
              volumeMl: log.volumeMl,
              loggedAt: log.loggedAt,
            ))
        .toList();
    entries.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return entries;
  }
});

/// Provider for Stats Sync Repository dependency injection
/// Returns null to indicate sync is not available - app works offline-only
@riverpod
StatsSyncRepository? statsSyncRepositoryNullable(Ref ref) {
  // Sync not configured - app works in offline-only mode
  debugPrint('⚠️ Sync not configured, running offline-only mode');
  return null;
}

/// Home screen state notifier với enhanced offline-first sync
@riverpod
class HomeNotifier extends _$HomeNotifier {
  StatsSyncRepository? _statsSyncRepository;

  @override
  Future<DailySummary> build() async {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      const dailyGoalMl = 2000;
      return DailySummary(
        dailyGoalMl: dailyGoalMl,
        totalEffectiveMl: 0,
        logCount: 0,
        progress: 0.0,
        remainingMl: dailyGoalMl,
        streakDays: 0,
        xpToday: 0,
        currentLevel: 1,
        location: 'Home',
        temperatureCelsius: 25.0,
        lastUpdated: DateTime.now(),
      );
    }

    // Watch user stats refresh counter for auto-refresh when stats change
    ref.watch(userStatsRefreshProvider);

    // Initialize sync repository if available
    _statsSyncRepository = ref.read(statsSyncRepositoryNullableProvider);
    if (_statsSyncRepository == null) {
      debugPrint('💾 HomeProvider: Running in offline-only mode');
    }

    // Load summary from server first
    final summary = await _loadTodaySummary();

    // Set up listeners for provider changes after build
    _setupProviderListeners();

    // Trigger background sync if available
    _triggerBackgroundSync();

    return summary;
  }

  /// Quick log action: 100ml, 250ml, 500ml buttons
  Future<void> quickLog(int volumeMl, {String liquidType = 'water'}) async {
    final current = await future;

    // Create intake log với hydration coefficient
    final hydrationCoeff = AppConstants.hydrationCoeff[liquidType] ?? 1.0;
    final intakeLog = IntakeLog.fromQuickLog(
      volumeMl: volumeMl,
      liquidType: liquidType,
      hydrationCoeff: hydrationCoeff,
    );

    // Update state immediately (offline-first)
    final updatedSummary = _updateSummaryWithNewLog(current, intakeLog);
    state = AsyncValue.data(updatedSummary);

    // Save to local storage
    await _saveIntakeLog(intakeLog);

    // Update level system với XP và stats
    await _updateLevelSystem(intakeLog, updatedSummary);

    // Background sync to server (không chặn UI)
    _syncToServerInBackground(intakeLog);

    // Trigger enhanced sync if available
    _triggerEnhancedSync();

    // TODO: Delay refresh to avoid race condition with server sync
    // _refreshUserStats();
  }

  /// Load today's summary (server first → local fallback)
  Future<DailySummary> _loadTodaySummary() async {
    try {
      final intakeRepository = IntakeRepository();

      // Try to get fresh data from server first
      final serverSummary = await intakeRepository.getTodaySummary();

      // Get daily goal from user stats or use default
      int dailyGoalMl = 2000; // Default fallback
      try {
        final userStatsAsync = ref.read(userStatsProvider);
        userStatsAsync.whenData((userStats) {
          if (userStats.dailyGoalMl > 0) {
            dailyGoalMl = userStats.dailyGoalMl;
          }
        });
      } catch (e) {
        debugPrint('⚠️ Using default goal, user stats unavailable: $e');
      }
      final remainingMl = (dailyGoalMl - serverSummary.totalEffectiveMl).clamp(
        0,
        dailyGoalMl,
      );
      final progress = (serverSummary.totalEffectiveMl / dailyGoalMl).clamp(
        0.0,
        1.0,
      );

      // Convert server response to DailySummary (will be synced later by listeners)
      final summary = DailySummary(
        dailyGoalMl: dailyGoalMl,
        totalEffectiveMl: serverSummary.totalEffectiveMl,
        logCount: serverSummary.logCount,
        progress: progress,
        remainingMl: remainingMl,
        streakDays: 0, // Will be updated by provider listeners
        xpToday: serverSummary.totalXpEarned,
        currentLevel: 1, // Will be updated by provider listeners
        location: 'Home', // Default location
        temperatureCelsius: 25.0, // Default temperature
        lastUpdated: DateTime.now(),
      );

      // Save to local storage as cache
      await HiveStorageService.instance.saveDailySummary(summary);

      debugPrint('🏠 HomeProvider: Loaded fresh data from server');
      return summary;
    } catch (e) {
      debugPrint('🏠 HomeProvider: Server error, falling back to local: $e');

      // Fallback to local storage if server fails
      try {
        final localSummary =
            await HiveStorageService.instance.loadTodaysSummary();
        if (localSummary != null) {
          debugPrint('🏠 HomeProvider: Loaded from local storage');
          return localSummary;
        }

        // If no local data, create default summary
        const dailyGoalMl = 2000;
        return DailySummary(
          dailyGoalMl: dailyGoalMl,
          totalEffectiveMl: 0,
          logCount: 0,
          progress: 0.0,
          remainingMl: dailyGoalMl,
          streakDays: 0,
          xpToday: 0,
          currentLevel: 1,
          location: 'Home',
          temperatureCelsius: 25.0,
          lastUpdated: DateTime.now(),
        );
      } catch (localError) {
        debugPrint('🏠 HomeProvider: Local storage error: $localError');
        // Return default summary if everything fails
        const dailyGoalMl = 2000;
        return DailySummary(
          dailyGoalMl: dailyGoalMl,
          totalEffectiveMl: 0,
          logCount: 0,
          progress: 0.0,
          remainingMl: dailyGoalMl,
          streakDays: 0,
          xpToday: 0,
          currentLevel: 1,
          location: 'Home',
          temperatureCelsius: 25.0,
          lastUpdated: DateTime.now(),
        );
      }
    }
  }

  /// Update summary với new intake log
  DailySummary _updateSummaryWithNewLog(DailySummary current, IntakeLog log) {
    final newTotal = current.totalEffectiveMl + log.effectiveVolumeMl;
    final newProgress = (newTotal / current.dailyGoalMl).clamp(0.0, 1.0);
    final newRemaining = (current.dailyGoalMl - newTotal).clamp(
      0,
      current.dailyGoalMl,
    );

    return current.copyWith(
      totalEffectiveMl: newTotal,
      logCount: current.logCount + 1,
      progress: newProgress,
      remainingMl: newRemaining,
      xpToday: current.xpToday + log.xpEarned,
      lastUpdated: DateTime.now(),
    );
  }

  /// Load from Hive local storage
  Future<DailySummary?> _loadFromLocalStorage() async {
    try {
      final storage = HiveStorageService.instance;
      final localSummary = await storage.loadTodaysSummary();

      if (localSummary != null) {
        // Calculate fresh summary từ stored logs
        final todaysLogs = await storage.loadTodaysLogs();
        return _recalculateSummaryFromLogs(localSummary, todaysLogs);
      }

      return null;
    } catch (e) {
      debugPrint('❌ HomeProvider: Error loading from local storage: $e');
      return null;
    }
  }

  Future<void> _saveIntakeLog(IntakeLog log) async {
    try {
      final storage = HiveStorageService.instance;

      // Save the intake log
      await storage.saveIntakeLog(log);

      // Update and save the daily summary
      final currentSummary = await future;
      final updatedSummary = _updateSummaryWithNewLog(currentSummary, log);
      await storage.saveDailySummary(updatedSummary);

      debugPrint(
        '💾 HomeProvider: Saved log: ${log.volumeMl}ml ${log.liquidType}',
      );
    } catch (e) {
      debugPrint('❌ HomeProvider: Error saving to local storage: $e');
    }
  }

  /// Recalculate summary from stored logs để đảm bảo data consistency
  DailySummary _recalculateSummaryFromLogs(
    DailySummary baseSummary,
    List<IntakeLog> logs,
  ) {
    int totalEffective = 0;
    int totalXp = 0;

    for (final log in logs) {
      totalEffective += log.effectiveVolumeMl;
      totalXp += log.xpEarned;
    }

    final progress = (totalEffective / baseSummary.dailyGoalMl).clamp(0.0, 1.0);
    final remaining = (baseSummary.dailyGoalMl - totalEffective).clamp(
      0,
      baseSummary.dailyGoalMl,
    );

    return baseSummary.copyWith(
      totalEffectiveMl: totalEffective,
      logCount: logs.length,
      progress: progress,
      remainingMl: remaining,
      xpToday: totalXp,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update level system với new log data
  Future<void> _updateLevelSystem(IntakeLog log, DailySummary summary) async {
    try {
      final levelNotifier = ref.read(levelNotifierProvider.notifier);

      // Add XP từ log
      final hasLeveledUp = await levelNotifier.addXP(log.xpEarned);

      // Calculate new streak if goal achieved today (only once per day)
      int? newStreak;
      if (summary.progress >= 1.0) {
        try {
          // Check if we already increased streak today
          final storage = HiveStorageService.instance;

          // DEBUG: Reset streak date for testing (remove in production)
          // await storage.saveSetting('last_streak_date', null); // Clear for clean test

          final lastStreakDate =
              await storage.loadSetting<String>('last_streak_date');
          final currentStoredStreak =
              await storage.loadSetting<int>('current_streak') ?? 0;
          final today =
              DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

          debugPrint(
              '🔍 Debug: lastStreakDate = $lastStreakDate, today = $today');
          debugPrint('🔍 Debug: currentStoredStreak = $currentStoredStreak');

          if (lastStreakDate != today) {
            // First time achieving goal today - increase streak
            final currentLevelState = await levelNotifier.future;
            newStreak = currentLevelState.currentStreak + 1;

            debugPrint(
                '🔥 HomeProvider: Goal achieved for the first time today!');
            debugPrint(
                '🔥 Current level state streak: ${currentLevelState.currentStreak}');
            debugPrint('🔥 New streak will be: $newStreak');
          } else {
            debugPrint(
                '🔥 HomeProvider: Goal already achieved today, streak unchanged');
          }
        } catch (e) {
          // If can't get current streak, start from 1
          newStreak = 1;
          debugPrint(
              '🔥 HomeProvider: Goal achieved! Starting new streak: 1 day');
        }
      }

      // Update các stats khác
      await levelNotifier.updateStats(
        additionalLogs: 1,
        additionalVolume: log.effectiveVolumeMl,
        newStreak: newStreak,
        achievedGoalToday: summary.progress >= 1.0,
      );

      // Save streak date AFTER successful updateStats
      if (newStreak != null && summary.progress >= 1.0) {
        final storage = HiveStorageService.instance;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await storage.saveSetting('last_streak_date', today);
        debugPrint('💾 HomeProvider: Saved streak date: $today');
      }

      debugPrint(
        '🎮 HomeProvider: Updated level system: +${log.xpEarned}XP${hasLeveledUp ? ' (LEVEL UP!)' : ''}${newStreak != null ? ', Streak: $newStreak' : ''}',
      );
    } catch (e) {
      debugPrint('❌ HomeProvider: Error updating level system: $e');
    }
  }

  void _syncToServerInBackground(IntakeLog log) async {
    try {
      final intakeRepository = IntakeRepository();

      // Sync this intake log to server and get achievements
      final result = await intakeRepository.createIntakeLog(
        volumeMl: log.volumeMl,
        liquidType: log.liquidType,
        temperature: null, // IntakeLog model doesn't have this field
        location: null, // IntakeLog model doesn't have this field
        moodBefore: null, // IntakeLog model doesn't have this field
        source: log.source,
      );

      debugPrint('🌐 HomeProvider: Successfully synced to server: ${log.id}');

      // Log achievements if any were unlocked
      if (result.hasAchievements) {
        debugPrint(
            '🏆 HomeProvider: Unlocked ${result.achievements.length} achievements!');
        for (final achievement in result.achievements) {
          debugPrint(
              '🏆 Achievement: ${achievement.title} (+${achievement.xpReward} XP)');
        }
      }

      // Log level progress if available and update streak
      if (result.levelProgress != null) {
        final progress = result.levelProgress!;
        debugPrint(
            '📊 Level Progress: Level ${progress.currentLevel} (${progress.currentXp}/${progress.xpForNextLevel} XP)');
        debugPrint(
            '🔥 Streak Update: ${progress.currentStreak} days (Goal: ${progress.goalAchievedToday})');

        // Update current summary with fresh streak data from backend
        state.whenData((currentSummary) {
          final updatedSummary = currentSummary.copyWith(
            streakDays: progress.currentStreak,
            currentLevel: progress.currentLevel,
            xpToday: progress.currentXp,
          );
          state = AsyncValue.data(updatedSummary);
          debugPrint(
              '✅ HomeProvider: Updated streak from backend: ${progress.currentStreak} days');
        });
      }
    } catch (e) {
      debugPrint('🌐 HomeProvider: Failed to sync to server: $e');
      // Log will remain in local storage and can be synced later
    }
  }

  /// Force refresh từ server
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final freshSummary = await _loadTodaySummary();
      state = AsyncValue.data(freshSummary);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Trigger background sync when app starts
  void _triggerBackgroundSync() {
    if (_statsSyncRepository != null) {
      // Trigger sync in background without blocking UI
      Future.microtask(() async {
        try {
          await _statsSyncRepository!.syncIntakeLogs(
            since: DateTime.now().subtract(const Duration(hours: 24)),
          );
          debugPrint('✅ HomeProvider: Background intake sync completed');
        } catch (e) {
          debugPrint('⚠️ HomeProvider: Background sync failed: $e');
        }
      });
    }
  }

  /// Trigger enhanced sync after new data changes
  void _triggerEnhancedSync() {
    if (_statsSyncRepository != null) {
      // Sync latest changes immediately
      Future.microtask(() async {
        try {
          await _statsSyncRepository!.syncDailySummaries(
            since: DateTime.now().subtract(const Duration(hours: 6)),
          );
          debugPrint('✅ HomeProvider: Enhanced summary sync completed');
        } catch (e) {
          debugPrint('⚠️ HomeProvider: Enhanced sync failed: $e');
        }
      });
    }
  }

  /// Setup listeners for other providers to sync data
  void _setupProviderListeners() {
    // Listen to user stats changes and update current summary
    ref.listen(userStatsProvider, (previous, next) {
      next.when(
        data: (userStats) async {
          try {
            final currentSummary = await future;
            final updatedSummary = currentSummary.copyWith(
              streakDays: userStats.currentStreak,
              currentLevel: userStats.currentLevel,
              // Don't override daily goal if user has custom goal
              dailyGoalMl: userStats.dailyGoalMl > 0
                  ? userStats.dailyGoalMl
                  : currentSummary.dailyGoalMl,
            );

            state = AsyncValue.data(updatedSummary);
            debugPrint(
                '🏠 HomeProvider: Synced with user stats - Level: ${userStats.currentLevel}, Streak: ${userStats.currentStreak}');
          } catch (e) {
            debugPrint('❌ HomeProvider: Error syncing user stats: $e');
          }
        },
        loading: () {},
        error: (error, stack) {
          debugPrint('❌ HomeProvider: User stats error: $error');
        },
      );
    });

    // Listen to level provider changes as backup
    ref.listen(levelNotifierProvider, (previous, next) {
      next.when(
        data: (levelState) async {
          try {
            final currentSummary = await future;
            // Only update if user stats haven't provided these values yet
            if (currentSummary.streakDays == 0 ||
                currentSummary.currentLevel == 1) {
              final updatedSummary = currentSummary.copyWith(
                streakDays: currentSummary.streakDays == 0
                    ? levelState.currentStreak
                    : currentSummary.streakDays,
                currentLevel: currentSummary.currentLevel == 1
                    ? levelState.currentLevel
                    : currentSummary.currentLevel,
              );

              state = AsyncValue.data(updatedSummary);
              debugPrint(
                  '🏠 HomeProvider: Synced with level provider - Level: ${levelState.currentLevel}, Streak: ${levelState.currentStreak}');
            }
          } catch (e) {
            debugPrint('❌ HomeProvider: Error syncing level state: $e');
          }
        },
        loading: () {},
        error: (error, stack) {},
      );
    });
  }

  /// Refresh user stats and level provider to update UI with latest data
  void _refreshUserStats() {
    try {
      // Just increment refresh counter - level provider will auto-sync
      final refreshNotifier = ref.read(userStatsRefreshProvider.notifier);
      refreshNotifier.state++;

      debugPrint('📊 HomeProvider: Refreshed user stats counter');
    } catch (e) {
      debugPrint('❌ HomeProvider: Error refreshing providers: $e');
    }
  }
}

/// Provider để get HomeState từ current summary
@riverpod
HomeState homeState(HomeStateRef ref) {
  final summaryAsync = ref.watch(homeNotifierProvider);

  return summaryAsync.when(
    data: (summary) => HomeStateHelper.getHomeState(
      summary.progress,
      summary.temperatureCelsius,
    ),
    loading: () => HomeState.normalCool,
    error: (_, __) => HomeState.normalCool,
  );
}

/// Provider để check if goal met today
@riverpod
bool goalMetToday(GoalMetTodayRef ref) {
  final summaryAsync = ref.watch(homeNotifierProvider);

  return summaryAsync.when(
    data: (summary) => summary.progress >= 1.0,
    loading: () => false,
    error: (_, __) => false,
  );
}
