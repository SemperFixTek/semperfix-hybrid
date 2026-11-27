#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Status Writer
# Version: Phoenix v2.2
# Component: wsl-phoenix-status-write
# Role: All roles (controller/responder/offsite)
# Refactor: 2026-11-26 — v2.1 → v2.2 rearchitecture
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

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh
# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

STATUS_FILE="${STATE_DIR}/phoenix-status.json"

HB_JSON="${STATE_DIR}/phoenix-heartbeat.json"
HANDSHAKE_JSON="${STATE_DIR}/mesh-handshake.json"
VERIFY_JSON="${STATE_DIR}/mesh-verify.json"
ACTIVATE_JSON="${STATE_DIR}/mesh-activate.json"
QUIC_JSON="${STATE_DIR}/quic-client-status.json"
SUP_JSON="${STATE_DIR}/phoenix-supervisor.json"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="${LOG_DIR}/phoenix-status.log"

log() {
    phoenix_log_file "INFO" "$*"
}

safe_field() {

    local file="$1"
    local field="$2"

    [[ -f "$file" ]] || {
        echo "not_available"
        return
    }

    jq -r \
        "$field // \"not_available\"" \
        "$file" \
        2>/dev/null ||
        echo "not_available"
}

get_cycle() {

    local file="$1"

    [[ -f "$file" ]] || {
        echo "missing"
        return
    }

    jq -r \
        '.supervisor_cycle // "missing"' \
        "$file" \
        2>/dev/null ||
        echo "missing"
}

validate_schema() {

    local file="$1"

    jq -e '
        .worker and
        .supervisor_cycle and
        .timestamp
    ' "$file" >/dev/null 2>&1
}

validate_cycles() {

    local expected

    expected=$(
        get_cycle "$SUP_JSON"
    )

    local files=(
        "$HB_JSON"
        "$HANDSHAKE_JSON"
        "$VERIFY_JSON"
        "$ACTIVATE_JSON"
        "$QUIC_JSON"
    )

    local file
    local actual

    for file in "${files[@]}"
    do

        actual=$(get_cycle "$file")

        if [[ "$actual" != "$expected" ]]
        then

            log "Cycle mismatch"

            log "Expected=${expected}"

            log "Actual=${actual}"

            log "File=${file}"

            return 1

        fi

    done

    return 0
}

validate_freshness() {

    local freshness="true"

    local files=(
        "$HB_JSON"
        "$HANDSHAKE_JSON"
        "$VERIFY_JSON"
        "$ACTIVATE_JSON"
        "$QUIC_JSON"
        "$SUP_JSON"
    )

    local file

    for file in "${files[@]}"
    do

        if phoenix_is_stale "$file" 300
        then
            freshness="false"
        fi

    done

    echo "$freshness"
}

write_status() {

    local freshness_valid

    freshness_valid=$(
        validate_freshness
    )

    validate_schema "$HB_JSON"
    validate_schema "$HANDSHAKE_JSON"
    validate_schema "$VERIFY_JSON"
    validate_schema "$ACTIVATE_JSON"
    validate_schema "$QUIC_JSON"
    validate_schema "$SUP_JSON"

    validate_cycles

    local supervisor_cycle

    supervisor_cycle=$(
        get_cycle "$SUP_JSON"
    )

    json_init "$STATUS_FILE"

    phoenix_write_metadata "$STATUS_FILE" "status"

    json_set_raw "$STATUS_FILE" "meta" "$(
        jq -n \
        --arg version "2.2" \
        --arg cycle "$supervisor_cycle" \
        --arg freshness "$freshness_valid" \
        '{
            version:$version,
            supervisor_cycle:$cycle,
            freshness_valid:$freshness
        }'
    )"

    json_set_raw "$STATUS_FILE" "heartbeat" "$(
        jq -n \
        --arg api_ok "$(safe_field "$HB_JSON" '.api_ok')" \
        --arg syncthing_ready "$(safe_field "$HB_JSON" '.syncthing_ready')" \
        '{
            api_ok:$api_ok,
            syncthing_ready:$syncthing_ready
        }'
    )"

    json_set_raw "$STATUS_FILE" "handshake" "$(
        jq -n \
        --arg status "$(safe_field "$HANDSHAKE_JSON" '.handshake_status')" \
        '{
            status:$status
        }'
    )"

    json_set_raw "$STATUS_FILE" "verify" "$(
        jq -n \
        --arg status "$(safe_field "$VERIFY_JSON" '.verify_status')" \
        '{
            status:$status
        }'
    )"

    json_set_raw "$STATUS_FILE" "activate" "$(
        jq -n \
        --arg status "$(safe_field "$ACTIVATE_JSON" '.activate_status')" \
        '{
            status:$status
        }'
    )"

    json_set_raw "$STATUS_FILE" "quic" "$(
        jq -n \
        --arg reachable "$(safe_field "$QUIC_JSON" '.quic_reachable')" \
        --arg latency "$(safe_field "$QUIC_JSON" '.latency_ms')" \
        '{
            reachable:$reachable,
            latency_ms:$latency
        }'
    )"

    json_set_raw "$STATUS_FILE" "supervisor" "$(
        jq -n \
        --arg handshake "$(safe_field "$SUP_JSON" '.handshake_status')" \
        --arg verify "$(safe_field "$SUP_JSON" '.verify_status')" \
        --arg activate "$(safe_field "$SUP_JSON" '.activate_status')" \
        --arg failover "$(safe_field "$SUP_JSON" '.failover_status')" \
        '{
            handshake_status:$handshake,
            verify_status:$verify,
            activate_status:$activate,
            failover_status:$failover
        }'
    )"

    json_finalize "$STATUS_FILE"

    /opt/semperfix/scripts/json-perms.sh "$STATUS_FILE"

    log "Phoenix status written"
}

write_status