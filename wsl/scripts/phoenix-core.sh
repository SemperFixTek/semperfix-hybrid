#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="/opt/semperfix/config"
CONFIG_JSON="${CONFIG_DIR}/phoenix.json"
CONFIG_CONF="${CONFIG_DIR}/phoenix.conf"

# -----------------------------
# Load phoenix.conf (env vars)
# -----------------------------
if [[ -f "$CONFIG_CONF" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_CONF"
else
    echo "[ERROR] Missing phoenix.conf at $CONFIG_CONF"
    exit 1
fi

# -----------------------------
# Load phoenix.json (structured)
# -----------------------------
if [[ -f "$CONFIG_JSON" ]]; then
    NODE_ROLE=$(jq -r '.node.role' "$CONFIG_JSON")
    HOSTNAME=$(jq -r '.node.hostname' "$CONFIG_JSON")

    STATE_DIR=$(jq -r '.node.state_dir' "$CONFIG_JSON")
    LOG_DIR=$(jq -r '.node.log_dir' "$CONFIG_JSON")

    API_URL=$(jq -r '.syncthing.api_url' "$CONFIG_JSON")
    API_KEY=$(jq -r '.syncthing.api_key' "$CONFIG_JSON")

    PEER_IP=$(jq -r '.syncthing.peer_ip' "$CONFIG_JSON")
    PEER_PORT=$(jq -r '.syncthing.peer_port' "$CONFIG_JSON")
else
    echo "[ERROR] Missing phoenix.json at $CONFIG_JSON"
    exit 1
fi

# -----------------------------
# Ensure directories exist
# -----------------------------
mkdir -p "$STATE_DIR" "$LOG_DIR"

# -----------------------------
# Export unified variables
# -----------------------------
export NODE_ROLE HOSTNAME
export STATE_DIR LOG_DIR
export API_URL API_KEY
export PEER_IP PEER_PORT
