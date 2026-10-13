# Setup

## Development environment

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio (Android builds) and/or Xcode on a Mac (iOS builds)
- Node.js – only for the push worker and the Firebase CLI

```bash
git clone https://github.com/deeni-jp/prayer_times_app.git
cd prayer_times_app
cp .env.example .env
flutter pub get
flutter run
```

Android builds also need `android/app/google-services.json` (not in git):
Firebase Console → Project settings → Your apps → Android app → download.

## `.env`

`.env` is bundled into every build and is **publicly readable** (on the web at
`/assets/.env`). Only public settings belong there; never keys or passwords.

| Variable | Meaning | Default |
|---|---|---|
| `ALADHAN_API_METHOD` | Prayer-time calculation method (table below) | `3` |
| `ALADHAN_SCHOOL` | Asr calculation: `0` Shafi/standard, `1` Hanafi | `1` |
| `PUSH_WORKER_URL` | URL of the deployed push worker; empty = no pushes | empty |
| `APP_CHECK_WEB_SITE_KEY` | reCAPTCHA v3 site key for App Check on the web | empty |

Read in code through `EnvConfig` (`lib/utils/env_config.dart`).

| Method | ID |
|---|---|
| Shia Ithna-Ashari | 0 |
| University of Islamic Sciences, Karachi | 1 |
| Islamic Society of North America (ISNA) | 2 |
| Muslim World League | 3 |
| Umm Al-Qura University, Makkah | 4 |
| Egyptian General Authority of Survey | 5 |

## Firebase

The app uses the Firebase project `dticc-app`; its client config is committed
in `lib/firebase_options.dart` (client API keys are public by design – the
security rules protect the data).

To set up a new Firebase project instead:

1. Create the project in the [Firebase Console](https://console.firebase.google.com/)
   and enable **Authentication → Email/Password** and **Firestore**.
2. Generate the config:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure
   ```
3. Deploy the security rules and indexes from this repo:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

### Firestore data

```
mosque/iqama                               iqamah times, e.g. Fajr: "5:30 AM"
mosque/data/notifications/{id}             notices: title, message, type, priority,
                                           active, createdAt, expiresAt, eventTime,
                                           postedBy, postedByRole, hasImage
mosque/data/notification_images/{id}       image attached to the notice with the same id
users/{uid}                                email, displayName, role (public|moderator|admin),
                                           createdAt, lastLogin, active, deleted
deletion_logs/{id}                         audit log of deleted users (admins only)
```

Access rules are in [`firestore.rules`](../firestore.rules); see
[security.md](security.md).

### First admin

1. Sign up in the app (new accounts get the `public` role).
2. Firebase Console → Firestore → `users` → your document → set `role` to `admin`.

Admins can then promote others from **Settings → Manage Users** in the app.

## Configuration in code

| What | Where |
|---|---|
| App name, timings, notice rotation, default expiry | `AppConstants` in `lib/utils/constants.dart` |
| Iqamah sequence durations | `lib/models/prayer_windows.dart` |
| Design colours and fonts (light/dark) | `DesignColors`, `DesignPalette`, `DesignText` in `lib/utils/design.dart` |
| Masjid name and donation QR code | `MasjidInfo` in `lib/utils/design.dart`; QR image `assets/images/qr code for donations.png` |

### Logo and app icons

`assets/images/mosque.png` is the source artwork. Regenerate the in-app logo and
all platform icons after replacing it:

```bash
dart run tool/generate_icons.dart
dart run flutter_launcher_icons
```

The current artwork is small (≈130×160 px), so large icons are slightly soft;
higher-resolution artwork gives better results.

## Common problems

| Problem | Fix |
|---|---|
| `No file found for asset: .env` | `cp .env.example .env` |
| Firestore "permission denied" | Check you're signed in and your `role` in `users/{uid}` |
| Location not working | Allow location permission; on the web it falls back to IP-based location |
| Fonts missing on first run | Fonts are downloaded once (`google_fonts`); needs internet the first time |
