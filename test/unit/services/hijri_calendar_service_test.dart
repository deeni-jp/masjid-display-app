// test/unit/services/hijri_calendar_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:prayer_app/models/hijri_date.dart';
import 'package:prayer_app/services/hijri_calendar_service.dart';
import 'package:prayer_app/services/storage_service.dart';
import 'package:prayer_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hijri_calendar_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HijriCalendarService', () {
    late MockClient mockClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockClient = MockClient();
    });

    group('API Fetching', () {
      test('successful API fetch creates HijriDate with correct URL format',
          () async {
        // Arrange
        final testDate = DateTime(2025, 12, 3);
        final responseBody = '''
{
  "code": 200,
  "status": "OK",
  "data": {
    "hijri": {
      "day": "02",
      "month": {
        "number": 6,
        "en": "Jumada al-Akhirah",
        "ar": "Jumada al-Akhirah"
      },
      "year": "1447",
      "weekday": {
        "en": "Wednesday",
        "ar": "Wednesday"
      }
    },
    "gregorian": {
      "date": "03-12-2025"
    }
  }
}''';

        when(mockClient.get(any)).thenAnswer(
            (_) async => http.Response(responseBody, 200));

        // Act
        final result = await HijriCalendarService.fetchHijriDate(
          date: testDate,
          client: mockClient,
        );

        // Assert
        expect(result.day, 2);
        expect(result.month, 6);
        expect(result.year, 1447);
        expect(result.monthNameEnglish, 'Jumada al-Akhirah');
        expect(result.weekdayNameEnglish, 'Wednesday');
        final captured = verify(mockClient.get(captureAny)).captured;
        expect(captured.length, 1);
        expect(captured[0].toString(),
            'https://api.aladhan.com/v1/gToH/03-12-2025');
      });

      test('null date defaults to today', () async {
        // Arrange
        final now = DateTime.now();
        final dateStr = '${now.day.toString().padLeft(2, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.year}';

        final responseBody = '''
{
  "code": 200,
  "status": "OK",
  "data": {
    "hijri": {
      "day": "02",
      "month": {
        "number": 6,
        "en": "Jumada al-Akhirah",
        "ar": "Jumada al-Akhirah"
      },
      "year": "1447",
      "weekday": {
        "en": "Wednesday",
        "ar": "Wednesday"
      }
    },
    "gregorian": {
      "date": "$dateStr"
    }
  }
}''';

        when(mockClient.get(any)).thenAnswer(
            (_) async => http.Response(responseBody, 200));

        // Act
        final result = await HijriCalendarService.fetchHijriDate(
          client: mockClient,
        );

        // Assert
        expect(result, isNotNull);
        final captured = verify(mockClient.get(captureAny)).captured;
        expect(captured.length, 1);
        expect(captured[0].toString(),
            'https://api.aladhan.com/v1/gToH/$dateStr');
      });

      test('HTTP 404 error throws HijriServiceException', () async {
        // Arrange
        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
          () => HijriCalendarService.fetchHijriDate(client: mockClient),
          throwsA(isA<HijriServiceException>()),
        );
      });

      test('HTTP 500 error throws HijriServiceException', () async {
        // Arrange
        when(mockClient.get(any)).thenAnswer(
            (_) async => http.Response('Internal Server Error', 500));

        // Act & Assert
        expect(
          () => HijriCalendarService.fetchHijriDate(client: mockClient),
          throwsA(isA<HijriServiceException>()),
        );
      });

      test('API error status throws HijriServiceException', () async {
        // Arrange
        final responseBody = jsonEncode({
          'code': 400,
          'status': 'Bad Request',
          'data': null,
        });

        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act & Assert
        expect(
          () => HijriCalendarService.fetchHijriDate(client: mockClient),
          throwsA(isA<HijriServiceException>()),
        );
      });

      test('invalid JSON throws HijriServiceException', () async {
        // Arrange
        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response('invalid json', 200));

        // Act & Assert
        expect(
          () => HijriCalendarService.fetchHijriDate(client: mockClient),
          throwsA(isA<HijriServiceException>()),
        );
      });

      test('network timeout throws HijriServiceException', () async {
        // Arrange
        when(mockClient.get(any))
            .thenAnswer((_) async => throw Exception('Connection timeout'));

        // Act & Assert
        expect(
          () => HijriCalendarService.fetchHijriDate(client: mockClient),
          throwsA(isA<HijriServiceException>()),
        );
      });
    });

    group('24-Hour Cache Validation', () {
      late HijriDate testHijriDate;

      setUp(() async {
        // Clear any existing cache
        await StorageService.remove(AppConstants.keyHijriDate);

        testHijriDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: DateTime.now(),
          cachedAt: DateTime.now(),
        );
      });

      test('valid cache within 24h and date matches returns cached', () async {
        // Arrange - Cache from 1 hour ago, same date
        final cachedDate = testHijriDate.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(cachedDate.toJson()),
        );

        // Act
        final result = await HijriCalendarService.getCachedHijriDate();

        // Assert
        expect(result, isNotNull);
        expect(result!.isCacheValid, isTrue);
        expect(result.day, cachedDate.day);
      });

      test('cache older than 24h is invalid', () async {
        // Arrange - Cache from 25 hours ago
        final cachedDate = testHijriDate.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(cachedDate.toJson()),
        );

        // Act
        final result = await HijriCalendarService.getCachedHijriDate();

        // Assert
        expect(result, isNotNull);
        expect(result!.isCacheValid, isFalse);
      });

      test('cache with date mismatch is invalid', () async {
        // Arrange - Cache from 1 hour ago but yesterday's date
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final cachedDate = testHijriDate.copyWith(
          gregorianDate: yesterday,
          cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(cachedDate.toJson()),
        );

        // Act
        final result = await HijriCalendarService.getCachedHijriDate();

        // Assert
        expect(result, isNotNull);
        expect(result!.isCacheValid, isFalse);
      });

      test('edge case: cache created 23:59 yesterday, checked 00:01 today is invalid',
          () async {
        // Arrange
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayAt2359 = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
        );

        final cachedDate = testHijriDate.copyWith(
          gregorianDate: yesterday,
          cachedAt: yesterdayAt2359,
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(cachedDate.toJson()),
        );

        // Act
        final result = await HijriCalendarService.getCachedHijriDate();

        // Assert
        expect(result, isNotNull);
        expect(result!.isCacheValid, isFalse,
            reason: 'Cache from yesterday should be invalid even if <24h');
      });

      test('corrupted cache is cleared and returns null', () async {
        // Arrange - Invalid JSON
        await StorageService.setString(
          AppConstants.keyHijriDate,
          'invalid json',
        );

        // Act
        final result = await HijriCalendarService.getCachedHijriDate();

        // Assert
        expect(result, isNull);

        // Verify cache was cleared
        final cacheExists =
            await StorageService.containsKey(AppConstants.keyHijriDate);
        expect(cacheExists, isFalse);
      });

      test('no cache returns null', () async {
        // Arrange - Ensure no cache
        await StorageService.remove(AppConstants.keyHijriDate);

        // Act
        final result = await HijriCalendarService.getCachedHijriDate();

        // Assert
        expect(result, isNull);
      });
    });

    group('Smart Caching - getHijriDate', () {
      late HijriDate validCachedDate;

      setUp(() async {
        await StorageService.remove(AppConstants.keyHijriDate);

        validCachedDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: DateTime.now(),
          cachedAt: DateTime.now(),
        );
      });

      test('returns cached date if valid without API call', () async {
        // Arrange - Set valid cache
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(validCachedDate.toJson()),
        );

        // Act
        final result = await HijriCalendarService.getHijriDate();

        // Assert
        expect(result.day, validCachedDate.day);
        expect(result.isCacheValid, isTrue);
        verifyNever(mockClient.get(any));
      });

      test('fetches from API if no cache exists', () async {
        // Arrange - No cache
        final responseBody = '''
{
  "code": 200,
  "status": "OK",
  "data": {
    "hijri": {
      "day": "03",
      "month": {
        "number": 6,
        "en": "Jumada al-Akhirah",
        "ar": "Jumada al-Akhirah"
      },
      "year": "1447",
      "weekday": {
        "en": "Thursday",
        "ar": "Thursday"
      }
    },
    "gregorian": {
      "date": "03-12-2025"
    }
  }
}''';

        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await HijriCalendarService.getHijriDate(
          client: mockClient,
        );

        // Assert
        expect(result.day, 3);
        verify(mockClient.get(any)).called(1);
      });

      test('forceRefresh bypasses cache and fetches from API', () async {
        // Arrange - Set valid cache
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(validCachedDate.toJson()),
        );

        final responseBody = '''
{
  "code": 200,
  "status": "OK",
  "data": {
    "hijri": {
      "day": "03",
      "month": {
        "number": 6,
        "en": "Jumada al-Akhirah",
        "ar": "Jumada al-Akhirah"
      },
      "year": "1447",
      "weekday": {
        "en": "Thursday",
        "ar": "Thursday"
      }
    },
    "gregorian": {
      "date": "03-12-2025"
    }
  }
}''';

        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await HijriCalendarService.getHijriDate(
          forceRefresh: true,
          client: mockClient,
        );

        // Assert
        expect(result.day, 3, reason: 'Should fetch fresh data');
        verify(mockClient.get(any)).called(1);
      });

      test('falls back to stale cache on network error', () async {
        // Arrange - Set stale cache (25 hours old)
        final staleCache = validCachedDate.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(staleCache.toJson()),
        );

        when(mockClient.get(any))
            .thenAnswer((_) async => throw Exception('Network error'));

        // Act
        final result = await HijriCalendarService.getHijriDate(
          client: mockClient,
        );

        // Assert
        expect(result.day, staleCache.day,
            reason: 'Should return stale cache on network error');
        expect(result.isCacheValid, isFalse);
      });

      test('throws exception if no cache and API fails', () async {
        // Arrange - No cache
        await StorageService.remove(AppConstants.keyHijriDate);

        when(mockClient.get(any))
            .thenAnswer((_) async => throw Exception('Network error'));

        // Act & Assert
        expect(
          () => HijriCalendarService.getHijriDate(client: mockClient),
          throwsA(isA<HijriServiceException>()),
        );
      });
    });

    group('Cache Writing', () {
      test('caches HijriDate with correct JSON serialization', () async {
        // Arrange
        await StorageService.remove(AppConstants.keyHijriDate);

        final hijriDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: DateTime(2025, 12, 3),
          cachedAt: DateTime.now(),
        );

        // Act
        final responseBody = '''
{
  "code": 200,
  "status": "OK",
  "data": {
    "hijri": {
      "day": "02",
      "month": {
        "number": 6,
        "en": "Jumada al-Akhirah",
        "ar": "Jumada al-Akhirah"
      },
      "year": "1447",
      "weekday": {
        "en": "Wednesday",
        "ar": "Wednesday"
      }
    },
    "gregorian": {
      "date": "03-12-2025"
    }
  }
}''';

        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        final result = await HijriCalendarService.getHijriDate(
          client: mockClient,
        );

        // Assert - Verify cache was written
        final cached = await HijriCalendarService.getCachedHijriDate();
        expect(cached, isNotNull);
        expect(cached!.day, result.day);
        expect(cached.month, result.month);
        expect(cached.year, result.year);
      });

      test('clearCache removes cached Hijri date', () async {
        // Arrange - Set cache
        final hijriDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: DateTime.now(),
          cachedAt: DateTime.now(),
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(hijriDate.toJson()),
        );

        // Act
        await HijriCalendarService.clearCache();

        // Assert
        final cached = await HijriCalendarService.getCachedHijriDate();
        expect(cached, isNull);
      });
    });

    group('isCacheValid', () {
      test('returns true when cache is valid', () async {
        // Arrange
        final validCache = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: DateTime.now(),
          cachedAt: DateTime.now(),
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(validCache.toJson()),
        );

        // Act
        final isValid = await HijriCalendarService.isCacheValid();

        // Assert
        expect(isValid, isTrue);
      });

      test('returns false when no cache exists', () async {
        // Arrange
        await StorageService.remove(AppConstants.keyHijriDate);

        // Act
        final isValid = await HijriCalendarService.isCacheValid();

        // Assert
        expect(isValid, isFalse);
      });

      test('returns false when cache is stale', () async {
        // Arrange
        final staleCache = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: DateTime.now(),
          cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
        );
        await StorageService.setString(
          AppConstants.keyHijriDate,
          jsonEncode(staleCache.toJson()),
        );

        // Act
        final isValid = await HijriCalendarService.isCacheValid();

        // Assert
        expect(isValid, isFalse);
      });
    });
  });
}
