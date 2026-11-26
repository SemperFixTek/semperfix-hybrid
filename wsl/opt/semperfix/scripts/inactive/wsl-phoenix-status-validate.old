#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Status JSON Validator
# Version: Phoenix v2.1
# Component: phoenix-json-validate
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 schema upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail
umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

STATUS_FILE="${STATE_DIR}/phoenix-status.json"

fail() { echo "[FAIL] $1"; exit 1; }
pass() { echo "[PASS] $1"; }

# ---------- Basic existence ----------
[[ -f "$STATUS_FILE" ]] || fail "Status file missing"

# ---------- JSON parse check ----------
jq . "$STATUS_FILE" >/dev/null 2>&1 || fail "Invalid JSON format"

# ---------- Required top-level objects ----------
for obj in meta node health; do
    jq -e ".${obj} | type == \"object\"" "$STATUS_FILE" >/dev/null 2>&1 \
        || fail "Missing or invalid object: .${obj}"
done

# ---------- Validate Phoenix v2.1 role ----------
ROLE=$(jq -r '.node.role' "$STATUS_FILE")

case "$ROLE" in
    MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|\
    SECONDARY-ACTIVE|SECONDARY-PASSIVE|OFFSITE)
        ;;
    *)
        fail "Invalid Phoenix role: $ROLE"
        ;;
esac

# ---------- Validate meta block ----------
jq -e '.meta.version' "$STATUS_FILE" >/dev/null || fail "Missing meta.version"
jq -e '.meta.timestamp' "$STATUS_FILE" >/dev/null || fail "Missing meta.timestamp"

# ---------- Validate node block ----------
jq -e '.node.api_url' "$STATUS_FILE" >/dev/null || fail "Missing node.api_url"
jq -e '.node.peer_target' "$STATUS_FILE" >/dev/null || fail "Missing node.peer_target"

# ---------- Role-aware health validation ----------
case "$ROLE" in

    MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|SECONDARY-ACTIVE)
        required_health=(
            ".health.api_ok"
            ".health.peer_connected"
            ".health.syncthing_ready"
            ".health.quic_ok"
            ".health.mesh_ok"
        )
        ;;

    SECONDARY-PASSIVE)
        required_health=(
            ".health.heartbeat_ok"
            ".health.api_ok"
            ".health.quic_ok"
        )
        ;;

    OFFSITE)
        required_health=(
            ".health.api_ok"
        )
        ;;
esac

for field in "${required_health[@]}"; do
    val=$(jq -r "$field // \"null\"" "$STATUS_FILE")
    [[ "$val" == "null" ]] && fail "Missing field: $field"
done

# ---------- Supervisor validation (ACTIVE roles only) ----------
case "$ROLE" in
    MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|SECONDARY-ACTIVE)
        jq -e '.supervisor | type == "object"' "$STATUS_FILE" >/dev/null \
            || fail "Missing supervisor block"

        for field in ".supervisor.handshake" ".supervisor.verify" ".supervisor.activate"; do
            val=$(jq -r "$field // \"null\"" "$STATUS_FILE")
            [[ "$val" == "null" ]] && fail "Missing supervisor field: $field"
            case "$val" in
                pass|fail|unknown) ;;
                *) fail "Invalid supervisor status for $field: $val" ;;
            esac
        done
        ;;
esac

pass "phoenix-status.json v2.1 validation OK"
exit 0
