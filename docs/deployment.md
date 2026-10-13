# Deployment

## Android

```bash
flutter build apk --release          # sideloadable APK
flutter build appbundle --release    # for Google Play
```

- App ID `com.dticc.app`, name "Darut Tauhid Masjid".
- Release signing reads `android/key.properties` (not in git):
  ```properties
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=/path/to/upload-keystore.jks
  ```
  Without it, release builds fall back to the debug key (fine for testing, not
  for Google Play). Create a keystore once and **keep it safe** – every future
  update must be signed with it:
  ```bash
  keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- CI builds signed APK/AAB on every push to `main` (see [ci-cd.md](ci-cd.md)).

## iOS

Needs a Mac with Xcode and an Apple Developer account.

1. Choose a production bundle ID (Xcode currently uses `com.example.prayerApp`),
   set it in Xcode → Runner → Signing & Capabilities, register it in the Apple
   Developer portal, and add/update the iOS app in Firebase
   (`flutterfire configure`).
2. Select your team for automatic signing; add the push capabilities from
   [push-notifications.md](push-notifications.md).
3. Build and upload:
   ```bash
   flutter build ipa --release
   ```
   then upload `build/ios/ipa/*.ipa` with Xcode's Organizer or Transporter.

Location usage descriptions are already in `ios/Runner/Info.plist`.

## Web

The web app is **not published on the internet** for now; it runs locally on
the masjid PC – see [masjid-display/README.md](../masjid-display/README.md).

```bash
flutter build web --release      # output in build/web
```

`build/web/assets/.env` is downloadable by anyone who can open the site, so
`.env` must only contain public settings.

**Going public later:** Firebase Hosting is already configured in
`firebase.json`. First enforce App Check (below), then
`firebase deploy --only hosting` (→ https://dticc-app.web.app), and add the URL
to `ALLOWED_ORIGINS` in `push-worker/wrangler.toml` and to the reCAPTCHA key's
domains.

## App Check

App Check makes Firebase reject requests that don't come from the real app.
It's activated in `_activateAppCheck` (`lib/main.dart`) and is in
**monitoring mode**: unverified requests are recorded but still allowed.

| Platform | Provider |
|---|---|
| Android | Play Integrity (release), debug provider (debug builds) |
| iOS | App Attest with DeviceCheck fallback (release), debug provider (debug) |
| Web | reCAPTCHA v3, only if `APP_CHECK_WEB_SITE_KEY` is set |

Setup in Firebase Console → **App Check**:

1. **Android** (`com.dticc.app`): register with Play Integrity and add the
   signing key's SHA-256 (`cd android && ./gradlew signingReport`).
2. **Web**: create a reCAPTCHA v3 key for `localhost` (and any other domain),
   register it, and put the **site key** in `.env` as `APP_CHECK_WEB_SITE_KEY`.
3. **Debug builds**: copy the "App Check debug token" from the debug log and add
   it under App Check → Apps → Manage debug tokens.
4. Watch the Cloud Firestore metrics for a while.
5. **Enforce** only after the Android app is installed from Google Play (Play
   Integrity rejects sideloaded APKs) – enforcing earlier locks those users out.

## Production checklist

- [ ] Deploy the push worker and set `PUSH_WORKER_URL` ([push-notifications.md](push-notifications.md))
- [ ] Delete old service-account keys once the worker has its own
- [ ] Register apps in App Check; enforce after the Play Store release
- [ ] Higher-resolution logo artwork ([setup.md](setup.md#logo-and-app-icons))
- [ ] Google Play: developer account, upload keystore, store listing, **privacy
      policy** (the app uses location and accounts)
- [ ] iOS: production bundle ID, APNs key, App Store listing
- [ ] Bump `version:` in `pubspec.yaml` for every store release
