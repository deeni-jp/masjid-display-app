// lib/utils/env_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
/// Handles loading and accessing environment variables from .env file
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

  /// Get Aladhan API method
  /// Default is 3 (Muslim World League)
  static int get aladhanApiMethod {
    final methodStr = dotenv.env['ALADHAN_API_METHOD'];
    return int.tryParse(methodStr ?? '3') ?? 3;
  }

  /// Base URL of the push worker (push-worker/), e.g.
  /// https://dticc-push.<account>.workers.dev. Empty if not configured.
  ///
  /// Note: .env is bundled into the app and is publicly readable on the web,
  /// so it must only ever contain non-secret values like this one.
  static String get pushWorkerUrl {
    final url = dotenv.env['PUSH_WORKER_URL']?.trim() ?? '';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// reCAPTCHA v3 site key for Firebase App Check on the web (a public key,
  /// not a secret). Empty: App Check isn't activated on the web.
  static String get appCheckWebSiteKey =>
      dotenv.env['APP_CHECK_WEB_SITE_KEY']?.trim() ?? '';

  /// Get Aladhan API school (Asr calculation method)
  /// 0 = Shafi/Standard, 1 = Hanafi
  /// Default is 1 (Hanafi)
  static int get aladhanSchool {
    final schoolStr = dotenv.env['ALADHAN_SCHOOL'];
    return int.tryParse(schoolStr ?? '1') ?? 1;
  }
}
