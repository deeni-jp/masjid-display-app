// lib/utils/env_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
/// Handles loading and accessing environment variables from .env file.
///
/// Everything that differs from one masjid to another (name, location,
/// Firebase project, ...) is read from here; see .env.example.
///
/// Note: .env is bundled into the app and is publicly readable on the web,
/// so it must only ever contain non-secret values.
class EnvConfig {
  /// Initialize environment configuration
  /// Must be called before accessing any environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // .env file not found or error loading
      // This is acceptable for production builds without .env
      debugPrint('Warning: .env file not found or could not be loaded: $e');
    }
  }

  /// Trimmed value of [key], or '' if it isn't set (or .env isn't loaded).
  static String get(String key) {
    if (!dotenv.isInitialized) return '';
    return dotenv.env[key]?.trim() ?? '';
  }

  static double _double(String key, double fallback) =>
      double.tryParse(get(key)) ?? fallback;

  static String _string(String key, String fallback) {
    final value = get(key);
    return value.isEmpty ? fallback : value;
  }

  /// Full masjid name, shown in the app and on the display.
  static String get masjidName => _string('MASJID_NAME', 'Masjid Prayer Times');

  /// Location used when the device location isn't available.
  static double get defaultLatitude => _double('DEFAULT_LATITUDE', 21.4225);
  static double get defaultLongitude => _double('DEFAULT_LONGITUDE', 39.8262);
  static String get defaultCity => _string('DEFAULT_CITY', 'Makkah');
  static String get defaultCountry =>
      _string('DEFAULT_COUNTRY', 'Saudi Arabia');

  /// Get Aladhan API method
  /// Default is 3 (Muslim World League)
  static int get aladhanApiMethod =>
      int.tryParse(get('ALADHAN_API_METHOD')) ?? 3;

  /// Base URL of the push worker (push-worker/), e.g.
  /// https://masjid-push.<account>.workers.dev. Empty if not configured.
  static String get pushWorkerUrl {
    final url = get('PUSH_WORKER_URL');
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// reCAPTCHA v3 site key for Firebase App Check on the web (a public key,
  /// not a secret). Empty: App Check isn't activated on the web.
  static String get appCheckWebSiteKey => get('APP_CHECK_WEB_SITE_KEY');

  /// Get Aladhan API school (Asr calculation method)
  /// 0 = Shafi/Standard, 1 = Hanafi
  /// Default is 1 (Hanafi)
  static int get aladhanSchool => int.tryParse(get('ALADHAN_SCHOOL')) ?? 1;
}
