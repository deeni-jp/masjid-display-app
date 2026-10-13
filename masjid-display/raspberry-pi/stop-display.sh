#!/usr/bin/env bash
#
# masjid-display/raspberry-pi/stop-display.sh
#
# Stops the masjid display: the keep-open loop, the kiosk Chromium window and
# the local web server. Run start-display.sh (or restart) to start it again.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Tell start-display.sh's loop to stop (it checks every 10 seconds).
touch "$HERE/stop.flag"

pkill -f -- "$HERE/start-display.sh"
pkill -f -- "--user-data-dir=$HERE/chrome-profile"
pkill -f -- "$HERE/serve_web.py"

echo 'Masjid display stopped.'
