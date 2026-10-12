// test/helpers/mock_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mock data for testing

class MockData {
  // Prayer Times
  static const Map<String, String> prayerTimings = {
    'Fajr': '05:30',
    'Sunrise': '06:45',
    'Dhuhr': '01:00 PM',
    'Asr': '04:30 PM',
    'Maghrib': '07:15 PM',
    'Isha': '08:45 PM',
  };

  static const Map<String, String> iqamaTimes = {
    'Fajr': '05:45',
    'Dhuhr': '01:15 PM',
    'Asr': '04:45 PM',
    'Maghrib': '07:20 PM',
    'Isha': '09:00 PM',
  };

  // API Response (Aladhan)
  static const Map<String, dynamic> aladhanApiResponse = {
    'code': 200,
    'status': 'OK',
    'data': {
      'timings': {
        'Fajr': '05:30',
        'Sunrise': '06:45',
        'Dhuhr': '13:00',
        'Asr': '16:30',
        'Sunset': '19:15',
        'Maghrib': '19:15',
        'Isha': '20:45',
        'Imsak': '05:20',
        'Midnight': '00:30',
      },
      'date': {'readable': '01 Jan 2024', 'timestamp': '1704067200'},
      'meta': {
        'latitude': 35.531,
        'longitude': 139.565,
        'timezone': 'Asia/Tokyo',
        'method': {'id': 2, 'name': 'Islamic Society of North America (ISNA)'},
      },
    },
  };

  static const Map<String, dynamic> aladhanApiErrorResponse = {
    'code': 400,
    'status': 'Bad Request',
    'data': null,
  };

  // User Data
  static const Map<String, dynamic> publicUser = {
    'uid': 'test_user_1',
    'email': 'user@test.com',
    'displayName': 'Test User',
    'role': 'public',
    'createdAt': '2024-01-01T00:00:00.000Z',
    'lastLogin': '2024-01-01T12:00:00.000Z',
  };

  static const Map<String, dynamic> moderatorUser = {
    'uid': 'test_mod_1',
    'email': 'moderator@test.com',
    'displayName': 'Test Moderator',
    'role': 'moderator',
    'createdAt': '2024-01-01T00:00:00.000Z',
    'lastLogin': '2024-01-01T12:00:00.000Z',
  };

  static const Map<String, dynamic> adminUser = {
    'uid': 'test_admin_1',
    'email': 'admin@test.com',
    'displayName': 'Test Admin',
    'role': 'admin',
    'createdAt': '2024-01-01T00:00:00.000Z',
    'lastLogin': '2024-01-01T12:00:00.000Z',
  };

  // Notification Data
  static Map<String, dynamic> announcement = {
    'id': 'notif_1',
    'title': 'Jumuah Khutbah',
    'message': 'This Friday\'s khutbah will be about patience.',
    'type': 'announcement',
    'priority': 'regular',
    'active': true,
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 1)),
    ),
    'expiresAt': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 6)),
    ),
    'postedBy': 'admin@test.com',
    'postedByRole': 'admin',
  };

  static Map<String, dynamic> eventNotification = {
    'id': 'notif_2',
    'title': 'Community Iftar',
    'message': 'Join us for community iftar this Saturday at 7 PM.',
    'type': 'event',
    'priority': 'high',
    'active': true,
    'eventTime': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 2)),
    ),
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 12)),
    ),
    'expiresAt': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 3)),
    ),
    'postedBy': 'moderator@test.com',
    'postedByRole': 'moderator',
  };

  static Map<String, dynamic> alertNotification = {
    'id': 'notif_3',
    'title': 'Prayer Hall Closure',
    'message': 'The main prayer hall will be closed for maintenance tomorrow.',
    'type': 'alert',
    'priority': 'high',
    'active': true,
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 2)),
    ),
    'expiresAt': Timestamp.fromDate(
      DateTime.now().add(const Duration(hours: 22)),
    ),
    'postedBy': 'admin@test.com',
    'postedByRole': 'admin',
  };

  static Map<String, dynamic> expiredNotification = {
    'id': 'notif_4',
    'title': 'Old Announcement',
    'message': 'This notification has expired.',
    'type': 'announcement',
    'priority': 'low',
    'active': true,
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 10)),
    ),
    'expiresAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 1)),
    ),
    'postedBy': 'admin@test.com',
    'postedByRole': 'admin',
  };

  // Location Data
  static const double testLatitude = 35.531;
  static const double testLongitude = 139.565;
  static const String testCity = 'Yokohama';
  static const String testCountry = 'Japan';

  // IP Geolocation Response
  static const Map<String, dynamic> ipApiResponse = {
    'status': 'success',
    'country': 'Japan',
    'countryCode': 'JP',
    'region': 'KN',
    'regionName': 'Kanagawa',
    'city': 'Yokohama',
    'zip': '224-0037',
    'lat': 35.531,
    'lon': 139.565,
    'timezone': 'Asia/Tokyo',
    'isp': 'Test ISP',
    'org': 'Test Org',
    'as': 'AS1234 Test',
    'query': '203.0.113.1',
  };

  // Storage Keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyDarkModeManual = 'dark_mode_manual';
  static const String keyDefaultLocation = 'default_location';
  static const String keyIqamaMap = 'iqama_map';
  static const String keyNotifications = 'notifications_list';
}
