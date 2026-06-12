import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquatrack_app/core/di/app_providers.dart';
import 'package:aquatrack_app/core/network/api_client.dart';
import 'package:aquatrack_app/features/profile/profile_screen_redesign.dart';

/// No-network ApiClient: returns empty successful responses immediately so the
/// widget under test never starts a real HTTP request (which would leave a
/// pending timeout timer and trip the framework's `!timersPending` assertion).
class _NoNetworkApiClient implements ApiClient {
  ApiResponse<T> _empty<T>() => ApiResponse<T>(statusCode: 200, message: 'ok');

  @override
  Future<ApiResponse<T>> get<T>(String endpoint,
          {Map<String, dynamic>? queryParams,
          T Function(dynamic)? fromJson}) async =>
      _empty<T>();

  @override
  Future<ApiResponse<T>> post<T>(String endpoint,
          {dynamic data, T Function(dynamic)? fromJson}) async =>
      _empty<T>();

  @override
  Future<ApiResponse<T>> put<T>(String endpoint,
          {dynamic data, T Function(dynamic)? fromJson}) async =>
      _empty<T>();

  @override
  Future<ApiResponse<T>> delete<T>(String endpoint,
          {T Function(dynamic)? fromJson}) async =>
      _empty<T>();

  // initialize/dispose/setAuthToken/upload/download/testConnection are unused
  // in this widget path; return harmless defaults.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Test ProfileScreenRedesign UI behavior
/// Focus: Daily goal shows computed value without edit button
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  // The screen loads the profile provider which reads the Hive-backed token
  // store via the network layer. Provide Hive + SharedPreferences so async
  // loads degrade gracefully instead of throwing into the test zone.
  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('aquatrack_profilescreen_test');
    Hive.init(tempDir.path);
    await Hive.openBox('auth_storage');
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ProfileScreenRedesign UI Tests', () {
    testWidgets('daily goal section shows computed value without edit button',
        (WidgetTester tester) async {
      // Arrange: Wrap screen in Riverpod with a no-network ApiClient so the
      // profile fetch fails fast instead of leaving a pending request timer.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_NoNetworkApiClient()),
          ],
          child: const MaterialApp(
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
