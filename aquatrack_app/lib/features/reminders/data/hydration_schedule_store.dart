import 'package:uuid/uuid.dart';

import '../../../shared/storage/hive_storage_service.dart';
import '../logic/schedule_suggestion.dart';
import 'reminder_slot.dart';

/// On-device persistence for the Hydration Schedule (slots + waking window),
/// backed by the shared Hive `app_settings` box. No backend involvement.
class HydrationScheduleStore {
  static const _scheduleKey = 'hydration_schedule';
  static const _wakeKey = 'hydration_wake_minutes';
  static const _sleepKey = 'hydration_sleep_minutes';

  static const int defaultWakeMinutes = 7 * 60; // 07:00
  static const int defaultSleepMinutes = 22 * 60; // 22:00

  final HiveStorageService _storage;
  static const _uuid = Uuid();

  HydrationScheduleStore([HiveStorageService? storage])
      : _storage = storage ?? HiveStorageService.instance;

  Future<List<ReminderSlot>> loadSchedule() async {
    final raw = await _storage.loadSetting<List>(_scheduleKey);
    if (raw == null) return defaultSchedule();
    try {
      final slots = raw
          .map(
              (e) => ReminderSlot.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
      return slots;
    } catch (_) {
      return defaultSchedule();
    }
  }

  Future<void> saveSchedule(List<ReminderSlot> slots) async {
    await _storage.saveSetting(
      _scheduleKey,
      slots.map((s) => s.toJson()).toList(),
    );
  }

  Future<int> loadWakeMinutes() async =>
      await _storage.loadSetting<int>(_wakeKey) ?? defaultWakeMinutes;

  Future<int> loadSleepMinutes() async =>
      await _storage.loadSetting<int>(_sleepKey) ?? defaultSleepMinutes;

  Future<void> saveWindow(int wakeMinutes, int sleepMinutes) async {
    await _storage.saveSetting(_wakeKey, wakeMinutes);
    await _storage.saveSetting(_sleepKey, sleepMinutes);
  }

  /// Default schedule shown before the user customises anything: the suggestion
  /// over the default 07:00–22:00 window.
  List<ReminderSlot> defaultSchedule() => buildSuggestedSlots(
        wakeMinutes: defaultWakeMinutes,
        sleepMinutes: defaultSleepMinutes,
      );

  /// Turn suggested times into enabled Reminder Slots with fresh ids.
  static List<ReminderSlot> buildSuggestedSlots({
    required int wakeMinutes,
    required int sleepMinutes,
    int intervalMinutes = 120,
    ReminderTone tone = ReminderTone.friendly,
  }) {
    final times = suggestReminderTimes(
      wakeMinutes: wakeMinutes,
      sleepMinutes: sleepMinutes,
      intervalMinutes: intervalMinutes,
    );
    return times
        .map((m) => ReminderSlot.fromMinutes(m, id: _uuid.v4(), tone: tone))
        .toList();
  }

  /// Generate a fresh unique id for a manually-added slot.
  static String newId() => _uuid.v4();
}
