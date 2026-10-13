# Security

## Model

- **Authentication:** Firebase Auth (email/password). Anyone can sign up; new
  accounts get the `public` role.
- **Authorisation:** enforced server-side by [`firestore.rules`](../firestore.rules):
  - users can read only their own profile (admins can read all);
  - users can't set or change their own role – only admins can;
  - only moderators/admins can write iqamah times, notices and notice images;
  - prayer times and notices are publicly readable.
- **No secrets in the app.** `.env` and `lib/firebase_options.dart` are public by
  design (Firebase client keys only identify the project). The only secret
  needed at runtime – the Firebase service-account key – lives in the push
  worker as a Cloudflare secret ([push-worker/README.md](../push-worker/README.md)).
- **App Check** (monitoring mode) records requests that don't come from the
  genuine app; enforcement is planned after the Play Store release
  ([deployment.md](deployment.md#app-check)).
- **CI secrets** (keystore, `google-services.json`, Firebase token) live in GitHub
  Secrets; signing files are deleted after each build.
- **Web** is served only on the masjid PC's own `localhost` for now, not on the
  internet.

## Never commit

`.env`, `android/app/google-services.json`, `GoogleService-Info.plist`,
`android/key.properties`, keystores (`*.jks`, `*.keystore`), service-account
JSON keys, `node_modules/`. Most are in `.gitignore`; check `git status` before
committing anyway.

## If a secret leaks

1. Revoke it immediately (delete the service-account key in Google Cloud
   Console, regenerate the Firebase token, etc.).
2. Create a new one and update where it's stored (Cloudflare secret, GitHub
   secret).
3. Check Firebase Console usage and Firestore data for anything unexpected.

## Reporting a problem

Email **dticcjp@gmail.com** rather than opening a public issue.

## Changing the rules

Edit `firestore.rules`, test them (Firebase emulator or a throwaway account),
then deploy from **Actions → Flutter CI/CD → Run workflow → Deploy Firestore
rules** or with `firebase deploy --only firestore:rules`.
