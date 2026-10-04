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


CONFIG_DIR="/opt/semperfix/config"
CONFIG_JSON="${CONFIG_DIR}/phoenix.json"
CONFIG_CONF="${CONFIG_DIR}/phoenix.conf"
PHOENIX_QUIC_PORT=$(jq -r '.phoenix.quic_port // 22001' "$CONFIG_JSON")


phoenix_error() {
    local message="$1"
    local code="${2:-1}"
    printf "[ERROR] %s\n" "$message" >&2
    exit "$code"
}

phoenix_log() {
    local level="$1"
    local message="$2"
    local color="${3:-}"
    if [[ -n "$color" ]]; then
        printf "%b[%s] %s%b\n" "$color" "$level" "$message" "\033[0m"
    else
        printf "[%s] %s\n" "$level" "$message"
    fi
}

phoenix_debug() {
    local message="$1"
    if [[ "${PHOENIX_DEBUG:-0}" == "1" ]]; then
        phoenix_log "DEBUG" "$message"
    fi
}

phoenix_load_config() {

    # ---------- Load phoenix.conf ----------
    if [[ -f "$CONFIG_CONF" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_CONF"
    else
        phoenix_error "Missing phoenix.conf at $CONFIG_CONF"
    fi

    # ---------- Load phoenix.json ----------
    if [[ -f "$CONFIG_JSON" ]]; then
        NODE_ROLE=$(jq -r '.node.role // empty' "$CONFIG_JSON")
        HOSTNAME=$(jq -r '.node.hostname // empty' "$CONFIG_JSON")

        STATE_DIR=$(jq -r '.node.state_dir // empty' "$CONFIG_JSON")
        LOG_DIR=$(jq -r '.node.log_dir // empty' "$CONFIG_JSON")

        API_URL=$(jq -r '.syncthing.api_url // empty' "$CONFIG_JSON")
        API_KEY=$(jq -r '.syncthing.api_key // empty' "$CONFIG_JSON")

        PEER_IP=$(jq -r '.syncthing.peer_ip // empty' "$CONFIG_JSON")
        PEER_PORT=$(jq -r '.syncthing.peer_port // empty' "$CONFIG_JSON")
    else
        phoenix_error "Missing phoenix.json at $CONFIG_JSON"
    fi

    # ---------- Validate required fields ----------
    [[ -z "$NODE_ROLE" ]] && phoenix_error "Missing node.role in phoenix.json"
    [[ -z "$HOSTNAME" ]] && phoenix_error "Missing node.hostname in phoenix.json"

    [[ -z "$STATE_DIR" ]] && phoenix_error "Missing node.state_dir in phoenix.json"
    [[ -z "$LOG_DIR" ]] && phoenix_error "Missing node.log_dir in phoenix.json"

    [[ -z "$API_URL" ]] && phoenix_error "Missing syncthing.api_url in phoenix.json"
    [[ -z "$API_KEY" ]] && phoenix_error "Missing syncthing.api_key in phoenix.json"

    [[ -z "$PEER_IP" ]] && phoenix_error "Missing syncthing.peer_ip in phoenix.json"
    [[ -z "$PEER_PORT" ]] && phoenix_error "Missing syncthing.peer_port in phoenix.json"

    # ---------- Ensure directories exist ----------
    mkdir -p "$STATE_DIR" "$LOG_DIR"

    # ---------- Export unified variables ----------
    export NODE_ROLE HOSTNAME
    export STATE_DIR LOG_DIR
    export API_URL API_KEY
    export PEER_IP PEER_PORT
    export PHOENIX_DEBUG
    export PHOENIX_QUIC_PORT
}

phoenix_init() {
    phoenix_load_config
    phoenix_log "INFO" "Phoenix core initialized for node role: ${NODE_ROLE:-unknown}"
}
