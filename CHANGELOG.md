# Changelog

## Unreleased

### Masjid display
- Footer ticker shows announcements and alerts only (no events).
- Notices with only an image (no description) are shown full screen for 5
  seconds instead of in the small notices card; never two in a row, and always
  underneath the iqamah countdown / prayer screens.

## 1.2.0 (13 October 2026)

UI redesign, masjid display mode, production readiness and the masjid display
PC setup. Deployed and running on the masjid display (Raspberry Pi).

### Masjid display PC
- One-step kiosk setup for the masjid display: `masjid-display/setup.bat`
  (Windows) and `masjid-display/raspberry-pi/setup.sh` (Raspberry Pi OS) build
  the app, serve it on localhost only and open it full screen at every boot.
- Notices card shows the full description: the text shrinks to fit the card
  (ellipsis only if it still doesn't fit); long notices stay on screen longer
  (10-30 s); notices with an image also show their description; event times
  include the date.

### Documentation
- Short README; detailed guides moved to `docs/`; added `CONTRIBUTING.md` and
  this changelog. Removed outdated guides and committed `node_modules`.

### Security
- Push notifications are sent by a Cloudflare Worker (`push-worker/`); the
  Firebase service-account key is no longer bundled in the app (`.env` now holds
  public settings only).
- Firestore rules: users can't assign themselves a role or undelete
  themselves; only moderators/admins can write `mosque/*`; only admins can read
  other users' profiles.

### Production readiness
- App name "Darut Tauhid Masjid", masjid logo in the app, new launcher/web icons.
- Compact, centred login page on wide screens (web).
- Android app ID `com.dticc.app`; release signing from `key.properties`.
- Firebase App Check (monitoring mode) on Android, iOS and web.
- Web app runs locally for now; Firebase Hosting config prepared for a later
  public launch.
- Browsers are no longer asked for notification permission (web push isn't set up).
- Removed unused token-based push code and the `googleapis_auth` dependency.

### CI
- Checks run on every branch; all analyzer issues fixed; Android builds on
  `main`, iOS builds and rules deployment are manual.

### UI redesign and masjid display

#### New
- Masjid display mode for screens ≥ 900 px wide: large prayer table, clock with
  Gregorian and Hijri dates, rotating notices, next-prayer countdown, donation
  QR code, notice ticker.
- Iqamah sequence: 60 s countdown → 30 s "Time for prayer" → 10-minute "Prayer
  in progress" → home (display and phones).
- "Time for prayer" screen with etiquette reminders.
- Jummah in the prayer tables, in place of Dhuhr on Fridays.
- Dark mode for the redesigned home screens; Arabic labels throughout; Japanese
  on the "Prayer in progress" screen.
- Image attachments for notices.

#### Changed
- Redesigned mobile home, iqamah countdown and "Prayer in progress" screens to
  match `design/screens`.
- Bottom navigation with English and Arabic labels.
- Mobile notice card rotates through all active notices (high priority first).
- "Prayer in progress" lasts 10 minutes (was 7).
- Sunrise removed from the Prayers tab and never counted as the next prayer.
- Prohibited-time alert implemented but disabled for now.

#### Fixed
- Bottom navigation overflow on very small browser windows.
- Notice dots switch to a "3 / 20" counter above 10 notices.

## 1.1.0

- Removed all hardcoded credentials; Firebase-only authentication.
- Environment configuration with `flutter_dotenv`.
- Input validation for prayer times, coordinates and user input.
- CI creates `.env` during builds; secrets kept in GitHub Secrets.

## 1.0.0

- Multiple notices with types (Announcement, Event, Alert) and priorities
  (High, Regular, Low), detail view, filtering, news ticker and auto-cleanup.
- Real-time Firestore sync; moderators can edit iqamah times.
- User management for admins.
- Improved dark mode and caching.
