// test/unit/models/notification_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/notification_model.dart';

void main() {
  group('NotificationType Enum', () {
    test('displayName returns correct strings', () {
      expect(NotificationType.announcement.displayName, 'Announcement');
      expect(NotificationType.event.displayName, 'Event');
      expect(NotificationType.alert.displayName, 'Alert');
    });

    test('icon returns correct IconData', () {
      expect(NotificationType.announcement.icon, Icons.campaign);
      expect(NotificationType.event.icon, Icons.event);
      expect(NotificationType.alert.icon, Icons.warning_amber_rounded);
    });

    test('fromString parses correctly', () {
      expect(NotificationType.fromString('event'), NotificationType.event);
      expect(NotificationType.fromString('EVENT'), NotificationType.event);
      expect(NotificationType.fromString('alert'), NotificationType.alert);
      expect(NotificationType.fromString('ALERT'), NotificationType.alert);
      expect(
          NotificationType.fromString('announcement'),
          NotificationType.announcement);
    });

    test('fromString defaults to announcement for unknown values', () {
      expect(NotificationType.fromString('unknown'),
          NotificationType.announcement);
      expect(NotificationType.fromString(''), NotificationType.announcement);
      expect(NotificationType.fromString(null), NotificationType.announcement);
    });

    test('toFirestore returns correct string', () {
      expect(NotificationType.announcement.toFirestore(), 'announcement');
      expect(NotificationType.event.toFirestore(), 'event');
      expect(NotificationType.alert.toFirestore(), 'alert');
    });
  });

  group('NotificationPriority Enum', () {
    test('displayName returns correct strings', () {
      expect(NotificationPriority.high.displayName, 'High');
      expect(NotificationPriority.regular.displayName, 'Regular');
      expect(NotificationPriority.low.displayName, 'Low');
    });

    test('color returns correct colors', () {
      expect(NotificationPriority.high.color, const Color(0xFFFF9800));
      expect(NotificationPriority.regular.color, const Color(0xFF1E88E5));
      expect(NotificationPriority.low.color, const Color(0xFF757575));
    });

    test('backgroundColor returns correct colors', () {
      expect(NotificationPriority.high.backgroundColor,
          const Color(0xFFFFF3E0));
      expect(NotificationPriority.regular.backgroundColor,
          const Color(0xFFE3F2FD));
      expect(
          NotificationPriority.low.backgroundColor, const Color(0xFFF5F5F5));
    });

    test('fromString parses correctly', () {
      expect(NotificationPriority.fromString('high'), NotificationPriority.high);
      expect(NotificationPriority.fromString('HIGH'), NotificationPriority.high);
      expect(NotificationPriority.fromString('low'), NotificationPriority.low);
      expect(NotificationPriority.fromString('LOW'), NotificationPriority.low);
      expect(NotificationPriority.fromString('regular'),
          NotificationPriority.regular);
    });

    test('fromString defaults to regular for unknown values', () {
      expect(NotificationPriority.fromString('unknown'),
          NotificationPriority.regular);
      expect(
          NotificationPriority.fromString(''), NotificationPriority.regular);
      expect(
          NotificationPriority.fromString(null), NotificationPriority.regular);
    });

    test('toFirestore returns correct string', () {
      expect(NotificationPriority.high.toFirestore(), 'high');
      expect(NotificationPriority.regular.toFirestore(), 'regular');
      expect(NotificationPriority.low.toFirestore(), 'low');
    });
  });

  group('MosqueNotification Factory Methods', () {
    test('empty() creates empty notification', () {
      final notification = MosqueNotification.empty();

      expect(notification.id, '');
      expect(notification.title, '');
      expect(notification.message, '');
      expect(notification.type, NotificationType.announcement);
      expect(notification.priority, NotificationPriority.regular);
      expect(notification.active, false);
      expect(notification.postedBy, '');
      expect(notification.postedByRole, 'Staff');
      expect(notification.eventTime, null);
    });

    test('create() creates new notification with generated values', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      final notification = MosqueNotification.create(
        title: 'Test Title',
        message: 'Test Message',
        type: NotificationType.event,
        priority: NotificationPriority.high,
        postedBy: 'admin@mosque.com',
        postedByRole: 'Admin',
        expiresAt: expiresAt,
      );

      expect(notification.id, ''); // Will be set by Firestore
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.type, NotificationType.event);
      expect(notification.priority, NotificationPriority.high);
      expect(notification.active, true);
      expect(notification.postedBy, 'admin@mosque.com');
      expect(notification.postedByRole, 'Admin');
      expect(notification.expiresAt, expiresAt);
    });

    test('legacy() creates notification with backward-compatible parameters', () {
      final timestamp = DateTime.now();

      final notification = MosqueNotification.legacy(
        title: 'Legacy Title',
        message: 'Legacy Message',
        active: true,
        postedBy: 'admin@mosque.com',
        timestamp: timestamp,
      );

      expect(notification.title, 'Legacy Title');
      expect(notification.message, 'Legacy Message');
      expect(notification.active, true);
      expect(notification.postedBy, 'admin@mosque.com');
      expect(notification.createdAt, timestamp);
      expect(notification.type, NotificationType.announcement);
      expect(notification.priority, NotificationPriority.regular);
      expect(notification.postedByRole, 'Staff');
    });

    test('fromMap() creates notification from map', () {
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(days: 7));

      final map = {
        'id': 'test-id',
        'title': 'Map Title',
        'message': 'Map Message',
        'type': 'alert',
        'priority': 'high',
        'active': true,
        'postedBy': 'admin@mosque.com',
        'postedByRole': 'Admin',
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
      };

      final notification = MosqueNotification.fromMap(map);

      expect(notification.id, 'test-id');
      expect(notification.title, 'Map Title');
      expect(notification.message, 'Map Message');
      expect(notification.type, NotificationType.alert);
      expect(notification.priority, NotificationPriority.high);
      expect(notification.active, true);
      expect(notification.postedBy, 'admin@mosque.com');
      expect(notification.postedByRole, 'Admin');
    });

    test('fromJsonString() creates notification from JSON', () {
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(days: 7));

      final jsonString = '''
      {
        "id": "json-id",
        "title": "JSON Title",
        "message": "JSON Message",
        "type": "event",
        "priority": "regular",
        "active": true,
        "postedBy": "admin@mosque.com",
        "postedByRole": "Admin",
        "createdAt": ${createdAt.millisecondsSinceEpoch},
        "expiresAt": ${expiresAt.millisecondsSinceEpoch}
      }
      ''';

      final notification = MosqueNotification.fromJsonString(jsonString);

      expect(notification.id, 'json-id');
      expect(notification.title, 'JSON Title');
      expect(notification.message, 'JSON Message');
      expect(notification.type, NotificationType.event);
      expect(notification.priority, NotificationPriority.regular);
    });

    test('fromJsonString() returns empty on invalid JSON', () {
      final notification =
          MosqueNotification.fromJsonString('invalid json {');

      expect(notification.id, '');
      expect(notification.title, '');
    });
  });

  group('MosqueNotification Serialization', () {
    late MosqueNotification testNotification;
    late DateTime createdAt;
    late DateTime expiresAt;

    setUp(() {
      createdAt = DateTime(2025, 12, 3, 10, 30);
      expiresAt = createdAt.add(const Duration(days: 7));

      testNotification = MosqueNotification(
        id: 'test-123',
        title: 'Test Notification',
        message: 'Test message content',
        type: NotificationType.event,
        priority: NotificationPriority.high,
        active: true,
        postedBy: 'admin@mosque.com',
        postedByRole: 'Admin',
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
    });

    test('toMap() creates correct map', () {
      final map = testNotification.toMap();

      expect(map['id'], 'test-123');
      expect(map['title'], 'Test Notification');
      expect(map['message'], 'Test message content');
      expect(map['type'], 'event');
      expect(map['priority'], 'high');
      expect(map['active'], true);
      expect(map['postedBy'], 'admin@mosque.com');
      expect(map['postedByRole'], 'Admin');
      expect(map['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(map['expiresAt'], expiresAt.millisecondsSinceEpoch);
    });

    test('toJsonString() creates valid JSON', () {
      final jsonString = testNotification.toJsonString();

      expect(jsonString, isNotEmpty);
      expect(jsonString, contains('"id":"test-123"'));
      expect(jsonString, contains('"title":"Test Notification"'));
    });

    test('toMap/fromMap roundtrip preserves data', () {
      final map = testNotification.toMap();
      final restored = MosqueNotification.fromMap(map);

      expect(restored.id, testNotification.id);
      expect(restored.title, testNotification.title);
      expect(restored.message, testNotification.message);
      expect(restored.type, testNotification.type);
      expect(restored.priority, testNotification.priority);
      expect(restored.active, testNotification.active);
    });
  });

  group('MosqueNotification Getters', () {
    test('hasContent returns true for non-empty message', () {
      final notification = MosqueNotification.empty().copyWith(
        message: 'Test message',
      );

      expect(notification.hasContent, true);
    });

    test('hasContent returns false for empty/whitespace message', () {
      expect(MosqueNotification.empty().hasContent, false);

      final whitespaceNotification = MosqueNotification.empty().copyWith(
        message: '   ',
      );
      expect(whitespaceNotification.hasContent, false);
    });

    test('isExpired returns true when past expiry', () {
      final expiredNotification = MosqueNotification.empty().copyWith(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expiredNotification.isExpired, true);
    });

    test('isExpired returns false when not expired', () {
      final validNotification = MosqueNotification.empty().copyWith(
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(validNotification.isExpired, false);
    });

    test('shouldShow returns true when active, has content, not expired', () {
      final notification = MosqueNotification(
        id: 'test',
        title: 'Title',
        message: 'Message',
        type: NotificationType.announcement,
        priority: NotificationPriority.regular,
        active: true,
        postedBy: 'admin',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(notification.shouldShow, true);
    });

    test('shouldShow returns false when inactive', () {
      final notification = MosqueNotification.empty().copyWith(
        active: false,
        message: 'Message',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(notification.shouldShow, false);
    });

    test('shouldShow returns false when expired', () {
      final notification = MosqueNotification.empty().copyWith(
        active: true,
        message: 'Message',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(notification.shouldShow, false);
    });

    test('isHighPriority returns true for high priority', () {
      final notification = MosqueNotification.empty().copyWith(
        priority: NotificationPriority.high,
      );

      expect(notification.isHighPriority, true);
    });

    test('isHighPriority returns false for other priorities', () {
      expect(
        MosqueNotification.empty()
            .copyWith(priority: NotificationPriority.regular)
            .isHighPriority,
        false,
      );
      expect(
        MosqueNotification.empty()
            .copyWith(priority: NotificationPriority.low)
            .isHighPriority,
        false,
      );
    });

    test('isEvent returns true for event type', () {
      final notification = MosqueNotification.empty().copyWith(
        type: NotificationType.event,
      );

      expect(notification.isEvent, true);
    });

    test('isAlert returns true for alert type', () {
      final notification = MosqueNotification.empty().copyWith(
        type: NotificationType.alert,
      );

      expect(notification.isAlert, true);
    });

    test('effectivePriorityColor returns red for high priority alert', () {
      final notification = MosqueNotification.empty().copyWith(
        type: NotificationType.alert,
        priority: NotificationPriority.high,
      );

      expect(notification.effectivePriorityColor, const Color(0xFFE53935));
    });

    test('effectivePriorityColor returns priority color for non-alerts', () {
      final notification = MosqueNotification.empty().copyWith(
        type: NotificationType.event,
        priority: NotificationPriority.high,
      );

      expect(notification.effectivePriorityColor,
          NotificationPriority.high.color);
    });

    test('effectivePriorityBgColor returns light red for high priority alert',
        () {
      final notification = MosqueNotification.empty().copyWith(
        type: NotificationType.alert,
        priority: NotificationPriority.high,
      );

      expect(notification.effectivePriorityBgColor, const Color(0xFFFFEBEE));
    });

    test('timeUntilExpiry calculates correct duration', () {
      final futureExpiry = DateTime.now().add(const Duration(hours: 24));
      final notification = MosqueNotification.empty().copyWith(
        expiresAt: futureExpiry,
      );

      final duration = notification.timeUntilExpiry;
      expect(duration.inHours, greaterThanOrEqualTo(23));
      expect(duration.inHours, lessThanOrEqualTo(24));
    });

    test('timeUntilExpiry returns zero for expired notifications', () {
      final notification = MosqueNotification.empty().copyWith(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(notification.timeUntilExpiry, Duration.zero);
    });

    test('expiryText shows days remaining', () {
      final notification = MosqueNotification.empty().copyWith(
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      );

      expect(notification.expiryText, contains('d left'));
    });

    test('expiryText shows hours remaining', () {
      final notification = MosqueNotification.empty().copyWith(
        expiresAt: DateTime.now().add(const Duration(hours: 5)),
      );

      expect(notification.expiryText, contains('h left'));
    });

    test('expiryText shows minutes remaining', () {
      final notification = MosqueNotification.empty().copyWith(
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      expect(notification.expiryText, contains('m left'));
    });

    test('expiryText shows "Expired" for past notifications', () {
      final notification = MosqueNotification.empty().copyWith(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(notification.expiryText, 'Expired');
    });
  });

  group('MosqueNotification Methods', () {
    test('getPreview() returns first line', () {
      final notification = MosqueNotification.empty().copyWith(
        message: 'First line\nSecond line\nThird line',
      );

      expect(notification.getPreview(), 'First line');
    });

    test('getPreview() truncates long lines', () {
      final longMessage = 'a' * 150;
      final notification = MosqueNotification.empty().copyWith(
        message: longMessage,
      );

      final preview = notification.getPreview(maxLength: 100);
      expect(preview.length, 103); // 100 + '...'
      expect(preview, endsWith('...'));
    });

    test('getPreview() returns empty for empty message', () {
      final notification = MosqueNotification.empty();

      expect(notification.getPreview(), '');
    });

    test('copyWith() creates new instance with updated fields', () {
      final original = MosqueNotification.empty();
      final updated = original.copyWith(
        title: 'New Title',
        message: 'New Message',
        priority: NotificationPriority.high,
      );

      expect(updated.title, 'New Title');
      expect(updated.message, 'New Message');
      expect(updated.priority, NotificationPriority.high);
      expect(updated.id, original.id);
      expect(updated.type, original.type);
    });

    test('toString() includes key information', () {
      final notification = MosqueNotification(
        id: 'test-123',
        title: 'Test',
        message: 'Message',
        type: NotificationType.event,
        priority: NotificationPriority.high,
        active: true,
        postedBy: 'admin',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      final str = notification.toString();
      expect(str, contains('test-123'));
      expect(str, contains('Test'));
      expect(str, contains('Event'));
      expect(str, contains('High'));
    });

    test('equality operator compares by id', () {
      final notification1 = MosqueNotification.empty().copyWith(id: 'id-1');
      final notification2 = MosqueNotification.empty().copyWith(id: 'id-1');
      final notification3 = MosqueNotification.empty().copyWith(id: 'id-2');

      expect(notification1, equals(notification2));
      expect(notification1, isNot(equals(notification3)));
    });

    test('hashCode is based on id', () {
      final notification1 = MosqueNotification.empty().copyWith(id: 'id-1');
      final notification2 = MosqueNotification.empty().copyWith(id: 'id-1');
      final notification3 = MosqueNotification.empty().copyWith(id: 'id-2');

      expect(notification1.hashCode, equals(notification2.hashCode));
      expect(notification1.hashCode, isNot(equals(notification3.hashCode)));
    });
  });

  group('NotificationListExtension', () {
    late List<MosqueNotification> testList;

    setUp(() {
      final now = DateTime.now();
      testList = [
        MosqueNotification(
          id: '1',
          title: 'High Priority Alert',
          message: 'Important alert',
          type: NotificationType.alert,
          priority: NotificationPriority.high,
          active: true,
          postedBy: 'admin',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 1)),
        ),
        MosqueNotification(
          id: '2',
          title: 'Regular Event',
          message: 'Regular event',
          type: NotificationType.event,
          priority: NotificationPriority.regular,
          active: true,
          postedBy: 'admin',
          createdAt: now.subtract(const Duration(days: 1)),
          expiresAt: now.add(const Duration(days: 2)),
        ),
        MosqueNotification(
          id: '3',
          title: 'Inactive',
          message: 'Inactive notification',
          type: NotificationType.announcement,
          priority: NotificationPriority.low,
          active: false,
          postedBy: 'admin',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 3)),
        ),
        MosqueNotification(
          id: '4',
          title: 'Expired',
          message: 'Expired notification',
          type: NotificationType.announcement,
          priority: NotificationPriority.regular,
          active: true,
          postedBy: 'admin',
          createdAt: now.subtract(const Duration(days: 10)),
          expiresAt: now.subtract(const Duration(days: 1)),
        ),
      ];
    });

    test('activeOnly filters out inactive and expired', () {
      final active = testList.activeOnly;

      expect(active.length, 2);
      expect(active.every((n) => n.shouldShow), true);
    });

    test('highPriorityOnly filters high priority notifications', () {
      final highPriority = testList.highPriorityOnly;

      expect(highPriority.length, 1);
      expect(highPriority.first.priority, NotificationPriority.high);
    });

    test('excludingHighPriority filters out high priority', () {
      final excluding = testList.excludingHighPriority;

      expect(excluding.every((n) => !n.isHighPriority), true);
      expect(excluding.any((n) => n.priority == NotificationPriority.high),
          false);
    });

    test('sortedByExpiry sorts by expiry date', () {
      final sorted = testList.sortedByExpiry;

      for (int i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].expiresAt.isBefore(sorted[i + 1].expiresAt) ||
              sorted[i].expiresAt == sorted[i + 1].expiresAt,
          true,
        );
      }
    });

    test('sortedByNewest sorts by creation date descending', () {
      final sorted = testList.sortedByNewest;

      for (int i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].createdAt.isAfter(sorted[i + 1].createdAt) ||
              sorted[i].createdAt == sorted[i + 1].createdAt,
          true,
        );
      }
    });

    test('groupedByType groups notifications by type', () {
      final grouped = testList.groupedByType;

      expect(grouped.containsKey(NotificationType.alert), true);
      expect(grouped.containsKey(NotificationType.event), true);
      expect(grouped.containsKey(NotificationType.announcement), true);
      expect(grouped[NotificationType.alert]?.length, 1);
      expect(grouped[NotificationType.event]?.length, 1);
      expect(grouped[NotificationType.announcement]?.length, 2);
    });

    test('priorityNotification returns high priority notification closest to expiry',
        () {
      final priority = testList.priorityNotification;

      expect(priority, isNotNull);
      expect(priority!.priority, NotificationPriority.high);
      expect(priority.id, '1');
    });

    test('priorityNotification returns null when no high priority notifications',
        () {
      final listWithoutHighPriority = testList
          .where((n) => n.priority != NotificationPriority.high)
          .toList();

      expect(listWithoutHighPriority.priorityNotification, null);
    });
  });
}
