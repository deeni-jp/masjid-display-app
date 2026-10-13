# Testing

```bash
flutter test                                   # everything
flutter test test/unit/                        # one folder
flutter test test/unit/models/prayer_time_test.dart
flutter test --name="prayer"                   # tests whose name matches
flutter test --coverage                        # writes coverage/lcov.info
```

CI runs `flutter test --coverage` on every push (see [ci-cd.md](ci-cd.md)).

## Layout

| Folder | Contents |
|---|---|
| `test/unit/` | Models and services (prayer times, iqamah windows, notices, caching) |
| `test/widget/` | Individual widgets |
| `test/integration/` | Navigation across screens |
| `test/helpers/` | Shared test helpers and mock data |
| `test/fixtures/` | Sample API responses and Firestore documents (JSON) |
| `test/mocks.dart` | Mockito mock declarations |

## Mocks

Mocks are generated with Mockito from `@GenerateMocks` annotations (in
`test/mocks.dart` and some test files). After changing one, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Writing tests

- Put a test next to its peers, mirroring the `lib/` path
  (`lib/models/prayer_windows.dart` → `test/unit/models/prayer_windows_test.dart`).
- Use fixed dates/times instead of `DateTime.now()` so tests don't depend on the
  clock.
- Use the fixtures and `test/helpers/` instead of real network or Firebase calls.

The `push-worker/` has its own tests: `cd push-worker && npm test`.
