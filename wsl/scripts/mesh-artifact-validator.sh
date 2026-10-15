#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

HANDSHAKE="${STATE_DIR}/mesh-handshake.json"
SUPERVISOR="${STATE_DIR}/phoenix-supervisor.json"
HEARTBEAT="${STATE_DIR}/phoenix-heartbeat.json"

echo "=== SemperFix Phoenix v2 Mesh Artifact Validator ==="

check_file() {
    local f="$1"
    if [[ ! -f "$f" ]]; then
        echo "[MISSING] $f"
        return 1
    fi
    echo "[OK] Found $f"
}

check_json_field() {
    local file="$1"
    local field="$2"
    if jq -e ".$field" "$file" >/dev/null 2>&1; then
        echo "[OK] $file contains .$field"
    else
        echo "[FAIL] $file missing .$field"
    fi
}

echo
echo "--- Checking Required Files ---"
check_file "$HANDSHAKE"
check_file "$SUPERVISOR"
check_file "$HEARTBEAT"

echo
echo "--- Checking Handshake JSON Schema ---"
check_json_field "$HANDSHAKE" "peer_dump"
check_json_field "$HANDSHAKE" "peer_dump.connections"

echo
echo "--- Checking Supervisor JSON Schema ---"
check_json_field "$SUPERVISOR" "handshake_status"
check_json_field "$SUPERVISOR" "verify_status"
check_json_field "$SUPERVISOR" "activate_status"

echo
echo "--- Checking Heartbeat JSON Schema ---"
check_json_field "$HEARTBEAT" "api_ok"
check_json_field "$HEARTBEAT" "peer_connected"
check_json_field "$HEARTBEAT" "quic_ok"
check_json_field "$HEARTBEAT" "mesh_ok"

echo
echo "--- Checking QUIC Reachability ---"
if nc -zvu "$PEER_IP" "$PEER_PORT" 2>/dev/null; then
    echo "[OK] QUIC reachable at $PEER_IP:$PEER_PORT"
else
    echo "[FAIL] QUIC unreachable at $PEER_IP:$PEER_PORT"
fi

echo
echo "--- Checking Syncthing API ---"
api_code=$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: $API_KEY" "$API_URL/system/status")
echo "Syncthing API returned HTTP $api_code"

echo
echo "=== Validator Complete ==="
