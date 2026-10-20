#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

CLUSTER_JSON="${STATE_DIR}/cluster-view.json"
CLUSTER_LOG="${LOG_DIR}/cluster-view.log"

PHOENIX_LOGFILE="$CLUSTER_LOG"
log() { phoenix_log_file "INFO" "$*"; }

# ---------------------------------------------------------
# Helper: safe JSON load
# ---------------------------------------------------------
load_json() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cat "$file"
    else
        echo "{}"
    fi
}

# ---------------------------------------------------------
# Collect MASTERZERO WSL logs
# ---------------------------------------------------------
mz_heartbeat=$(load_json "${STATE_DIR}/phoenix-heartbeat.json")
mz_supervisor=$(load_json "${STATE_DIR}/phoenix-supervisor.json")
mz_mesh=$(load_json "${STATE_DIR}/mesh-status.json")
mz_quic=$(load_json "${STATE_DIR}/quic-client-status.json")
mz_failover=$(load_json "${STATE_DIR}/phoenix-failover.json")

# ---------------------------------------------------------
# Collect MASTERZERO Windows heartbeat
# ---------------------------------------------------------
mz_win_heartbeat=$(wslpath -w "${STATE_DIR}/windows-heartbeat.json" 2>/dev/null || echo "{}")

# ---------------------------------------------------------
# Collect SECONDARY WSL logs (via Syncthing share)
# ---------------------------------------------------------
sec_state="/mnt/c/semperfix/secondary"
sec_heartbeat=$(load_json "${sec_state}/phoenix-heartbeat.json")
sec_supervisor=$(load_json "${sec_state}/phoenix-supervisor.json")
sec_mesh=$(load_json "${sec_state}/mesh-status.json")
sec_quic=$(load_json "${sec_state}/quic-client-status.json")
sec_failover=$(load_json "${sec_state}/phoenix-failover.json")

# ---------------------------------------------------------
# Collect SECONDARY Windows heartbeat
# ---------------------------------------------------------
sec_win_heartbeat=$(load_json "${sec_state}/windows-heartbeat.json")

# ---------------------------------------------------------
# Build unified cluster JSON
# ---------------------------------------------------------
json_init "$CLUSTER_JSON"

json_set "$CLUSTER_JSON" "timestamp" "$(date -Iseconds)"

json_set "$CLUSTER_JSON" "masterzero.wsl.heartbeat" "$mz_heartbeat"
json_set "$CLUSTER_JSON" "masterzero.wsl.supervisor" "$mz_supervisor"
json_set "$CLUSTER_JSON" "masterzero.wsl.mesh" "$mz_mesh"
json_set "$CLUSTER_JSON" "masterzero.wsl.quic" "$mz_quic"
json_set "$CLUSTER_JSON" "masterzero.wsl.failover" "$mz_failover"

json_set "$CLUSTER_JSON" "masterzero.windows.heartbeat" "$mz_win_heartbeat"

json_set "$CLUSTER_JSON" "secondary.wsl.heartbeat" "$sec_heartbeat"
json_set "$CLUSTER_JSON" "secondary.wsl.supervisor" "$sec_supervisor"
json_set "$CLUSTER_JSON" "secondary.wsl.mesh" "$sec_mesh"
json_set "$CLUSTER_JSON" "secondary.wsl.quic" "$sec_quic"
json_set "$CLUSTER_JSON" "secondary.wsl.failover" "$sec_failover"

json_set "$CLUSTER_JSON" "secondary.windows.heartbeat" "$sec_win_heartbeat"

json_finalize "$CLUSTER_JSON"
/opt/semperfix/scripts/json-perms.sh "$CLUSTER_JSON"
log "Cluster-wide JSON written to $CLUSTER_JSON"

# ---------------------------------------------------------
# Human-readable summary
# ---------------------------------------------------------
log "Cluster Summary:"
log "MASTERZERO heartbeat: $(jq -r '.api_ok' <<< "$mz_heartbeat")"
log "MASTERZERO mesh: $(jq -r '.mesh_ok' <<< "$mz_heartbeat")"
log "MASTERZERO quic: $(jq -r '.quic_ok' <<< "$mz_heartbeat")"

log "SECONDARY heartbeat: $(jq -r '.api_ok' <<< "$sec_heartbeat")"
log "SECONDARY mesh: $(jq -r '.mesh_ok' <<< "$sec_heartbeat")"
log "SECONDARY quic: $(jq -r '.quic_ok' <<< "$sec_heartbeat")"

log "Cluster view complete."
