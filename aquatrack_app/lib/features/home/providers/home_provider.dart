import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/home_state.dart';
import '../../../core/repositories/intake_repository.dart';
import '../../../core/sync/stats_sync_repository.dart';
import '../../../core/sync/sync_service.dart';
import '../../../shared/models/daily_summary.dart';
import '../../../shared/models/intake_log.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../../level/providers/level_provider.dart';
import '../../stats/providers/stats_provider.dart';

part 'home_provider.g.dart';

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
    // Initialize sync repository if available
    _statsSyncRepository = ref.read(statsSyncRepositoryNullableProvider);
    if (_statsSyncRepository == null) {
      debugPrint('💾 HomeProvider: Running in offline-only mode');
    }

    // Load from local storage first, then trigger background sync
    final summary = await _loadTodaySummary();

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
  }

  /// Load today's summary (server first → local fallback)
  Future<DailySummary> _loadTodaySummary() async {
    try {
      final intakeRepository = IntakeRepository();

      // Try to get fresh data from server first
      final serverSummary = await intakeRepository.getTodaySummary();

      // Calculate additional fields needed for DailySummary
      const dailyGoalMl = 2000; // Default goal, should come from user settings
      final remainingMl = (dailyGoalMl - serverSummary.totalEffectiveMl).clamp(
        0,
        dailyGoalMl,
      );
      final progress = (serverSummary.totalEffectiveMl / dailyGoalMl).clamp(
        0.0,
        1.0,
      );

      // Convert server response to DailySummary
      final summary = DailySummary(
        dailyGoalMl: dailyGoalMl,
        totalEffectiveMl: serverSummary.totalEffectiveMl,
        logCount: serverSummary.logCount,
        progress: progress,
        remainingMl: remainingMl,
        streakDays: 1, // TODO: Get from server or calculate
        xpToday: serverSummary.totalXpEarned,
        currentLevel: 1, // TODO: Get from level provider
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
        final localSummary = HiveStorageService.instance.loadTodaysSummary();
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
      final localSummary = storage.loadTodaysSummary();

      if (localSummary != null) {
        // Calculate fresh summary từ stored logs
        final todaysLogs = storage.loadTodaysLogs();
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

      // Update các stats khác
      await levelNotifier.updateStats(
        additionalLogs: 1,
        additionalVolume: log.effectiveVolumeMl,
        achievedGoalToday: summary.progress >= 1.0,
      );

      debugPrint(
        '🎮 HomeProvider: Updated level system: +${log.xpEarned}XP${hasLeveledUp ? ' (LEVEL UP!)' : ''}',
      );
    } catch (e) {
      debugPrint('❌ HomeProvider: Error updating level system: $e');
    }
  }

  void _syncToServerInBackground(IntakeLog log) async {
    try {
      final intakeRepository = IntakeRepository();

      // Sync this intake log to server
      await intakeRepository.createIntakeLog(
        volumeMl: log.volumeMl,
        liquidType: log.liquidType,
        temperature: null, // IntakeLog model doesn't have this field
        location: null, // IntakeLog model doesn't have this field
        moodBefore: null, // IntakeLog model doesn't have this field
        source: log.source,
      );

      debugPrint('🌐 HomeProvider: Successfully synced to server: ${log.id}');
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
