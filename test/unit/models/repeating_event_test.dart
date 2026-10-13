// test/unit/models/repeating_event_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/notification_model.dart';

MosqueNotification weekly({
  List<int> days = const [DateTime.friday],
  String time = '19:30',
  DateTime? until,
  NotificationType type = NotificationType.event,
}) {
  return MosqueNotification(
    id: 'r1',
    title: 'Friday halaqa',
    message: 'After Isha',
    type: type,
    priority: NotificationPriority.regular,
    active: true,
    postedBy: 'admin@example.com',
    createdAt: DateTime(2026, 10, 1),
    expiresAt: DateTime(2100),
    repeatWeekdays: days,
    repeatTime: time,
    repeatUntil: until,
  );
}

void main() {
  // 2026-10-13 is a Tuesday; 2026-10-16 is a Friday.
  final tuesday = DateTime(2026, 10, 13, 12, 0);

  group('isRepeating', () {
    test('needs an event with weekdays and a time', () {
      expect(weekly().isRepeating, isTrue);
      expect(weekly(days: const []).isRepeating, isFalse);
      expect(weekly(type: NotificationType.announcement).isRepeating, isFalse);
    });
  });

  group('nextEventTime', () {
    test('next matching weekday at the repeat time', () {
      expect(weekly().nextEventTime(tuesday), DateTime(2026, 10, 16, 19, 30));
    });

    test('later today when today matches', () {
      final friMorning = DateTime(2026, 10, 16, 9, 0);
      expect(
        weekly().nextEventTime(friMorning),
        DateTime(2026, 10, 16, 19, 30),
      );
    });

    test('still today within an hour after it starts', () {
      final duringEvent = DateTime(2026, 10, 16, 20, 15);
      expect(
        weekly().nextEventTime(duringEvent),
        DateTime(2026, 10, 16, 19, 30),
      );
    });

    test('next week once today\'s has finished', () {
      final afterEvent = DateTime(2026, 10, 16, 20, 31);
      expect(
        weekly().nextEventTime(afterEvent),
        DateTime(2026, 10, 23, 19, 30),
      );
    });

    test('earliest of several weekdays', () {
      final n = weekly(days: const [DateTime.monday, DateTime.thursday]);
      expect(n.nextEventTime(tuesday), DateTime(2026, 10, 15, 19, 30));
    });

    test('null after the end date', () {
      final n = weekly(until: DateTime(2026, 10, 14));
      expect(n.nextEventTime(tuesday), isNull);
    });

    test('the end date itself still counts', () {
      final n = weekly(until: DateTime(2026, 10, 16));
      expect(n.nextEventTime(tuesday), DateTime(2026, 10, 16, 19, 30));
    });

    test('one-off events return eventTime', () {
      final eventTime = DateTime(2026, 11, 1, 18, 0);
      final n = weekly(days: const []).copyWith(eventTime: eventTime);
      expect(n.nextEventTime(tuesday), eventTime);
    });
  });

  group('repeatLabel', () {
    test('describes the weekdays', () {
      expect(weekly().repeatLabel, 'Every Friday');
      expect(
        weekly(days: const [DateTime.saturday, DateTime.sunday]).repeatLabel,
        'Every Sat & Sun',
      );
      expect(
        weekly(
          days: const [DateTime.monday, DateTime.wednesday, DateTime.friday],
        ).repeatLabel,
        'Every Mon, Wed & Fri',
      );
      expect(
        weekly(days: const [1, 2, 3, 4, 5, 6, 7]).repeatLabel,
        'Every day',
      );
      expect(weekly(days: const []).repeatLabel, isNull);
    });
  });

  group('serialisation', () {
    test('toMap/fromMap keeps the repeat rule', () {
      final n = weekly(
        days: const [DateTime.friday, DateTime.monday],
        until: DateTime(2026, 12, 31),
      );
      final back = MosqueNotification.fromMap(n.toMap());
      expect(back.repeatWeekdays, [DateTime.monday, DateTime.friday]);
      expect(back.repeatTime, '19:30');
      expect(back.repeatUntil, DateTime(2026, 12, 31));
      expect(back.isRepeating, isTrue);
    });

    test('older notices without repeat fields still load', () {
      final map =
          weekly().toMap()
            ..remove('repeatWeekdays')
            ..remove('repeatTime')
            ..remove('repeatUntil');
      final back = MosqueNotification.fromMap(map);
      expect(back.repeatWeekdays, isEmpty);
      expect(back.isRepeating, isFalse);
    });

    test('invalid stored values are ignored', () {
      final map =
          weekly().toMap()
            ..['repeatWeekdays'] = [0, 5, 5, 9, 'x']
            ..['repeatTime'] = '25:00';
      final back = MosqueNotification.fromMap(map);
      expect(back.repeatWeekdays, [DateTime.friday]);
      expect(back.repeatTime, isNull);
      expect(back.isRepeating, isFalse);
    });

    test('toFirestore writes the rule only for repeating events', () {
      final data = weekly(until: DateTime(2026, 12, 31)).toFirestore();
      expect(data['repeatWeekdays'], [DateTime.friday]);
      expect(data['repeatTime'], '19:30');
      expect(data['repeatUntil'], isA<Timestamp>());

      final oneOff = weekly(days: const []).toFirestore();
      expect(oneOff['repeatWeekdays'], isNull);
      expect(oneOff['repeatTime'], isNull);
    });
  });

  test('a weekly event without an end date does not expire', () {
    expect(weekly().isExpired, isFalse);
  });

  test('expiry badge says Weekly instead of a day count', () {
    expect(weekly().expiryText, 'Weekly');
  });
}
