#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phoenix v2 — Core Module
# Provides:
# - Config loader
# - Shared environment variables
# - Unified error/logging helpers (optional expansion later)
# ============================================================

CONFIG_FILE="/opt/semperfix/config/phoenix.conf"
METADATA_FILE="/opt/semperfix/config/phoenix.json"

phoenix_load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "[ERROR] Phoenix config file not found: $CONFIG_FILE"
        exit 1
    fi

    if [[ ! -f "$METADATA_FILE" ]]; then
        echo "[ERROR] Phoenix metadata file not found: $METADATA_FILE"
        exit 1
    fi

    # Load shell config
    source "$CONFIG_FILE"

    # Load JSON metadata
    API_URL=$(jq -r '.ApiUrl' "$METADATA_FILE")
    API_KEY=$(jq -r '.ApiKey' "$METADATA_FILE")
    NODE_ROLE=$(jq -r '.NodeRole' "$METADATA_FILE")
    MESH_ENDPOINT=$(jq -r '.MeshEndpoint' "$METADATA_FILE")

    if [[ -z "$API_URL" || -z "$API_KEY" ]]; then
        echo "[ERROR] Phoenix metadata missing required fields (ApiUrl/ApiKey)"
        exit 1
    fi
}


# ---------- Optional Shared Logging (future expansion) ----------
phoenix_log() {
    local level="$1"
    local msg="$2"
    echo "[${level}] ${msg}"
}

# ---------- Optional Shared Error Handler ----------
phoenix_error() {
    local code="$1"
    local msg="$2"
    echo "[ERROR] (${code}) ${msg}"
    exit 1
}
