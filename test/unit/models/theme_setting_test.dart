import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/theme_setting.dart';
import 'package:prayer_app/services/storage_service.dart';
import 'package:prayer_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final sunrise = DateTime(2026, 10, 14, 5, 50);
  final sunset = DateTime(2026, 10, 14, 17, 10);
  DateTime at(int hour, int minute) => DateTime(2026, 10, 14, hour, minute);

  group('isNightAt', () {
    bool night(DateTime now) =>
        isNightAt(now, sunrise: sunrise, sunset: sunset);

    test('before sunrise is night', () => expect(night(at(4, 0)), isTrue));
    test('at sunrise is day', () => expect(night(at(5, 50)), isFalse));
    test('midday is day', () => expect(night(at(12, 0)), isFalse));
    test('at sunset is night', () => expect(night(at(17, 10)), isTrue));
    test('late evening is night', () => expect(night(at(23, 0)), isTrue));
  });

  group('nextThemeEvent', () {
    DateTime next(DateTime now) =>
        nextThemeEvent(now, sunrise: sunrise, sunset: sunset);

    test('before sunrise -> sunrise', () => expect(next(at(3, 0)), sunrise));
    test('during the day -> sunset', () => expect(next(at(12, 0)), sunset));
    test('after sunset -> next midnight', () {
      expect(next(at(20, 0)), DateTime(2026, 10, 15));
    });
    test('month end rolls over', () {
      final now = DateTime(2026, 10, 31, 21, 0);
      expect(
        nextThemeEvent(now, sunrise: sunrise, sunset: sunset),
        DateTime(2026, 11, 1),
      );
    });
  });

  group('ThemeSetting.fromName', () {
    test('parses stored names', () {
      for (final value in ThemeSetting.values) {
        expect(ThemeSetting.fromName(value.name), value);
      }
    });
    test('unknown or missing -> null', () {
      expect(ThemeSetting.fromName('sepia'), isNull);
      expect(ThemeSetting.fromName(null), isNull);
    });
  });

  group('StorageService.getThemeSetting migration', () {
    Future<ThemeSetting> load(Map<String, Object> stored) async {
      SharedPreferences.setMockInitialValues(stored);
      await StorageService.init();
      return StorageService.getThemeSetting();
    }

    test('nothing stored -> auto', () async {
      expect(await load({}), ThemeSetting.auto);
    });

    test('old auto (not manual) -> auto', () async {
      expect(await load({AppConstants.keyDarkMode: true}), ThemeSetting.auto);
    });

    test('old manual dark -> dark', () async {
      expect(
        await load({
          AppConstants.keyDarkMode: true,
          AppConstants.keyDarkModeManual: true,
        }),
        ThemeSetting.dark,
      );
    });

    test('old manual light -> light, and the result is saved', () async {
      expect(
        await load({
          AppConstants.keyDarkMode: false,
          AppConstants.keyDarkModeManual: true,
        }),
        ThemeSetting.light,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.keyThemeSetting), 'light');
      expect(prefs.containsKey(AppConstants.keyDarkModeManual), isFalse);
    });

    test('a stored setting wins', () async {
      expect(
        await load({
          AppConstants.keyThemeSetting: 'dark',
          AppConstants.keyDarkModeManual: true,
        }),
        ThemeSetting.dark,
      );
    });
  });
}
