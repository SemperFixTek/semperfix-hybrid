#!/bin/bash
# /opt/semperfix/monitors/inotify-monitor.sh
# SemperFix Phoenix v2 — inotify File Integrity Monitor
# Requires: inotify-tools (apt install inotify-tools)

set -euo pipefail

LOG=/opt/semperfix/logs/inotify.log
ALERT_LOG=/opt/semperfix/logs/inotify-alerts.log

WATCH_PATHS=(
    "/etc/wsl.conf"
    "/opt/semperfix/config"
    "/opt/semperfix/scripts"
    "/etc/resolv.conf"
)

SYSTEMD_WATCH="/etc/systemd/system"

log() {
    echo "[$(date -Iseconds)] [INOTIFY] $*" | tee -a "$LOG"
}

alert() {
    echo "[$(date -Iseconds)] [ALERT] $*" | tee -a "$ALERT_LOG" "$LOG"
}

log "inotify-monitor starting. PID=$$"
log "Watching: ${WATCH_PATHS[*]}"

# Watch critical paths recursively
inotifywait -m -r \
    -e modify -e create -e delete -e move -e attrib \
    --format '%T %w %f %e' --timefmt '%Y-%m-%dT%H:%M:%S' \
    "${WATCH_PATHS[@]}" \
    "$SYSTEMD_WATCH"/semperfix-*.service \
    2>>"$LOG" | while read -r timestamp dir file events; do

    TARGET="${dir}${file}"
    log "EVENT: $events on $TARGET at $timestamp"

    # Escalate wsl.conf and resolv.conf events as ALERTS
    if [[ "$TARGET" == "/etc/wsl.conf" || "$TARGET" == "/etc/resolv.conf" ]]; then
        alert "PROTECTED FILE MODIFIED: $TARGET — Event: $events"
    fi

done
