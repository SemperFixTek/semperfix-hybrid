#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

CLUSTER_JSON="${STATE_DIR}/cluster-view.json"
CLUSTER_LOG="${LOG_DIR}/cluster-view.log"

PHOENIX_LOGFILE="$CLUSTER_LOG"
log() { phoenix_log_file "INFO" "$*"; }

load_json() {
    [[ -f "$1" ]] && cat "$1" || echo "{}"
}

# ---------------------------------------------------------
# Load roles
# ---------------------------------------------------------
master_role=$(jq -r '.node.role // "UNKNOWN"' "${STATE_DIR}/phoenix-status.json" 2>/dev/null)
secondary_role=$(jq -r '.node.role // "UNKNOWN"' "${STATE_DIR}/secondary/phoenix-status.json" 2>/dev/null)

log "Cluster-view roles: MASTERZERO=$master_role SECONDARY=$secondary_role"

# ---------------------------------------------------------
# MASTERZERO telemetry (always full)
# ---------------------------------------------------------
mz = {
    "role": master_role,
    "heartbeat": load_json "${STATE_DIR}/phoenix-heartbeat.json",
    "supervisor": load_json "${STATE_DIR}/phoenix-supervisor.json",
    "mesh": load_json "${STATE_DIR}/mesh-status.json",
    "quic": load_json "${STATE_DIR}/quic-client-status.json",
    "failover": load_json "${STATE_DIR}/phoenix-failover.json",
    "windows": load_json "${STATE_DIR}/windows-heartbeat.json"
}

# ---------------------------------------------------------
# SECONDARY telemetry (role-aware)
# ---------------------------------------------------------
sec_base="/mnt/c/semperfix/secondary"

sec_heartbeat=$(load_json "${sec_base}/phoenix-heartbeat.json")
sec_mesh=$(load_json "${sec_base}/mesh-status.json")
sec_quic=$(load_json "${sec_base}/quic-client-status.json")
sec_windows=$(load_json "${sec_base}/windows-heartbeat.json")

# Controller telemetry only if SECONDARY-ACTIVE
if [[ "$secondary_role" == "SECONDARY-ACTIVE" ]]; then
    sec_supervisor=$(load_json "${sec_base}/phoenix-supervisor.json")
    sec_failover=$(load_json "${sec_base}/phoenix-failover.json")
else
    sec_supervisor='{"status":"not_applicable"}'
    sec_failover='{"status":"not_applicable"}'
fi

# ---------------------------------------------------------
# Build unified cluster JSON
# ---------------------------------------------------------
json_init "$CLUSTER_JSON"

json_set "$CLUSTER_JSON" "timestamp" "$(date -Iseconds)"

json_set_raw "$CLUSTER_JSON" "masterzero" "$(jq -n \
    --argjson hb "$mz_heartbeat" \
    --argjson sup "$mz_supervisor" \
    --argjson mesh "$mz_mesh" \
    --argjson quic "$mz_quic" \
    --argjson fail "$mz_failover" \
    --argjson win "$mz_windows" \
    --arg role "$master_role" \
    '{role:$role, heartbeat:$hb, supervisor:$sup, mesh:$mesh, quic:$quic, failover:$fail, windows:$win}')"

json_set_raw "$CLUSTER_JSON" "secondary" "$(jq -n \
    --argjson hb "$sec_heartbeat" \
    --argjson sup "$sec_supervisor" \
    --argjson mesh "$sec_mesh" \
    --argjson quic "$sec_quic" \
    --argjson fail "$sec_failover" \
    --argjson win "$sec_windows" \
    --arg role "$secondary_role" \
    '{role:$role, heartbeat:$hb, supervisor:$sup, mesh:$mesh, quic:$quic, failover:$fail, windows:$win}')"

json_finalize "$CLUSTER_JSON"
/opt/semperfix/scripts/json-perms.sh "$CLUSTER_JSON"

log "Cluster-wide JSON written to $CLUSTER_JSON"

# ---------------------------------------------------------
# Human-readable summary
# ---------------------------------------------------------
log "Cluster Summary:"
log "MASTERZERO role: $master_role"
log "SECONDARY role: $secondary_role"

log "MASTERZERO heartbeat: $(jq -r '.api_ok' <<< "$mz_heartbeat")"
log "MASTERZERO quic: $(jq -r '.quic_ok' <<< "$mz_heartbeat")"

log "SECONDARY heartbeat: $(jq -r '.api_ok' <<< "$sec_heartbeat")"
log "SECONDARY quic: $(jq -r '.quic_ok' <<< "$sec_heartbeat")"

log "Cluster view complete."
