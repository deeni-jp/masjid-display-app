// test/widget/widgets/notification_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/notification_model.dart';
import 'package:prayer_app/widgets/notification_card.dart';

void main() {
  group('NotificationCard Widget', () {
    late MosqueNotification testNotification;

    setUp(() {
      testNotification = MosqueNotification.create(
        title: 'Test Event',
        message: 'This is a test notification message',
        type: NotificationType.announcement,
        priority: NotificationPriority.regular,
        postedBy: 'test@example.com',
        postedByRole: 'Admin',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
    });

    testWidgets('displays notification title and message', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(notification: testNotification),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Event'), findsOneWidget);
      expect(find.text('This is a test notification message'), findsOneWidget);
    });

    testWidgets('shows type badge', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(notification: testNotification),
          ),
        ),
      );

      // Assert
      expect(find.text('Announcement'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows priority badge', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(notification: testNotification),
          ),
        ),
      );

      // Assert
      expect(find.text('Regular'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      MosqueNotification? tappedNotification;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: testNotification,
              onTap: (notification) {
                tapped = true;
                tappedNotification = notification;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
      expect(tappedNotification?.id, testNotification.id);
    });

    testWidgets('shows admin actions in admin mode', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: testNotification,
              adminMode: true,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('does not show admin actions when not in admin mode', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: testNotification,
              adminMode: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('shows read more text for long messages', (
      WidgetTester tester,
    ) async {
      // Arrange
      final longNotification = MosqueNotification.create(
        title: 'Long Message',
        message: 'A' * 200, // Very long message
        type: NotificationType.announcement,
        priority: NotificationPriority.regular,
        postedBy: 'test@example.com',
        postedByRole: 'Admin',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(notification: longNotification),
          ),
        ),
      );

      // Assert
      expect(find.text('Tap to read more'), findsOneWidget);
    });

    testWidgets('high priority notification has thicker border', (
      WidgetTester tester,
    ) async {
      // Arrange
      final highPriorityNotification = MosqueNotification.create(
        title: 'Urgent',
        message: 'High priority message',
        type: NotificationType.alert,
        priority: NotificationPriority.high,
        postedBy: 'test@example.com',
        postedByRole: 'Admin',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(notification: highPriorityNotification),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(InkWell),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isA<Border>());
      // High priority should have border width of 2
      final border = decoration.border as Border;
      expect(border.left.width, equals(2.0));
    });
  });

  group('EmptyNotificationState Widget', () {
    testWidgets('displays empty state message', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyNotificationState())),
      );

      // Assert
      expect(find.text('No announcements'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    });

    testWidgets('shows add button in admin mode', (WidgetTester tester) async {
      // Arrange
      bool addCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyNotificationState(
              adminMode: true,
              onAddNotification: () => addCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Add Announcement'), findsOneWidget);

      // Test button tap
      await tester.tap(find.text('Add Announcement'));
      await tester.pump();

      expect(addCalled, isTrue);
    });

    testWidgets('does not show add button when not in admin mode', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyNotificationState(adminMode: false)),
        ),
      );

      // Assert
      expect(find.text('Add Announcement'), findsNothing);
    });
  });

  group('NotificationChip Widget', () {
    late MosqueNotification testNotification;

    setUp(() {
      testNotification = MosqueNotification.create(
        title: 'Quick Alert',
        message: 'Test message',
        type: NotificationType.alert,
        priority: NotificationPriority.high,
        postedBy: 'test@example.com',
        postedByRole: 'Admin',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
    });

    testWidgets('displays notification title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationChip(notification: testNotification),
          ),
        ),
      );

      // Assert
      expect(find.text('Quick Alert'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationChip(
              notification: testNotification,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('does not display if notification should not show', (
      WidgetTester tester,
    ) async {
      // Arrange - Create an inactive notification
      final inactiveNotification = testNotification.copyWith(active: false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationChip(notification: inactiveNotification),
          ),
        ),
      );

      // Assert
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget); // SizedBox.shrink()
    });
  });
}
