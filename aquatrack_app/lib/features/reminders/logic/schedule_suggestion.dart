/// Pure scheduling logic for the Hydration Schedule's "Gợi ý lịch" feature.
///
/// Kept free of Flutter/Hive imports so it is unit-testable in isolation.
/// Times are expressed as minutes since local midnight (0..1439).
library;

/// Suggest evenly-spaced reminder times across the waking window
/// [wakeMinutes]..[sleepMinutes], aiming for ~[intervalMinutes] between
/// reminders.
///
/// The first time is exactly [wakeMinutes] and the last is exactly
/// [sleepMinutes]; interior times snap to the nearest 5 minutes for tidy
/// suggestions. Returns an empty list when the window is non-positive.
List<int> suggestReminderTimes({
  required int wakeMinutes,
  required int sleepMinutes,
  int intervalMinutes = 120,
}) {
  if (sleepMinutes <= wakeMinutes) return const [];

  final window = sleepMinutes - wakeMinutes;

  // Gaps of ~intervalMinutes each; at least 1 gap, capped so we never produce
  // an absurd number of reminders for a very long window.
  final gaps = (window / intervalMinutes).round().clamp(1, 11);
  final count = gaps + 1; // slots include both endpoints
  final spacing = window / gaps;

  final times = <int>[];
  for (var i = 0; i < count; i++) {
    final int t;
    if (i == 0) {
      t = wakeMinutes;
    } else if (i == count - 1) {
      t = sleepMinutes;
    } else {
      final raw = wakeMinutes + spacing * i;
      t = (raw / 5).round() * 5; // snap to nearest 5 minutes
    }
    // Guard against rounding collisions keeping the list strictly increasing.
    if (times.isEmpty || t > times.last) times.add(t);
  }
  return times;
}
