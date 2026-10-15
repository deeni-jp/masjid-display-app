# Setup for your masjid

Everything that differs between masjids — name, app ID, logo, location,
Firebase project — is set in `.env` and a logo file. No code changes needed.

## 1. Tools

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio (Android builds) and/or Xcode on a Mac (iOS builds)
- Node.js – for the Firebase CLI and the push worker

## 2. Get the code

Fork this repository on GitHub (or download it), then clone your copy:

```bash
git clone https://github.com/<you>/masjid-display-app.git
cd masjid-display-app
cp .env.example .env
flutter pub get
```

To receive later improvements, add this repository as `upstream` and pull
from it now and then:

```bash
git remote add upstream https://github.com/deeni-jp/masjid-display-app.git
git pull upstream main
```

## 3. Firebase project

The app uses Firebase (free Spark plan) for accounts, iqamah times and notices.

1. [Firebase Console](https://console.firebase.google.com/) → **Add project**.
2. **Build → Authentication → Get started** → enable **Email/Password**.
3. **Build → Firestore Database → Create database** (production mode, a
   region near you).
4. **Project settings → Your apps** → add the platforms you need:
   - **Android**: package name = your `APP_ID` (step 4). Download
     `google-services.json` into `android/app/` (it's ignored by git).
   - **Web**: needed for the masjid display and for the web values in `.env`.
   - **iOS**: bundle ID = your `APP_ID`.
5. Deploy the security rules and indexes from this repository:
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules,firestore:indexes --project <your-project-id>
   ```

## 4. `.env`

`.env` is bundled into every build and is **publicly readable** (on the web at
`/assets/.env`). Only public settings belong there; never keys or passwords.
Firebase client values are public by design – the security rules protect the
data.

| Variable | Meaning |
|---|---|
| `MASJID_NAME` | Full name, shown in the app, on the display and as the app name |
| `MASJID_SHORT_NAME` | Short name (≤ 12 characters) under the icon on phones |
| `APP_ID` | Android app ID / iOS bundle ID, e.g. `org.yourmasjid.app`. Unique; never change it after publishing on Google Play |
| `DEFAULT_LATITUDE`, `DEFAULT_LONGITUDE`, `DEFAULT_CITY`, `DEFAULT_COUNTRY` | Location used when the device location isn't available – normally the masjid's |
| `ALADHAN_API_METHOD` | Prayer-time calculation method (table below) |
| `ALADHAN_SCHOOL` | Asr calculation: `0` Shafi/standard, `1` Hanafi |
| `FIREBASE_*` | Your Firebase project (below) |
| `PUSH_WORKER_URL` | URL of the deployed push worker; empty = no pushes ([push-notifications.md](push-notifications.md)) |
| `APP_CHECK_WEB_SITE_KEY` | reCAPTCHA v3 site key for App Check on the web (optional) |

**Firebase values**: Firebase Console → ⚙ Project settings → **Your apps**.
The web app's config snippet has `apiKey`, `authDomain`, `projectId`,
`storageBucket`, `messagingSenderId`, `appId` and `measurementId`; the
Android and iOS apps each show their own **App ID** (and `google-services.json`
has the Android `current_key`). Platform API keys are optional: the web key is
used where they're empty.

Alternatively, `flutterfire configure` writes `lib/firebase_options.dart` with
these values built in; the `FIREBASE_*` values are then not used.

Read in code through `EnvConfig` (`lib/utils/env_config.dart`). Until the
Firebase values are filled in, the app shows a "Firebase is not set up yet"
screen.

| Method | ID |
|---|---|
| Shia Ithna-Ashari | 0 |
| University of Islamic Sciences, Karachi | 1 |
| Islamic Society of North America (ISNA) | 2 |
| Muslim World League | 3 |
| Umm Al-Qura University, Makkah | 4 |
| Egyptian General Authority of Survey | 5 |

Full list: [aladhan.com/calculation-methods](https://aladhan.com/calculation-methods).

## 5. Name, app ID and logo

The Android, iOS, web and Windows project files can't read `.env`, so copy
the name and app ID into them:

```bash
dart run tool/apply_branding.dart
```

Run it again whenever you change `MASJID_NAME`, `MASJID_SHORT_NAME` or
`APP_ID`.

**Logo**: replace `assets/images/mosque.png` with your masjid's logo (a PNG,
ideally square, at least 512×512 px, with a transparent background), then
regenerate the in-app logo and all app icons:

```bash
dart run tool/generate_icons.dart
dart run flutter_launcher_icons
```

Colours and fonts are in `lib/utils/design.dart` (`DesignColors`,
`DesignPalette`, `DesignText`) if you want to match your masjid's colours.

## 6. Run and create the first admin

```bash
flutter run              # add -d chrome for the web version
```

1. Sign up in the app (new accounts get the `public` role).
2. Firebase Console → Firestore → `users` → your document → set `role` to `admin`.

Admins can then promote others from **Settings → Manage Users** in the app,
and moderators/admins set the iqamah times and post notices.

Next: [give the app to your community](deployment.md), and optionally set up
[push notifications](push-notifications.md) and the
[masjid display](../masjid-display/README.md).

## Firestore data

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

## Other settings in code

| What | Where |
|---|---|
| Timings, notice rotation, default expiry | `AppConstants` in `lib/utils/constants.dart` |
| Iqamah sequence durations | `lib/models/prayer_windows.dart` |
| Design colours and fonts (light/dark) | `DesignColors`, `DesignPalette`, `DesignText` in `lib/utils/design.dart` |

## Common problems

| Problem | Fix |
|---|---|
| "Firebase is not set up yet" | Fill in the `FIREBASE_*` values in `.env` and rebuild |
| `No file found for asset: .env` | `cp .env.example .env` |
| Android build: `google-services.json` missing | Download it from Firebase (step 3) into `android/app/` |
| Android build: no matching client for package name | `APP_ID` must equal the Android package registered in Firebase; run `tool/apply_branding.dart` |
| Firestore "permission denied" | Rules deployed? Signed in? Check your `role` in `users/{uid}` |
| Location not working | Allow location permission; on the web it falls back to IP-based location |
| Fonts missing on first run | Fonts are downloaded once (`google_fonts`); needs internet the first time |
