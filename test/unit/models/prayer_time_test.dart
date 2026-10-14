// test/unit/models/prayer_time_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/prayer_time.dart';

void main() {
  group('PrayerTime Model', () {
    group('Time Parsing - 12-hour format', () {
      test('parses 12:30 PM correctly', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Dhuhr',
          timings: {'Dhuhr': '12:30 PM'},
          iqamaMap: {'Dhuhr': '12:45 PM'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 12);
        expect(waqtTime.minute, 30);
      });

      test('parses 01:00 AM correctly', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '01:00 AM'},
          iqamaMap: {'Fajr': '01:15 AM'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 1);
        expect(waqtTime.minute, 0);
      });

      test('parses 11:59 PM correctly', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Isha',
          timings: {'Isha': '11:59 PM'},
          iqamaMap: {'Isha': '12:15 AM'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 23);
        expect(waqtTime.minute, 59);
      });

      test('parses case insensitive - 12:30pm', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Dhuhr',
          timings: {'Dhuhr': '12:30pm'},
          iqamaMap: {'Dhuhr': '12:45pm'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 12);
        expect(waqtTime.minute, 30);
      });

      test('parses case insensitive - 05:30 AM', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '05:30 AM'},
          iqamaMap: {'Fajr': '05:45 AM'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 5);
        expect(waqtTime.minute, 30);
      });

      test('parses 12:00 AM as midnight', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '12:00 AM'},
          iqamaMap: {'Fajr': '12:15 AM'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 0);
        expect(waqtTime.minute, 0);
      });

      test('parses 12:00 PM as noon', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Dhuhr',
          timings: {'Dhuhr': '12:00 PM'},
          iqamaMap: {'Dhuhr': '12:15 PM'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 12);
        expect(waqtTime.minute, 0);
      });
    });

    group('Time Parsing - 24-hour format', () {
      test('parses 13:00 correctly', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Asr',
          timings: {'Asr': '13:00'},
          iqamaMap: {'Asr': '13:15'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 13);
        expect(waqtTime.minute, 0);
      });

      test('parses 00:30 correctly', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '00:30'},
          iqamaMap: {'Fajr': '00:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 0);
        expect(waqtTime.minute, 30);
      });

      test('parses 23:59 correctly', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Isha',
          timings: {'Isha': '23:59'},
          iqamaMap: {'Isha': '12:15'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 23);
        expect(waqtTime.minute, 59);
      });
    });

    group('Time Parsing - "next day" detection', () {
      test('detects "(next day)" annotation', () {
        // Arrange
        final today = DateTime.now();
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '05:30 (next day)'},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.day, today.add(const Duration(days: 1)).day);
      });

      test('detects "next" keyword', () {
        // Arrange
        final today = DateTime.now();
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '05:30 next'},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.day, today.add(const Duration(days: 1)).day);
      });

      test('detects "tomorrow" keyword', () {
        // Arrange
        final today = DateTime.now();
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '05:30 tomorrow'},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.day, today.add(const Duration(days: 1)).day);
      });
    });

    group('Time Parsing - annotations', () {
      test('extracts time from "(Fajr) 05:30" format', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '(Fajr) 05:30'},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.hour, 5);
        expect(waqtTime.minute, 30);
      });

      test('handles "05:30 (Tomorrow)" format', () {
        // Arrange
        final today = DateTime.now();
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '05:30 (Tomorrow)'},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNotNull);
        expect(waqtTime!.day, today.add(const Duration(days: 1)).day);
      });
    });

    group('Time Parsing - invalid formats', () {
      test('empty string returns null time', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': ''},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNull);
      });

      test('invalid string returns null time', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': 'invalid'},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNull);
      });

      test('invalid hour 25:00 returns null time', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '25:00'},
          iqamaMap: {'Fajr': '05:45'},
        );

        // Act
        final waqtTime = prayer.getWaqtTime();

        // Assert
        expect(waqtTime, isNull);
      });
    });

    group('Prayer Logic', () {
      test('isNext returns true when prayer is upcoming', () {
        // Arrange: a fixed time of day, so "an hour later" never wraps past
        // midnight (times are parsed for today)
        final today = DateTime.now();
        final now = DateTime(today.year, today.month, today.day, 10, 0);

        final prayer = PrayerTime.fromMaps(
          name: 'Dhuhr',
          timings: {'Dhuhr': '11:00'},
          iqamaMap: {'Dhuhr': '11:00'},
        );

        // Act & Assert
        expect(prayer.isNext(now), isTrue);
      });

      test('isNext returns false when prayer has passed', () {
        // Arrange: a fixed time of day, so "an hour earlier" never wraps
        // back past midnight (times are parsed for today)
        final today = DateTime.now();
        final now = DateTime(today.year, today.month, today.day, 10, 0);

        final prayer = PrayerTime.fromMaps(
          name: 'Fajr',
          timings: {'Fajr': '09:00'},
          iqamaMap: {'Fajr': '09:00'},
        );

        // Act & Assert
        expect(prayer.isNext(now), isFalse);
      });

      test('isNext returns true when same minute as prayer', () {
        // Arrange
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        final prayer = PrayerTime.fromMaps(
          name: 'Dhuhr',
          timings: {'Dhuhr': timeStr},
          iqamaMap: {'Dhuhr': timeStr},
        );

        // Act & Assert
        expect(prayer.isNext(now), isTrue);
      });

      test('getNextTime prefers iqama over waqt', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Dhuhr',
          timings: {'Dhuhr': '12:00 PM'},
          iqamaMap: {'Dhuhr': '12:15 PM'},
        );

        // Act
        final nextTime = prayer.getNextTime();

        // Assert
        expect(nextTime, isNotNull);
        expect(nextTime!.hour, 12);
        expect(nextTime.minute, 15);
      });

      test('getNextTime falls back to waqt when iqama is empty', () {
        // Arrange
        final prayer = PrayerTime.fromMaps(
          name: 'Sunrise',
          timings: {'Sunrise': '06:00 AM'},
          iqamaMap: {'Sunrise': ''},
        );

        // Act
        final nextTime = prayer.getNextTime();

        // Assert
        expect(nextTime, isNotNull);
        expect(nextTime!.hour, 6);
        expect(nextTime.minute, 0);
      });
    });

    group('trimTime', () {
      test('removes " (EST)" suffix', () {
        // Act & Assert
        expect(PrayerTime.trimTime('12:30 PM (EST)'), '12:30 PM');
      });

      test('removes " (PST)" suffix', () {
        // Act & Assert
        expect(PrayerTime.trimTime('05:30 AM (PST)'), '05:30 AM');
      });

      test('returns original if no suffix', () {
        // Act & Assert
        expect(PrayerTime.trimTime('12:30 PM'), '12:30 PM');
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        // Arrange
        final original = PrayerTime.fromMaps(
          name: 'Dhuhr',
          timings: {'Dhuhr': '12:00 PM'},
          iqamaMap: {'Dhuhr': '12:15 PM'},
        );

        // Act
        final updated = original.copyWith(iqama: '12:30 PM');

        // Assert
        expect(updated.name, 'Dhuhr');
        expect(updated.waqt, '12:00 PM');
        expect(updated.iqama, '12:30 PM');
      });
    });
  });

  group('PrayerSchedule Model', () {
    late Map<String, String> testTimings;
    late Map<String, String> testIqamaMap;

    setUp(() {
      testTimings = {
        'Fajr': '05:30 AM',
        'Sunrise': '06:45 AM',
        'Dhuhr': '12:30 PM',
        'Asr': '03:00 PM',
        'Maghrib': '06:15 PM',
        'Isha': '08:00 PM',
      };

      testIqamaMap = {
        'Fajr': '05:45 AM',
        'Sunrise': '',
        'Dhuhr': '12:45 PM',
        'Asr': '03:15 PM',
        'Maghrib': '06:25 PM',
        'Isha': '08:15 PM',
      };
    });

    group('Prayer Retrieval', () {
      test('getAllPrayers returns all prayers including Sunrise', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final allPrayers = schedule.getAllPrayers();

        // Assert
        expect(allPrayers.length, 7); // 6 regular prayers + Jumuah
        expect(allPrayers.any((p) => p.name == 'Sunrise'), isTrue);
        expect(allPrayers.any((p) => p.name == 'Jumuah'), isTrue);
      });

      test('getMainPrayers excludes Sunrise', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final mainPrayers = schedule.getMainPrayers();

        // Assert
        expect(mainPrayers.length, 6); // 5 regular prayers + Jumuah
        expect(mainPrayers.any((p) => p.name == 'Sunrise'), isFalse);
        expect(mainPrayers.any((p) => p.name == 'Fajr'), isTrue);
        expect(mainPrayers.any((p) => p.name == 'Isha'), isTrue);
        expect(mainPrayers.any((p) => p.name == 'Jumuah'), isTrue);
      });

      test('getPrayerByName returns correct prayer', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final prayer = schedule.getPrayerByName('Dhuhr');

        // Assert
        expect(prayer, isNotNull);
        expect(prayer!.name, 'Dhuhr');
        expect(prayer.waqt, '12:30 PM');
      });

      test('getPrayerByName returns null for non-existent prayer', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final prayer = schedule.getPrayerByName('NonExistent');

        // Assert
        expect(prayer, isNull);
      });
    });

    group('Next Prayer Logic', () {
      // Fixed times on today's date, so results don't depend on when the
      // tests run. (Times in a schedule are parsed as "today".) The prayers
      // used avoid Dhuhr, which is skipped for Jumuah on Fridays.
      DateTime at(int hour, int minute) {
        final today = DateTime.now();
        return DateTime(today.year, today.month, today.day, hour, minute);
      }

      final schedule = PrayerSchedule(
        timings: {'Fajr': '05:30', 'Asr': '15:00', 'Isha': '20:00'},
        iqamaMap: {'Fajr': '05:45', 'Asr': '15:15', 'Isha': '20:15'},
      );

      test('getNextPrayer returns next prayer after current time', () {
        final nextPrayer = schedule.getNextPrayer(now: at(12, 0));

        expect(nextPrayer?.name, 'Asr');
      });

      test('getNextPrayer counts a prayer until its iqamah', () {
        // Asr has begun (15:00) but its iqamah (15:15) hasn't.
        expect(schedule.getNextPrayer(now: at(15, 10))?.name, 'Asr');
        expect(schedule.getNextPrayer(now: at(15, 16))?.name, 'Isha');
      });

      test('getNextPrayer skips Sunrise', () {
        // Sunrise is sooner than Asr, but is not a prayer
        final withSunrise = PrayerSchedule(
          timings: {'Sunrise': '06:10', 'Asr': '15:00'},
          iqamaMap: {'Sunrise': '06:10', 'Asr': '15:15'},
        );

        final nextPrayer = withSunrise.getNextPrayer(now: at(5, 0));

        expect(nextPrayer?.name, 'Asr');
      });

      test('getNextPrayer wraps to Fajr when all prayers passed', () {
        final nextPrayer = schedule.getNextPrayer(now: at(23, 0));

        expect(nextPrayer?.name, 'Fajr');
      });

      test('getTimeToNextPrayer calculates correct duration', () {
        final timeToNext = schedule.getTimeToNextPrayer(now: at(12, 45));

        // Until Asr iqamah at 15:15
        expect(timeToNext, const Duration(hours: 2, minutes: 30));
      });

      test("getTimeToNextPrayer counts to tomorrow's Fajr after Isha", () {
        final timeToNext = schedule.getTimeToNextPrayer(now: at(23, 0));

        // 23:00 today -> 05:45 tomorrow
        expect(timeToNext, const Duration(hours: 6, minutes: 45));
      });
    });

    group('Friday Prayer Handling', () {
      test('getPrayersInOrder includes both Dhuhr and Jumuah', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final prayers = schedule.getPrayersInOrder();

        // Assert
        expect(
          prayers.any((p) => p.name == 'Dhuhr'),
          isTrue,
          reason: 'Dhuhr should be in the list',
        );
        expect(
          prayers.any((p) => p.name == 'Jumuah'),
          isTrue,
          reason: 'Jumuah should be added at the end',
        );
        expect(prayers.any((p) => p.name == 'Fajr'), isTrue);
        expect(prayers.any((p) => p.name == 'Asr'), isTrue);
      });

      test('Jumuah prayer uses Dhuhr waqt time', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final prayers = schedule.getPrayersInOrder();
        final jumuah = prayers.firstWhere((p) => p.name == 'Jumuah');
        final dhuhr = prayers.firstWhere((p) => p.name == 'Dhuhr');

        // Assert
        expect(
          jumuah.waqt,
          dhuhr.waqt,
          reason: 'Jumuah should use Dhuhr waqt time',
        );
      });

      test('Jumuah iqama falls back to the old "Jummah" key', () {
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: {'Jummah': '13:15'},
        );

        for (final prayers in [
          schedule.getPrayersInOrder(),
          schedule.getAllPrayers(),
        ]) {
          expect(prayers.firstWhere((p) => p.name == 'Jumuah').iqama, '13:15');
        }
      });

      test('the new "Jumuah" key wins over the old one', () {
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: {'Jummah': '13:15', 'Jumuah': '13:30'},
        );

        final jumuah = schedule.getPrayersInOrder().firstWhere(
          (p) => p.name == 'Jumuah',
        );
        expect(jumuah.iqama, '13:30');
      });
    });

    group('Update Iqama', () {
      test('updateIqama creates new schedule with updated iqama', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final updated = schedule.updateIqama('Dhuhr', '01:00 PM');
        final dhuhrPrayer = updated.getPrayerByName('Dhuhr');

        // Assert
        expect(dhuhrPrayer, isNotNull);
        expect(dhuhrPrayer!.iqama, '01:00 PM');
        expect(dhuhrPrayer.waqt, '12:30 PM', reason: 'Waqt should not change');

        // Original should be unchanged
        final originalDhuhr = schedule.getPrayerByName('Dhuhr');
        expect(originalDhuhr!.iqama, '12:45 PM');
      });

      test('updateIqama does not affect other prayers', () {
        // Arrange
        final schedule = PrayerSchedule(
          timings: testTimings,
          iqamaMap: testIqamaMap,
        );

        // Act
        final updated = schedule.updateIqama('Dhuhr', '01:00 PM');
        final asrPrayer = updated.getPrayerByName('Asr');

        // Assert
        expect(asrPrayer, isNotNull);
        expect(
          asrPrayer!.iqama,
          '03:15 PM',
          reason: 'Other prayers should not be affected',
        );
      });
    });
  });
}
