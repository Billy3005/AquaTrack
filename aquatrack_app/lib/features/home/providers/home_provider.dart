import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/home_state.dart';
import '../../../shared/models/daily_summary.dart';
import '../../../shared/models/intake_log.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../../level/providers/level_provider.dart';

part 'home_provider.g.dart';

/// Home screen state notifier với offline-first approach
@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<DailySummary> build() async {
    // Load from local storage first, then sync with server
    return await _loadTodaySummary();
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
  }

  /// Load today's summary (local → server fallback)
  Future<DailySummary> _loadTodaySummary() async {
    try {
      // Try loading from local storage first
      final localSummary = await _loadFromLocalStorage();
      if (localSummary != null) {
        return localSummary;
      }

      // Fallback to mock data for development
      return DailySummary.mock();
    } catch (e) {
      // Return mock data if everything fails
      return DailySummary.mock();
    }
  }

  /// Update summary với new intake log
  DailySummary _updateSummaryWithNewLog(DailySummary current, IntakeLog log) {
    final newTotal = current.totalEffectiveMl + log.effectiveVolumeMl;
    final newProgress = (newTotal / current.dailyGoalMl).clamp(0.0, 1.0);
    final newRemaining =
        (current.dailyGoalMl - newTotal).clamp(0, current.dailyGoalMl);

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
      print('❌ Error loading from local storage: $e');
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

      print('💾 Saved log: ${log.volumeMl}ml ${log.liquidType}');
    } catch (e) {
      print('❌ Error saving to local storage: $e');
    }
  }

  /// Recalculate summary from stored logs để đảm bảo data consistency
  DailySummary _recalculateSummaryFromLogs(
      DailySummary baseSummary, List<IntakeLog> logs) {
    int totalEffective = 0;
    int totalXp = 0;

    for (final log in logs) {
      totalEffective += log.effectiveVolumeMl;
      totalXp += log.xpEarned;
    }

    final progress = (totalEffective / baseSummary.dailyGoalMl).clamp(0.0, 1.0);
    final remaining = (baseSummary.dailyGoalMl - totalEffective)
        .clamp(0, baseSummary.dailyGoalMl);

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

      print(
          '🎮 Updated level system: +${log.xpEarned}XP${hasLeveledUp ? ' (LEVEL UP!)' : ''}');
    } catch (e) {
      print('❌ Error updating level system: $e');
    }
  }

  void _syncToServerInBackground(IntakeLog log) {
    // TODO: Implement API sync
    print('🌐 Background sync: ${log.id}');
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
