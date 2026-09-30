#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

FAILOVER_FILE="${STATE_DIR}/phoenix-failover.json"
HB_FILE="${STATE_DIR}/phoenix-heartbeat.json"
LOGFILE="${LOG_DIR}/phoenix-failover.log"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log() {
    echo "[INFO] $1" | tee -a "$LOGFILE"
}

safe_bool() {
    local file="$1"
    local field="$2"
    local val

    val=$(jq -r "$field // \"false\"" "$file" 2>/dev/null || echo "false")
    [[ "$val" == "true" ]] && echo "true" || echo "false"
}

should_failover() {
    local api_ok mesh_ok

    api_ok=$(safe_bool "$HB_FILE" '.api_ok')
    mesh_ok=$(safe_bool "$HB_FILE" '.mesh_ok')

    if [[ "$api_ok" == "false" || "$mesh_ok" == "false" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

main() {
    : > "$LOGFILE"
    log "Starting Phoenix v2 Failover Check"

    local failover_needed
    failover_needed=$(should_failover)

    # ---------- Unified JSON Writer ----------
    json_init "$FAILOVER_FILE"

    json_set "$FAILOVER_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$FAILOVER_FILE" "node_role" "$NODE_ROLE"
    json_set_raw "$FAILOVER_FILE" "failover_needed" "$failover_needed"

    json_finalize "$FAILOVER_FILE"

    log "Failover state written to $FAILOVER_FILE"
}

main "$@"
