#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

HEARTBEAT_FILE="/opt/semperfix/state/phoenix-heartbeat.json"
FAILOVER_FILE="/opt/semperfix/state/phoenix-failover.json"
LOGFILE="/opt/semperfix/logs/phoenix-failover.log"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$LOGFILE"
}

json_init() { echo "{" > "$FAILOVER_FILE"; }
json_add() {
    local key="$1"
    local value="$2"
    value=$(printf '%s' "$value" | jq -Rsa .)
    value="${value:1:${#value}-2}"
    echo "  \"${key}\": \"${value}\"," >> "$FAILOVER_FILE"
}
json_close() {
    sed -i '$ s/,$//' "$FAILOVER_FILE"
    echo "}" >>