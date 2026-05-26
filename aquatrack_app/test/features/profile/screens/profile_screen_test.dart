import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquatrack_app/features/profile/profile_screen_redesign.dart';

/// Test ProfileScreenRedesign UI behavior
/// Focus: Daily goal shows computed value without edit button
void main() {
  group('ProfileScreenRedesign UI Tests', () {
    testWidgets('daily goal section shows computed value without edit button',
        (WidgetTester tester) async {
      // Arrange: Wrap screen in Riverpod
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreenRedesign(),
          ),
        ),
      );

      // Wait for async loading
      await tester.pump();

      // Act: Look for daily goal section
      final dailyGoalSection = find.textContaining('ml');

      // Assert: Daily goal is displayed
      expect(dailyGoalSection, findsWidgets);

      // Assert: No manual edit button for daily goal
      // Daily goal should be computed-only, not editable
      final editGoalButton = find.widgetWithText(TextButton, 'Sửa');
      expect(editGoalButton, findsNothing);

      // Verify Water Formula inputs are present for goal computation
      final bodyInfoSection = find.textContaining('Hồ sơ');
      expect(bodyInfoSection, findsWidgets);
    });
  });
}
