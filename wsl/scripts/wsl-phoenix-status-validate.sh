#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phoenix Status Validator — SemperFix Edition (v2)
# Validates phoenix-status.json structure and required fields
# ============================================================

STATUS_FILE="/opt/semperfix/state/phoenix-status.json"

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

# ---------- Required fields ----------
required_fields=(
    ".meta.version"
    ".meta.timestamp"
    ".node.role"
    ".node.api_url"
    ".node.peer_target"
    ".health.api_ok"
    ".health.peer_connected"
    ".supervisor.handshake"
    ".supervisor.verify"
    ".supervisor.activate"
)

for field in "${required_fields[@]}"; do
    value=$(jq -r "$field" "$STATUS_FILE")
    [[ "$value" == "null" ]] && fail "Missing field: $field"
done

pass "phoenix-status.json v2 validation OK"
exit 0
