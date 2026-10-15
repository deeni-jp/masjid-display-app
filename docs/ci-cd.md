# CI/CD

One GitHub Actions workflow: [`.github/workflows/flutter-ci.yml`](../.github/workflows/flutter-ci.yml).

## Jobs

| Job | Runs on | What it does |
|---|---|---|
| **Analyze** | Every push to any branch; PRs to `main`/`develop` | `dart format` check, `flutter analyze --no-fatal-infos`, `flutter test --coverage` |
| **Build Android** | Pushes to `main`, `v*` tags, manual runs – only when the Android secrets below are set (skipped otherwise, e.g. on the public template) | Signed release APK + AAB, uploaded as artifacts |
| **Build iOS** | Manual runs only ("Build iOS") | Unsigned iOS build |
| **Deploy Firebase** | Manual runs only ("Deploy Firestore rules") | Deploys `firestore.rules` and indexes to `FIREBASE_PROJECT_ID` from `.env` |
| **Release** | `v*` tags | GitHub release with the APK and AAB attached – a download link for your community |

- Manual runs: GitHub → **Actions** → **Flutter CI/CD** → **Run workflow**.
- A newer push to the same branch cancels the older run.
- Rules deployment is never automatic, because it changes live database security.
- Release: bump `version:` in `pubspec.yaml`, then `git tag v1.3.0 && git push origin v1.3.0`.

Every job needs `.env` (your masjid's public settings, see
[setup.md](setup.md#4-env)). It's taken from, in order:

1. a committed `.env` – simplest in your own copy of the repository (all its
   values are public anyway): `git add -f .env`;
2. the `ENV_FILE` repository variable – the whole `.env` file pasted as the value;
3. `.env.example` – template defaults, enough for format/analyze/tests.

See `.github/scripts/create-env.sh`.

## Secrets

**Settings → Secrets and variables → Actions → Secrets**

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Upload keystore, base64 on one line (see below) |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias (e.g. `upload`) |
| `GOOGLE_SERVICES_JSON` | Full contents of `android/app/google-services.json` |
| `FIREBASE_TOKEN` | `firebase login:ci` – for the rules deployment |

```bash
base64 upload-keystore.jks | tr -d '\n'                                  # Linux/macOS
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))  # PowerShell
```

## Variables (public)

**Settings → Secrets and variables → Actions → Variables**

| Variable | Value |
|---|---|
| `ENV_FILE` | Optional: the whole `.env` file, if it isn't committed |

## Troubleshooting

| Failure | Fix |
|---|---|
| Formatting check fails | Run `dart format .` and commit |
| Analyze fails | Run `flutter analyze` locally; warnings and errors fail, infos don't |
| Android build skipped | Set the `GOOGLE_SERVICES_JSON` and `ANDROID_KEYSTORE_BASE64` secrets |
| Android signing fails | Keystore base64 must be one line; check the passwords and alias |
| No matching client for package name | `APP_ID` in `.env` must match the Android app in `GOOGLE_SERVICES_JSON` |
| Rules deployment fails | Token expired – run `firebase login:ci` and update `FIREBASE_TOKEN` |
