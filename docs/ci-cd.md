# CI/CD

One GitHub Actions workflow: [`.github/workflows/flutter-ci.yml`](../.github/workflows/flutter-ci.yml).

## Jobs

| Job | Runs on | What it does |
|---|---|---|
| **Analyze** | Every push to any branch; PRs to `main`/`develop` | `dart format` check, `flutter analyze --no-fatal-infos`, `flutter test --coverage` |
| **Build Android** | Pushes to `main`, `v*` tags, manual runs | Signed release APK + AAB, uploaded as artifacts |
| **Build iOS** | Manual runs only ("Build iOS") | Unsigned iOS build |
| **Deploy Firebase** | Manual runs only ("Deploy Firestore rules") | `firebase deploy --only firestore:rules` |
| **Release** | `v*` tags | GitHub release with the APK and AAB attached |

- Manual runs: GitHub → **Actions** → **Flutter CI/CD** → **Run workflow**.
- A newer push to the same branch cancels the older run.
- Rules deployment is never automatic, because it changes live database security.
- Release: `git tag v1.2.0 && git push origin v1.2.0`.

Every build creates its own `.env` from defaults plus the repository variables
below.

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
| `PUSH_WORKER_URL` | Push worker URL (`npx wrangler deploy` prints it) |
| `APP_CHECK_WEB_SITE_KEY` | reCAPTCHA v3 site key (optional) |

## Troubleshooting

| Failure | Fix |
|---|---|
| Formatting check fails | Run `dart format .` and commit |
| Analyze fails | Run `flutter analyze` locally; warnings and errors fail, infos don't |
| Android signing fails | Keystore base64 must be one line; check the passwords and alias |
| Rules deployment fails | Token expired – run `firebase login:ci` and update `FIREBASE_TOKEN` |
