// lib/services/prayer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time.dart';
import '../utils/constants.dart';

class PrayerService {
  /// Fetch prayer times by coordinates from Aladhan API
  static Future<PrayerSchedule> fetchByCoordinates({
    required double latitude,
    required double longitude,
    int? method,
  }) async {
    final apiMethod = method ?? AppConstants.aladhanApiMethod;

    final url = Uri.parse(
        'https://api.aladhan.com/v1/timings?latitude=$latitude&longitude=$longitude&method=$apiMethod');

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

      return PrayerSchedule(
        timings: timingsMap,
        iqamaMap: iqamaMap,
      );
    } on PrayerServiceException {
      rethrow;
    } catch (e) {
      throw PrayerServiceException(
        'Failed to fetch prayer times: $e',
      );
    }
  }

  /// Fetch prayer times by city name
  static Future<PrayerSchedule> fetchByCity({
    required String city,
    required String country,
    int? method,
  }) async {
    final apiMethod = method ?? AppConstants.aladhanApiMethod;

    final url = Uri.parse(
        'https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$apiMethod');

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

      return PrayerSchedule(
        timings: timingsMap,
        iqamaMap: iqamaMap,
      );
    } on PrayerServiceException {
      rethrow;
    } catch (e) {
      throw PrayerServiceException(
        'Failed to fetch prayer times: $e',
      );
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
