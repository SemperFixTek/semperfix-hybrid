#!/usr/bin/env bash
# /opt/semperfix/monitors/inotify-monitor.sh
# Phoenix v2 — Optional Hardening Module
# Requires: inotify-tools

set -euo pipefail

# Phoenix v2 Standard Header
umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Phoenix v2 directories
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

mkdir -p "${STATE_DIR}"
mkdir -p "${LOG_DIR}"

PHOENIX_LOGFILE="${LOG_DIR}/inotify.log"
ALERT_LOG="${LOG_DIR}/inotify-alerts.log"

log()   { phoenix_log_file "INFO" "$*"; }
alert() { echo "[$(date -Iseconds)] [ALERT] $*" | tee -a "$ALERT_LOG" "$PHOENIX_LOGFILE"; }

# --- ROLE GUARD ---
# MASTERZERO = full monitoring
# SECONDARY  = optional monitoring
# OFFSITE    = disabled
if [[ "$NODE_ROLE" == "OFFSITE" ]]; then
    log "inotify-monitor disabled for OFFSITE role"
    exit 0
fi

# --- WATCH TARGETS ---
WATCH_PATHS=(
    "/etc/wsl.conf"
    "/etc/resolv.conf"
    "/opt/semperfix/config"
    "/opt/semperfix/scripts"
)

SYSTEMD_WATCH="/etc/systemd/system"

# --- HIGH-VALUE FILES (ALERTS ONLY) ---
PROTECTED_FILES=(
    "/etc/wsl.conf"
    "/etc/resolv.conf"
)

# --- EVENT FILTERING ---
# Only log meaningful events:
#   modify, create, delete, move
# Ignore:
#   attrib, open, close, access
EVENTS="modify,create,delete,move"

# --- RATE LIMITING ---
# Prevent log spam by suppressing repeated events within 2 seconds
LAST_EVENT_FILE="/tmp/inotify-last-event"
touch "$LAST_EVENT_FILE"

should_log_event() {
    local now last diff
    now=$(date +%s)
    last=$(cat "$LAST_EVENT_FILE" 2>/dev/null || echo 0)
    diff=$((now - last))

    if (( diff >= 2 )); then
        echo "$now" > "$LAST_EVENT_FILE"
        return 0
    else
        return 1
    fi
}

log "Phoenix v2 inotify-monitor starting (PID=$$)"
log "Watching paths: ${WATCH_PATHS[*]}"

# --- MAIN LOOP ---
inotifywait -m -r \
    -e modify -e create -e delete -e move \
    --format '%T %w %f %e' --timefmt '%Y-%m-%dT%H:%M:%S' \
    "${WATCH_PATHS[@]}" \
    "$SYSTEMD_WATCH"/semperfix-*.service \
    2>>"$PHOENIX_LOGFILE" | while read -r timestamp dir file events; do

    TARGET="${dir}${file}"

    # Rate-limit noisy events
    if ! should_log_event; then
        continue
    fi

    # Log meaningful event
    log "EVENT: $events on $TARGET at $timestamp"

    # Escalate protected files
    for protected in "${PROTECTED_FILES[@]}"; do
        if [[ "$TARGET" == "$protected" ]]; then
            alert "PROTECTED FILE MODIFIED: $TARGET — Event: $events"
        fi
    done

done
