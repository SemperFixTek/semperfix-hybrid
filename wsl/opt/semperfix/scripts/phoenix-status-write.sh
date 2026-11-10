#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Status Writer
# Version: Phoenix v2.1
# Component: wsl-phoenix-status-write
# Role: All roles (controller/responder/offsite)
# Refactor: 2026-11-09 — v2.1 → v2.1.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
#
# Philosophy:
#   Read state.
#   Aggregate state.
#   Write state.
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

# ---------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------

STATUS_FILE="${STATE_DIR}/phoenix-status.json"

HB_JSON="${STATE_DIR}/phoenix-heartbeat.json"
SUP_JSON="${STATE_DIR}/phoenix-supervisor.json"
FAIL_JSON="${STATE_DIR}/phoenix-failover.json"
MESH_JSON="${STATE_DIR}/mesh-status.json"
QUIC_JSON="${STATE_DIR}/quic-client-status.json"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="${LOG_DIR}/phoenix-status.log"

log() {
    phoenix_log_file "INFO" "$*"
}

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------

safe_field() {

    local file="$1"
    local field="$2"

    [[ -f "$file" ]] || { 
        echo "not_available"
        return
    }

    jq -r "$field // \"not_available\"" \
        "$file" 2>/dev/null || echo "not_available"
}

safe_exists() {

    local file="$1"

    if [[ -f "$file" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

compute_mesh_ok() {

    local handshake
    local verify
    local activate

    handshake=$(safe_field "$SUP_JSON" '.handshake_status'
    )

    verify=$(safe_field "$SUP_JSON" '.verify_status'
    )

    activate=$(safe_field "$SUP_JSON" '.activate_status'
    )

    if [[ "$handshake" == "pass" &&
          "$verify"    == "pass" &&
          "$activate"  == "pass"
    ]]
    then
        echo "true"
    else
        echo "false"
    fi
}

validate_output() {

    jq . "$STATUS_FILE" >/dev/null 2>&1 || {
        log "Generated invalid JSON"
        return 1
    }
}

# ---------------------------------------------------------------------
# Authoritative Role
# ---------------------------------------------------------------------

ROLE="$NODE_ROLE"

log "Writing status for role=${ROLE}"

# ---------------------------------------------------------------------
# Status Writer
# ---------------------------------------------------------------------

write_status() {

    local timestamp

    timestamp="$(date -Iseconds)"

    json_init "$STATUS_FILE"

    # -------------------------------------------------------------
    # Meta
    # -------------------------------------------------------------

    json_set_raw "$STATUS_FILE" "meta" "$(
        jq -n \
            --arg version "2.1.1" \
            --arg writer "phoenix-status" \
            --arg timestamp "$timestamp" \
            '{
                version:$version,
                generated_by:$writer,
                timestamp:$timestamp
            }'
    )"

    # -------------------------------------------------------------
    # Node
    # -------------------------------------------------------------

    json_set_raw "$STATUS_FILE" "node" "$(
        jq -n \
            --arg role "$ROLE" \
            --arg api "${API_URL}" \
            --arg peer "${PEER_IP}:${PEER_PORT}" \
            '{
                role:$role,
                api_url:$api,
                peer_target:$peer
            }'
    )"

    # -------------------------------------------------------------
    # Heartbeat
    # -------------------------------------------------------------

    json_set_raw "$STATUS_FILE" "heartbeat" "$(
        jq -n \
            --arg file_present "$(safe_exists "$HB_JSON")" \
            --arg heartbeat_ok "$(safe_field "$HB_JSON" '.heartbeat_ok')" \
            --arg api_ok "$(safe_field "$HB_JSON" '.api_ok')" \
            --arg peer_connected "$(safe_field "$HB_JSON" '.peer_connected')" \
            --arg syncthing_ready "$(safe_field "$HB_JSON" '.syncthing_ready')" \
            --arg quic_ok "$(safe_field "$HB_JSON" '.quic_ok')" \
            '{
                file_present:$file_present,
                heartbeat_ok:$heartbeat_ok,
                api_ok:$api_ok,
                peer_connected:$peer_connected,
                syncthing_ready:$syncthing_ready,
                quic_ok:$quic_ok
            }'
    )"

    # -------------------------------------------------------------
    # Supervisor
    # -------------------------------------------------------------

    json_set_raw "$STATUS_FILE" "supervisor" "$(
        jq -n \
            --arg file_present "$(safe_exists "$SUP_JSON")" \
            --arg handshake "$(safe_field "$SUP_JSON" '.handshake_status')" \
            --arg verify "$(safe_field "$SUP_JSON" '.verify_status')" \
            --arg activate "$(safe_field "$SUP_JSON" '.activate_status')" \
            --arg failover "$(safe_field "$SUP_JSON" '.failover_status')" \
            '{
                file_present:$file_present,
                handshake_status:$handshake,
                verify_status:$verify,
                activate_status:$activate,
                failover_status:$failover
            }'
    )"

    # -------------------------------------------------------------
    # QUIC
    # -------------------------------------------------------------

    json_set_raw "$STATUS_FILE" "quic" "$(
        jq -n \
            --arg file_present "$(safe_exists "$QUIC_JSON")" \
            --arg reachable "$(safe_field "$QUIC_JSON" '.quic_reachable')" \
            --arg latency "$(safe_field "$QUIC_JSON" '.latency_ms')" \
            '{
                file_present:$file_present,
                reachable:$reachable,
                latency_ms:$latency
            }'
    )"

    # -------------------------------------------------------------
    # Mesh
    # -------------------------------------------------------------

    json_set_raw "$STATUS_FILE" "mesh" "$(
        jq -n \
            --arg file_present "$(safe_exists "$MESH_JSON")" \
            --arg mesh_ok "$(compute_mesh_ok)" \
            '{
                file_present:$file_present,
                mesh_ok:$mesh_ok
            }'
    )"

    # -------------------------------------------------------------
    # Failover
    # -------------------------------------------------------------

    json_set_raw "$STATUS_FILE" "failover" "$(
        jq -n \
            --arg file_present "$(safe_exists "$FAIL_JSON")" \
            --arg state "$(safe_field "$SUP_JSON" '.failover_status')" \
            '{
                file_present:$file_present,
                state:$state
            }'
    )"

    json_finalize "$STATUS_FILE"

if ! validate_output; then
    log "Generated invalid phoenix-status.json"
    exit 1
fi

/opt/semperfix/scripts/json-perms.sh "$STATUS_FILE"

    log "Phoenix status written to ${STATUS_FILE}"
}

write_status