#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Mesh Activate
# Version: Phoenix v2.1
# Component: wsl-mesh-activate
# Role: Responder / Controller (role-aware)
# Refactor: 2026-11-05 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-05
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

LOGFILE="${LOG_DIR}/mesh-activate.log"
JSON_OUT="${STATE_DIR}/mesh-activate.json"
LOCKFILE="/run/lock/mesh-activate.lock"
mkdir -p "$(dirname "$LOCKFILE")"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

# ------------------------------------------------------------
# Locking
# ------------------------------------------------------------

exec 200>"$LOCKFILE"

if ! flock -n 200; then
    echo "[WARN] Another mesh activate is already running"
    exit 1
fi

#
# Cached Syncthing API response
#
declare -g SYNCTHING_STATUS=""

log() {
    phoenix_log_file INFO "$*"
}

error() {
    phoenix_log_file FAIL "$*"
}

#
# ------------------------------------------------------------
# Fetch Syncthing status once
# ------------------------------------------------------------
#
fetch_syncthing_status() {

    log "Fetching Syncthing status"

    SYNCTHING_STATUS="$(
        curl -s --max-time 3 -H "X-API-Key: $API_KEY" \
            "$API_URL/system/status" || true
    )"

    if [[ -z "$SYNCTHING_STATUS" ]]; then

        error "Unable to retrieve Syncthing status"

        return 1
    fi

    return 0
}

#
# ------------------------------------------------------------
# Cached API validation
# ------------------------------------------------------------
#
check_syncthing_api() {

    log "Checking Syncthing API reachability"

    [[ -z "$SYNCTHING_STATUS" ]] && {
        error "No Syncthing status cached"
        json_set "$JSON_OUT" "syncthing_api_ok" "false"
        return 1
    }

    if ! jq -e '.myID' >/dev/null <<< "$SYNCTHING_STATUS"; then

        error "Syncthing API invalid at $API_URL/system/status"

        json_set "$JSON_OUT" "syncthing_api_ok" "false"

        return 1
    fi

    json_set "$JSON_OUT" "syncthing_api_ok" "true"

    log "Syncthing API reachable"

    return 0
}

#
# ------------------------------------------------------------
# Cached QUIC validation
# ------------------------------------------------------------
#
check_quic_listener() {

    log "Checking QUIC listener via cached Syncthing status"

    [[ -z "$SYNCTHING_STATUS" ]] && {
        error "No Syncthing status cached"
        json_set "$JSON_OUT" "quic_ok" "false"
        return 1
    }
# TODO:
# Replace with generic QUIC discovery during Phoenix v2.2 consolidation.
    local quic_ok

    quic_ok=$(
        jq -r '
            .connectionServiceStatus["quic://0.0.0.0:22000"].error == null
                ' <<< "$SYNCTHING_STATUS" 2>/dev/null || echo false
    )

    if [[ "$quic_ok" == "true" ]]; then

        json_set "$JSON_OUT" "quic_ok" "true"

        log "QUIC listener reported healthy"

        return 0
    fi

    json_set "$JSON_OUT" "quic_ok" "false"

    error "QUIC listener not healthy"

    return 1
}

#
# ------------------------------------------------------------
# Readiness
# ------------------------------------------------------------
#
check_readiness() {

    log "Checking Syncthing + QUIC readiness (Phoenix v2.1.1)"

    fetch_syncthing_status || return 1

    check_syncthing_api || return 1

    check_quic_listener || return 1

    json_set "$JSON_OUT" "syncthing_ready" "true"

    log "Phoenix readiness check passed"

    return 0
}

activate_mesh_controller() {

    log "${NODE_ROLE} performing controller-side mesh activation"

    json_set "$JSON_OUT" "activation_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    if ! check_readiness; then

        error "Mesh activation aborted: readiness check failed"

        json_set "$JSON_OUT" "activate_status" "fail"

        return 1
    fi

    log "Sending QUIC activation probe to ${PEER_IP}:${PHOENIX_QUIC_PORT}"

    if ! echo "phoenix-activate" |
        socat -u - \
        UDP-SENDTO:"${PEER_IP}:${PHOENIX_QUIC_PORT}" \
        >/dev/null 2>&1
    then

        error "QUIC activation probe failed"

        json_set "$JSON_OUT" "quic_activation_sent" "false"
        json_set "$JSON_OUT" "activate_status" "fail"

        return 1
    fi

    json_set "$JSON_OUT" "quic_activation_sent" "true"
    json_set "$JSON_OUT" "activate_status" "pass"

    log "Mesh activation completed successfully"

    return 0
}

activate_mesh_secondary_passive() {

    log "SECONDARY-PASSIVE acknowledging mesh activation (responder mode)"

#Todo:
# Replace hardcoded activte_status with dynamic status based on QUIC responder.
    json_set "$JSON_OUT" "activation_role" "SECONDARY-PASSIVE"
    json_set "$JSON_OUT" "activate_status" "pass"
    json_set "$JSON_OUT" "quic_activation_sent" "not_applicable"

    return 0
}

activate_mesh_offsite() {

    log "OFFSITE node: mesh activation not applicable"

    json_set "$JSON_OUT" "activation_role" "OFFSITE"
    json_set "$JSON_OUT" "activate_status" "not_applicable"
    json_set "$JSON_OUT" "quic_activation_sent" "not_applicable"

    return 0
}

main() {

    log "Starting Phoenix Mesh Activation for role: $NODE_ROLE"

    json_init "$JSON_OUT"

    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"
    json_set "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)
            activate_mesh_controller
            ;;

        SECONDARY-ACTIVE)
            activate_mesh_controller
            ;;

        SECONDARY-PASSIVE)
            activate_mesh_secondary_passive
            ;;

        OFFSITE)
            activate_mesh_offsite
            ;;

        *)
            error "Unknown NODE_ROLE: $NODE_ROLE"
            json_set "$JSON_OUT" "activate_status" "fail"
            ;;
    esac

    json_finalize "$JSON_OUT"

    /opt/semperfix/scripts/json-perms.sh "$JSON_OUT"
}

main "$@"