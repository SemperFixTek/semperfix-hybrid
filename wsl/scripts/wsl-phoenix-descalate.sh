#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Normalize line endings
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

HB_LOG="${LOG_DIR}/phoenix-heartbeat.log"
SUP_LOG="${LOG_DIR}/phoenix-supervisor.log"
DESC_LOG="${LOG_DIR}/phoenix-descalate.log"

PHOENIX_LOGFILE="$DESC_LOG"
log() { phoenix_log_file "INFO" "$*"; }

# --- ROLE GUARD ---
if [[ "$NODE_ROLE" != "MASTERZERO" ]]; then
    log "Descalate snapshot disabled for role: ${NODE_ROLE}"
    exit 0
fi

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

    # Fix permissions for Syncthing + Windows
    chown root:semperfix "$DESC_LOG"
    chmod 664 "$DESC_LOG"
}

main "$@"
