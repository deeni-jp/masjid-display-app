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
  static const Duration blackoutDuration = Duration(minutes: 7);

  // API Configuration
  static const int aladhanApiMethod =
      2; // Islamic Society of North America (ISNA)
  static const Duration apiTimeout = Duration(seconds: 10);

  // SharedPreferences Keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyDarkModeManual = 'dark_mode_manual';
  static const String keyDefaultLocation = 'default_location';
  static const String keyIqamaMap = 'iqama_map';
  static const String keyNotificationDoc = 'notification_doc';

  // Firestore Collections
  static const String collectionMosque = 'mosque';
  static const String docIqama = 'iqama';
  static const String docNotification = 'notification';

  // Local Admin Credentials (for testing)
  static const String localAdminEmail = 'blank999@gmail.com';
  static const String localAdminPassword = 'qweasdzxc123';
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
    return Icons.access_time;
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

  // Card Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
