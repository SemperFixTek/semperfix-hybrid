#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

mkdir -p "$STATE_DIR" "$LOG_DIR"
dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

# --- ROLE GUARD ---
if [[ "$NODE_ROLE" != "MASTERZERO" ]]; then
    log "Descalate snapshot disabled for role: ${NODE_ROLE}"
    exit 0
fi


HB_LOG="${LOG_DIR}/phoenix-heartbeat.log"
SUP_LOG="${LOG_DIR}/phoenix-supervisor.log"
DESC_LOG="${LOG_DIR}/phoenix-descalate.log"

PHOENIX_LOGFILE="$DESC_LOG"
log() { phoenix_log_file "INFO" "$*"; }

main() {
    log "Phoenix v2 Descalate — log snapshot"

    if [[ -f "$HB_LOG" ]]; then
        log "Heartbeat log (last 20 lines):"
        tail -n 20 "$HB_LOG" >> "$DESC_LOG"
    else
        log "No heartbeat log found"
    fi

    if [[ -f "$SUP_LOG" ]]; then
        log "Supervisor log (last 20 lines):"
        tail -n 20 "$SUP_LOG" >> "$DESC_LOG"
    else
        log "No supervisor log found"
    fi
}

main "$@"
