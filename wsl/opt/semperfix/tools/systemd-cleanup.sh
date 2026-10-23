#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

log() {
    echo "[SYSTEMD-CLEANUP] $*"
}

# Directories systemd uses for symlinks
WANTS_DIRS=(
    "/etc/systemd/system/multi-user.target.wants"
    "/etc/systemd/system/timers.target.wants"
    "/etc/systemd/system/sysinit.target.wants"
    "/etc/systemd/system/sockets.target.wants"
    "/etc/systemd/system/semperfix.target.wants"
)

# Phoenix v2.1 legitimate units
declare -A PHOENIX_UNITS=(
    # Core Phoenix v2.1 units
    ["semperfix-phoenix-supervisor.service"]=1
    ["semperfix-phoenix-supervisor.timer"]=1
    ["semperfix-phoenix-heartbeat.timer"]=1
    ["semperfix-mesh-status.timer"]=1
    ["semperfix-quic-client.timer"]=1
    ["semperfix-quic-responder.service"]=1
    ["semperfix-phoenix-failover.timer"]=1
    ["semperfix-phoenix-descalate.timer"]=1
    ["semperfix-phoenix-promote.timer"]=1
    ["semperfix-mesh-listener.service"]=1
    ["semperfix-state-export-windows.timer"]=1
)

cleanup_symlink() {
    local link="$1"

    # Extract unit name
    local unit
    unit=$(basename "$link")

    # If not a Phoenix v2.1 unit → remove it
    if [[ -z "${PHOENIX_UNITS[$unit]:-}" ]]; then
        log "Removing garbage symlink: $link"
        rm -f "$link"
    else
        log "Keeping legitimate Phoenix unit: $unit"
    fi
}

main() {
    log "Starting systemd garbage symlink cleanup"

    for dir in "${WANTS_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            log "Scanning: $dir"
            for link in "$dir"/*; do
                [[ -e "$link" ]] || continue
                cleanup_symlink "$link"
            done
        fi
    done

    log "Systemd cleanup complete"
}

main "$@"
