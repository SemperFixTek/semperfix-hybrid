#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Supervisor
# Version: Phoenix v2.2
# Component: phoenix-supervisor
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

SUP_FILE="${STATE_DIR}/phoenix-supervisor.json"
LOGFILE="${LOG_DIR}/phoenix-supervisor.log"
LOCKFILE="/run/lock/phoenix-supervisor.lock"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

log() {
    phoenix_log_file "INFO" "$*"
}

# ------------------------------------------------------------
# Locking
# ------------------------------------------------------------

exec 200>"$LOCKFILE"

flock -n 200 || {
    log "Supervisor already running"
    exit 0
}

# ------------------------------------------------------------
# Supervisor Workflow Cycle
# ------------------------------------------------------------

SUPERVISOR_CYCLE=$(date +%s)

export SUPERVISOR_CYCLE

log "Supervisor cycle=${SUPERVISOR_CYCLE}"

# ------------------------------------------------------------
# Workers
# ------------------------------------------------------------

run_handshake() {
    /opt/semperfix/scripts/mesh-handshake.sh || true
}

run_verify() {
    /opt/semperfix/scripts/mesh-verify.sh || true
}

run_activate() {
    /opt/semperfix/scripts/mesh-activate.sh || true
}


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

read_state_value() {

    local file="$1"
    local key="$2"

    jq -r \
        ".${key} // \"unknown\"" "$file" 2>/dev/null || echo "unknown"
}

validate_worker_cycle() {

    local file="$1"
    local worker="$2"

    local cycle

    if [[ ! -f "$file" ]]; then

        log "${worker} output missing"

        return 1

    fi

    cycle=$(
        jq -r '.supervisor_cycle // empty' "$file" 2>/dev/null
    )

    if [[ "$cycle" != "$SUPERVISOR_CYCLE" ]]; then

        log "${worker} cycle mismatch"

        log "Expected=${SUPERVISOR_CYCLE}"

        log "Actual=${cycle:-missing}"

        return 1

    fi

    return 0
}

get_failover() {

    local handshake="$1"
    local verify="$2"
    local activate="$3"

    if [[ "$handshake" == "pass" &&
          "$verify"    == "pass" &&
          "$activate"  == "pass"
    ]]
    then
        echo "not_needed"
    else
        echo "needed"
    fi
}

ROLE="$NODE_ROLE"

log "Phoenix Supervisor starting for role=${ROLE}"

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {

    local handshake_status="not_applicable"
    local verify_status="not_applicable"
    local activate_status="not_applicable"
    local failover_status="not_applicable"

    case "$ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)

            log "$ROLE performing full supervisor cycle"

            run_handshake

            validate_worker_cycle "${STATE_DIR}/mesh-handshake.json" "handshake" || true
            handshake_status=$(
                read_state_value "${STATE_DIR}/mesh-handshake.json" "handshake_status"
            )

            run_verify

            validate_worker_cycle "${STATE_DIR}/mesh-verify.json" "verify" || true              
            verify_status=$(
                read_state_value "${STATE_DIR}/mesh-verify.json" "verify_status"
            )

            run_activate

            validate_worker_cycle "${STATE_DIR}/mesh-activate.json" "activate" || true
            activate_status=$(
                read_state_value "${STATE_DIR}/mesh-activate.json" "activate_status"
            )

            failover_status=$(
                get_failover "$handshake_status" "$verify_status" "$activate_status"
            )

            ;;

        SECONDARY-ACTIVE)

            log "SECONDARY-ACTIVE performing promoted cycle"

            run_handshake

            handshake_status=$(
                read_state_value "${STATE_DIR}/mesh-handshake.json" "handshake_status"
            )

            run_verify

            verify_status=$(
                read_state_value "${STATE_DIR}/mesh-verify.json" "verify_status"
            )

            run_activate

            activate_status=$(
                read_state_value "${STATE_DIR}/mesh-activate.json" "activate_status"
            )

            failover_status=$(
                get_failover \
                    "$handshake_status" "$verify_status" "$activate_status"
            )

            ;;

        SECONDARY-PASSIVE)

            log "SECONDARY-PASSIVE supervisor telemetry"

            run_handshake

            handshake_status=$(
                read_state_value \
                    "${STATE_DIR}/mesh-handshake.json" "handshake_status"
            )

            verify_status="not_applicable"
            activate_status="not_applicable"
            failover_status="not_applicable"

            ;;

        OFFSITE)

            log "OFFSITE limited supervisor cycle"

            run_handshake

            handshake_status=$(
                read_state_value \
                    "${STATE_DIR}/mesh-handshake.json" "handshake_status"
            )

            verify_status="not_applicable"
            activate_status="not_applicable"
            failover_status="not_applicable"

            ;;

        *)

            log "Unknown node role: ${ROLE}"

            handshake_status="invalid_role"
            verify_status="invalid_role"
            activate_status="invalid_role"
            failover_status="invalid_role"

            ;;

    esac

    log "cycle=${SUPERVISOR_CYCLE}"
    log "handshake_status=${handshake_status}"
    log "verify_status=${verify_status}"
    log "activate_status=${activate_status}"
    log "failover_status=${failover_status}"

    json_init "$SUP_FILE"

    json_set "$SUP_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$SUP_FILE" "supervisor_cycle" "$SUPERVISOR_CYCLE"
    json_set "$SUP_FILE" "node_role" "$ROLE"
    json_set "$SUP_FILE" "handshake_status" "$handshake_status"
    json_set "$SUP_FILE" "verify_status" "$verify_status"
    json_set "$SUP_FILE" "activate_status" "$activate_status"
    json_set "$SUP_FILE" "failover_status" "$failover_status"
    
    json_finalize "$SUP_FILE"

    /opt/semperfix/scripts/json-perms.sh "$SUP_FILE"

    log "Supervisor state written to $SUP_FILE"
}

main "$@"