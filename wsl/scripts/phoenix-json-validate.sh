#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Normalize line endings
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

STATUS_FILE="${STATE_DIR}/phoenix-status.json"

fail() {
    echo "[FAIL] $1"
    exit 1
}

pass() {
    echo "[PASS] $1"
}

# ---------- Basic existence ----------
[[ -f "$STATUS_FILE" ]] || fail "Status file missing"

# ---------- JSON parse check ----------
jq . "$STATUS_FILE" >/dev/null 2>&1 || fail "Invalid JSON format"

# ---------- Required top-level objects ----------
for obj in meta node health supervisor; do
    jq -e ".${obj} | type == \"object\"" "$STATUS_FILE" >/dev/null 2>&1 \
        || fail "Missing or invalid object: .${obj}"
done

# ---------- Required fields ----------
required_fields=(
    ".meta.version"
    ".meta.timestamp"
    ".node.role"
    ".node.api_url"
    ".node.peer_target"
    ".health.api_ok"
    ".health.peer_connected"
    ".health.syncthing_ready"
    ".health.quic_ok"
    ".health.mesh_ok"
    ".supervisor.handshake"
    ".supervisor.verify"
    ".supervisor.activate"
)

for field in "${required_fields[@]}"; do
    value=$(jq -r "$field" "$STATUS_FILE")
    [[ "$value" == "null" ]] && fail "Missing field: $field"
done

# ---------- Boolean validation (allow not_applicable) ----------
bool_fields=(
    ".health.api_ok"
    ".health.peer_connected"
    ".health.syncthing_ready"
    ".health.quic_ok"
    ".health.mesh_ok"
)

for field in "${bool_fields[@]}"; do
    val=$(jq -r "$field" "$STATUS_FILE")
    case "$val" in
        true|false|not_applicable) ;;
        *) fail "Invalid boolean-like value for $field: $val" ;;
    esac
done

# ---------- Supervisor status validation ----------
status_fields=(
    ".supervisor.handshake"
    ".supervisor.verify"
    ".supervisor.activate"
)

for field in "${status_fields[@]}"; do
    val=$(jq -r "$field" "$STATUS_FILE")
    case "$val" in
        pass|fail|unknown) ;;
        *) fail "Invalid supervisor status for $field: $val" ;;
    esac
done

pass "phoenix-status.json v2 validation OK"
exit 0
