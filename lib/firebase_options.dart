// lib/firebase_options.dart
//
// Firebase client config, read from .env (FIREBASE_* values, see
// .env.example), so each masjid uses its own Firebase project without
// changing code. These values are public by design: Firestore security rules
// protect the data.
//
// Running `flutterfire configure` replaces this file with generated,
// hard-coded options; that works too.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'utils/env_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform.',
        );
    }
  }

  static String get _projectId => EnvConfig.get('FIREBASE_PROJECT_ID');
  static String get _senderId => EnvConfig.get('FIREBASE_MESSAGING_SENDER_ID');
  static String? get _bucket =>
      _orNull(EnvConfig.get('FIREBASE_STORAGE_BUCKET'));

  /// Platform API key, falling back to the web key.
  static String _apiKey(String key) {
    final value = EnvConfig.get(key);
    return value.isNotEmpty ? value : EnvConfig.get('FIREBASE_WEB_API_KEY');
  }

  static String? _orNull(String value) => value.isEmpty ? null : value;

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _apiKey('FIREBASE_WEB_API_KEY'),
    appId: EnvConfig.get('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: _orNull(EnvConfig.get('FIREBASE_AUTH_DOMAIN')),
    storageBucket: _bucket,
    measurementId: _orNull(EnvConfig.get('FIREBASE_WEB_MEASUREMENT_ID')),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _apiKey('FIREBASE_ANDROID_API_KEY'),
    appId: EnvConfig.get('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _apiKey('FIREBASE_IOS_API_KEY'),
    appId: EnvConfig.get('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
    iosBundleId: _orNull(EnvConfig.get('APP_ID')),
  );
}
