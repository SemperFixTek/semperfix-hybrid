#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Supervisor
# Version: Phoenix v2.1
# Component: phoenix-supervisor
# Role: Controller / Observer (role-aware)
# Refactor: 2026-11-08 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-08
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" >/dev/null 2>&1 || true

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

#
# ------------------------------------------------------------
# Locking
# ------------------------------------------------------------
#

exec 200>"$LOCKFILE"

flock -n 200 || {
    log "Supervisor already running"
    exit 0
}

#
# ------------------------------------------------------------
# Workers
# ------------------------------------------------------------
#

run_handshake() {
    local handshake_script=$HANDSHAKE_SCRIPT
    # shellcheck disable=SC2154
    ${handshake_script} || true
}

run_verify() {
    local verify_script=$VERIFY_SCRIPT
    # shellcheck disable=SC2154
    ${verify_script} || true
}

run_activate() {
    local activate_script=$ACTIVATE_SCRIPT
    # shellcheck disable=SC2154
    ${activate_script} || true
}

#
# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
#

read_state_value() {

    local file="$1"
    local key="$2"

    jq -r ".${key} // \"unknown\"" "$file" 2>/dev/null || echo "unknown"
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

main() {

    local handshake_status="not_applicable"
    local verify_status="not_applicable"
    local activate_status="not_applicable"
    local failover_status="not_applicable"

    case "$ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)

            log "$ROLE performing full supervisor cycle"

            run_handshake || true

            handshake_status=$(read_state_value "${STATE_DIR}/mesh-handshake.json" "handshake_status"
            )

            run_verify || true

            verify_status=$(
                read_state_value "${STATE_DIR}/mesh-verify.json" "verify_status"
            )

            run_activate || true

            activate_status=$(
                read_state_value "${STATE_DIR}/mesh-activate.json" "activate_status"
            )

            failover_status=$(get_failover \
                    "$handshake_status" \
                    "$verify_status" \
                    "$activate_status"
            )

            ;;

        SECONDARY-ACTIVE)

            log "SECONDARY-ACTIVE performing promoted cycle"

            run_handshake || true

            handshake_status=$(read_state_value "${STATE_DIR}/mesh-handshake.json" "handshake_status"
            )

            run_verify || true

            verify_status=$(read_state_value "${STATE_DIR}/mesh-verify.json" "verify_status"
            )

            run_activate || true

            activate_status=$(read_state_value "${STATE_DIR}/mesh-activate.json" "activate_status"
            )

            failover_status=$(get_failover \
                    "$handshake_status" \
                    "$verify_status" \
                    "$activate_status"
            )

            ;;

        SECONDARY-PASSIVE)

            log "SECONDARY-PASSIVE supervisor telemetry"

            run_handshake || true

            handshake_status=$(read_state_value "${STATE_DIR}/mesh-handshake.json" "handshake_status"
            )

            verify_status="not_applicable"
            activate_status="not_applicable"
            failover_status="not_applicable"

            ;;

        OFFSITE)

            log "OFFSITE limited supervisor cycle"

            run_handshake || true

            handshake_status=$(read_state_value "${STATE_DIR}/mesh-handshake.json" "handshake_status"
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

    log "handshake_status=${handshake_status}"
    log "verify_status=${verify_status}"
    log "activate_status=${activate_status}"
    log "failover_status=${failover_status}"

    json_init "$SUP_FILE"

    json_set "$SUP_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$SUP_FILE" "node_role" "$ROLE"

    json_set "$SUP_FILE" "handshake_status" "$handshake_status"
    json_set "$SUP_FILE" "verify_status" "$verify_status"
    json_set "$SUP_FILE" "activate_status" "$activate_status"
    json_set "$SUP_FILE" "failover_status" "$failover_status"

    #
    # Backward compatibility
    #

    json_set "$SUP_FILE" "handshake" "$handshake_status"
    json_set "$SUP_FILE" "verify" "$verify_status"
    json_set "$SUP_FILE" "activate" "$activate_status"

    json_finalize "$SUP_FILE"

    /opt/semperfix/scripts/json-perms.sh "$SUP_FILE"

    log "Supervisor state written to $SUP_FILE"
}

main "$@"