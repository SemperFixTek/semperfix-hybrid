#!/usr/bin/env bash
set -euo pipefail

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
