// lib/models/theme_setting.dart

/// The user's theme choice. Light and Dark are fixed; Auto is dark from
/// sunset until sunrise.
enum ThemeSetting {
  light,
  dark,
  auto;

  String get label {
    switch (this) {
      case ThemeSetting.light:
        return 'Light';
      case ThemeSetting.dark:
        return 'Dark';
      case ThemeSetting.auto:
        return 'Auto (sunrise / sunset)';
    }
  }

  /// Parses a stored [name]; null if it isn't one of the values.
  static ThemeSetting? fromName(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// Whether [now] is between today's [sunset] and [sunrise] (night).
bool isNightAt(
  DateTime now, {
  required DateTime sunrise,
  required DateTime sunset,
}) {
  return now.isBefore(sunrise) || !now.isBefore(sunset);
}

/// When the auto theme next needs re-checking: today's sunrise or sunset,
/// or after sunset the next midnight (when the new day's times are fetched).
DateTime nextThemeEvent(
  DateTime now, {
  required DateTime sunrise,
  required DateTime sunset,
}) {
  if (now.isBefore(sunrise)) return sunrise;
  if (now.isBefore(sunset)) return sunset;
  return DateTime(now.year, now.month, now.day + 1);
}
