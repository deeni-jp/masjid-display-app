# Masjid display

Opens the app full screen on the masjid PC every time it starts. The PC serves
the app itself on `http://localhost:8080` (reachable only from that PC); it
still needs internet to reach Firebase.

## Setup

Clone or copy your copy of the project onto the PC. It needs your masjid's
`.env` in the project folder (masjid name, Firebase values – see
[docs/setup.md](../docs/setup.md)); if it's missing, setup creates it from
`.env.example` and stops so you can fill it in. Then:

| PC | Run |
|---|---|
| **Windows 10/11** | Double-click `masjid-display\setup.bat` |
| **Raspberry Pi** (Pi 4/5, 4 GB+, 64-bit Raspberry Pi OS with desktop) | `bash masjid-display/raspberry-pi/setup.sh` |

Setup installs what's missing (Chrome/Chromium; Flutter after asking – about
2 GB, one time), builds the app, makes it start automatically, and opens it.
**First time only:** sign in with the display account (needs a keyboard).

Setup also asks two questions (saved in `display.conf` next to the setup
script; press Enter to keep the current answer):

- **How the screen is mounted** – horizontal or vertical. A vertical screen
  gets its own layout (prayer times on top, notices below). On a Raspberry Pi
  setup turns the picture itself; if it ends up upside down, run setup again
  and pick "Vertical, the other way up". On Windows, rotate it once in
  Settings → System → Display → Display orientation.
- **Text size** – Normal, Large or Extra large, for reading from far away.

Screen size in inches doesn't need a setting: the layout always fills the
screen, so a bigger monitor simply shows everything bigger.

**Unattended restarts:** the PC must sign in by itself after a power cut.

- Windows: Win+R → `netplwiz` → untick "Users must enter a user name and
  password" (if missing: Settings → Accounts → Sign-in options → turn off
  "only allow Windows Hello sign-in").
- Raspberry Pi: setup offers to turn on auto-login and turn off screen blanking.

Building on a Pi takes 10+ minutes. Alternatively build on another PC
(`flutter build web --release`) and copy its `build/web` folder into the
project; setup then skips the build.

## Everyday use

| To… | Do |
|---|---|
| Leave full screen briefly | `Alt+F4` – it reopens within ~10 seconds |
| Stop the display and use the PC normally | Windows: double-click `stop-display.bat` · Pi: `bash masjid-display/raspberry-pi/stop-display.sh`. It stays off, also after a restart, until you run setup again |
| Start it again | Run setup again (`setup.bat` / `setup.sh`) |
| Update the app | `git pull`, then run setup again (rebuilds and restarts) |
| Change orientation or text size | Run setup again. Text size can also be changed on the display: settings (gear) → Settings |

## Troubleshooting

- Log: `masjid-display/logs/display.log` (Pi: `masjid-display/raspberry-pi/logs/display.log`).
- Blank screen: check the log; open `http://localhost:8080` in a normal browser window.
- Port 8080 in use: change `$Port` / `PORT` at the top of `start-display.ps1`
  / `start-display.sh` and run setup again.
- Location: allow the browser's location prompt, or the app uses IP-based location.
- Setup stops with "Fill in your masjid's settings": fill in `.env` (at least
  the `FIREBASE_*` values) and run setup again. `PUSH_WORKER_URL` is only needed
  if notices will be posted from this PC.
