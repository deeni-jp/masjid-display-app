# Masjid Prayer Times

[![Flutter CI/CD](https://github.com/deeni-jp/masjid-display-app/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/deeni-jp/masjid-display-app/actions/workflows/flutter-ci.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

A free, open-source app for any masjid: prayer and iqamah times, notices with
push notifications, and a full-screen display for the masjid TV. Runs on
Android, iOS and the web, with Firebase's free plan as the backend.

Set it up for your own masjid (name, logo, location, your own Firebase
project) without changing any code, then give it to your community as an APK
or through Google Play.

![Masjid display](design/screens/1%20%C2%B7%20Home%20display%402x.png)

## Features

- Prayer times from the [Aladhan API](https://aladhan.com/prayer-times-api) for
  the device's location, with iqamah times set by the masjid and Jumuah on Fridays
- Live countdown and an iqamah sequence: countdown → "Time for prayer" →
  "Prayer in progress"
- Notices (announcements, events, alerts) with priorities, images, expiry,
  weekly repeating events and push notifications
- **Masjid display mode** on screens ≥ 900 px wide (horizontal or vertical):
  large prayer table, clock, Hijri date, rotating notices
- Roles: public, moderator (edits iqamah times and notices), admin (manages users)
- Light / Dark / Auto (sunset to sunrise) theme and adjustable text size;
  English with Arabic labels

## Set it up for your masjid

You need a computer with the [Flutter SDK](https://docs.flutter.dev/get-started/install)
and a free [Firebase](https://console.firebase.google.com/) account.

1. **Get the code**: fork this repository (or download it) and clone your copy.
2. **Create a Firebase project** with Authentication (Email/Password) and
   Firestore, and register an Android app (and iOS/web if you need them).
3. **Fill in `.env`**: `cp .env.example .env`, then set your masjid's name,
   app ID, location and the Firebase values. Everything masjid-specific is in
   this one file.
4. **Apply the name and app ID** to the Android/iOS/web project files, and
   optionally your own logo:
   ```bash
   dart run tool/apply_branding.dart
   ```
5. **Run it**: `flutter pub get && flutter run`, sign up, and make yourself
   admin in Firestore.

Step-by-step details: **[docs/setup.md](docs/setup.md)**.

## Getting the app to your community

| | APK (simplest) | Google Play |
|---|---|---|
| Cost | Free | One-time Google Play developer fee |
| Install | Share the `.apk` file or a download link; people allow "install unknown apps" | From the Play Store, like any app |
| Updates | People install the new APK themselves | Automatic |
| Good for | A small community | A larger community, or if people find APKs hard |

Both are described in [docs/deployment.md](docs/deployment.md). With GitHub
Actions set up, pushing a version tag (e.g. `v1.3.0`) builds a signed APK and
attaches it to a GitHub release you can link to ([docs/ci-cd.md](docs/ci-cd.md)).

## Masjid display

To run the display on a masjid PC (Windows or Raspberry Pi), clone your copy
of the project there and run one setup script. It builds the app, opens it
full screen and starts it automatically at every boot. See
[masjid-display/README.md](masjid-display/README.md).

## Documentation

| Guide                                            | Contents                                                        |
| ------------------------------------------------ | --------------------------------------------------------------- |
| [Setup](docs/setup.md)                           | Your masjid's settings, Firebase, logo, first admin             |
| [Features](docs/features.md)                     | Roles, notices, iqamah sequence, display mode, UI behaviour     |
| [Push notifications](docs/push-notifications.md) | How pushes are sent, Android/iOS setup, troubleshooting         |
| [Deployment](docs/deployment.md)                 | APK, Google Play, iOS, web, App Check                           |
| [CI/CD](docs/ci-cd.md)                           | GitHub Actions jobs, secrets and variables                      |
| [Testing](docs/testing.md)                       | Running and writing tests                                       |
| [Security](docs/security.md)                     | Security model and reporting issues                             |

## Project structure

| Path              | What's there                                                                      |
| ----------------- | --------------------------------------------------------------------------------- |
| `lib/`            | Flutter app: `models/`, `services/`, `screens/`, `widgets/`, `utils/`             |
| `test/`           | Unit, widget and integration tests                                                |
| `tool/`           | `apply_branding.dart` (name/app ID), `generate_icons.dart` (logo and icons)       |
| `push-worker/`    | Cloudflare Worker that sends push notifications ([README](push-worker/README.md)) |
| `masjid-display/` | Kiosk setup for the masjid display PC ([README](masjid-display/README.md))        |
| `firestore.rules` | Firestore security rules                                                          |
| `design/screens/` | UI design mockups                                                                 |

## Contributing

Improvements are welcome: open an issue or a pull request into `main`; see
[CONTRIBUTING.md](CONTRIBUTING.md). Changes are listed in
[CHANGELOG.md](CHANGELOG.md).

## License

[GNU General Public License v3.0](LICENSE). You may use, change and share the
app, including publishing it for your masjid; if you distribute a changed
version, its source code must be available under the same license.
