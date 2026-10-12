#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"
SUP_FILE="${STATE_DIR}/phoenix-supervisor.json"
LOGFILE="${LOG_DIR}/phoenix-supervisor.log"

mkdir -p "$STATE_DIR" "$LOG_DIR"

# Convert CRLF if needed
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core + JSON utilities
source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

# Use core logging function
PHOENIX_LOGFILE="$LOGFILE"
log() {
    phoenix_log_file "INFO" "$*";
}

run_handshake() {
    /opt/semperfix/scripts/wsl-mesh-handshake.sh
}

run_verify() {
    /opt/semperfix/scripts/wsl-mesh-verify.sh
}

run_activate() {
    /opt/semperfix/scripts/wsl-mesh-activate.sh
}

main() {
    log "Starting Phoenix v2 Supervisor for role: ${NODE_ROLE}"

    local handshake_status="not_applicable"
    local verify_status="not_applicable"
    local activate_status="not_applicable"

    case "${NODE_ROLE}" in

        MASTERZERO)
            log "MASTERZERO performing full supervisor cycle"

            if run_handshake; then handshake_status="pass"; else handshake_status="fail"; fi
            if run_verify; then verify_status="pass"; else verify_status="fail"; fi
            if run_activate; then activate_status="pass"; else activate_status="fail"; fi
            ;;

        SECONDARY)
            log "SECONDARY performing full supervisor cycle"

            if run_handshake; then handshake_status="pass"; else handshake_status="fail"; fi
            if run_verify; then verify_status="pass"; else verify_status="fail"; fi
            if run_activate; then activate_status="pass"; else activate_status="fail"; fi
            ;;

        OFFSITE)
            log "OFFSITE performing limited supervisor cycle"

            if run_handshake; then handshake_status="pass"; else handshake_status="fail"; fi

            verify_status="not_applicable"
            activate_status="not_applicable"
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            handshake_status="invalid_role"
            verify_status="invalid_role"
            activate_status="invalid_role"
            ;;
    esac

    # Unified JSON Writer
    json_init "$SUP_FILE"

    json_set "$SUP_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$SUP_FILE" "node_role" "$NODE_ROLE"
    json_set "$SUP_FILE" "handshake_status" "$handshake_status"
    json_set "$SUP_FILE" "verify_status" "$verify_status"
    json_set "$SUP_FILE" "activate_status" "$activate_status"

    # Backward compatibility
    json_set "$SUP_FILE" "handshake" "$handshake_status"
    json_set "$SUP_FILE" "verify" "$verify_status"
    json_set "$SUP_FILE" "activate" "$activate_status"

    json_finalize "$SUP_FILE"

    log "Supervisor state written to $SUP_FILE"
}

main "$@"
