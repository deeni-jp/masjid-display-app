// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Darut Tauhid Masjid';
  static const String appVersion = '1.0.0';

  // Prayer Names
  static const List<String> prayerNames = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  static const List<String> mainPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  // Timing Constants
  static const Duration countdownWarningTime = Duration(seconds: 60);
  static const Duration iqamaTransitionTime = Duration(seconds: 5);
  static const Duration blackoutDuration = Duration(minutes: 10);

  // API Configuration
  // NOTE: Method and School are now configured in .env
  // See EnvConfig.aladhanApiMethod and EnvConfig.aladhanSchool
  static const Duration apiTimeout = Duration(seconds: 10);

  // SharedPreferences Keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyDarkModeManual = 'dark_mode_manual';
  static const String keyDefaultLocation = 'default_location';
  static const String keyIqamaMap = 'iqama_map';
  static const String keyNotifications =
      'notifications_list'; // Updated key for list
  static const String keyNotificationDoc =
      'notification_doc'; // Legacy - keeping for migration
  static const String keyHijriDate = 'hijri_date_cache';

  // Firestore Collections
  static const String collectionMosque = 'mosque';
  static const String collectionNotifications =
      'notifications'; // New collection
  static const String docIqama = 'iqama';
  static const String docNotification = 'notification'; // Legacy single doc

  // Notification Settings
  static const Duration notificationRotationInterval = Duration(seconds: 5);
  static const Duration tickerRotationInterval = Duration(seconds: 4);
  static const Duration notificationCleanupInterval = Duration(minutes: 15);
  static const int maxActiveNotifications = 50;

  // Default Expiration Durations
  static const Duration defaultAnnouncementExpiry = Duration(days: 7);
  static const Duration defaultEventExpiry = Duration(days: 1); // After event
  static const Duration defaultAlertExpiry = Duration(hours: 24);
}

class AppColors {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF2D5F3F);
  static const Color primaryGreenLight = Color(0xFF4A8B5F);
  static const Color primaryGreenDark = Color(0xFF1A3A2E);

  static const Color secondaryGold = Color(0xFFD4AF37);

  // Prayer Icon Colors
  static const Color fajrColor = Color(0xFF5B8FA3);
  static const Color sunriseColor = Color(0xFF26A69A);
  static const Color dhuhrColor = Color(0xFFFF9800);
  static const Color asrColor = Color(0xFFFFC107);
  static const Color maghribColor = Color(0xFFFF5722);
  static const Color ishaColor = Color(0xFF673AB7);
  static const Color jummahColor = Color(0xFF4CAF50);

  // Notification Priority Colors
  static const Color priorityHigh = Color(0xFFE53935);
  static const Color priorityHighBg = Color(0xFFFFEBEE);
  static const Color priorityRegular = Color(0xFF1E88E5);
  static const Color priorityRegularBg = Color(0xFFE3F2FD);
  static const Color priorityLow = Color(0xFF757575);
  static const Color priorityLowBg = Color(0xFFF5F5F5);

  // Notification Type Colors
  static const Color typeAnnouncement = Color(0xFF2196F3);
  static const Color typeAnnouncementBg = Color(0xFFE3F2FD);
  static const Color typeEvent = Color(0xFF4CAF50);
  static const Color typeEventBg = Color(0xFFE8F5E9);
  static const Color typeAlert = Color(0xFFFF9800);
  static const Color typeAlertBg = Color(0xFFFFF3E0);

  // Gradient Colors
  static const List<Color> headerGradientLight = [
    primaryGreen,
    primaryGreenLight,
  ];

  static const List<Color> headerGradientDark = [
    primaryGreenDark,
    primaryGreen,
  ];

  static const List<Color> nextPrayerGradientLight = [
    Color(0xFFFFF8DC),
    Color(0xFFFFE4B5),
  ];

  static const List<Color> nextPrayerGradientDark = [
    Color(0xFF3D2F1F),
    Color(0xFF5C4A2F),
  ];

  // Ticker Colors
  static const Color tickerBackground = Color(0xFF1A1A2E);
  static const Color tickerBackgroundLight = Color(0xFFF5F5F5);
  static const Color tickerText = Colors.white;
  static const Color tickerTextLight = Color(0xFF333333);

  // Helper method to get prayer color
  static Color getPrayerColor(String prayerName) {
    final lowerName = prayerName.toLowerCase();
    if (lowerName.contains('fajr')) return fajrColor;
    if (lowerName.contains('sunrise')) return sunriseColor;
    if (lowerName.contains('dhuhr') || lowerName.contains('zuhr'))
      return dhuhrColor;
    if (lowerName.contains('asr')) return asrColor;
    if (lowerName.contains('maghrib')) return maghribColor;
    if (lowerName.contains('isha')) return ishaColor;
    if (lowerName.contains('jummah') || lowerName.contains('jumuah'))
      return jummahColor;
    return primaryGreen;
  }

  // Helper method to get prayer icon
  static IconData getPrayerIcon(String prayerName) {
    final lowerName = prayerName.toLowerCase();
    if (lowerName.contains('fajr')) return Icons.wb_twilight;
    if (lowerName.contains('sunrise')) return Icons.wb_sunny_outlined;
    if (lowerName.contains('dhuhr') || lowerName.contains('zuhr'))
      return Icons.wb_sunny;
    if (lowerName.contains('asr')) return Icons.wb_sunny_outlined;
    if (lowerName.contains('maghrib')) return Icons.wb_twilight;
    if (lowerName.contains('isha')) return Icons.nightlight_round;
    if (lowerName.contains('jummah') || lowerName.contains('jumuah'))
      return Icons.people;
    return Icons.access_time;
  }

  // Helper method to get notification type color
  static Color getNotificationTypeColor(String typeName) {
    final lowerName = typeName.toLowerCase();
    if (lowerName.contains('event')) return typeEvent;
    if (lowerName.contains('alert')) return typeAlert;
    return typeAnnouncement;
  }

  // Helper method to get notification type background color
  static Color getNotificationTypeBgColor(String typeName) {
    final lowerName = typeName.toLowerCase();
    if (lowerName.contains('event')) return typeEventBg;
    if (lowerName.contains('alert')) return typeAlertBg;
    return typeAnnouncementBg;
  }

  // Helper method to get notification type icon
  static IconData getNotificationTypeIcon(String typeName) {
    final lowerName = typeName.toLowerCase();
    if (lowerName.contains('event')) return Icons.event;
    if (lowerName.contains('alert')) return Icons.warning_amber_rounded;
    return Icons.campaign;
  }
}

class AppStyles {
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingXLarge = 24.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Ticker Height
  static const double tickerHeight = 40.0;

  // Card Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Notification Badge Style
  static BoxDecoration priorityBadgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(radiusSmall),
      border: Border.all(
        color: color.withValues(alpha: 0.5),
        width: 1,
      ),
    );
  }

  // Ticker Decoration
  static BoxDecoration tickerDecoration(bool darkMode) {
    return BoxDecoration(
      color: darkMode
          ? AppColors.tickerBackground
          : AppColors.tickerBackgroundLight,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }
}

/// Notification filter options for the notifications tab
enum NotificationFilter {
  all,
  announcements,
  events,
  alerts;

  String get displayName {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.announcements:
        return 'Announcements';
      case NotificationFilter.events:
        return 'Events';
      case NotificationFilter.alerts:
        return 'Alerts';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationFilter.all:
        return Icons.all_inbox;
      case NotificationFilter.announcements:
        return Icons.campaign;
      case NotificationFilter.events:
        return Icons.event;
      case NotificationFilter.alerts:
        return Icons.warning_amber_rounded;
    }
  }
}
