// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Common test helpers and utilities

/// Pump and settle with custom duration
Future<void> pumpAndSettleExtended(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 500),
}) async {
  await tester.pumpAndSettle(duration);
}

/// Find widget by key
Finder findByKey(String key) => find.byKey(Key(key));

/// Find widget by type
Finder findByType<T>() => find.byType(T);

/// Find text widget
Finder findText(String text) => find.text(text);

/// Verify widget exists
void expectWidgetExists(Finder finder) {
  expect(finder, findsOneWidget);
}

/// Verify widget doesn't exist
void expectWidgetNotExists(Finder finder) {
  expect(finder, findsNothing);
}

/// Verify text exists
void expectTextExists(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Tap on widget and pump
Future<void> tapAndPump(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  await tester.tap(finder);
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  }
}

/// Enter text in text field
Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  await tester.enterText(finder, text);
  await tester.pump();
}

/// Scroll until visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder itemFinder,
  Finder scrollableFinder, {
  double delta = 300.0,
}) async {
  await tester.scrollUntilVisible(
    itemFinder,
    delta,
    scrollable: scrollableFinder,
  );
}

/// Wait for condition
Future<void> waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (condition()) return;
    await tester.pump(pollInterval);
  }
  throw TimeoutException('Condition not met within $timeout');
}

/// Simulate platform brightness
void setPlatformBrightness(WidgetTester tester, Brightness brightness) {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
}

/// Create test material app wrapper
Widget createTestApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// Create test material app with theme
Widget createTestAppWithTheme(
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(body: child),
  );
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
