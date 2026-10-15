import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/firebase_options.dart';
import 'package:prayer_app/utils/env_config.dart';

void main() {
  group('EnvConfig', () {
    test('uses template defaults when values are empty', () {
      dotenv.testLoad(fileInput: 'MASJID_NAME=\nDEFAULT_LATITUDE=abc\n');

      expect(EnvConfig.masjidName, 'Masjid Prayer Times');
      expect(EnvConfig.defaultLatitude, 21.4225);
      expect(EnvConfig.defaultCity, 'Makkah');
      expect(EnvConfig.aladhanApiMethod, 3);
      expect(EnvConfig.aladhanSchool, 1);
    });

    test('reads the masjid settings from .env', () {
      dotenv.testLoad(
        fileInput: '''
MASJID_NAME= Al-Noor Masjid
DEFAULT_LATITUDE=51.5072
DEFAULT_LONGITUDE=-0.1276
DEFAULT_CITY=London
ALADHAN_SCHOOL=0
PUSH_WORKER_URL=https://push.example.workers.dev/
''',
      );

      expect(EnvConfig.masjidName, 'Al-Noor Masjid');
      expect(EnvConfig.defaultLatitude, 51.5072);
      expect(EnvConfig.defaultLongitude, -0.1276);
      expect(EnvConfig.defaultCity, 'London');
      expect(EnvConfig.aladhanSchool, 0);
      expect(EnvConfig.pushWorkerUrl, 'https://push.example.workers.dev');
    });
  });

  group('DefaultFirebaseOptions', () {
    test('builds options from FIREBASE_* values', () {
      dotenv.testLoad(
        fileInput: '''
APP_ID=org.example.masjid
FIREBASE_PROJECT_ID=my-masjid
FIREBASE_MESSAGING_SENDER_ID=123
FIREBASE_WEB_API_KEY=web-key
FIREBASE_ANDROID_APP_ID=1:123:android:abc
FIREBASE_IOS_APP_ID=1:123:ios:def
''',
      );

      final android = DefaultFirebaseOptions.android;
      expect(android.projectId, 'my-masjid');
      expect(android.appId, '1:123:android:abc');
      // No Android key set: falls back to the web key.
      expect(android.apiKey, 'web-key');
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'org.example.masjid');
      expect(DefaultFirebaseOptions.web.storageBucket, isNull);
    });

    test('is empty when Firebase is not configured', () {
      dotenv.testLoad(fileInput: '');

      expect(DefaultFirebaseOptions.android.projectId, isEmpty);
      expect(DefaultFirebaseOptions.android.apiKey, isEmpty);
    });
  });
}
