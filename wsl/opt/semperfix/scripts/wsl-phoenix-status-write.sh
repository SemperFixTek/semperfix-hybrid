#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Status Writer
# Version: Phoenix v2.1
# Component: wsl-phoenix-status-write
# Role: All roles (controller/responder/offsite)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

STATUS_FILE="${STATE_DIR}/phoenix-status.json"
HB_JSON="${STATE_DIR}/phoenix-heartbeat.json"
SUP_JSON="${STATE_DIR}/phoenix-supervisor.json"
FAIL_JSON="${STATE_DIR}/phoenix-failover.json"
MESH_JSON="${STATE_DIR}/mesh-status.json"

PHOENIX_LOGFILE="${LOG_DIR}/phoenix-status.log"
log() { phoenix_log_file "INFO" "$*"; }

safe_field() {
    local file="$1"
    local field="$2"
    jq -r "$field // \"not_applicable\"" "$file" 2>/dev/null || echo "not_applicable"
}

detect_role() {
    local base_role="$NODE_ROLE"


    # Promotion detection → SECONDARY-ACTIVE
    if [[ -f "$FAIL_JSON" ]]; then
        local promoted
        promoted=$(jq -r '.promoted // "false"' "$FAIL_JSON" 2>/dev/null)
        if [[ "$promoted" == "true" ]]; then
            base_role="SECONDARY-ACTIVE"
        fi
    fi

    # MASTERZERO degraded detection
    if [[ "$base_role" == "MASTERZERO-ACTIVE" ]]; then
        local handshake verify activate
        handshake=$(safe_field "$MESH_JSON" '.handshake_status')
        verify=$(safe_field "$MESH_JSON" '.verify_status')
        activate=$(safe_field "$MESH_JSON" '.activate_status')

        if [[ "$handshake" != "pass" || "$verify" != "pass" || "$activate" != "pass" ]]; then
            base_role="MASTERZERO-DEGRADED"
        fi
    fi

    echo "$base_role"
}

ROLE="$(detect_role)"
log "Detected Phoenix role: $ROLE"

write_status() {
    local timestamp
    timestamp=$(date -Iseconds)

    json_init "$STATUS_FILE"

    # meta
    json_set_raw "$STATUS_FILE" "meta" "$(jq -n \
        --arg ts "$timestamp" \
        '{version:"2.1", generated_by:"phoenix-status-write", timestamp:$ts}')"

    # node
    json_set_raw "$STATUS_FILE" "node" "$(jq -n \
        --arg role "$ROLE" \
        --arg api "$API_URL" \
        --arg peer "${PEER_IP}:${PEER_PORT}" \
        '{role:$role, api_url:$api, peer_target:$peer}')"

    # health block (role-aware)
    case "$ROLE" in

        SECONDARY-PASSIVE)
            json_set_raw "$STATUS_FILE" "health" "$(jq -n \
                --arg hb "$(safe_field "$HB_JSON" '.heartbeat_ok')" \
                --arg api_ok "$(safe_field "$HB_JSON" '.api_ok')" \
                --arg quic_ok "$(safe_field "$HB_JSON" '.quic_ok')" \
                '{heartbeat_ok:$hb, api_ok:$api_ok, quic_ok:$quic_ok}')"
            ;;

        OFFSITE)
            json_set_raw "$STATUS_FILE" "health" "$(jq -n \
                --arg api_ok "$(safe_field "$HB_JSON" '.api_ok')" \
                '{api_ok:$api_ok}')"
            ;;

        *)
            json_set_raw "$STATUS_FILE" "health" "$(jq -n \
                --arg api_ok "$(safe_field "$HB_JSON" '.api_ok')" \
                --arg peer_connected "$(safe_field "$HB_JSON" '.peer_connected')" \
                --arg syncthing_ready "$(safe_field "$HB_JSON" '.syncthing_ready')" \
                --arg quic_ok "$(safe_field "$HB_JSON" '.quic_ok')" \
                --arg mesh_ok "$(safe_field "$MESH_JSON" '.mesh_ok')" \
                '{api_ok:$api_ok, peer_connected:$peer_connected, syncthing_ready:$syncthing_ready, quic_ok:$quic_ok, mesh_ok:$mesh_ok}')"
            ;;
    esac

    # supervisor block only for ACTIVE roles
    case "$ROLE" in
        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|SECONDARY-ACTIVE)
            json_set_raw "$STATUS_FILE" "supervisor" "$(jq -n \
                --arg handshake "$(safe_field "$SUP_JSON" '.handshake')" \
                --arg verify "$(safe_field "$SUP_JSON" '.verify')" \
                --arg activate "$(safe_field "$SUP_JSON" '.activate')" \
                '{handshake:$handshake, verify:$verify, activate:$activate}')"
            ;;
    esac

    json_finalize "$STATUS_FILE"
    /opt/semperfix/scripts/json-perms.sh "$STATUS_FILE"

    log "Phoenix status written to $STATUS_FILE"
}

write_status
