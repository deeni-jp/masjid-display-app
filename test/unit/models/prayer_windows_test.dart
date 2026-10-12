// test/unit/models/prayer_windows_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/prayer_time.dart';
import 'package:prayer_app/models/prayer_windows.dart';

void main() {
  // PrayerTime parses times as "today", so build test instants on today.
  DateTime at(int hour, int minute, [int second = 0]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute, second);
  }

  final schedule = PrayerSchedule(
    timings: {
      'Fajr': '04:52',
      'Sunrise': '06:10',
      'Dhuhr': '11:38',
      'Asr': '14:50',
      'Sunset': '17:20',
      'Maghrib': '17:20',
      'Isha': '18:42',
    },
    iqamaMap: {
      'Fajr': '05:15',
      'Dhuhr': '12:30',
      'Asr': '15:15',
      'Maghrib': '17:25',
      'Isha': '19:15',
      'Jummah': '13:15',
    },
  );

  group('getPrayerPhase', () {
    // Asr iqamah is 15:15 (Asr is not affected by the Friday rule).
    test('nothing before the countdown starts', () {
      expect(schedule.getPrayerPhase(at(15, 13, 59)), isNull);
    });

    test('iqamah countdown for the final minute', () {
      final now = at(15, 14);
      final state = schedule.getPrayerPhase(now)!;
      expect(state.phase, PrayerPhase.iqamahCountdown);
      expect(state.prayer.name, 'Asr');
      expect(state.remaining(now), const Duration(seconds: 60));
    });

    test('prayer time started for 30 seconds from iqamah', () {
      final state = schedule.getPrayerPhase(at(15, 15))!;
      expect(state.phase, PrayerPhase.prayerStarted);
      expect(state.endsAt, at(15, 15, 30));
      expect(
        schedule.getPrayerPhase(at(15, 15, 29))?.phase,
        PrayerPhase.prayerStarted,
      );
    });

    test('prayer in progress for 10 minutes after that', () {
      final state = schedule.getPrayerPhase(at(15, 15, 30))!;
      expect(state.phase, PrayerPhase.prayerInProgress);
      expect(state.endsAt, at(15, 25, 30));
      expect(
        schedule.getPrayerPhase(at(15, 25, 29))?.phase,
        PrayerPhase.prayerInProgress,
      );
    });

    test('back to the home screen when prayer in progress ends', () {
      expect(schedule.getPrayerPhase(at(15, 25, 30)), isNull);
    });
  });

  group('congregationalPrayers', () {
    List<String> names(DateTime day) =>
        schedule.congregationalPrayers(day).map((p) => p.name).toList();

    test('Jummah replaces Dhuhr on Fridays', () {
      final friday = DateTime(2026, 10, 16);
      expect(names(friday), ['Fajr', 'Asr', 'Maghrib', 'Isha', 'Jummah']);
    });

    test('Dhuhr on other days', () {
      final tuesday = DateTime(2026, 10, 13);
      expect(names(tuesday), ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']);
    });
  });

  group('getProhibitedWindow', () {
    test('sunrise window starts at sunrise', () {
      final w = schedule.getProhibitedWindow(at(6, 15));
      expect(w?.name, 'Sunrise');
      expect(w?.end, at(6, 10).add(kSunriseProhibitedDuration));
    });

    test('zenith window ends at Dhuhr', () {
      expect(schedule.getProhibitedWindow(at(11, 30))?.name, 'Zenith');
      expect(schedule.getProhibitedWindow(at(11, 38)), isNull);
    });

    test('sunset window counts down to sunset', () {
      final now = at(17, 3, 51);
      final w = schedule.getProhibitedWindow(now);
      expect(w?.name, 'Sunset');
      expect(w?.remaining(now), const Duration(minutes: 16, seconds: 9));
    });

    test('falls back to Maghrib when Sunset is missing', () {
      final noSunset = PrayerSchedule(
        timings: Map.of(schedule.timings)..remove('Sunset'),
        iqamaMap: schedule.iqamaMap,
      );
      expect(noSunset.getProhibitedWindow(at(17, 10))?.name, 'Sunset');
    });

    test('returns null outside all windows', () {
      expect(schedule.getProhibitedWindow(at(9, 0)), isNull);
      expect(schedule.getProhibitedWindow(at(17, 20)), isNull);
    });
  });
}
