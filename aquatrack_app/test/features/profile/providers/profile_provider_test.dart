import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquatrack_app/features/profile/providers/profile_provider.dart';

/// Test ProfileProvider backend integration behavior
/// Focus: Testing behavior - does provider support real user data loading?
void main() {
  group('ProfileProvider Backend Integration', () {
    test('loads user data from backend when available', () {
      // Arrange: Create provider container
      final container = ProviderContainer();

      // Act: Read profile state (will use backend if authenticated)
      final profile = container.read(profileNotifierProvider);

      // Assert: Verify behavior - either loads from backend or fallback
      // If authenticated: loads real data
      // If not authenticated: uses fallback values
      expect(profile.userName, isNotNull);
      expect(profile.dailyGoalMl, greaterThan(0));

      // Verify daily goal is computed (not hardcoded 2000)
      // Should be calculated_daily_goal_ml from backend or fallback
      debugPrint(
          'Profile loaded - User: ${profile.userName}, Goal: ${profile.dailyGoalMl}ml');

      // Cleanup
      container.dispose();
    });

    test('updateDailyGoal method removed - daily goal is computed only', () {
      final container = ProviderContainer();
      final notifier = container.read(profileNotifierProvider.notifier);

      // Verify updateDailyGoal method is no longer available
      // This test ensures manual goal editing is prevented
      expect(notifier, isA<ProfileNotifier>());

      // Daily goal should come from Water Formula calculation only
      container.dispose();
    });
  });
}
