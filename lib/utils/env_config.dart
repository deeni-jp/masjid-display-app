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

  /// Get Aladhan API school (Asr calculation method)
  /// 0 = Shafi/Standard, 1 = Hanafi
  /// Default is 1 (Hanafi)
  static int get aladhanSchool {
    final schoolStr = dotenv.env['ALADHAN_SCHOOL'];
    return int.tryParse(schoolStr ?? '1') ?? 1;
  }
}
