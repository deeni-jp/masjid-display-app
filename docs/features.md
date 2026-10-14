# Features

## Roles

| Role | Can |
|---|---|
| **Public** (default for new accounts) | View prayer times and notices; edit own display name and password |
| **Moderator** | Everything above, plus edit iqamah times and create/edit/delete notices |
| **Admin** | Everything above, plus view users and change their roles (Settings → Manage Users) |

Roles are enforced by the Firestore rules, not only by the app.

## Prayer times

- Begin times come from the Aladhan API for the device's location (GPS, with
  IP-based fallback); iqamah times are set by moderators and synced live.
- **Sunrise** is shown but is not a prayer: no iqamah, never the "next prayer".
- **Jumuah** replaces Dhuhr on Fridays; other days it is an extra row.
- Data is cached, so the app keeps working briefly without internet.

## Iqamah sequence

Shown on phones and the display, calculated from the iqamah time (so the right
screen appears even after a restart):

| Screen | When |
|---|---|
| Iqamah countdown | Final 60 seconds before iqamah |
| Time for prayer | 30 seconds from iqamah, with etiquette reminders |
| Prayer in progress | 10-minute black, silent screen (English and Japanese) |

Durations: `lib/models/prayer_windows.dart`. A prohibited-time alert (sunrise,
zenith, sunset) is implemented in `prohibited_time_overlay.dart` but disabled.

## Notices

- Types: **Announcement**, **Event** (with event time), **Alert**.
- Priorities: **High**, **Regular**, **Low**; high-priority notices are shown first.
- Optional image, expiry date and active/inactive switch. Expired notices are
  cleaned up every 15 minutes.
- The home screen rotates through active notices every 5 seconds; a ticker
  scrolls them on the display.
- Saving a notice sends a push notification to phones (see
  [push-notifications.md](push-notifications.md)).

## Masjid display mode

When the window is at least **900 px wide** (TV, monitor, landscape tablet),
the Home tab switches to the display layout (`design/screens/1 · Home display`)
and hides the bottom navigation; the ⚙️ button opens Settings.

| Area | Content |
|---|---|
| Top left | Clock: time, Gregorian date, Hijri date (English and Arabic) |
| Top right | Masjid logo and name, settings button |
| Left | Large prayer table with begin and iqamah times; next prayer highlighted |
| Right | Next-prayer countdown, rotating notices |
| Bottom | Notice ticker |

On a screen taller than wide (monitor mounted vertically) the same parts are
stacked instead: clock, masjid name, prayer table (largest), countdown,
notices, then the ticker.

To run it on a dedicated PC that opens it full screen at boot, see
[masjid-display/README.md](../masjid-display/README.md).

## Appearance

- **Theme**: Light, Dark, or Auto (dark from sunset to sunrise; the default).
- **Text size**: Small, Normal, Large or Extra large, on top of the device's
  own font size; applies everywhere, including the masjid display. Both are in
  Settings.
- English UI with Arabic labels; fonts Manrope, Noto Sans Arabic, Noto Sans JP.
- Phone layout: next-prayer card, prayer list, rotating notice card, and bottom
  navigation (Times, Prayers, Qibla – not on web, Notices, Settings).
