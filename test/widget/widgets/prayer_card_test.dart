// test/widget/widgets/prayer_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/prayer_time.dart';
import 'package:prayer_app/widgets/prayer_card.dart';

void main() {
  group('PrayerCard Widget', () {
    late PrayerTime testPrayer;

    setUp(() {
      testPrayer = PrayerTime.fromMaps(
        name: 'Fajr',
        timings: {'Fajr': '05:30 AM'},
        iqamaMap: {'Fajr': '05:45 AM'},
      );
    });

    testWidgets('displays prayer name', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(prayer: testPrayer),
          ),
        ),
      );

      // Assert
      expect(find.text('Fajr'), findsOneWidget);
    });

    testWidgets('displays waqt and iqama times', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(prayer: testPrayer),
          ),
        ),
      );

      // Assert
      expect(find.text('05:30 AM'), findsOneWidget);
      expect(find.text('05:45 AM'), findsOneWidget);
    });

    testWidgets('shows NEXT badge when isNext is true',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(
              prayer: testPrayer,
              isNext: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('does not show NEXT badge when isNext is false',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(
              prayer: testPrayer,
              isNext: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('NEXT'), findsNothing);
    });

    testWidgets('shows edit button in admin mode',
        (WidgetTester tester) async {
      // Arrange
      bool editCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(
              prayer: testPrayer,
              adminMode: true,
              onEditIqama: () => editCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Test button tap
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(editCalled, isTrue);
    });

    testWidgets('does not show edit button when not in admin mode',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(
              prayer: testPrayer,
              adminMode: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('has border when isNext is true', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(
              prayer: testPrayer,
              isNext: true,
            ),
          ),
        ),
      );

      // Assert - Find the container with border
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Fajr'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });

  group('CompactPrayerRow Widget', () {
    late PrayerTime testPrayer;

    setUp(() {
      testPrayer = PrayerTime.fromMaps(
        name: 'Dhuhr',
        timings: {'Dhuhr': '12:30 PM'},
        iqamaMap: {'Dhuhr': '12:45 PM'},
      );
    });

    testWidgets('displays prayer information in compact format',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPrayerRow(prayer: testPrayer),
          ),
        ),
      );

      // Assert
      expect(find.text('Dhuhr'), findsOneWidget);
      expect(find.text('12:30 PM'), findsOneWidget);
      expect(find.text('12:45 PM'), findsOneWidget);
    });

    testWidgets('highlights when isNext is true', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPrayerRow(
              prayer: testPrayer,
              isNext: true,
            ),
          ),
        ),
      );

      // Assert - check if highlighted
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      // The color should not be transparent when isNext is true
      expect(decoration.color, isNot(Colors.transparent));
    });
  });

  group('PrayerChip Widget', () {
    late PrayerTime testPrayer;

    setUp(() {
      testPrayer = PrayerTime.fromMaps(
        name: 'Asr',
        timings: {'Asr': '03:00 PM'},
        iqamaMap: {'Asr': '03:15 PM'},
      );
    });

    testWidgets('displays prayer name and iqama time',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerChip(prayer: testPrayer),
          ),
        ),
      );

      // Assert
      expect(find.text('Asr'), findsOneWidget);
      expect(find.text('03:15 PM'), findsOneWidget);
    });

    testWidgets('displays prayer icon', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerChip(prayer: testPrayer),
          ),
        ),
      );

      // Assert
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
