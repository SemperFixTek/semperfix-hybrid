#!/usr/bin/env bash
set -euo pipefail

STATUS_FILE="/var/lib/semperfix/state/phoenix-status.json"

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
    jq -e ".${obj} | objects" "$STATUS_FILE" >/dev/null 2>&1 \
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

# ---------- Boolean validation ----------
bool_fields=(
    ".health.api_ok"
    ".health.peer_connected"
    ".health.syncthing_ready"
    ".health.quic_ok"
    ".health.mesh_ok"
)

for field in "${bool_fields[@]}"; do
    val=$(jq -r "$field" "$STATUS_FILE")
    [[ "$val" != "true" && "$val" != "false" ]] \
        && fail "Invalid boolean for $field: $val"
done

# ---------- Supervisor status validation ----------
status_fields=(
    ".supervisor.handshake"
    ".supervisor.verify"
    ".supervisor.activate"
)

for field in "${status_fields[@]}"; do
    val=$(jq -r "$field" "$STATUS_FILE")
    [[ "$val" != "pass" && "$val" != "fail" ]] \
        && fail "Invalid supervisor status for $field: $val"
done

pass "phoenix-status.json v2 validation OK"
exit 0
