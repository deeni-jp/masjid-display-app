#!/usr/bin/env bash
#
# masjid-display/raspberry-pi/stop-display.sh
#
# Stops the masjid display: the keep-open loop, the kiosk Chromium window and
# the local web server, and removes autostart so it stays off after a restart.
# Run setup.sh to start the display (and autostart) again.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Tell start-display.sh's loop to stop (it checks every 10 seconds).
touch "$HERE/stop.flag"

pkill -f -- "$HERE/start-display.sh"
pkill -f -- "--user-data-dir=$HERE/chrome-profile"
pkill -f -- "$HERE/serve_web.py"

# Don't open again at start-up (setup.sh creates this file).
rm -f "$HOME/.config/autostart/masjid-display.desktop"

echo 'Masjid display stopped. It will not open at start-up until you run setup.sh again.'
