# Masjid display (Windows PC)

Opens the app full screen in Google Chrome every time the masjid PC starts.
The PC serves the app itself (`http://localhost:8080`, reachable only from that
PC), so no other server or internet hosting is needed. The app still needs
internet access to reach Firebase.

## Setup (one step)

1. Put the project on the masjid PC — `git clone` it or copy the whole folder
   (e.g. to `C:\MasjidDisplay\prayer_times_app`).
2. Open the `masjid-display` folder and **double-click `setup.bat`**.

That's it. Setup will:

- check Google Chrome is installed (and offer to install it),
- build the app — if Flutter isn't installed it offers to download it
  (about 2 GB, one time only; needs Git),
- make the display open automatically whenever Windows signs in,
- open the display now in full screen.

**First time only:** sign in with the display account (connect a keyboard).
Chrome remembers the sign-in.

**Recommended:** turn on automatic Windows sign-in, so the display comes back
on its own after a restart or power cut: press Win+R → `netplwiz` → untick
"Users must enter a user name and password" (if it's missing: Settings →
Accounts → Sign-in options → turn off "only allow Windows Hello sign-in").
Optionally set the PC's BIOS to power on after a power loss.

## Everyday use

- **Leave full screen temporarily:** `Alt+F4` closes Chrome; it reopens within
  ~10 seconds.
- **Stop the display** (e.g. for maintenance): right-click `stop-display.ps1` →
  *Run with PowerShell*.
- **Start it again:** restart the PC, or run `setup.bat` again.
- **Update the app:** `git pull` (or copy the new project files over), then
  run `setup.bat` again — it rebuilds and restarts the display.
- **Remove autostart:** `setup.bat -Uninstall` from a command prompt.

## Files

| File | What it does |
|---|---|
| `setup.bat` | The only thing you need to run: builds, installs autostart, starts the display |
| `start-display.ps1` | Run at every sign-in: starts the local web server, opens Chrome in kiosk mode, reopens it if closed, keeps the screen awake |
| `serve-web.ps1` | Tiny web server (built-in PowerShell, nothing to install) |
| `stop-display.ps1` | Stops everything |
| `raspberry-pi/` | The same scripts for Raspberry Pi OS (`setup.sh`, …) |

## Raspberry Pi instead of Windows

The same thing works on a Raspberry Pi with **Raspberry Pi OS (64-bit, with
desktop)**; the scripts are in `raspberry-pi/`.

1. Put the project on the Pi (`git clone ...`).
2. Open a terminal in the project folder and run:

   ```bash
   bash masjid-display/raspberry-pi/setup.sh
   ```

It does the same steps as `setup.bat`, using Chromium. It also offers to turn
on desktop auto-login and turn off screen blanking. Update with `git pull`
and run it again. Stop with `bash masjid-display/raspberry-pi/stop-display.sh`;
remove autostart with `setup.sh --uninstall`. Log:
`masjid-display/raspberry-pi/logs/display.log`.

Notes:

- Use a **Raspberry Pi 4 or 5 with 4 GB+ RAM**. Smaller models can run the
  display but may be too slow or run out of memory building the app.
- Building on the Pi is slow (10+ minutes the first time). Alternatively,
  build on a PC (`flutter build web --release`) and copy its `build/web`
  folder into the project on the Pi; setup then skips the build.

## Troubleshooting

- Log file: `masjid-display\logs\display.log`.
- **Black/blank screen:** check the log; open `http://localhost:8080` in
  normal Chrome.
- **"Port in use":** another program uses 8080 — change the default `$Port` at
  the top of `start-display.ps1` and run `setup.bat` again.
- **Location:** the browser may ask once for location permission; allow it,
  or the app uses IP-based location.
- **Pushes from this PC:** sending notices works, but phone notifications are
  only sent if `PUSH_WORKER_URL` is set in the project's `.env` (setup creates
  `.env` from `.env.example` if it's missing).
