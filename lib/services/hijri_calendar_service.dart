// lib/services/hijri_calendar_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/hijri_date.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Service for fetching and caching Islamic (Hijri) calendar dates
/// Uses Aladhan API for Gregorian to Hijri conversion
class HijriCalendarService {
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  /// Get Hijri date with smart caching
  /// Returns cached date if valid, otherwise fetches from API
  /// Falls back to stale cache on network errors
  static Future<HijriDate> getHijriDate({
    DateTime? date,
    bool forceRefresh = false,
    http.Client? client,
  }) async {
    // Try cache first (if not force refresh)
    if (!forceRefresh) {
      final cached = await getCachedHijriDate();
      if (cached != null && cached.isCacheValid) {
        return cached;
      }
    }

    // Fetch from API
    try {
      final hijriDate = await fetchHijriDate(date: date, client: client);
      await _cacheHijriDate(hijriDate);
      return hijriDate;
    } catch (e) {
      // Fallback to stale cache on error
      final cached = await getCachedHijriDate();
      if (cached != null) {
        return cached;
      }

      // No cache available, rethrow error
      throw HijriServiceException('Failed to get Hijri date: $e');
    }
  }

  /// Fetch Hijri date from Aladhan API
  /// Converts Gregorian date to Hijri using Umm Al-Qura calculation
  static Future<HijriDate> fetchHijriDate({
    DateTime? date,
    http.Client? client,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(targetDate);
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final url = Uri.parse('$_baseUrl/gToH/$dateStr');
      final response = await httpClient
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw HijriServiceException('HTTP error: ${response.statusCode}');
      }

      final body = json.decode(response.body) as Map<String, dynamic>;

      // Check API status code
      if (body['code'] != 200) {
        throw HijriServiceException('API error: ${body['status']}');
      }

      return HijriDate.fromApiResponse(body['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is HijriServiceException) {
        rethrow;
      }
      throw HijriServiceException('Network error: $e');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  /// Get cached Hijri date from storage
  /// Returns null if no cache exists or cache is corrupted
  static Future<HijriDate?> getCachedHijriDate() async {
    try {
      final raw = await StorageService.getString(AppConstants.keyHijriDate);
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return HijriDate.fromCache(json);
    } catch (e) {
      // Clear corrupted cache
      await clearCache();
      return null;
    }
  }

  /// Cache Hijri date to storage
  static Future<void> _cacheHijriDate(HijriDate date) async {
    try {
      await StorageService.setString(
        AppConstants.keyHijriDate,
        jsonEncode(date.toJson()),
      );
    } catch (e) {
      // Non-critical error, log but don't throw
      print('Failed to cache Hijri date: $e');
    }
  }

  /// Check if cached date is still valid
  /// Valid if: exists, within 24 hours, and date matches current date
  static Future<bool> isCacheValid() async {
    final cached = await getCachedHijriDate();
    return cached != null && cached.isCacheValid;
  }

  /// Clear Hijri date cache
  static Future<void> clearCache() async {
    try {
      await StorageService.remove(AppConstants.keyHijriDate);
    } catch (e) {
      print('Failed to clear Hijri cache: $e');
    }
  }
}

/// Custom exception for Hijri calendar service errors
class HijriServiceException implements Exception {
  final String message;

  HijriServiceException(this.message);

  @override
  String toString() => 'HijriServiceException: $message';
}
