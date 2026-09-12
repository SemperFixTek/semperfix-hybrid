#!/usr/bin/env bash
# ==============================================================================
# Phoenix + Mesh v2 — wsl-mesh-status.sh
# Emits a full JSON status snapshot of the Phoenix node from WSL.
#
# Drop into: /opt/semperfix/scripts/
# Run as:    bash /opt/semperfix/scripts/wsl-mesh-status.sh
# Pipe to:   bash wsl-mesh-status.sh | jq .
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
[[ -f "$PHOENIX_JSON"   ]] || { echo "{\"error\":\"phoenix.json not found\"}" >&2; exit 1; }
[[ -f "$SYNCTHING_JSON" ]] || { echo "{\"error\":\"syncthing-config.json not found\"}" >&2; exit 1; }

API_URL=$(jq -r '.ApiUrl' "$PHOENIX_JSON" | sed 's|/$||')
API_KEY=$(jq -r '.apiKey' "$SYNCTHING_JSON")

[[ -z "$API_URL" || "$API_URL" == "null" ]] && { echo "{\"error\":\"ApiUrl empty\"}" >&2; exit 1; }
[[ -z "$API_KEY" || "$API_KEY" == "null" ]] && { echo "{\"error\":\"apiKey empty\"}"  >&2; exit 1; }

NODE=$(hostname)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── API helper ────────────────────────────────────────────────────────────────
mesh_api() {
  local path="$1"
  curl -sf \
    -H "X-API-Key: ${API_KEY}" \
    -H "Accept: application/json" \
    "${API_URL}${path}"
}

# ── Collect sections ──────────────────────────────────────────────────────────

# system
if SYS=$(mesh_api "/rest/system/status" 2>/dev/null); then
  SYSTEM=$(echo "$SYS" | jq '{
    ok:         true,
    myID:       .myID,
    uptime:     .uptime,
    goroutines: .goroutines,
    alloc:      .alloc,
    sys:        .sys
  }')
else
  SYSTEM='{"ok":false,"error":"failed to reach /rest/system/status"}'
fi

# version
if VER=$(mesh_api "/rest/system/version" 2>/dev/null); then
  VERSION=$(echo "$VER" | jq '{ok:true,version:.version,os:.os,arch:.arch}')
else
  VERSION='{"ok":false,"error":"failed to reach /rest/system/version"}'
fi

# connections
if CONN=$(mesh_api "/rest/system/connections" 2>/dev/null); then
  CONNECTIONS=$(echo "$CONN" | jq '{
    ok:        true,
    total:     ([.connections | to_entries[]] | length),
    connected: ([.connections | to_entries[] | select(.value.connected==true)] | length),
    peers:     [.connections | to_entries[] | {
      deviceID:      .key,
      connected:     .value.connected,
      address:       .value.address,
      type:          .value.type,
      inBytesTotal:  .value.inBytesTotal,
      outBytesTotal: .value.outBytesTotal
    }]
  }')
else
  CONNECTIONS='{"ok":false,"error":"failed to reach /rest/system/connections"}'
fi

# folders
if FOLD=$(mesh_api "/rest/config/folders" 2>/dev/null); then
  FOLDERS=$(echo "$FOLD" | jq '{
    ok:    true,
    count: length,
    items: [.[] | {id:.id,label:.label,path:.path,type:.type,paused:.paused}]
  }')
else
  FOLDERS='{"ok":false,"error":"failed to reach /rest/config/folders"}'
fi

# errors
if ERRS=$(mesh_api "/rest/system/error" 2>/dev/null); then
  ERRORS=$(echo "$ERRS" | jq '{ok:true,count:(.errors|length),items:.errors}')
else
  ERRORS='{"ok":false,"error":"failed to reach /rest/system/error"}'
fi

# ── Final output ──────────────────────────────────────────────────────────────
jq -n \
  --arg     script      "wsl-mesh-status.sh" \
  --arg     ts          "$TIMESTAMP" \
  --arg     node        "$NODE" \
  --arg     url         "$API_URL" \
  --argjson system      "$SYSTEM" \
  --argjson version     "$VERSION" \
  --argjson connections "$CONNECTIONS" \
  --argjson folders     "$FOLDERS" \
  --argjson errors      "$ERRORS" \
  '{
    script:      $script,
    timestamp:   $ts,
    node:        $node,
    apiUrl:      $url,
    system:      $system,
    version:     $version,
    connections: $connections,
    folders:     $folders,
    errors:      $errors
  }'
