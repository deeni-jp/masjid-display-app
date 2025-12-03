# Complete Testing Guide for Prayer Times App

This guide teaches you how to write and run tests in your Flutter application.

## Test Types Overview

### 1. Unit Tests (`test/unit/`)
- Test individual functions and classes in isolation
- Fast execution
- No UI rendering
- Mock external dependencies

### 2. Widget Tests (`test/widget/`)
- Test UI components
- Verify widget rendering and interactions
- Test user interactions (taps, gestures)
- Faster than integration tests

### 3. Integration Tests (`test/integration/`)
- Test complete user flows
- Test app as a whole
- Can run on real devices
- Slower but most comprehensive

---

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Types
```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

### Run a Single Test File
```bash
flutter test test/unit/models/prayer_time_test.dart
```

### Run Tests Matching a Pattern
```bash
# Run all tests with "cache" in the name
flutter test --name="cache"

# Run all tests with "prayer" in the name
flutter test --name="prayer"
```

### Generate Coverage Report
```bash
# Generate coverage
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html
# Then open coverage/html/index.html in browser
```

### Run Tests in Watch Mode
```bash
flutter test --watch
```

### Verbose Output
```bash
flutter test --verbose
```

---

## Unit Test Examples

### Basic Unit Test Structure
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Name', () {
    // Setup runs before each test
    setUp(() {
      // Initialize test data
    });

    // Teardown runs after each test
    tearDown(() {
      // Clean up
    });

    test('should do something', () {
      // Arrange - Set up test data
      final input = 'test';

      // Act - Execute the code
      final result = myFunction(input);

      // Assert - Verify results
      expect(result, expectedValue);
    });
  });
}
```

### Testing with Mocks (Mockito)
```dart
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([http.Client])
void main() {
  test('fetches data from API', () async {
    // Create mock
    final mockClient = MockClient();

    // Stub method
    when(mockClient.get(any))
      .thenAnswer((_) async => http.Response('{"data": "test"}', 200));

    // Use mock
    final result = await fetchData(client: mockClient);

    // Verify
    expect(result, isNotNull);
    verify(mockClient.get(any)).called(1);
  });
}
```

### Common Matchers
```dart
// Equality
expect(actual, equals(expected));
expect(actual, isNull);
expect(actual, isNotNull);

// Type checking
expect(actual, isA<String>());
expect(actual, isA<List<int>>());

// Numeric comparisons
expect(value, greaterThan(5));
expect(value, lessThan(10));
expect(value, greaterThanOrEqualTo(5));

// Collections
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, contains('item'));
expect(list, hasLength(3));

// Exceptions
expect(() => throwError(), throwsException);
expect(() => throwError(), throwsA(isA<CustomException>()));

// Async
await expectLater(future, completes);
await expectLater(future, throwsException);
```

---

## Widget Test Examples

### Basic Widget Test
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays text', (WidgetTester tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text('Hello'),
        ),
      ),
    );

    // Find widget
    expect(find.text('Hello'), findsOneWidget);
  });
}
```

### Testing User Interactions
```dart
testWidgets('button tap calls callback', (WidgetTester tester) async {
  bool tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () => tapped = true,
          child: Text('Tap me'),
        ),
      ),
    ),
  );

  // Tap the button
  await tester.tap(find.text('Tap me'));
  await tester.pump();

  expect(tapped, isTrue);
});
```

### Finding Widgets
```dart
// By text
find.text('Hello')

// By key
find.byKey(Key('my-key'))

// By type
find.byType(ElevatedButton)

// By icon
find.byIcon(Icons.add)

// Descendant
find.descendant(
  of: find.byType(Container),
  matching: find.byType(Text),
)

// Ancestor
find.ancestor(
  of: find.text('Hello'),
  matching: find.byType(Container),
)
```

### Common Widget Test Actions
```dart
// Tap
await tester.tap(find.byType(Button));

// Long press
await tester.longPress(find.byType(Button));

// Drag
await tester.drag(find.byType(Slider), Offset(100, 0));

// Enter text
await tester.enterText(find.byType(TextField), 'Hello');

// Pump (rebuild once)
await tester.pump();

// Pump and settle (wait for animations)
await tester.pumpAndSettle();

// Pump with duration
await tester.pump(Duration(seconds: 1));
```

### Testing Widget Properties
```dart
testWidgets('widget has correct properties', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());

  // Get widget
  final container = tester.widget<Container>(find.byType(Container));
  final decoration = container.decoration as BoxDecoration;

  // Assert properties
  expect(decoration.color, Colors.blue);
  expect(decoration.borderRadius, BorderRadius.circular(8));
});
```

---

## Integration Test Setup

### 1. Create Integration Test Driver (Optional for older Flutter versions)
Create `test_driver/integration_test.dart`:
```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

### 2. Write Integration Tests
Place tests in `integration_test/` directory:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete user flow', (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle();

    // Navigate through the app
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(find.byType(TextField).first, 'user@test.com');
    await tester.enterText(find.byType(TextField).last, 'password');

    // Submit
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Verify
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

### 3. Run Integration Tests
```bash
# Run in headless mode
flutter test integration_test/

# Run on a device
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

---

## Generating Mocks

### 1. Add Mock Annotation
In `test/mocks.dart`:
```dart
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([
  http.Client,
  YourService,
  YourRepository,
])
void main() {}
```

### 2. Generate Mock Classes
```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates `test/mocks.mocks.dart` with mock classes.

### 3. Use Generated Mocks
```dart
import 'mocks.mocks.dart';

void main() {
  test('uses mock', () {
    final mockClient = MockClient();
    // Use mockClient...
  });
}
```

---

## Test Best Practices

### 1. Arrange-Act-Assert Pattern
```dart
test('example', () {
  // Arrange: Set up test data
  final input = 'test';

  // Act: Execute the code
  final result = doSomething(input);

  // Assert: Verify results
  expect(result, expectedValue);
});
```

### 2. Descriptive Test Names
```dart
// Good
test('returns null when input is empty string')
test('throws exception when user is not authenticated')

// Bad
test('test1')
test('it works')
```

### 3. Test One Thing Per Test
```dart
// Good
test('parses valid date string')
test('throws error for invalid date string')

// Bad
test('date parsing') {
  // Tests multiple scenarios in one test
}
```

### 4. Use setUp and tearDown
```dart
group('Calculator', () {
  late Calculator calculator;

  setUp(() {
    calculator = Calculator();
  });

  tearDown(() {
    calculator.dispose();
  });

  test('adds two numbers', () {
    expect(calculator.add(2, 3), 5);
  });
});
```

### 5. Mock External Dependencies
```dart
// Don't test real HTTP calls
test('fetches data', () async {
  final mockClient = MockClient();
  when(mockClient.get(any))
    .thenAnswer((_) async => http.Response('data', 200));

  final result = await service.fetchData(client: mockClient);
  expect(result, isNotNull);
});
```

---

## Current Test Summary

### Unit Tests (136 tests)
- ✅ `hijri_date_test.dart` - 20 tests
- ✅ `notification_model_test.dart` - 55 tests
- ✅ `prayer_time_test.dart` - 38 tests
- ✅ `hijri_calendar_service_test.dart` - 23 tests

### Widget Tests (25 tests)
- ✅ `prayer_card_test.dart` - 11 tests
- ✅ `notification_card_test.dart` - 14 tests

### Integration Tests (3 tests)
- ✅ `app_navigation_test.dart` - 3 example tests

**Total: 164 tests**

---

## Quick Reference Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific directory
flutter test test/unit/

# Run specific file
flutter test test/unit/models/prayer_time_test.dart

# Run tests matching name
flutter test --name="cache"

# Watch mode
flutter test --watch

# Verbose output
flutter test --verbose

# Generate mocks
dart run build_runner build --delete-conflicting-outputs

# Run integration tests on device
flutter drive --target=integration_test/app_test.dart
```

---

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [Test Coverage Guide](https://docs.flutter.dev/cookbook/testing/unit/introduction)

---

## Next Steps

1. **Add more widget tests** for other widgets:
   - `news_ticker.dart`
   - `next_prayer_card.dart`
   - `countdown_overlay.dart`

2. **Add screen tests** for full pages:
   - `prayers_tab.dart`
   - `notifications_tab.dart`
   - `home_tab.dart`

3. **Add service tests** for:
   - `prayer_times_service.dart`
   - `location_service.dart`
   - `notification_service.dart`

4. **Create real integration tests** that:
   - Test authentication flow
   - Test navigation between tabs
   - Test prayer time display
   - Test notification interactions

Happy Testing! 🎉
