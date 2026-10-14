#!/usr/bin/env bash
#
# masjid-display/raspberry-pi/start-display.sh
#
# Starts the masjid display (Raspberry Pi version of start-display.ps1):
#   1. starts the local web server (serve_web.py) if it isn't running,
#   2. waits until the app is reachable,
#   3. opens it in Chromium in full-screen kiosk mode,
#   4. reopens Chromium if it's closed or crashes.
#
# Runs automatically at desktop sign-in once setup.sh has been run.
# Stop it with stop-display.sh. To leave the kiosk temporarily: Alt+F4
# (it reopens after a few seconds unless stop-display.sh was run).
#
# Options: --dry-run  start the server and print the Chromium command only

set -u

PORT=8080
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_ROOT="$(cd "$HERE/../.." && pwd)/build/web"

# Screen orientation and text size, chosen in setup.sh
ORIENTATION=horizontal
TEXT_SIZE=normal
# shellcheck source=/dev/null
[ -f "$HERE/display.conf" ] && . "$HERE/display.conf"

URL="http://localhost:$PORT/?textSize=$TEXT_SIZE"
STOP_FLAG="$HERE/stop.flag"
PROFILE_DIR="$HERE/chrome-profile"
LOG_DIR="$HERE/logs"
LOG_FILE="$LOG_DIR/display.log"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

mkdir -p "$LOG_DIR"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" | tee -a "$LOG_FILE"; }

app_reachable() { curl -fsS -o /dev/null --max-time 3 "$URL"; }

start_server() {
    nohup python3 "$HERE/serve_web.py" --root "$WEB_ROOT" --port "$PORT" \
        >>"$LOG_FILE" 2>&1 &
}

find_chromium() {
    for c in chromium-browser chromium google-chrome; do
        if command -v "$c" >/dev/null 2>&1; then echo "$c"; return 0; fi
    done
    return 1
}

kiosk_running() { pgrep -f -- "--user-data-dir=$PROFILE_DIR" >/dev/null; }

# Turns the picture for a vertically mounted screen (every start, so it
# survives restarts). Wayland (newer Raspberry Pi OS): wlr-randr; X11: xrandr.
rotate_screen() {
    local wayland xorg output
    case "$ORIENTATION" in
        vertical) wayland=90; xorg=left ;;     # both: 90° anticlockwise
        vertical-flipped) wayland=270; xorg=right ;;
        *) return 0 ;;
    esac
    if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wlr-randr >/dev/null 2>&1; then
        output="$(wlr-randr | awk '/^[^ ]/ { print $1; exit }')"
        if [ -n "$output" ] && wlr-randr --output "$output" --transform "$wayland"; then
            log "Screen rotated for $ORIENTATION ($output)"
            return 0
        fi
    elif [ -n "${DISPLAY:-}" ] && command -v xrandr >/dev/null 2>&1; then
        output="$(xrandr --query | awk '/ connected/ { print $1; exit }')"
        if [ -n "$output" ] && xrandr --output "$output" --rotate "$xorg"; then
            log "Screen rotated for $ORIENTATION ($output)"
            return 0
        fi
    fi
    log 'WARNING: could not rotate the screen; set it in Preferences > Screen Configuration'
}

log "Starting masjid display ($URL)"
rm -f "$STOP_FLAG"

# 1. Web server
if app_reachable; then
    log 'Web server already running'
else
    if [ ! -f "$WEB_ROOT/index.html" ]; then
        log "ERROR: no web build in '$WEB_ROOT' (run setup.sh)"
        exit 1
    fi
    start_server
    log 'Web server starting...'
fi

# 2. Wait for it (up to 60 s; the desktop may still be starting)
for _ in $(seq 60); do
    app_reachable && break
    sleep 1
done
if ! app_reachable; then
    log 'ERROR: web server did not respond within 60 seconds'
    exit 1
fi
log 'Web server is up'

# 3. Chromium in kiosk mode
if ! CHROMIUM="$(find_chromium)"; then
    log 'ERROR: Chromium not found. Run setup.sh again.'
    exit 1
fi
CHROMIUM_ARGS=(
    --kiosk "$URL"
    "--user-data-dir=$PROFILE_DIR"
    --no-first-run
    --no-default-browser-check
    --noerrdialogs
    --disable-session-crashed-bubble
    --disable-infobars
    --disable-features=Translate
    --overscroll-history-navigation=0
    --password-store=basic   # no "unlock keyring" pop-up
)

if [ "$DRY_RUN" = 1 ]; then
    log "DryRun: would run $CHROMIUM ${CHROMIUM_ARGS[*]}"
    exit 0
fi

# Keep the screen on (X11 desktops; on Wayland setup.sh turns blanking off).
command -v xset >/dev/null 2>&1 && xset s off -dpms s noblank 2>/dev/null

rotate_screen

# 4. Keep it open
while [ ! -f "$STOP_FLAG" ]; do
    if ! kiosk_running; then
        if ! app_reachable; then
            log 'Web server not responding; restarting it'
            start_server
            sleep 3
        fi
        log 'Opening Chromium (kiosk)'
        nohup "$CHROMIUM" "${CHROMIUM_ARGS[@]}" >/dev/null 2>&1 &
    fi
    sleep 10
done

log 'Stop requested; exiting'
