// lib/models/prayer_time.dart
import 'package:intl/intl.dart';

class PrayerTime {
  final String name;
  final String waqt;
  final String iqama;

  PrayerTime({
    required this.name,
    required this.waqt,
    required this.iqama,
  });

  /// Parse time string to DateTime for today
  DateTime? getWaqtTime() {
    return _parseTimeForToday(waqt);
  }

  /// Parse iqama time string to DateTime for today
  DateTime? getIqamaTime() {
    return _parseTimeForToday(iqama);
  }

  /// Get the next prayer time (prefers iqama if available)
  DateTime? getNextTime() {
    final iqamaTime = getIqamaTime();
    if (iqamaTime != null && iqama.trim().isNotEmpty) {
      return iqamaTime;
    }
    return getWaqtTime();
  }

  /// Check if this prayer is the next one
  bool isNext(DateTime now) {
    final nextTime = getNextTime();
    if (nextTime == null) return false;
    return nextTime.isAfter(now) || _isSameMinute(nextTime, now);
  }

  /// Parse time string like "12:30 PM" or "14:30" to DateTime for today
  static DateTime? _parseTimeForToday(String raw) {
    if (raw.trim().isEmpty) return null;

    final lower = raw.toLowerCase();
    int dayOffset = 0;
    if (lower.contains('next') ||
        lower.contains('tomorrow') ||
        lower.contains('next day')) {
      dayOffset = 1;
    }

    final cleaned = raw.replaceAll(RegExp(r"\(.*?\)"), '').trim();

    final timeMatch = RegExp(r'([0-9]{1,2}:[0-9]{2}(?:\s*[apAP][\.]?[mM][\.]?)?)')
        .firstMatch(cleaned);
    String? timeToken = timeMatch?.group(1)?.trim();
    if (timeToken == null) {
      final m2 = RegExp(r'([0-9]{1,2}:[0-9]{2})').firstMatch(cleaned);
      timeToken = m2?.group(1);
    }
    if (timeToken == null) return null;

    timeToken = timeToken.replaceAll('.', '').toUpperCase();
    timeToken = timeToken.replaceAllMapped(
        RegExp(r'([0-9])([AP]M)$'), (m) => '${m.group(1)} ${m.group(2)}');

    int hour = 0;
    int minute = 0;

    try {
      if (timeToken.contains(RegExp(r'[AP]M'))) {
        final parsed = DateFormat('h:mm a').parse(timeToken);
        hour = parsed.hour;
        minute = parsed.minute;
      } else {
        final parts = timeToken.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);

        // Validate hour range
        if (hour < 0 || hour > 23) {
          return null;
        }
      }

      // Validate minute range
      if (minute < 0 || minute > 59) {
        return null;
      }
    } catch (_) {
      return null;
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
  }

  static bool _isSameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  /// Trim time string to show only the time part
  static String trimTime(String raw) {
    final m =
        RegExp(r'([0-9]{1,2}:[0-9]{2}(?:\s*[APMapm\.]{0,5})?)').firstMatch(raw);
    return m?.group(1) ?? raw;
  }

  /// Create PrayerTime from raw timings map
  /// If iqamaMap is empty or doesn't have the prayer, fallback to waqt (for initial setup)
  factory PrayerTime.fromMaps({
    required String name,
    required Map<String, String> timings,
    required Map<String, String> iqamaMap,
  }) {
    final waqt = timings[name] ?? '-';
    // Fallback to waqt only if iqamaMap doesn't have this prayer (initial setup)
    final iqama = iqamaMap[name] ?? waqt;
    return PrayerTime(name: name, waqt: waqt, iqama: iqama);
  }

  /// Copy with new values
  PrayerTime copyWith({
    String? name,
    String? waqt,
    String? iqama,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      waqt: waqt ?? this.waqt,
      iqama: iqama ?? this.iqama,
    );
  }

  @override
  String toString() => 'PrayerTime(name: $name, waqt: $waqt, iqama: $iqama)';
}

class PrayerSchedule {
  final Map<String, String> timings;
  final Map<String, String> iqamaMap;
  final DateTime fetchedAt;

  PrayerSchedule({
    required this.timings,
    required this.iqamaMap,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// Get all prayer times as list
  List<PrayerTime> getAllPrayers() {
    final prayers = <PrayerTime>[];
    for (final name in timings.keys) {
      prayers.add(PrayerTime.fromMaps(
        name: name,
        timings: timings,
        iqamaMap: iqamaMap,
      ));
    }

    // Add Jummah prayer with Dhuhr waqt and custom iqama
    final dhuhrWaqt = timings['Dhuhr'];
    if (dhuhrWaqt != null) {
      prayers.add(PrayerTime(
        name: 'Jummah',
        waqt: dhuhrWaqt,
        iqama: iqamaMap['Jummah'] ?? '12:30',
      ));
    }

    return prayers;
  }

  /// Get only main prayers (exclude Sunrise, etc.)
  List<PrayerTime> getMainPrayers() {
    final mainNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Jummah'];
    return getAllPrayers().where((p) => mainNames.contains(p.name)).toList();
  }

  /// Get all prayers in order
  List<PrayerTime> getPrayersInOrder() {
    final order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final prayers = <PrayerTime>[];
    for (final name in order) {
      if (timings.containsKey(name)) {
        prayers.add(PrayerTime.fromMaps(
          name: name,
          timings: timings,
          iqamaMap: iqamaMap,
        ));
      }
    }
    // Add Jummah at the end (uses Dhuhr waqt)
    if (timings.containsKey('Dhuhr')) {
      prayers.add(PrayerTime(
        name: 'Jummah',
        waqt: timings['Dhuhr']!,
        iqama: iqamaMap['Jummah'] ?? '12:30',
      ));
    }
    return prayers;
  }

  /// Find the next prayer
  PrayerTime? getNextPrayer() {
    final now = DateTime.now();
    final isFriday = now.weekday == DateTime.friday;
    final prayers = getPrayersInOrder();

    // Find next prayer today
    for (final prayer in prayers) {
      // On Fridays, skip Dhuhr in next prayer calculation
      if (isFriday && prayer.name == 'Dhuhr') {
        continue;
      }

      final nextTime = prayer.getNextTime();
      if (nextTime != null &&
          (nextTime.isAfter(now) || _isSameMinute(nextTime, now))) {
        return prayer;
      }
    }

    // If no prayer left today, return first prayer (for tomorrow)
    return prayers.isNotEmpty ? prayers.first : null;
  }

  /// Get time remaining until next prayer
  Duration getTimeToNextPrayer() {
    final nextPrayer = getNextPrayer();
    if (nextPrayer == null) return Duration.zero;

    final now = DateTime.now();
    final nextTime = nextPrayer.getNextTime();
    if (nextTime == null) return Duration.zero;

    // If it's tomorrow's prayer
    if (nextTime.isBefore(now)) {
      final tomorrow = DateTime(
          now.year, now.month, now.day + 1, nextTime.hour, nextTime.minute);
      return tomorrow.difference(now);
    }

    return nextTime.difference(now);
  }

  /// Get specific prayer by name
  PrayerTime? getPrayerByName(String name) {
    if (!timings.containsKey(name)) return null;
    return PrayerTime.fromMaps(
      name: name,
      timings: timings,
      iqamaMap: iqamaMap,
    );
  }

  /// Update iqama time for a prayer
  PrayerSchedule updateIqama(String prayerName, String newIqama) {
    final newIqamaMap = Map<String, String>.from(iqamaMap);
    newIqamaMap[prayerName] = newIqama;
    return PrayerSchedule(
      timings: timings,
      iqamaMap: newIqamaMap,
      fetchedAt: fetchedAt,
    );
  }

  static bool _isSameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  @override
  String toString() =>
      'PrayerSchedule(prayers: ${timings.length}, fetched: $fetchedAt)';
}
