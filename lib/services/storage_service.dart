// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  /// Initialize storage service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (lazy load)
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ THEME SETTINGS ============

  /// Get dark mode preference
  static Future<bool> getDarkMode() async {
    final prefs = await _getPrefs();
    return prefs.getBool(AppConstants.keyDarkMode) ?? false;
  }

  /// Save dark mode preference
  static Future<void> setDarkMode(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(AppConstants.keyDarkMode, value);
  }

  /// Get dark mode manual override status
  static Future<bool> getDarkModeManual() async {
    final prefs = await _getPrefs();
    return prefs.getBool(AppConstants.keyDarkModeManual) ?? false;
  }

  /// Save dark mode manual override status
  static Future<void> setDarkModeManual(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(AppConstants.keyDarkModeManual, value);
  }

  // ============ LOCATION SETTINGS ============

  /// Get default location
  static Future<String> getDefaultLocation() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyDefaultLocation) ?? '';
  }

  /// Save default location
  static Future<void> setDefaultLocation(String location) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyDefaultLocation, location);
  }

  // ============ IQAMA TIMES ============

  /// Get cached iqama times
  static Future<Map<String, String>> getIqamaTimes() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(AppConstants.keyIqamaMap);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final parsed = json.decode(raw) as Map<String, dynamic>;
      return parsed.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // Invalid JSON, return empty map
      return {};
    }
  }

  /// Save iqama times to cache
  static Future<void> saveIqamaTimes(Map<String, String> iqamaMap) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyIqamaMap, json.encode(iqamaMap));
  }

  /// Clear cached iqama times
  static Future<void> clearIqamaTimes() async {
    final prefs = await _getPrefs();
    await prefs.remove(AppConstants.keyIqamaMap);
  }

  // ============ NOTIFICATIONS ============

  /// Get cached notification
  static Future<MosqueNotification> getNotification() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(AppConstants.keyNotificationDoc);

    if (raw == null || raw.isEmpty) {
      return MosqueNotification.empty();
    }

    try {
      return MosqueNotification.fromJsonString(raw);
    } catch (e) {
      // Invalid JSON, return empty notification
      return MosqueNotification.empty();
    }
  }

  /// Save notification to cache
  static Future<void> saveNotification(MosqueNotification notification) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      AppConstants.keyNotificationDoc,
      notification.toJsonString(),
    );
  }

  /// Clear cached notification
  static Future<void> clearNotification() async {
    final prefs = await _getPrefs();
    await prefs.remove(AppConstants.keyNotificationDoc);
  }

  // ============ GENERIC HELPERS ============

  /// Get string value
  static Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  /// Set string value
  static Future<void> setString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  /// Get int value
  static Future<int?> getInt(String key) async {
    final prefs = await _getPrefs();
    return prefs.getInt(key);
  }

  /// Set int value
  static Future<void> setInt(String key, int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(key, value);
  }

  /// Get bool value
  static Future<bool?> getBool(String key) async {
    final prefs = await _getPrefs();
    return prefs.getBool(key);
  }

  /// Set bool value
  static Future<void> setBool(String key, bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(key, value);
  }

  /// Get double value
  static Future<double?> getDouble(String key) async {
    final prefs = await _getPrefs();
    return prefs.getDouble(key);
  }

  /// Set double value
  static Future<void> setDouble(String key, double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(key, value);
  }

  /// Remove a key
  static Future<void> remove(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  /// Check if key exists
  static Future<bool> containsKey(String key) async {
    final prefs = await _getPrefs();
    return prefs.containsKey(key);
  }

  /// Get all keys
  static Future<Set<String>> getAllKeys() async {
    final prefs = await _getPrefs();
    return prefs.getKeys();
  }

  // ============ BULK OPERATIONS ============

  /// Save multiple key-value pairs
  static Future<void> saveMultiple(Map<String, dynamic> data) async {
    final prefs = await _getPrefs();

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    }
  }

  /// Remove multiple keys
  static Future<void> removeMultiple(List<String> keys) async {
    final prefs = await _getPrefs();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
