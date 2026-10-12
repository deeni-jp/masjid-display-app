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

  // ============ NOTIFICATIONS (NEW - LIST BASED) ============

  /// Get all cached notifications
  static Future<List<MosqueNotification>> getNotifications() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(AppConstants.keyNotifications);

    if (raw == null || raw.isEmpty) {
      // Try to migrate from legacy single notification
      final legacyNotification = await _getLegacyNotification();
      if (legacyNotification != null && legacyNotification.hasContent) {
        return [legacyNotification];
      }
      return [];
    }

    try {
      final parsed = json.decode(raw) as List<dynamic>;
      final notifications =
          parsed
              .map(
                (item) =>
                    MosqueNotification.fromMap(item as Map<String, dynamic>),
              )
              .where((n) => !n.isExpired) // Filter out expired
              .toList();

      return notifications;
    } catch (e) {
      // Invalid JSON, return empty list
      return [];
    }
  }

  /// Get active (non-expired) notifications
  static Future<List<MosqueNotification>> getActiveNotifications() async {
    final notifications = await getNotifications();
    return notifications.activeOnly;
  }

  /// Get high priority notifications
  static Future<List<MosqueNotification>> getHighPriorityNotifications() async {
    final notifications = await getNotifications();
    return notifications.highPriorityOnly.sortedByExpiry;
  }

  /// Get notifications for ticker (excluding high priority)
  static Future<List<MosqueNotification>> getTickerNotifications() async {
    final notifications = await getNotifications();
    return notifications.excludingHighPriority;
  }

  /// Get the priority notification (high priority, closest to expiry)
  static Future<MosqueNotification?> getPriorityNotification() async {
    final notifications = await getNotifications();
    return notifications.priorityNotification;
  }

  /// Save notifications list to cache
  static Future<void> saveNotifications(
    List<MosqueNotification> notifications,
  ) async {
    final prefs = await _getPrefs();

    // Filter out expired notifications before saving
    final activeNotifications =
        notifications.where((n) => !n.isExpired).toList();

    final jsonList = activeNotifications.map((n) => n.toMap()).toList();
    await prefs.setString(AppConstants.keyNotifications, json.encode(jsonList));
  }

  /// Add a single notification to cache
  static Future<void> addNotification(MosqueNotification notification) async {
    final notifications = await getNotifications();

    // Check if notification already exists
    final existingIndex = notifications.indexWhere(
      (n) => n.id == notification.id,
    );
    if (existingIndex >= 0) {
      notifications[existingIndex] = notification;
    } else {
      notifications.add(notification);
    }

    await saveNotifications(notifications);
  }

  /// Update a notification in cache
  static Future<void> updateNotification(
    MosqueNotification notification,
  ) async {
    final notifications = await getNotifications();

    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      notifications[index] = notification;
      await saveNotifications(notifications);
    }
  }

  /// Remove a notification from cache
  static Future<void> removeNotification(String id) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == id);
    await saveNotifications(notifications);
  }

  /// Clear all cached notifications
  static Future<void> clearNotifications() async {
    final prefs = await _getPrefs();
    await prefs.remove(AppConstants.keyNotifications);
  }

  /// Clean up expired notifications from cache
  static Future<int> cleanupExpiredNotifications() async {
    final notifications = await getNotifications();
    final activeCount = notifications.activeOnly.length;
    final totalCount = notifications.length;

    // Save only active notifications
    await saveNotifications(notifications.activeOnly);

    return totalCount - activeCount;
  }

  /// Get notification by ID
  static Future<MosqueNotification?> getNotificationById(String id) async {
    final notifications = await getNotifications();
    try {
      return notifications.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  // ============ LEGACY NOTIFICATION SUPPORT ============

  /// Get legacy cached notification (single document)
  static Future<MosqueNotification?> _getLegacyNotification() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(AppConstants.keyNotificationDoc);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final notification = MosqueNotification.fromJsonString(raw);
      return notification;
    } catch (e) {
      return null;
    }
  }

  /// Migrate legacy notification to new list format
  static Future<void> migrateLegacyNotification() async {
    try {
      final legacy = await _getLegacyNotification();
      if (legacy != null && legacy.hasContent) {
        // Add to new list
        await addNotification(
          legacy.copyWith(
            id: 'legacy_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.announcement,
            priority: NotificationPriority.regular,
            expiresAt: DateTime.now().add(
              AppConstants.defaultAnnouncementExpiry,
            ),
          ),
        );

        // Clear legacy storage
        final prefs = await _getPrefs();
        await prefs.remove(AppConstants.keyNotificationDoc);
      }
    } catch (e) {
      // Ignore migration errors
    }
  }

  /// Get legacy notification (deprecated - for backward compatibility)
  @Deprecated('Use getNotifications or getPriorityNotification instead')
  static Future<MosqueNotification> getNotification() async {
    final priority = await getPriorityNotification();
    if (priority != null) return priority;

    final notifications = await getNotifications();
    if (notifications.isNotEmpty) return notifications.first;

    return MosqueNotification.empty();
  }

  /// Save legacy notification (deprecated - redirects to new system)
  @Deprecated('Use saveNotifications or addNotification instead')
  static Future<void> saveNotification(MosqueNotification notification) async {
    await addNotification(notification);
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
