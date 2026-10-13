# Darut Tauhid Masjid – Prayer Times App

[![Flutter CI/CD](https://github.com/deeni-jp/prayer_times_app/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/deeni-jp/prayer_times_app/actions/workflows/flutter-ci.yml)

Flutter app for Darut Tauhid Masjid: prayer and iqamah times, masjid notices
with push notifications, and a full-screen display mode for the masjid TV.
Runs on Android, iOS and the web, with Firebase (free Spark plan) as the backend.

![Masjid display](design/screens/1%20%C2%B7%20Home%20display%402x.png)

## Features

- Prayer times from the [Aladhan API](https://aladhan.com/prayer-times-api) for
  the device's location, with iqamah times set by the masjid and Jummah on Fridays
- Live countdown and an iqamah sequence: countdown → "Time for prayer" →
  "Prayer in progress"
- Notices (announcements, events, alerts) with priorities, images, expiry and
  push notifications
- **Masjid display mode** on screens ≥ 900 px wide: large prayer table, clock,
  Hijri date, rotating notices, donation QR code
- Roles: public, moderator (edits iqamah times and notices), admin (manages users)
- Automatic dark mode after Maghrib; English with Arabic labels

## Quick start

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable).

```bash
git clone https://github.com/deeni-jp/prayer_times_app.git
cd prayer_times_app
cp .env.example .env     # public settings only – never put secrets here
flutter pub get
flutter run              # add -d chrome for the web version
```

The app connects to the existing Firebase project (`lib/firebase_options.dart`).
To use your own Firebase project, see [docs/setup.md](docs/setup.md).

## Masjid display

To run the display on a masjid PC (Windows or Raspberry Pi), clone the project
there and run one setup script. It builds the app, opens it full screen and
starts it automatically at every boot. See
[masjid-display/README.md](masjid-display/README.md).

## Documentation

| Guide | Contents |
|---|---|
| [Setup](docs/setup.md) | Development setup, `.env`, Firebase, first admin, configuration |
| [Features](docs/features.md) | Roles, notices, iqamah sequence, display mode, UI behaviour |
| [Push notifications](docs/push-notifications.md) | How pushes are sent, Android/iOS setup, troubleshooting |
| [Deployment](docs/deployment.md) | Release builds, web, App Check, production checklist |
| [CI/CD](docs/ci-cd.md) | GitHub Actions jobs, secrets and variables |
| [Testing](docs/testing.md) | Running and writing tests |
| [Security](docs/security.md) | Security model and reporting issues |

## Project structure

| Path | What's there |
|---|---|
| `lib/` | Flutter app: `models/`, `services/`, `screens/`, `widgets/`, `utils/` |
| `test/` | Unit, widget and integration tests |
| `push-worker/` | Cloudflare Worker that sends push notifications ([README](push-worker/README.md)) |
| `masjid-display/` | Kiosk setup for the masjid display PC ([README](masjid-display/README.md)) |
| `firestore.rules` | Firestore security rules |
| `design/screens/` | UI design mockups |
| `functions/` | Legacy Cloud Functions (need the paid Blaze plan; not deployed) |

## Contributing

Push to a branch and open a pull request into `main`; see
[CONTRIBUTING.md](CONTRIBUTING.md). Changes are listed in
[CHANGELOG.md](CHANGELOG.md).

## Contact

dardticcjp@gmail.com
