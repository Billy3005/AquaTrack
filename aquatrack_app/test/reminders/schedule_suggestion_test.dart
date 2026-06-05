import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_app/features/reminders/logic/schedule_suggestion.dart';

void main() {
  group('suggestReminderTimes', () {
    test('spreads across a 7:00–22:00 window at ~2h cadence', () {
      final times = suggestReminderTimes(
        wakeMinutes: 7 * 60, // 420
        sleepMinutes: 22 * 60, // 1320
        intervalMinutes: 120,
      );

      // Endpoints are exact wake/sleep.
      expect(times.first, 7 * 60);
      expect(times.last, 22 * 60);

      // ~2h cadence over 15h => 9 slots (8 gaps of ~112min).
      expect(times.length, 9);

      // Strictly increasing.
      for (var i = 1; i < times.length; i++) {
        expect(times[i] > times[i - 1], isTrue);
      }

      // Interior slots snap to 5-minute boundaries.
      for (var i = 1; i < times.length - 1; i++) {
        expect(times[i] % 5, 0);
      }

      // Each gap stays near the target interval.
      for (var i = 1; i < times.length; i++) {
        final gap = times[i] - times[i - 1];
        expect(gap, inInclusiveRange(90, 140));
      }
    });

    test('returns empty when the window is non-positive', () {
      expect(
        suggestReminderTimes(wakeMinutes: 22 * 60, sleepMinutes: 7 * 60),
        isEmpty,
      );
      expect(
        suggestReminderTimes(wakeMinutes: 8 * 60, sleepMinutes: 8 * 60),
        isEmpty,
      );
    });

    test('a short window yields just the two endpoints', () {
      final times = suggestReminderTimes(
        wakeMinutes: 7 * 60, // 420
        sleepMinutes: 8 * 60, // 480
        intervalMinutes: 120,
      );
      expect(times, [7 * 60, 8 * 60]);
    });
  });
}
