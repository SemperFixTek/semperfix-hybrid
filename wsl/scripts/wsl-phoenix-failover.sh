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
    log "Starting Phoenix v2 Failover Check for role: ${NODE_ROLE}"

    json_init "$FAILOVER_FILE"
    json_set "$FAILOVER_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$FAILOVER_FILE" "node_role" "$NODE_ROLE"

    case "$NODE_ROLE" in

        MASTERZERO)
            log "INFO" "MASTERZERO evaluating failover conditions"

            local failover_needed
            failover_needed=$(should_failover)

            json_set_raw "$FAILOVER_FILE" "failover_needed" "$failover_needed"
            ;;

        SECONDARY)
            log "INFO" "SECONDARY does not evaluate failover — MASTERZERO decides"

            json_set "$FAILOVER_FILE" "failover_needed" "handled_by_master"
            ;;

        OFFSITE)
            log "INFO" "OFFSITE does not participate in failover logic"

            json_set "$FAILOVER_FILE" "failover_needed" "not_applicable"
            ;;

        *)
            log "INFO" "Unknown node role: ${NODE_ROLE}"
            json_set "$FAILOVER_FILE" "failover_needed" "invalid_node_role"
            ;;
    esac

    json_finalize "$FAILOVER_FILE"
    log "Failover state written to $FAILOVER_FILE"
}


main "$@"
