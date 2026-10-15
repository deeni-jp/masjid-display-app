# Deployment

## Android

There are two ways to get the app to your community. Both need the same
**upload keystore**, created once:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep the `.jks` file and its passwords **safe and private** (e.g. in a password
manager, plus a backup): every future update must be signed with the same key,
or phones won't install it over the old version. Never commit it.

Point the build at it with `android/key.properties` (ignored by git):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

Without it, release builds fall back to the debug key (fine for testing, not
for giving to people). Before building, check `.env` and that
`tool/apply_branding.dart` has been run (see [setup.md](setup.md)), and bump
`version:` in `pubspec.yaml` for every release (e.g. `1.3.0+5` – the number
after `+` must go up each time).

### Option A: APK (free, simplest)

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Share the APK file (WhatsApp, a website, a GitHub release, …). People open it
on their phone and allow "Install unknown apps" for the app they opened it
from. For an update, they install the new APK the same way; their settings
stay.

With GitHub Actions set up, pushing a version tag builds the signed APK and
publishes it as a GitHub release, so you can share one link:

```bash
git tag v1.3.0 && git push origin v1.3.0
# → https://github.com/<you>/<repo>/releases/latest
```

See [ci-cd.md](ci-cd.md). **App Check:** don't *enforce* App Check if you
distribute APKs – Play Integrity rejects apps not installed from Google Play.

### Option B: Google Play

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

1. Create a [Google Play developer account](https://play.google.com/console)
   (one-time fee).
2. Create the app, fill in the store listing, content rating and data safety
   form, and a **privacy policy** URL (the app uses location and accounts).
3. Upload the `.aab` (start with the internal testing track), keep Play App
   Signing on, and roll out to production.
4. Add the **app signing key** SHA-256 from Play Console → Setup → App
   integrity to your Android app in Firebase (needed for App Check / Play
   Integrity).

`APP_ID` becomes the app's permanent identity on Google Play: don't change it
after the first upload. CI also builds the `.aab` on every push to `main`.

## iOS

Needs a Mac with Xcode and an Apple Developer account.

1. The bundle ID is your `APP_ID` (set by `tool/apply_branding.dart`).
   Register it in the Apple Developer portal and as an iOS app in Firebase,
   and put its App ID in `.env` as `FIREBASE_IOS_APP_ID`.
2. Select your team for automatic signing; add the push capabilities from
   [push-notifications.md](push-notifications.md).
3. Build and upload:
   ```bash
   flutter build ipa --release
   ```
   then upload `build/ios/ipa/*.ipa` with Xcode's Organizer or Transporter.

Location usage descriptions are already in `ios/Runner/Info.plist`.

## Web

The masjid display runs the web app locally on the masjid PC – see
[masjid-display/README.md](../masjid-display/README.md). Publishing it on the
internet is optional.

```bash
flutter build web --release      # output in build/web
```

`build/web/assets/.env` is downloadable by anyone who can open the site, so
`.env` must only contain public settings.

**Publishing on the internet:** Firebase Hosting is configured in
`firebase.json`. Set up App Check for the web (below), then
`firebase deploy --only hosting --project <your-project-id>`
(→ `https://<your-project-id>.web.app`), and add that URL to `ALLOWED_ORIGINS`
in `push-worker/wrangler.toml` and to the reCAPTCHA key's domains.

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

1. **Android**: register with Play Integrity and add the signing key's SHA-256
   (Play Console → App integrity, or `cd android && ./gradlew signingReport`).
2. **Web**: create a reCAPTCHA v3 key for `localhost` (and any other domain),
   register it, and put the **site key** in `.env` as `APP_CHECK_WEB_SITE_KEY`.
3. **Debug builds**: copy the "App Check debug token" from the debug log and add
   it under App Check → Apps → Manage debug tokens.
4. Watch the Cloud Firestore metrics for a while.
5. **Enforce** only if everyone installs the Android app from Google Play (Play
   Integrity rejects APKs installed directly). If you distribute APKs, stay in
   monitoring mode – enforcing would lock those users out.

## Release checklist

- [ ] `.env` filled in and `dart run tool/apply_branding.dart` run ([setup.md](setup.md))
- [ ] Your logo and icons generated ([setup.md](setup.md#5-name-app-id-and-logo))
- [ ] Firestore rules deployed; first admin created
- [ ] Upload keystore created and backed up
- [ ] Optional: push worker deployed and `PUSH_WORKER_URL` set ([push-notifications.md](push-notifications.md))
- [ ] Optional: apps registered in App Check (enforce only with Google Play-only distribution)
- [ ] Google Play only: developer account, store listing, **privacy policy**
      (the app uses location and accounts)
- [ ] iOS: production bundle ID, APNs key, App Store listing
- [ ] Bump `version:` in `pubspec.yaml` for every release
