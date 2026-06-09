import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquatrack_app/core/services/auth_service.dart' as legacy;
import 'package:aquatrack_app/core/storage/secure_storage.dart';
import 'package:aquatrack_app/core/storage/storage_service.dart';
import 'package:aquatrack_app/features/auth/data/auth_storage.dart';
import 'package:aquatrack_app/features/auth/domain/entities/user.dart';

/// Regression tests for the auth storage foundation.
///
/// The previous implementation kept tokens in a per-instance in-memory Map and
/// serialized the user with `map.toString()` (un-parseable). That meant the
/// user was logged out on every restart. These tests assert the data now
/// survives being read back through brand-new storage instances, which is the
/// proxy for an app restart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('aquatrack_auth_test');
    Hive.init(tempDir.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AuthStorage newStorage() => AuthStorageImpl(
        secureStorage: SecureStorageImpl(),
        storageService: StorageServiceImpl(),
      );

  const testUser = User(
    id: 'user-1',
    email: 'alice@example.com',
    username: 'alice',
    fullName: 'Alice Nguyen',
    currentLevel: 7,
    totalXp: 1234,
    dailyGoalMl: 2500,
  );

  test('tokens persist across new storage instances (restart sim)', () async {
    final storage = newStorage();
    await storage.saveTokens(
      accessToken: 'access-123',
      refreshToken: 'refresh-456',
    );

    // Brand-new instance == fresh objects, no shared in-memory state.
    final fresh = newStorage();
    expect(await fresh.getAccessToken(), 'access-123');
    expect(await fresh.getRefreshToken(), 'refresh-456');
  });

  test('user round-trips through JSON and persists', () async {
    final storage = newStorage();
    await storage.saveUser(testUser);

    final restored = await newStorage().getStoredUser();
    expect(restored, isNotNull);
    expect(restored!.id, 'user-1');
    expect(restored.username, 'alice');
    expect(restored.fullName, 'Alice Nguyen');
    expect(restored.currentLevel, 7);
    expect(restored.totalXp, 1234);
    expect(restored.dailyGoalMl, 2500);
  });

  test('isAuthenticated true only when both token and user present', () async {
    final storage = newStorage();
    expect(await storage.isAuthenticated(), false);

    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
    expect(await newStorage().isAuthenticated(), false,
        reason: 'token without user is not authenticated');

    await storage.saveUser(testUser);
    expect(await newStorage().isAuthenticated(), true);
  });

  test('clearAllData removes tokens and user', () async {
    final storage = newStorage();
    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
    await storage.saveUser(testUser);
    expect(await newStorage().isAuthenticated(), true);

    await storage.clearAllData();

    final fresh = newStorage();
    expect(await fresh.getAccessToken(), isNull);
    expect(await fresh.getStoredUser(), isNull);
    expect(await fresh.isAuthenticated(), false);
  });

  // Regression for the cross-stack user_data split: the new auth stack must
  // write user_data where the legacy AuthService reads it, so getCurrentUserId()
  // (used by HiveStorageService scoping, coach sessions, etc.) is correct right
  // after a new-stack login — not null until Profile incidentally back-fills it.
  test('legacy AuthService.getCurrentUserId sees new-stack saveUser', () async {
    await newStorage().saveUser(testUser);

    final legacyAuth = legacy.AuthService();
    await legacyAuth.initialize();

    expect(await legacyAuth.getCurrentUserId(), 'user-1');
  });

  test('clearUserData hides the user from legacy AuthService too', () async {
    final storage = newStorage();
    await storage.saveUser(testUser);
    await storage.clearUserData();

    final legacyAuth = legacy.AuthService();
    await legacyAuth.initialize();

    expect(await legacyAuth.getCurrentUserId(), isNull);
  });
}
