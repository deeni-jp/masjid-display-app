#!/usr/bin/env bash
#
# masjid-display/raspberry-pi/setup.sh
#
# One-step setup for a Raspberry Pi masjid display (Raspberry Pi OS with
# desktop). Run it from the project folder (cloned or copied):
#
#   bash masjid-display/raspberry-pi/setup.sh
#
# It:
#   1. installs what's missing (Chromium, curl, Python) with apt,
#   2. builds the web app (installs Flutter first if needed, asking you),
#   3. makes the display start automatically when the desktop starts,
#   4. turns on desktop auto-login and turns off screen blanking (asks first),
#   5. opens the display now (full-screen Chromium).
#
# Run it again any time to rebuild and restart (e.g. after `git pull`).
#
#   Remove autostart:  bash masjid-display/raspberry-pi/setup.sh --uninstall

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$HERE/../.." && pwd)"
WEB_BUILD="$PROJECT_ROOT/build/web"
AUTOSTART_FILE="$HOME/.config/autostart/masjid-display.desktop"
LOCAL_FLUTTER="$HOME/flutter/bin/flutter"

step() { printf '\n\033[36m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[31mERROR: %s\033[0m\n' "$*"; exit 1; }
ask() {
    local reply
    read -r -p "$1 [Y/N] " reply
    [[ "$reply" =~ ^([yY]|[yY][eE][sS])$ ]]
}

if [ "${1:-}" = "--uninstall" ]; then
    bash "$HERE/stop-display.sh"
    rm -f "$AUTOSTART_FILE"
    echo 'Autostart removed. The display will no longer open at start-up.'
    exit 0
fi

chmod +x "$HERE"/*.sh "$HERE"/*.py

# 1. Packages ----------------------------------------------------------------
step 'Checking required software'
missing=()
command -v curl >/dev/null 2>&1 || missing+=(curl)
command -v python3 >/dev/null 2>&1 || missing+=(python3)
if ! command -v chromium-browser >/dev/null 2>&1 && ! command -v chromium >/dev/null 2>&1; then
    # The package is "chromium" on newer Raspberry Pi OS, "chromium-browser" on older.
    if apt-cache show chromium >/dev/null 2>&1; then missing+=(chromium); else missing+=(chromium-browser); fi
fi
if [ ${#missing[@]} -gt 0 ]; then
    echo "Installing: ${missing[*]} (you may be asked for your password)"
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
fi
echo 'Chromium, curl and Python are installed.'

# 2. Build the web app -------------------------------------------------------
step 'Building the app'
FLUTTER="$(command -v flutter || true)"
[ -z "$FLUTTER" ] && [ -x "$LOCAL_FLUTTER" ] && FLUTTER="$LOCAL_FLUTTER"

if [ -z "$FLUTTER" ]; then
    if [ -f "$WEB_BUILD/index.html" ]; then
        echo 'Flutter is not installed; using the existing build in build/web.'
    else
        echo 'Flutter (the tool that builds the app) is not installed.'
        if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "x86_64" ]; then
            fail "Flutter needs 64-bit Raspberry Pi OS (this is $(uname -m)). Build on another PC and copy its build/web folder into the project."
        fi
        ask "Download Flutter to $HOME/flutter now? (about 2 GB, one time only)" ||
            fail 'Cannot build the app without Flutter.'
        sudo apt-get install -y git unzip xz-utils zip
        git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter" ||
            fail 'Downloading Flutter failed. Check the internet connection and try again.'
        FLUTTER="$LOCAL_FLUTTER"
    fi
fi

if [ -n "$FLUTTER" ]; then
    # The app reads its settings from .env (public values only).
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        echo 'Created .env from .env.example.'
    fi
    echo 'Building (the first build can take 10+ minutes on a Raspberry Pi)...'
    (cd "$PROJECT_ROOT" && "$FLUTTER" build web --release) ||
        fail 'Building the app failed (see the messages above).'
fi
echo 'App is ready.'

# 3. Autostart ---------------------------------------------------------------
step 'Setting up autostart'
mkdir -p "$(dirname "$AUTOSTART_FILE")"
cat >"$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Masjid Display
Comment=Opens the masjid prayer-times display in full screen
Exec=bash "$HERE/start-display.sh"
X-GNOME-Autostart-enabled=true
EOF
echo 'The display will open automatically every time the desktop starts.'

# 4. Unattended start + screen always on --------------------------------------
if command -v raspi-config >/dev/null 2>&1; then
    step 'Raspberry Pi settings'
    if ask 'Log in to the desktop automatically and never blank the screen? (recommended)'; then
        sudo raspi-config nonint do_boot_behaviour B4   # desktop, auto-login
        sudo raspi-config nonint do_blanking 1          # 1 = screen blanking off
        echo 'Done (takes effect after a restart).'
    fi
fi

# 5. Start it now ------------------------------------------------------------
step 'Opening the display'
bash "$HERE/stop-display.sh" >/dev/null 2>&1 || true   # restart cleanly with the new build
if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    sleep 2
    setsid nohup bash "$HERE/start-display.sh" >/dev/null 2>&1 &
    echo
    printf '\033[32mDone! Chromium will open full screen in a few seconds.\033[0m\n'
else
    echo
    printf '\033[32mDone!\033[0m No desktop in this session (e.g. over SSH):\n'
    echo 'the display opens at the next restart (sudo reboot).'
fi
echo 'First time only: sign in with the display account (needs a keyboard).'
