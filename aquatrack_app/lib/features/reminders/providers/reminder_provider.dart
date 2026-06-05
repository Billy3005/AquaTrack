import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hydration_schedule_store.dart';
import '../data/reminder_slot.dart';
import '../services/local_notification_service.dart';

/// Immutable UI state for the Hydration Schedule.
@immutable
class ReminderState {
  final List<ReminderSlot> slots;
  final int wakeMinutes;
  final int sleepMinutes;
  final bool permissionGranted;
  final bool loading;

  const ReminderState({
    this.slots = const [],
    this.wakeMinutes = HydrationScheduleStore.defaultWakeMinutes,
    this.sleepMinutes = HydrationScheduleStore.defaultSleepMinutes,
    this.permissionGranted = false,
    this.loading = true,
  });

  int get activeCount => slots.where((s) => s.enabled).length;
  bool get hasEnabled => slots.any((s) => s.enabled);

  /// True when reminders are configured but the OS will not deliver them.
  bool get blockedByPermission => hasEnabled && !permissionGranted && !loading;

  ReminderState copyWith({
    List<ReminderSlot>? slots,
    int? wakeMinutes,
    int? sleepMinutes,
    bool? permissionGranted,
    bool? loading,
  }) {
    return ReminderState(
      slots: slots ?? this.slots,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      loading: loading ?? this.loading,
    );
  }
}

final reminderProvider =
    NotifierProvider<ReminderNotifier, ReminderState>(ReminderNotifier.new);

class ReminderNotifier extends Notifier<ReminderState> {
  final HydrationScheduleStore _store = HydrationScheduleStore();
  final LocalNotificationService _service = LocalNotificationService.instance;

  @override
  ReminderState build() {
    _load();
    return const ReminderState();
  }

  Future<void> _load() async {
    try {
      final slots = await _store.loadSchedule();
      final wake = await _store.loadWakeMinutes();
      final sleep = await _store.loadSleepMinutes();

      bool granted = false;
      try {
        granted = await _service.hasPermission();
      } catch (e) {
        debugPrint('🔔 ReminderProvider: hasPermission failed: $e');
      }

      state = ReminderState(
        slots: _sorted(slots),
        wakeMinutes: wake,
        sleepMinutes: sleep,
        permissionGranted: granted,
        loading: false,
      );

      // Keep the OS in sync with what we persisted (no prompt on load).
      if (granted && state.hasEnabled) {
        await _safeSync();
      }
    } catch (e) {
      // Storage unavailable (e.g. in tests): degrade to defaults rather than
      // throwing from the fire-and-forget loader.
      debugPrint('🔔 ReminderProvider: load failed: $e');
      state = state.copyWith(loading: false);
    }
  }

  List<ReminderSlot> _sorted(List<ReminderSlot> slots) =>
      [...slots]..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));

  Future<void> toggleSlot(String id) async {
    final slots = state.slots
        .map((s) => s.id == id ? s.copyWith(enabled: !s.enabled) : s)
        .toList();
    await _commit(slots);
  }

  Future<void> updateSlot(
    String id, {
    required int hour,
    required int minute,
    required ReminderTone tone,
  }) async {
    final slots = state.slots
        .map((s) =>
            s.id == id ? s.copyWith(hour: hour, minute: minute, tone: tone) : s)
        .toList();
    await _commit(slots);
  }

  Future<void> addSlot({
    required int hour,
    required int minute,
    ReminderTone tone = ReminderTone.friendly,
  }) async {
    final slot = ReminderSlot(
      id: HydrationScheduleStore.newId(),
      hour: hour,
      minute: minute,
      tone: tone,
    );
    await _commit([...state.slots, slot]);
  }

  Future<void> removeSlot(String id) async {
    final slots = state.slots.where((s) => s.id != id).toList();
    await _commit(slots);
  }

  /// Replace the whole schedule with a fresh suggestion over [wakeMinutes]..
  /// [sleepMinutes] and remember the window.
  Future<void> applySuggestion({
    required int wakeMinutes,
    required int sleepMinutes,
  }) async {
    final slots = HydrationScheduleStore.buildSuggestedSlots(
      wakeMinutes: wakeMinutes,
      sleepMinutes: sleepMinutes,
    );
    await _store.saveWindow(wakeMinutes, sleepMinutes);
    state =
        state.copyWith(wakeMinutes: wakeMinutes, sleepMinutes: sleepMinutes);
    await _commit(slots);
  }

  /// Re-request notification permission (e.g. from the "đang tắt" hint) and
  /// resync if it becomes granted.
  Future<void> ensurePermission() async {
    var granted = state.permissionGranted;
    try {
      granted = await _service.requestPermission();
    } catch (e) {
      debugPrint('🔔 ReminderProvider: ensurePermission failed: $e');
    }
    state = state.copyWith(permissionGranted: granted);
    await _safeSync();
  }

  /// Persist [slots], ensure permission if anything is enabled, then resync.
  Future<void> _commit(List<ReminderSlot> slots) async {
    final sorted = _sorted(slots);
    state = state.copyWith(slots: sorted);
    await _store.saveSchedule(sorted);

    var granted = state.permissionGranted;
    if (state.hasEnabled && !granted) {
      try {
        granted = await _service.requestPermission();
      } catch (e) {
        debugPrint('🔔 ReminderProvider: requestPermission failed: $e');
      }
      state = state.copyWith(permissionGranted: granted);
    }

    await _safeSync();
  }

  Future<void> _safeSync() async {
    try {
      if (state.permissionGranted) {
        await _service.syncSchedule(state.slots);
      } else {
        await _service.cancelAll();
      }
    } catch (e) {
      debugPrint('🔔 ReminderProvider: syncSchedule failed: $e');
    }
  }
}
