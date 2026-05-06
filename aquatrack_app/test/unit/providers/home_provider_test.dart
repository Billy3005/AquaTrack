import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aquatrack_app/features/home/providers/home_provider.dart';
import 'package:aquatrack_app/shared/models/daily_summary.dart';

void main() {
  group('HomeProvider Tests', () {
    test('goalMetToday provider handles loading state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Test should handle loading state gracefully
      final goalMet = container.read(goalMetTodayProvider);

      // Should return false during loading state
      expect(goalMet, false);
    });

    test('homeState provider handles loading state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Test should handle loading state gracefully
      final state = container.read(homeStateProvider);

      // Should return default state when data is loading
      expect(state.name, isNotEmpty);
    });

    test('DailySummary model has correct properties', () {
      final summary = DailySummary(
        dailyGoalMl: 2000,
        totalEffectiveMl: 1500,
        logCount: 5,
        progress: 0.75,
        remainingMl: 500,
        streakDays: 3,
        xpToday: 150,
        currentLevel: 2,
        location: 'Test Location',
        temperatureCelsius: 25.0,
        lastUpdated: DateTime.now(),
      );

      expect(summary.dailyGoalMl, 2000);
      expect(summary.totalEffectiveMl, 1500);
      expect(summary.progress, 0.75);
      expect(summary.xpToday, 150);
    });
  });
}
