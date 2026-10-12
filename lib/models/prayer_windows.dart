// lib/models/prayer_windows.dart
//
// Time windows that drive the full-screen states:
// iqamah countdown -> prayer time started -> prayer in progress, and the
// prohibited-time alert.
import '../utils/constants.dart';
import 'prayer_time.dart';

/// Iqamah countdown, shown before iqamah.
const Duration kIqamahCountdownDuration = AppConstants.countdownWarningTime;

/// "Prayer time started" screen, shown from iqamah.
const Duration kPrayerStartedDuration = Duration(seconds: 30);

/// "Prayer in progress" screen, shown after the started screen.
const Duration kPrayerInProgressDuration = AppConstants.blackoutDuration;

enum PrayerPhase { iqamahCountdown, prayerStarted, prayerInProgress }

/// The full-screen phase around a prayer's iqamah.
class PrayerPhaseState {
  final PrayerPhase phase;
  final PrayerTime prayer;
  final DateTime iqamah;
  final DateTime endsAt;

  const PrayerPhaseState({
    required this.phase,
    required this.prayer,
    required this.iqamah,
    required this.endsAt,
  });

  Duration remaining(DateTime now) => endsAt.difference(now);
}

/// Lengths of the windows in which voluntary prayer is not permitted.
const Duration kSunriseProhibitedDuration = Duration(minutes: 15);
const Duration kZenithProhibitedDuration = Duration(minutes: 10);
const Duration kSunsetProhibitedDuration = Duration(minutes: 20);

/// A period during which prayer is not permitted.
class ProhibitedWindow {
  /// Key into [Bilingual.prayerNames]: 'Sunrise', 'Zenith' or 'Sunset'.
  final String name;
  final DateTime start;
  final DateTime end;

  const ProhibitedWindow({
    required this.name,
    required this.start,
    required this.end,
  });

  Duration remaining(DateTime now) => end.difference(now);

  /// Identifies this window for the day, e.g. to remember a dismissal.
  String get id => '$name-${start.toIso8601String()}';
}

extension PrayerWindows on PrayerSchedule {
  /// The prayers held in congregation on [now]'s day: the five daily
  /// prayers, with Jummah in place of Dhuhr on Fridays.
  List<PrayerTime> congregationalPrayers(DateTime now) {
    final isFriday = now.weekday == DateTime.friday;
    return getMainPrayers().where((p) {
      if (p.name == 'Dhuhr') return !isFriday;
      if (p.name == 'Jummah') return isFriday;
      return true;
    }).toList();
  }

  /// The full-screen phase at [now], if any: the iqamah countdown, then
  /// "prayer time started", then "prayer in progress", then nothing.
  PrayerPhaseState? getPrayerPhase(DateTime now) {
    for (final prayer in congregationalPrayers(now)) {
      final iqamah = prayer.getIqamaTime();
      if (iqamah == null) continue;

      final countdownStart = iqamah.subtract(kIqamahCountdownDuration);
      final startedEnd = iqamah.add(kPrayerStartedDuration);
      final inProgressEnd = startedEnd.add(kPrayerInProgressDuration);
      if (now.isBefore(countdownStart) || !now.isBefore(inProgressEnd)) {
        continue;
      }

      final (phase, endsAt) =
          now.isBefore(iqamah)
              ? (PrayerPhase.iqamahCountdown, iqamah)
              : now.isBefore(startedEnd)
              ? (PrayerPhase.prayerStarted, startedEnd)
              : (PrayerPhase.prayerInProgress, inProgressEnd);
      return PrayerPhaseState(
        phase: phase,
        prayer: prayer,
        iqamah: iqamah,
        endsAt: endsAt,
      );
    }
    return null;
  }

  /// The prohibited window containing [now], if any.
  ProhibitedWindow? getProhibitedWindow(DateTime now) {
    DateTime? waqt(String name) => getPrayerByName(name)?.getWaqtTime();

    final sunrise = waqt('Sunrise');
    final dhuhr = waqt('Dhuhr');
    final sunset = waqt('Sunset') ?? waqt('Maghrib');

    final windows = <ProhibitedWindow>[
      if (sunrise != null)
        ProhibitedWindow(
          name: 'Sunrise',
          start: sunrise,
          end: sunrise.add(kSunriseProhibitedDuration),
        ),
      if (dhuhr != null)
        ProhibitedWindow(
          name: 'Zenith',
          start: dhuhr.subtract(kZenithProhibitedDuration),
          end: dhuhr,
        ),
      if (sunset != null)
        ProhibitedWindow(
          name: 'Sunset',
          start: sunset.subtract(kSunsetProhibitedDuration),
          end: sunset,
        ),
    ];

    for (final w in windows) {
      if (!now.isBefore(w.start) && now.isBefore(w.end)) return w;
    }
    return null;
  }
}
