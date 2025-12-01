// test/helpers/widget_tester_extensions.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extensions for WidgetTester to make testing easier

extension WidgetTesterExtensions on WidgetTester {
  /// Find by key helper
  Finder findByKey(String key) => find.byKey(Key(key));

  /// Find by type helper
  Finder findByType<T>() => find.byType(T);

  /// Tap and settle
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enter text and pump
  Future<void> enterTextAndPump(Finder finder, String text) async {
    await enterText(finder, text);
    await pump();
  }

  /// Verify text exists with count
  void expectTextCount(String text, int count) {
    expect(find.text(text), findsNWidgets(count));
  }

  /// Verify widget visible
  void expectVisible(Finder finder) {
    expect(finder, findsOneWidget);
    final widget = this.widget(finder);
    expect(widget, isNotNull);
  }

  /// Verify widget not visible
  void expectNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Wait for widget to appear
  Future<void> waitForWidget(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (any(finder)) return;
    }
    throw TimeoutException('Widget not found within $timeout');
  }

  /// Wait for text to appear
  Future<void> waitForText(
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await waitForWidget(find.text(text), timeout: timeout);
  }

  /// Drag to scroll
  Future<void> dragToScroll(
    Finder scrollable,
    double delta,
  ) async {
    await drag(scrollable, Offset(0, delta));
    await pumpAndSettle();
  }

  /// Verify icon exists
  void expectIcon(IconData icon) {
    expect(find.byIcon(icon), findsOneWidget);
  }

  /// Get text from widget
  String getText(Finder finder) {
    final textWidget = widget<Text>(finder);
    return textWidget.data ?? '';
  }

  /// Verify widget is enabled
  void expectEnabled(Finder finder) {
    final button = widget(finder);
    if (button is ElevatedButton) {
      expect(button.enabled, isTrue);
    } else if (button is TextButton) {
      expect(button.enabled, isTrue);
    } else if (button is OutlinedButton) {
      expect(button.enabled, isTrue);
    }
  }

  /// Verify widget is disabled
  void expectDisabled(Finder finder) {
    final button = widget(finder);
    if (button is ElevatedButton) {
      expect(button.enabled, isFalse);
    } else if (button is TextButton) {
      expect(button.enabled, isFalse);
    } else if (button is OutlinedButton) {
      expect(button.enabled, isFalse);
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
