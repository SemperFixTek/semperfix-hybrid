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

    [[ -f "$HB_LOG" ]] && tail -n 20 "$HB_LOG" || log "No heartbeat log found"
    [[ -f "$SUP_LOG" ]] && tail -n 20 "$SUP_LOG" || log "No supervisor log found"
}

main "$@"
