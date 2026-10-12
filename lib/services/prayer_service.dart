// lib/services/prayer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time.dart';
import '../utils/constants.dart';
import '../utils/env_config.dart';

class PrayerService {
  /// Validate prayer time format (HH:MM or HH:MM AM/PM)
  static bool isValidPrayerTime(String time) {
    if (time.isEmpty || time.length > 20) {
      return false;
    }

    // Basic regex for time formats: HH:MM or HH:MM AM/PM
    final timeRegex = RegExp(
      r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9](\s?(AM|PM|am|pm))?$',
    );
    return timeRegex.hasMatch(time.trim());
  }

  /// Validate iqama times map
  static void validateIqamaTimes(Map<String, String> iqamaTimes) {
    if (iqamaTimes.isEmpty) {
      throw PrayerServiceException('Iqama times cannot be empty');
    }

    for (final entry in iqamaTimes.entries) {
      if (entry.key.isEmpty) {
        throw PrayerServiceException('Prayer name cannot be empty');
      }
      if (!isValidPrayerTime(entry.value)) {
        throw PrayerServiceException(
          'Invalid time format for ${entry.key}: ${entry.value}',
        );
      }
    }
  }

  /// Fetch prayer times by coordinates from Aladhan API
  static Future<PrayerSchedule> fetchByCoordinates({
    required double latitude,
    required double longitude,
    int? method,
    int? school,
  }) async {
    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      throw PrayerServiceException(
        'Invalid latitude: must be between -90 and 90',
      );
    }
    if (longitude < -180 || longitude > 180) {
      throw PrayerServiceException(
        'Invalid longitude: must be between -180 and 180',
      );
    }

    // Validate calculation method
    if (method != null && (method < 0 || method > 23)) {
      throw PrayerServiceException(
        'Invalid calculation method: must be between 0 and 23',
      );
    }

    final apiMethod = method ?? EnvConfig.aladhanApiMethod;
    final apiSchool = school ?? EnvConfig.aladhanSchool;

    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings?latitude=$latitude&longitude=$longitude&method=$apiMethod&school=$apiSchool',
    );

    try {
      final response = await http.get(url).timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw PrayerServiceException(
          'Failed to fetch prayer times: HTTP ${response.statusCode}',
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;

      if (body['code'] != 200) {
        throw PrayerServiceException(
          'API error: ${body['status'] ?? 'Unknown error'}',
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;

      // Convert to Map<String, String>
      final timingsMap = <String, String>{};
      for (final key in timings.keys) {
        timingsMap[key] = timings[key].toString();
      }

      // Initialize iqama map with same times
      final iqamaMap = Map<String, String>.from(timingsMap);

      return PrayerSchedule(timings: timingsMap, iqamaMap: iqamaMap);
    } on PrayerServiceException {
      rethrow;
    } catch (e) {
      throw PrayerServiceException('Failed to fetch prayer times: $e');
    }
  }

  /// Fetch prayer times by city name
  static Future<PrayerSchedule> fetchByCity({
    required String city,
    required String country,
    int? method,
    int? school,
  }) async {
    // Validate city and country
    if (city.trim().isEmpty) {
      throw PrayerServiceException('City name cannot be empty');
    }
    if (country.trim().isEmpty) {
      throw PrayerServiceException('Country name cannot be empty');
    }
    if (city.length > 100) {
      throw PrayerServiceException('City name is too long');
    }
    if (country.length > 100) {
      throw PrayerServiceException('Country name is too long');
    }

    // Validate calculation method
    if (method != null && (method < 0 || method > 23)) {
      throw PrayerServiceException(
        'Invalid calculation method: must be between 0 and 23',
      );
    }

    final apiMethod = method ?? EnvConfig.aladhanApiMethod;
    final apiSchool = school ?? EnvConfig.aladhanSchool;

    final url = Uri.parse(
      'https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$apiMethod&school=$apiSchool',
    );

    try {
      final response = await http.get(url).timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw PrayerServiceException(
          'Failed to fetch prayer times: HTTP ${response.statusCode}',
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;

      if (body['code'] != 200) {
        throw PrayerServiceException(
          'API error: ${body['status'] ?? 'Unknown error'}',
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;

      // Convert to Map<String, String>
      final timingsMap = <String, String>{};
      for (final key in timings.keys) {
        timingsMap[key] = timings[key].toString();
      }

      // Initialize iqama map with same times
      final iqamaMap = Map<String, String>.from(timingsMap);

      return PrayerSchedule(timings: timingsMap, iqamaMap: iqamaMap);
    } on PrayerServiceException {
      rethrow;
    } catch (e) {
      throw PrayerServiceException('Failed to fetch prayer times: $e');
    }
  }

  /// Get sample prayer times (for testing/offline)
  static PrayerSchedule getSampleTimes() {
    return PrayerSchedule(
      timings: {
        'Fajr': '05:30',
        'Sunrise': '06:45',
        'Dhuhr': '01:00 PM',
        'Asr': '04:30 PM',
        'Maghrib': '07:15 PM',
        'Isha': '08:45 PM',
      },
      iqamaMap: {
        'Fajr': '05:30',
        'Sunrise': '06:45',
        'Dhuhr': '01:15 PM',
        'Asr': '04:45 PM',
        'Maghrib': '07:20 PM',
        'Isha': '09:00 PM',
      },
    );
  }
}

/// Custom exception for prayer service errors
class PrayerServiceException implements Exception {
  final String message;

  PrayerServiceException(this.message);

  @override
  String toString() => 'PrayerServiceException: $message';
}
