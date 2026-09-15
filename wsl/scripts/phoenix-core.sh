#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phoenix Core (v2)
# Shared configuration + environment loader for all WSL modules
# ============================================================

# ---------- Base Paths ----------
PHOENIX_ROOT="/opt/semperfix"
PHOENIX_CONFIG="$PHOENIX_ROOT/config/phoenix.conf"

# ---------- Default Values ----------
NODE_ROLE="UNKNOWN"
API_URL=""
API_KEY=""
PEER_IP=""
PEER_PORT=""

# ---------- Logging Colors ----------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# ---------- Safe Logging Helper ----------
phoenix_log() {
    local level="$1"
    local msg="$2"
    local color="${3:-$NC}"

    echo -e "${color}[${level}]${NC} ${msg}"
}

# ---------- Config Loader ----------
phoenix_load_config() {
    if [[ ! -f "$PHOENIX_CONFIG" ]]; then
        phoenix_log "WARN" "Phoenix config missing at $PHOENIX_CONFIG" "$YELLOW"
        return 0
    fi

    # shellcheck disable=SC1090
    source "$PHOENIX_CONFIG"

    # Validate required fields
    [[ -z "${NODE_ROLE:-}" ]] && phoenix_log "WARN" "NODE_ROLE missing in config" "$YELLOW"
    [[ -z "${API_URL:-}" ]] && phoenix_log "WARN" "API_URL missing in config" "$YELLOW"
    [[ -z "${API_KEY:-}" ]] && phoenix_log "WARN" "API_KEY missing in config" "$YELLOW"
    [[ -z "${PEER_IP:-}" ]] && phoenix_log "WARN" "PEER_IP missing in config" "$YELLOW"
    [[ -z "${PEER_PORT:-}" ]] && phoenix_log "WARN" "PEER_PORT missing in config" "$YELLOW"

    phoenix_log "INFO" "Phoenix config loaded (v2)" "$BLUE"
}

# ---------- JSON Writer Import ----------
# All modules rely on phoenix-json.sh for safe JSON output
if [[ -f "$PHOENIX_ROOT/scripts/phoenix-json.sh" ]]; then
    # shellcheck disable=SC1090
    source "$PHOENIX_ROOT/scripts/phoenix-json.sh"
else
    phoenix_log "WARN" "phoenix-json.sh missing — JSON output may fail" "$YELLOW"
fi

# ---------- Utility: Safe Curl Wrapper ----------
phoenix_api_get() {
    local endpoint="$1"
    curl -s -H "X-API-Key: $API_KEY" "$API_URL/$endpoint"
}

# ---------- Utility: QUIC Packet Sender ----------
phoenix_quic_send() {
    local payload="$1"
    echo "$payload" | nc -u -w1 "$PEER_IP" "$PEER_PORT" &>/dev/null
}

# ---------- Utility: Timestamp ----------
phoenix_timestamp() {
    date -Iseconds
}
