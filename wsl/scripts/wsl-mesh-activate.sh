#!/usr/bin/env bash
# ==============================================================================
# Phoenix + Mesh v2 — wsl-mesh-activate.sh
# Activates the Phoenix node from WSL: resumes paused folders, triggers rescan,
# writes an activation event sentinel, emits a JSON activation receipt.
#
# Drop into: /opt/semperfix/scripts/
# Run as:    bash /opt/semperfix/scripts/wsl-mesh-activate.sh
#            bash /opt/semperfix/scripts/wsl-mesh-activate.sh --force
# Requires:  curl, jq
# ==============================================================================
set -euo pipefail

FORCE=false
for arg in "$@"; do
  [[ "$arg" == "--force" ]] && FORCE=true
done

# ── Config paths ──────────────────────────────────────────────────────────────
WINDOWS_CONFIG="/mnt/c/SemperFix/ConfigBackup"
PHOENIX_JSON="${WINDOWS_CONFIG}/phoenix.json"
SYNCTHING_JSON="${WINDOWS_CONFIG}/syncthing-config.json"
SCRIPTS_DIR="/opt/semperfix/scripts"
EVENTS_DIR="/opt/semperfix/events"

# ── Dependency check ──────────────────────────────────────────────────────────
for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "{\"error\":\"missing dependency: $bin\"}" >&2; exit 1; }
done

# ── Load config ───────────────────────────────────────────────────────────────
[[ -f "$PHOENIX_JSON"   ]] || { echo "{\"error\":\"phoenix.json not found\"}" >&2; exit 1; }
[[ -f "$SYNCTHING_JSON" ]] || { echo "{\"error\":\"syncthing-config.json not found\"}" >&2; exit 1; }

API_URL=$(jq -r '.ApiUrl' "$PHOENIX_JSON" | sed 's|/$||')
API_KEY=$(jq -r '.apiKey' "$SYNCTHING_JSON")
NODE_NAME=$(jq -r '.nodeName // empty' "$PHOENIX_JSON" 2>/dev/null || hostname)
[[ -z "$NODE_NAME" ]] && NODE_NAME=$(hostname)

[[ -z "$API_URL" || "$API_URL" == "null" ]] && { echo "{\"error\":\"ApiUrl empty\"}" >&2; exit 1; }
[[ -z "$API_KEY" || "$API_KEY" == "null" ]] && { echo "{\"error\":\"apiKey empty\"}"  >&2; exit 1; }

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── Helpers ───────────────────────────────────────────────────────────────────
mesh_api_get() {
  curl -sf \
    -H "X-API-Key: ${API_KEY}" \
    -H "Accept: application/json" \
    "${API_URL}${1}"
}

mesh_api_post() {
  local path="$1" body="${2:-}"
  if [[ -n "$body" ]]; then
    curl -sf -X POST \
      -H "X-API-Key: ${API_KEY}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "$body" \
      "${API_URL}${path}"
  else
    curl -sf -X POST \
      -H "X-API-Key: ${API_KEY}" \
      -H "Accept: application/json" \
      "${API_URL}${path}"
  fi
}

mesh_api_patch() {
  local path="$1" body="$2"
  curl -sf -X PATCH \
    -H "X-API-Key: ${API_KEY}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "${API_URL}${path}"
}

ACTIONS="[]"

append_action() {
  ACTIONS=$(echo "$ACTIONS" | jq --argjson a "$1" '. + [$a]')
}

# ── Pre-flight verify (unless --force) ────────────────────────────────────────
if [[ "$FORCE" == false ]]; then
  VERIFY_SCRIPT="${SCRIPTS_DIR}/wsl-mesh-verify.sh"
  if [[ -f "$VERIFY_SCRIPT" ]]; then
    if VERIFY_OUT=$(bash "$VERIFY_SCRIPT" 2>/dev/null); then
      OVERALL=$(echo "$VERIFY_OUT" | jq -r '.overall // "UNKNOWN"')
      if [[ "$OVERALL" != "PASS" ]]; then
        CHECKS=$(echo "$VERIFY_OUT" | jq '.checks // []')
        append_action "$(jq -n \
          --arg     detail "wsl-mesh-verify.sh returned FAIL — use --force to override" \
          --argjson checks "$CHECKS" \
          '{action:"pre_verify",status:"abort",detail:$detail,checks:$checks}')"
        jq -n \
          --arg     script  "wsl-mesh-activate.sh" \
          --arg     ts      "$TIMESTAMP" \
          --arg     node    "$NODE_NAME" \
          --arg     url     "$API_URL" \
          --argjson force   "$( [[ "$FORCE" == true ]] && echo true || echo false )" \
          --argjson actions "$ACTIONS" \
          '{script:$script,timestamp:$ts,node:$node,apiUrl:$url,force:$force,actions:$actions,activationStatus:"aborted"}'
        exit 1
      fi
      append_action '{"action":"pre_verify","status":"pass"}'
    else
      append_action '{"action":"pre_verify","status":"warn","detail":"verify script returned non-zero"}'
    fi
  else
    append_action '{"action":"pre_verify","status":"skip","detail":"wsl-mesh-verify.sh not found"}'
  fi
fi

# ── Step 1 — Ping ─────────────────────────────────────────────────────────────
if PING_OUT=$(mesh_api_get "/rest/system/ping" 2>/dev/null); then
  PONG=$(echo "$PING_OUT" | jq -r '.ping // "unknown"')
  append_action "$(jq -n --arg pong "$PONG" '{action:"ping",status:"ok",pong:$pong}')"
else
  append_action '{"action":"ping","status":"error","error":"API unreachable"}'
  jq -n \
    --arg     script  "wsl-mesh-activate.sh" \
    --arg     ts      "$TIMESTAMP" \
    --arg     node    "$NODE_NAME" \
    --arg     url     "$API_URL" \
    --argjson force   "$( [[ "$FORCE" == true ]] && echo true || echo false )" \
    --argjson actions "$ACTIONS" \
    '{script:$script,timestamp:$ts,node:$node,apiUrl:$url,force:$force,actions:$actions,activationStatus:"failed"}'
  exit 1
fi

# ── Step 2 — Resume paused folders ───────────────────────────────────────────
if FOLD_OUT=$(mesh_api_get "/rest/config/folders" 2>/dev/null); then
  RESUMED="[]"
  TOTAL=$(echo "$FOLD_OUT" | jq 'length')
  while IFS= read -r folder_id; do
    mesh_api_patch "/rest/config/folders/${folder_id}" '{"paused":false}' >/dev/null 2>&1 || true
    RESUMED=$(echo "$RESUMED" | jq --arg id "$folder_id" '. + [$id]')
  done < <(echo "$FOLD_OUT" | jq -r '.[] | select(.paused==true) | .id')
  append_action "$(jq -n \
    --argjson total   "$TOTAL" \
    --argjson resumed "$RESUMED" \
    '{action:"resume_folders",status:"ok",total:$total,resumed:$resumed}')"
else
  append_action '{"action":"resume_folders","status":"error","error":"failed to reach /rest/config/folders"}'
fi

# ── Step 3 — Trigger rescan on all folders ────────────────────────────────────
if FOLD_OUT2=$(mesh_api_get "/rest/config/folders" 2>/dev/null); then
  SCANNED="[]"
  while IFS= read -r folder_id; do
    ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" \
              "$folder_id" 2>/dev/null || echo "$folder_id")
    mesh_api_post "/rest/db/scan?folder=${ENCODED}" "" >/dev/null 2>&1 || true
    SCANNED=$(echo "$SCANNED" | jq --arg id "$folder_id" '. + [$id]')
  done < <(echo "$FOLD_OUT2" | jq -r '.[].id')
  append_action "$(jq -n \
    --argjson scanned "$SCANNED" \
    '{action:"rescan_folders",status:"ok",scanned:$scanned}')"
else
  append_action '{"action":"rescan_folders","status":"error","error":"failed to list folders for rescan"}'
fi

# ── Step 4 — Write activation event ──────────────────────────────────────────
mkdir -p "$EVENTS_DIR"
EVENT_FILE="${EVENTS_DIR}/mesh-activate-$(date -u +"%Y%m%d-%H%M%S").json"
EVENT_PAYLOAD=$(jq -n \
  --arg event   "MeshActivate" \
  --arg node    "$NODE_NAME" \
  --arg ts      "$TIMESTAMP" \
  --arg url     "$API_URL" \
  --arg version "v2" \
  '{event:$event,node:$node,timestamp:$ts,apiUrl:$url,version:$version}')
echo "$EVENT_PAYLOAD" > "$EVENT_FILE"
append_action "$(jq -n --arg file "$EVENT_FILE" '{action:"activation_event",status:"ok",file:$file}')"

# ── Step 5 — Final health ─────────────────────────────────────────────────────
if SYS2=$(mesh_api_get "/rest/system/status" 2>/dev/null) && \
   CONN2=$(mesh_api_get "/rest/system/connections" 2>/dev/null); then
  MY_ID=$(echo "$SYS2"   | jq -r '.myID  // ""')
  UPTIME=$(echo "$SYS2"  | jq -r '.uptime // 0')
  CONNECTED=$(echo "$CONN2" | jq \
    '[.connections | to_entries[] | select(.value.connected==true)] | length')
  append_action "$(jq -n \
    --arg     myID           "$MY_ID" \
    --argjson uptime         "$UPTIME" \
    --argjson connectedPeers "$CONNECTED" \
    '{action:"final_health",status:"ok",myID:$myID,uptime:$uptime,connectedPeers:$connectedPeers}')"
else
  append_action '{"action":"final_health","status":"error","error":"failed to retrieve final status"}'
fi

# ── Final output ──────────────────────────────────────────────────────────────
jq -n \
  --arg     script  "wsl-mesh-activate.sh" \
  --arg     ts      "$TIMESTAMP" \
  --arg     node    "$NODE_NAME" \
  --arg     url     "$API_URL" \
  --argjson force   "$( [[ "$FORCE" == true ]] && echo true || echo false )" \
  --argjson actions "$ACTIONS" \
  '{
    script:           $script,
    timestamp:        $ts,
    node:             $node,
    apiUrl:           $url,
    force:            $force,
    actions:          $actions,
    activationStatus: "complete"
  }'
