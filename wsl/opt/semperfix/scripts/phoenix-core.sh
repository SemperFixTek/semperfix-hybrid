#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Core Loader
# Version: Phoenix v2.1
# Component: phoenix-core
# Role: All roles (controller/responder/offsite)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade + optional features
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

CONFIG_DIR="/opt/semperfix/config"
CONFIG_JSON="${CONFIG_DIR}/phoenix.json"
#CONFIG_CONF="${CONFIG_DIR}/phoenix.conf"

mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# ---------- Logging Helpers ----------
phoenix_error() {
    local message="$1"
    local code="${2:-1}"
    printf "\033[1;31m[ERROR]\033[0m %s\n" "$message" >&2
    exit "$code"
}

phoenix_log() {
    local level="$1"
    local message="$2"
    printf "[%s] %s\n" "$level" "$message"
}

phoenix_log_file() {
    local level="$1"
    shift
    local message="$*"

    phoenix_log "$level" "$message"

    if [[ -n "${PHOENIX_LOGFILE:-}" ]]; then
        printf "[%s] %s\n" "$level" "$message" >> "$PHOENIX_LOGFILE" 2>/dev/null || true
    fi
}

# TODO: change location of PHOENIX_DEBUG to JSON file (done 2026-11-09), and retire CONF file (deactivated)

phoenix_debug() {
    local message="$1"
    if [[ "${PHOENIX_DEBUG:-0}" == "1" ]]; then
        phoenix_log "DEBUG" "$message"
    fi
}

# ---------- Optional: Validate phoenix.conf variables ----------
#phoenix_validate_conf() {
#    local required_vars=(
#       PHOENIX_DEBUG
#    )

#    for var in "${required_vars[@]}"; do
#        if [[ -z "${!var:-}" ]]; then
#            phoenix_error "Missing required variable in phoenix.conf: $var"
#       fi
#    done
#}

# ---------- Load Phoenix Configuration ----------
phoenix_load_config() {

    # Load phoenix.conf
    #if [[ -f "$CONFIG_CONF" ]]; then
        # shellcheck disable=SC1090
    #    source "$CONFIG_CONF"
#        phoenix_validate_conf
    #else
    #    phoenix_error "Missing phoenix.conf at $CONFIG_CONF"
    #fi

    # Load phoenix.json
    if [[ -f "$CONFIG_JSON" ]]; then

        # Optional: config checksum for drift detection
        CONFIG_SHA=$(sha256sum "$CONFIG_JSON" | awk '{print $1}')
        phoenix_log "INFO" "Loaded phoenix.json (sha256: $CONFIG_SHA)"

        NODE_ROLE=$(jq -r '.node.role // empty' "$CONFIG_JSON")

        # ---------- Optional: Normalize legacy roles here ----------
        case "$NODE_ROLE" in
            MASTERZERO) NODE_ROLE="MASTERZERO-ACTIVE" ;;
            SECONDARY)  NODE_ROLE="SECONDARY-PASSIVE" ;;
        esac

        # ---------- Validate v2.1 role model ----------
        case "$NODE_ROLE" in
            MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|\
            SECONDARY-PASSIVE|SECONDARY-ACTIVE|\
            OFFSITE)
                ;;
            *)
                phoenix_error "Invalid node.role in phoenix.json: $NODE_ROLE"
                ;;
        esac

        HOSTNAME=$(jq -r '.node.hostname // empty' "$CONFIG_JSON")
        STATE_DIR=$(jq -r '.node.state_dir // empty' "$CONFIG_JSON")
        LOG_DIR=$(jq -r '.node.log_dir // empty' "$CONFIG_JSON")

        API_URL=$(jq -r '.syncthing.api_url // empty' "$CONFIG_JSON")
        API_KEY=$(jq -r '.syncthing.api_key // empty' "$CONFIG_JSON")

        NODE_IP=$(jq -r '.node.node_ip // empty' "$CONFIG_JSON")
        GATEWAY_IP=$(jq -r '.node.gateway_ip // empty' "$CONFIG_JSON")
        DNS1=$(jq -r '.node.dns1 // empty' "$CONFIG_JSON")
        DNS2=$(jq -r '.node.dns2 // empty' "$CONFIG_JSON")
        NETWORK_MODE=$(jq -r '.node.network_mode // empty' "$CONFIG_JSON")

        PEER_IP=$(jq -r '.syncthing.peer_ip // empty' "$CONFIG_JSON")
        PEER_PORT=$(jq -r '.syncthing.peer_port // empty' "$CONFIG_JSON")
        PEER_DEVICE_ID=$(jq -r '.syncthing.peer_device_id // empty' "$CONFIG_JSON")

        PHOENIX_QUIC_PORT=$(jq -r '.phoenix.quic_port // empty' "$CONFIG_JSON")
        PHOENIX_DEBUG=$(jq -r '.phoenix.debug // empty' "$CONFIG_JSON")

        HANDSHAKE_SCRIPT=$(jq -r '.mesh.handshake_script // empty' "$CONFIG_JSON")
        VERIFY_SCRIPT=$(jq -r '.mesh.verify_script // empty' "$CONFIG_JSON")
        ACTIVATE_SCRIPT=$(jq -r '.mesh.activate_script // empty' "$CONFIG_JSON")
        ROLE_SWITCH_SCRIPT=$(jq -r '.phoenix.role_switch_script // empty' "$CONFIG_JSON")

    else
        phoenix_error "Missing phoenix.json at $CONFIG_JSON"
    fi

    # ---------- Validate required fields ----------
    [[ -z "$NODE_ROLE" ]] && phoenix_error "Missing node.role in phoenix.json"
    
    [[ -z "$HOSTNAME" ]] && phoenix_error "Missing node.hostname in phoenix.json"
    [[ -z "$NODE_IP" ]] && phoenix_error "Missing node.node_ip in phoenix.json"
    [[ -z "$GATEWAY_IP" ]] && phoenix_error "Missing node.gateway_ip in phoenix.json"
    [[ -z "$DNS1" ]] && phoenix_error "Missing node.dns1 in phoenix.json"
    [[ -z "$DNS2" ]] && phoenix_error "Missing node.dns2 in phoenix.json"
    [[ -z "$NETWORK_MODE" ]] && phoenix_error "Missing node.network_mode in phoenix.json"

    [[ -z "$STATE_DIR" ]] && phoenix_error "Missing node.state_dir in phoenix.json"
    [[ -z "$LOG_DIR" ]] && phoenix_error "Missing node.log_dir in phoenix.json"

    [[ -z "$API_URL" ]] && phoenix_error "Missing syncthing.api_url in phoenix.json"
    [[ -z "$API_KEY" ]] && phoenix_error "Missing syncthing.api_key in phoenix.json"

    [[ -z "$PEER_IP" ]] && phoenix_error "Missing syncthing.peer_ip in phoenix.json"
    [[ -z "$PEER_PORT" ]] && phoenix_error "Missing syncthing.peer_port in phoenix.json"
    [[ -z "$PEER_DEVICE_ID" ]] && phoenix_error "Missing syncthing.peer_device_id in phoenix.json"

    [[ -z "$PHOENIX_QUIC_PORT" ]] && phoenix_error "Missing phoenix.quic_port in phoenix.json"
    [[ -z "$PHOENIX_DEBUG" ]] && phoenix_error "Missing phoenix.debug in phoenix.json"

    [[ -z "$HANDSHAKE_SCRIPT" ]] && phoenix_error "Missing mesh.handshake_script in phoenix.json"
    [[ -z "$VERIFY_SCRIPT" ]] && phoenix_error "Missing mesh.verify_script in phoenix.json"
    [[ -z "$ACTIVATE_SCRIPT" ]] && phoenix_error "Missing mesh.activate_script in phoenix.json"
    [[ -z "$ROLE_SWITCH_SCRIPT" ]] && phoenix_error "Missing phoenix.role_switch_script in phoenix.json"

    # ---------- Ensure directories exist + writable ----------
    mkdir -p "$STATE_DIR" "$LOG_DIR"

    [[ -w "$STATE_DIR" ]] || phoenix_error "State directory not writable: $STATE_DIR"
    [[ -w "$LOG_DIR" ]] || phoenix_error "Log directory not writable: $LOG_DIR"

    # ---------- Export unified variables ----------
    export NODE_ROLE HOSTNAME NETWORK_MODE
    export NODE_IP GATEWAY_IP DNS1 DNS2 
    export STATE_DIR LOG_DIR
    export API_URL API_KEY
    export PEER_IP PEER_PORT PEER_DEVICE_ID
    export PHOENIX_DEBUG PHOENIX_QUIC_PORT PHOENIX_LOGFILE
    export HANDSHAKE_SCRIPT VERIFY_SCRIPT ACTIVATE_SCRIPT ROLE_SWITCH_SCRIPT

    phoenix_log "INFO" "Phoenix core loaded for role: $NODE_ROLE"
}

phoenix_init() {
    phoenix_load_config
    phoenix_log "INFO" "Phoenix core initialized"
}
