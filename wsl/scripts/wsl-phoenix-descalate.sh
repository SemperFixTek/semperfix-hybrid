#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002

# Ensure consistent locale + predictable JSON behavior
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true


source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

LOG_DIR="/opt/semperfix/logs"
HB_LOG="${LOG_DIR}/phoenix-heartbeat.log"
SUP_LOG="${LOG_DIR}/phoenix-supervisor.log"

log() {
    echo "[INFO] $1"
}

main() {
    log "Phoenix v2 Descalate — log snapshot"

    if [[ -f "$HB_LOG" ]]; then
        log "Heartbeat log (last 20 lines):"
        tail -n 20 "$HB_LOG"
    else
        log "No heartbeat log found"
    fi

    if [[ -f "$SUP_LOG" ]]; then
        log "Supervisor log (last 20 lines):"
        tail -n 20 "$SUP_LOG"
    else
        log "No supervisor log found"
    fi
}

main "$@"
