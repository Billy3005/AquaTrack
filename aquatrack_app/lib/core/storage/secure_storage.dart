import 'package:hive/hive.dart';

import '../config/app_config.dart';
import '../utils/logger.dart';

import '../network/api_client.dart' show TokenStorage;

/// Abstract interface cho secure storage operations
///
/// Handles storing và retrieving sensitive data như authentication tokens,
/// credentials, và other secure information. Implementation sẽ được upgrade
/// to sử dụng platform-specific secure storage sau.
abstract class SecureStorage implements TokenStorage {
  Future<void> initialize();

  /// Token management
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> clearTokens();

  /// Generic secure storage
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
  Future<void> clear();

  /// Check if data exists
  Future<bool> containsKey(String key);

  /// Get all keys
  Future<List<String>> getAllKeys();
}

/// Persistent implementation backed by Hive.
///
/// Uses the same Hive box ('auth_storage') và keys as the legacy AuthService
/// so tokens stay valid across the migration và survive app restarts.
/// Note: Hive is not encrypted-at-rest; swap to flutter_secure_storage if the
/// app later requires hardware-backed secure storage.
class SecureStorageImpl implements SecureStorage {
  static const String _tag = 'SecureStorage';
  static const String _boxName = 'auth_storage';
  // Reuse legacy keys so old và new auth stacks share the same tokens.
  static const String _accessTokenKey = AppConfig.accessTokenKey;
  static const String _refreshTokenKey = AppConfig.refreshTokenKey;

  Box? _box;

  /// Lazily open the Hive box so callers never have to depend on init order.
  Future<Box> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> initialize() async {
    await _ensureBox();
    AppLogger.debug(_tag, 'Hive-backed secure storage initialized');
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<String?> getAccessToken() async {
    return await getString(_accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await getString(_refreshTokenKey);
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await setString(_accessTokenKey, token);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await setString(_refreshTokenKey, token);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      remove(_accessTokenKey),
      remove(_refreshTokenKey),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // GENERIC SECURE STORAGE
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<String?> getString(String key) async {
    try {
      final box = await _ensureBox();
      return box.get(key) as String?;
    } catch (e) {
      AppLogger.error(_tag, 'getString error for key $key', e);
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      final box = await _ensureBox();
      await box.put(key, value);
      AppLogger.debug(_tag, 'Stored value for key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'setString error for key $key', e);
      rethrow;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final box = await _ensureBox();
      await box.delete(key);
      AppLogger.debug(_tag, 'Removed key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'remove error for key $key', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final box = await _ensureBox();
      await box.clear();
      AppLogger.debug(_tag, 'Cleared all data');
    } catch (e) {
      AppLogger.error(_tag, 'clear error', e);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final box = await _ensureBox();
      return box.containsKey(key);
    } catch (e) {
      AppLogger.error(_tag, 'containsKey error for key $key', e);
      return false;
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    try {
      final box = await _ensureBox();
      return box.keys.map((k) => k.toString()).toList();
    } catch (e) {
      AppLogger.error(_tag, 'getAllKeys error', e);
      return [];
    }
  }
}