import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Abstract interface cho general storage operations
///
/// Handles storing và retrieving non-sensitive app data như user preferences,
/// settings, cached data, và other application state. Implementation sử dụng
/// SharedPreferences cho persistent storage.
abstract class StorageService {
  Future<void> initialize();

  // String operations
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  // Integer operations
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  // Boolean operations
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  // Double operations
  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);

  // List operations
  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);

  // Generic operations
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
  Future<Set<String>> getKeys();
}

/// Concrete implementation sử dụng SharedPreferences
class StorageServiceImpl implements StorageService {
  static const String _tag = 'StorageService';

  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.debug(_tag, 'StorageService initialized');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize StorageService', e);
      rethrow;
    }
  }

  /// Lazily resolve SharedPreferences so callers never depend on init order.
  Future<SharedPreferences> _prefsAsync() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // STRING OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<String?> getString(String key) async {
    try {
      final value = (await _prefsAsync()).getString(key);
      AppLogger.debug(
          _tag, 'Retrieved string for key: $key (exists: ${value != null})');
      return value;
    } catch (e) {
      AppLogger.error(_tag, 'getString error for key $key', e);
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      await (await _prefsAsync()).setString(key, value);
      AppLogger.debug(_tag, 'Stored string for key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'setString error for key $key', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // INTEGER OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<int?> getInt(String key) async {
    try {
      final value = (await _prefsAsync()).getInt(key);
      AppLogger.debug(
          _tag, 'Retrieved int for key: $key (exists: ${value != null})');
      return value;
    } catch (e) {
      AppLogger.error(_tag, 'getInt error for key $key', e);
      return null;
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      await (await _prefsAsync()).setInt(key, value);
      AppLogger.debug(_tag, 'Stored int for key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'setInt error for key $key', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // BOOLEAN OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<bool?> getBool(String key) async {
    try {
      final value = (await _prefsAsync()).getBool(key);
      AppLogger.debug(
          _tag, 'Retrieved bool for key: $key (exists: ${value != null})');
      return value;
    } catch (e) {
      AppLogger.error(_tag, 'getBool error for key $key', e);
      return null;
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      await (await _prefsAsync()).setBool(key, value);
      AppLogger.debug(_tag, 'Stored bool for key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'setBool error for key $key', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // DOUBLE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<double?> getDouble(String key) async {
    try {
      final value = (await _prefsAsync()).getDouble(key);
      AppLogger.debug(
          _tag, 'Retrieved double for key: $key (exists: ${value != null})');
      return value;
    } catch (e) {
      AppLogger.error(_tag, 'getDouble error for key $key', e);
      return null;
    }
  }

  @override
  Future<void> setDouble(String key, double value) async {
    try {
      await (await _prefsAsync()).setDouble(key, value);
      AppLogger.debug(_tag, 'Stored double for key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'setDouble error for key $key', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // LIST OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<List<String>?> getStringList(String key) async {
    try {
      final value = (await _prefsAsync()).getStringList(key);
      AppLogger.debug(_tag,
          'Retrieved string list for key: $key (exists: ${value != null})');
      return value;
    } catch (e) {
      AppLogger.error(_tag, 'getStringList error for key $key', e);
      return null;
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    try {
      await (await _prefsAsync()).setStringList(key, value);
      AppLogger.debug(_tag, 'Stored string list for key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'setStringList error for key $key', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // GENERIC OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<void> remove(String key) async {
    try {
      await (await _prefsAsync()).remove(key);
      AppLogger.debug(_tag, 'Removed key: $key');
    } catch (e) {
      AppLogger.error(_tag, 'remove error for key $key', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await (await _prefsAsync()).clear();
      AppLogger.debug(_tag, 'Cleared all stored data');
    } catch (e) {
      AppLogger.error(_tag, 'clear error', e);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final exists = (await _prefsAsync()).containsKey(key);
      AppLogger.debug(_tag, 'Key $key exists: $exists');
      return exists;
    } catch (e) {
      AppLogger.error(_tag, 'containsKey error for key $key', e);
      return false;
    }
  }

  @override
  Future<Set<String>> getKeys() async {
    try {
      final keys = (await _prefsAsync()).getKeys();
      AppLogger.debug(_tag, 'Retrieved ${keys.length} keys');
      return keys;
    } catch (e) {
      AppLogger.error(_tag, 'getKeys error', e);
      return <String>{};
    }
  }
}
