// test/unit/models/hijri_date_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/hijri_date.dart';

void main() {
  group('HijriDate Model', () {
    group('Parsing', () {
      test('fromApiResponse creates HijriDate from valid API response', () {
        // Arrange
        final apiData = {
          'hijri': {
            'day': '24',
            'month': {'number': 1, 'en': 'Muharram', 'ar': 'Muharram'},
            'year': '1446',
            'weekday': {'en': 'Thursday', 'ar': 'Thursday'},
          },
          'gregorian': {'date': '01-08-2024'},
        };

        // Act
        final hijriDate = HijriDate.fromApiResponse(apiData);

        // Assert
        expect(hijriDate.day, 24);
        expect(hijriDate.month, 1);
        expect(hijriDate.year, 1446);
        expect(hijriDate.monthNameEnglish, 'Muharram');
        expect(hijriDate.monthName, 'Muharram');
        expect(hijriDate.weekdayNameEnglish, 'Thursday');
        expect(hijriDate.weekdayName, 'Thursday');
        expect(hijriDate.gregorianDate.year, 2024);
        expect(hijriDate.gregorianDate.month, 8);
        expect(hijriDate.gregorianDate.day, 1);
        expect(hijriDate.cachedAt, isNotNull);
      });

      test('fromApiResponse parses day/month/year correctly', () {
        // Arrange
        final apiData = {
          'hijri': {
            'day': '02',
            'month': {
              'number': 6,
              'en': 'Jumada al-Akhirah',
              'ar': 'Jumada al-Akhirah',
            },
            'year': '1447',
            'weekday': {'en': 'Wednesday', 'ar': 'Wednesday'},
          },
          'gregorian': {'date': '03-12-2025'},
        };

        // Act
        final hijriDate = HijriDate.fromApiResponse(apiData);

        // Assert
        expect(hijriDate.day, 2);
        expect(hijriDate.month, 6);
        expect(hijriDate.year, 1447);
      });

      test('fromApiResponse parses Gregorian date in DD-MM-YYYY format', () {
        // Arrange
        final apiData = {
          'hijri': {
            'day': '15',
            'month': {
              'number': 3,
              'en': 'Rabi al-Awwal',
              'ar': 'Rabi al-Awwal',
            },
            'year': '1447',
            'weekday': {'en': 'Monday', 'ar': 'Monday'},
          },
          'gregorian': {'date': '25-09-2025'},
        };

        // Act
        final hijriDate = HijriDate.fromApiResponse(apiData);

        // Assert
        expect(hijriDate.gregorianDate.year, 2025);
        expect(hijriDate.gregorianDate.month, 9);
        expect(hijriDate.gregorianDate.day, 25);
      });

      test('fromCache creates HijriDate from cached JSON', () {
        // Arrange
        final json = {
          'day': 24,
          'month': 1,
          'year': 1446,
          'monthName': 'Muharram',
          'monthNameEnglish': 'Muharram',
          'weekdayName': 'Thursday',
          'weekdayNameEnglish': 'Thursday',
          'gregorianDate': '2024-08-01T00:00:00.000',
          'cachedAt': '2024-08-01T10:00:00.000',
        };

        // Act
        final hijriDate = HijriDate.fromCache(json);

        // Assert
        expect(hijriDate.day, 24);
        expect(hijriDate.month, 1);
        expect(hijriDate.year, 1446);
        expect(hijriDate.monthNameEnglish, 'Muharram');
        expect(hijriDate.gregorianDate.year, 2024);
        expect(hijriDate.gregorianDate.month, 8);
        expect(hijriDate.gregorianDate.day, 1);
        expect(hijriDate.cachedAt.year, 2024);
        expect(hijriDate.cachedAt.month, 8);
        expect(hijriDate.cachedAt.day, 1);
        expect(hijriDate.cachedAt.hour, 10);
      });

      test('toJson/fromCache roundtrip preserves all data', () {
        // Arrange
        final original = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime(2024, 8, 1, 10, 0, 0),
        );

        // Act
        final json = original.toJson();
        final restored = HijriDate.fromCache(json);

        // Assert
        expect(restored.day, original.day);
        expect(restored.month, original.month);
        expect(restored.year, original.year);
        expect(restored.monthName, original.monthName);
        expect(restored.monthNameEnglish, original.monthNameEnglish);
        expect(restored.weekdayName, original.weekdayName);
        expect(restored.weekdayNameEnglish, original.weekdayNameEnglish);
        expect(restored.gregorianDate, original.gregorianDate);
        expect(restored.cachedAt.year, original.cachedAt.year);
        expect(restored.cachedAt.month, original.cachedAt.month);
        expect(restored.cachedAt.day, original.cachedAt.day);
      });
    });

    group('Cache Validation - CRITICAL', () {
      test('isCacheValid returns true when cached 1 hour ago, same date', () {
        // Arrange
        final now = DateTime.now();
        final hijriDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: now,
          cachedAt: now.subtract(const Duration(hours: 1)),
        );

        // Act & Assert
        expect(
          hijriDate.isCacheValid,
          isTrue,
          reason: 'Cache within 24h and same date should be valid',
        );
      });

      test('isCacheValid returns true when cached 23 hours ago, same date', () {
        // Arrange
        final now = DateTime.now();
        final hijriDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: now,
          cachedAt: now.subtract(const Duration(hours: 23)),
        );

        // Act & Assert
        expect(
          hijriDate.isCacheValid,
          isTrue,
          reason: 'Cache within 24h and same date should be valid',
        );
      });

      test('isCacheValid returns false when cached 25 hours ago', () {
        // Arrange
        final now = DateTime.now();
        final hijriDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: now,
          cachedAt: now.subtract(const Duration(hours: 25)),
        );

        // Act & Assert
        expect(
          hijriDate.isCacheValid,
          isFalse,
          reason: 'Cache older than 24h should be invalid',
        );
      });

      test(
        'isCacheValid returns false when cached 1 hour ago but yesterday\'s date',
        () {
          // Arrange
          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(days: 1));
          final hijriDate = HijriDate(
            day: 2,
            month: 6,
            year: 1447,
            monthName: 'Jumada al-Akhirah',
            monthNameEnglish: 'Jumada al-Akhirah',
            weekdayName: 'Wednesday',
            weekdayNameEnglish: 'Wednesday',
            gregorianDate: yesterday,
            cachedAt: now.subtract(const Duration(hours: 1)),
          );

          // Act & Assert
          expect(
            hijriDate.isCacheValid,
            isFalse,
            reason: 'Cache with different date should be invalid',
          );
        },
      );

      test(
        'EDGE CASE: isCacheValid returns false when cached at 23:59 yesterday, checked at 00:01 today',
        () {
          // Arrange
          final today = DateTime.now();
          final yesterday = today.subtract(const Duration(days: 1));
          final yesterdayAt2359 = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
          );

          final hijriDate = HijriDate(
            day: 2,
            month: 6,
            year: 1447,
            monthName: 'Jumada al-Akhirah',
            monthNameEnglish: 'Jumada al-Akhirah',
            weekdayName: 'Wednesday',
            weekdayNameEnglish: 'Wednesday',
            gregorianDate: yesterday,
            cachedAt: yesterdayAt2359,
          );

          // Act & Assert
          expect(
            hijriDate.isCacheValid,
            isFalse,
            reason:
                'Cache from yesterday should be invalid even if less than 24 hours',
          );
        },
      );

      test('isCacheValid checks date ignoring time component', () {
        // Arrange - Same calendar date but different times
        final today = DateTime.now();
        final todayMorning = DateTime(today.year, today.month, today.day, 8, 0);
        final todayEvening = DateTime(
          today.year,
          today.month,
          today.day,
          20,
          0,
        );

        final hijriDate = HijriDate(
          day: 2,
          month: 6,
          year: 1447,
          monthName: 'Jumada al-Akhirah',
          monthNameEnglish: 'Jumada al-Akhirah',
          weekdayName: 'Wednesday',
          weekdayNameEnglish: 'Wednesday',
          gregorianDate: todayMorning,
          cachedAt: todayEvening.subtract(const Duration(hours: 2)),
        );

        // Act & Assert
        expect(
          hijriDate.isCacheValid,
          isTrue,
          reason: 'Same calendar date should be valid regardless of time',
        );
      });
    });

    group('Formatting', () {
      test('formattedShort returns correct format', () {
        // Arrange
        final hijriDate = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime.now(),
        );

        // Act & Assert
        expect(hijriDate.formattedShort, '24 Muharram 1446 AH');
      });

      test('formattedLong returns correct format', () {
        // Arrange
        final hijriDate = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime.now(),
        );

        // Act & Assert
        expect(hijriDate.formattedLong, 'Thursday, 24 Muharram 1446 AH');
      });

      test('toString returns formattedShort', () {
        // Arrange
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

        // Act & Assert
        expect(hijriDate.toString(), '2 Jumada al-Akhirah 1447 AH');
      });
    });

    group('Equality and HashCode', () {
      test('two HijriDates with same hijri and gregorian dates are equal', () {
        // Arrange
        final date1 = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime(2024, 8, 1, 10, 0),
        );

        final date2 = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime(2024, 8, 1, 15, 0), // Different cache time
        );

        // Act & Assert
        expect(
          date1,
          equals(date2),
          reason: 'Same hijri/gregorian dates should be equal',
        );
      });

      test('two HijriDates with different hijri dates are not equal', () {
        // Arrange
        final date1 = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime.now(),
        );

        final date2 = HijriDate(
          day: 25,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Friday',
          weekdayNameEnglish: 'Friday',
          gregorianDate: DateTime(2024, 8, 2),
          cachedAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          date1,
          isNot(equals(date2)),
          reason: 'Different hijri dates should not be equal',
        );
      });

      test('hashCode is consistent for equal objects', () {
        // Arrange
        final date1 = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime(2024, 8, 1, 10, 0),
        );

        final date2 = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime(2024, 8, 1, 15, 0),
        );

        // Act & Assert
        expect(
          date1.hashCode,
          equals(date2.hashCode),
          reason: 'Equal objects should have equal hashCodes',
        );
      });

      test('hashCode is different for different objects', () {
        // Arrange
        final date1 = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime.now(),
        );

        final date2 = HijriDate(
          day: 25,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Friday',
          weekdayNameEnglish: 'Friday',
          gregorianDate: DateTime(2024, 8, 2),
          cachedAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          date1.hashCode,
          isNot(equals(date2.hashCode)),
          reason: 'Different objects should (usually) have different hashCodes',
        );
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance with updated fields', () {
        // Arrange
        final original = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime(2024, 8, 1, 10, 0),
        );

        // Act
        final updated = original.copyWith(
          day: 25,
          cachedAt: DateTime(2024, 8, 1, 15, 0),
        );

        // Assert
        expect(updated.day, 25);
        expect(updated.month, original.month);
        expect(updated.year, original.year);
        expect(updated.cachedAt, DateTime(2024, 8, 1, 15, 0));
      });

      test('copyWith with no parameters returns equivalent object', () {
        // Arrange
        final original = HijriDate(
          day: 24,
          month: 1,
          year: 1446,
          monthName: 'Muharram',
          monthNameEnglish: 'Muharram',
          weekdayName: 'Thursday',
          weekdayNameEnglish: 'Thursday',
          gregorianDate: DateTime(2024, 8, 1),
          cachedAt: DateTime(2024, 8, 1, 10, 0),
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.day, original.day);
        expect(copy.month, original.month);
        expect(copy.year, original.year);
        expect(copy.monthName, original.monthName);
        expect(copy.gregorianDate, original.gregorianDate);
      });
    });
  });
}
