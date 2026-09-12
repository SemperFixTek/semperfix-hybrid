#!/usr/bin/env bash
# ==============================================================================
# Phoenix + Mesh v2 — wsl-mesh-bootstrap.sh
# Initializes the local WSL node against the Phoenix mesh.
# Reads ApiUrl from phoenix.json, Syncthing API key from syncthing-config.json.
#
# Drop into: /opt/semperfix/scripts/
# Run as:    bash /opt/semperfix/scripts/wsl-mesh-bootstrap.sh
# Requires:  curl, jq
# ==============================================================================
set -euo pipefail

# ── Config paths ──────────────────────────────────────────────────────────────
WINDOWS_CONFIG="/mnt/c/SemperFix/ConfigBackup"
PHOENIX_JSON="${WINDOWS_CONFIG}/phoenix.json"
SYNCTHING_JSON="${WINDOWS_CONFIG}/syncthing-config.json"

# ── Dependency check ──────────────────────────────────────────────────────────
for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "{\"error\":\"missing dependency: $bin\"}" >&2; exit 1; }
done

# ── Load config ───────────────────────────────────────────────────────────────
[[ -f "$PHOENIX_JSON"   ]] || { echo "{\"error\":\"phoenix.json not found at $PHOENIX_JSON\"}" >&2; exit 1; }
[[ -f "$SYNCTHING_JSON" ]] || { echo "{\"error\":\"syncthing-config.json not found at $SYNCTHING_JSON\"}" >&2; exit 1; }

API_URL=$(jq -r '.ApiUrl' "$PHOENIX_JSON" | sed 's|/$||')
API_KEY=$(jq -r '.apiKey' "$SYNCTHING_JSON")

[[ -z "$API_URL" || "$API_URL" == "null" ]] && { echo "{\"error\":\"ApiUrl is empty in phoenix.json\"}" >&2; exit 1; }
[[ -z "$API_KEY" || "$API_KEY" == "null" ]] && { echo "{\"error\":\"apiKey is empty in syncthing-config.json\"}" >&2; exit 1; }

# ── API helper ────────────────────────────────────────────────────────────────
mesh_api() {
  local path="$1"
  curl -sf \
    -H "X-API-Key: ${API_KEY}" \
    -H "Accept: application/json" \
    "${API_URL}${path}"
}

# ── Bootstrap ─────────────────────────────────────────────────────────────────
NODE=$(hostname)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
STEPS="[]"

append_step() {
  STEPS=$(echo "$STEPS" | jq --argjson s "$1" '. + [$s]')
}

# Step 1 — Ping
if PING_OUT=$(mesh_api "/rest/system/ping" 2>/dev/null); then
  PONG=$(echo "$PING_OUT" | jq -r '.ping // "unknown"')
  append_step "$(jq -n --arg pong "$PONG" '{step:"ping",status:"ok",pong:$pong}')"
else
  append_step '{"step":"ping","status":"error","error":"API unreachable"}'
  jq -n \
    --arg script "wsl-mesh-bootstrap.sh" \
    --arg ts "$TIMESTAMP" \
    --arg node "$NODE" \
    --arg url "$API_URL" \
    --argjson steps "$STEPS" \
    '{script:$script,timestamp:$ts,node:$node,apiUrl:$url,steps:$steps,bootstrapStatus:"failed"}'
  exit 1
fi

# Step 2 — System status
if SYS_OUT=$(mesh_api "/rest/system/status" 2>/dev/null); then
  MY_ID=$(echo "$SYS_OUT"  | jq -r '.myID   // ""')
  UPTIME=$(echo "$SYS_OUT" | jq -r '.uptime // 0')
  append_step "$(jq -n \
    --arg myID "$MY_ID" \
    --argjson uptime "$UPTIME" \
    '{step:"system_status",status:"ok",myID:$myID,uptime:$uptime}')"
else
  append_step '{"step":"system_status","status":"error","error":"failed to reach /rest/system/status"}'
fi

# Step 3 — Connections
if CONN_OUT=$(mesh_api "/rest/system/connections" 2>/dev/null); then
  PEER_COUNT=$(echo "$CONN_OUT" | jq '[.connections | to_entries[] | .value] | length')
  CONNECTED=$(echo "$CONN_OUT"  | jq '[.connections | to_entries[] | select(.value.connected==true)] | length')
  PEERS=$(echo "$CONN_OUT" | jq '[.connections | to_entries[] | {
    deviceID: .key,
    connected: .value.connected,
    address:   .value.address,
    type:      .value.type
  }]')
  append_step "$(jq -n \
    --argjson total "$PEER_COUNT" \
    --argjson connected "$CONNECTED" \
    --argjson peers "$PEERS" \
    '{step:"connections",status:"ok",total:$total,connected:$connected,peers:$peers}')"
else
  append_step '{"step":"connections","status":"error","error":"failed to reach /rest/system/connections"}'
fi

# Step 4 — Folders
if FOLDERS_OUT=$(mesh_api "/rest/config/folders" 2>/dev/null); then
  FOLDER_COUNT=$(echo "$FOLDERS_OUT" | jq 'length')
  FOLDERS=$(echo "$FOLDERS_OUT" | jq '[.[] | {id:.id,label:.label,path:.path,type:.type,paused:.paused}]')
  append_step "$(jq -n \
    --argjson count "$FOLDER_COUNT" \
    --argjson folders "$FOLDERS" \
    '{step:"folders",status:"ok",count:$count,folders:$folders}')"
else
  append_step '{"step":"folders","status":"error","error":"failed to reach /rest/config/folders"}'
fi

# ── Final output ──────────────────────────────────────────────────────────────
jq -n \
  --arg script    "wsl-mesh-bootstrap.sh" \
  --arg ts        "$TIMESTAMP" \
  --arg node      "$NODE" \
  --arg url       "$API_URL" \
  --argjson steps "$STEPS" \
  '{
    script:          $script,
    timestamp:       $ts,
    node:            $node,
    apiUrl:          $url,
    steps:           $steps,
    bootstrapStatus: "complete"
  }'
