// test/widget/display_layout_test.dart
//
// Renders the masjid display at common screen sizes, landscape and portrait,
// at every text size. Flutter fails a test on any layout overflow, so this
// catches text that no longer fits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/notification_model.dart';
import 'package:prayer_app/models/prayer_time.dart';
import 'package:prayer_app/models/text_size.dart';
import 'package:prayer_app/screens/display_home.dart';

import '../helpers/display_fonts.dart';

void main() {
  setUpAll(loadDisplayFonts);

  final schedule = PrayerSchedule(
    timings: const {
      'Fajr': '04:45',
      'Sunrise': '06:05',
      'Dhuhr': '11:50',
      'Asr': '15:05',
      'Sunset': '17:20',
      'Maghrib': '17:20',
      'Isha': '18:40',
    },
    iqamaMap: const {
      'Fajr': '05:15',
      'Dhuhr': '13:00',
      'Asr': '15:30',
      'Maghrib': '17:25',
      'Isha': '19:30',
      'Jumuah': '13:15',
    },
  );

  final now = DateTime.now();
  MosqueNotification notice(
    String id,
    String type,
    String title,
  ) => MosqueNotification.fromMap({
    'id': id,
    'title': title,
    'message':
        'Please join us after Isha for a short talk and light refreshments. '
        'Sisters\' area available.',
    'type': type,
    'priority': 'regular',
    'active': true,
    'createdAt': now.millisecondsSinceEpoch,
    'expiresAt': now.add(const Duration(days: 3)).millisecondsSinceEpoch,
  });

  final notices = [
    notice('a', 'announcement', 'Jumuah khutbah in English and Arabic'),
    notice('b', 'event', 'Weekly study circle'),
  ];

  const screens = {
    'landscape 1920x1080': Size(1920, 1080),
    'portrait 1080x1920': Size(1080, 1920),
    'landscape 1366x768': Size(1366, 768),
    'portrait 768x1366': Size(768, 1366),
  };

  for (final MapEntry(key: name, value: size) in screens.entries) {
    for (final textSize in TextSize.values) {
      for (final withNotices in [true, false]) {
        for (final web in [false, true]) {
          final label =
              '$name, ${textSize.label} text, '
              '${withNotices ? 'with' : 'no'} notices${web ? ', web table size' : ''}';
          testWidgets('display fits: $label', (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(textSize.factor),
                  ),
                  child: Scaffold(
                    body: DisplayHome(
                      prayerSchedule: schedule,
                      nextPrayer: schedule.getPrayerByName('Asr'),
                      timeToNext: const Duration(minutes: 42),
                      notifications: withNotices ? notices : const [],
                      prayerTableFontScale: web ? kWebPrayerTableFontScale : 1,
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 100));

            expect(tester.takeException(), isNull);
            expect(find.byType(DisplayHome), findsOneWidget);

            // Dispose, so the rotation timers stop.
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
