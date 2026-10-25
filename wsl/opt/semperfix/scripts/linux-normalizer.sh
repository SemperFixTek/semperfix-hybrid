#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------
# Phoenix bootstrap
# ---------------------------------------------------------
umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

mkdir -p "${STATE_DIR}"
mkdir -p "${LOG_DIR}"

LOG="${LOG_DIR}/linux-normalizer.log"

log() {
    echo "[$(date -Iseconds)] $*" | tee -a "$LOG"
}

log "Linux normalizer started."
log "Node role: ${NODE_ROLE}"

# ---------------------------------------------------------
# Detect WSL + mirrored networking
# ---------------------------------------------------------

IS_WSL=false
IS_MIRRORED=false

if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

if [[ "${NETWORK_MODE}" == "mirrored" ]]; then
    IS_MIRRORED=true
fi

log "WSL detected: ${IS_WSL}"
log "Mirrored networking detected: ${IS_MIRRORED}"

# ---------------------------------------------------------
# Network information only
# Never modify networking under mirrored mode
# ---------------------------------------------------------

if [[ "${IS_WSL}" == "true" && "${IS_MIRRORED}" == "true" ]]; then

    CURRENT_IP=$(hostname -I | awk '{print $1}')
    DEFAULT_ROUTE=$(ip route show default | head -1 || true)

    log "Current IP: ${CURRENT_IP}"
    log "Current route: ${DEFAULT_ROUTE}"

    echo "${CURRENT_IP}" > "${STATE_DIR}/wsl-ip.txt"

    log "Windows-owned networking detected."
    log "Skipping IP enforcement."
    log "Skipping route enforcement."
    log "Skipping interface modification."

else

    log "Non-mirrored networking mode."

    # If you really want route enforcement, do it only here.
    # Never in mirrored mode.

fi

# ---------------------------------------------------------
# DNS
# ---------------------------------------------------------

if systemctl is-active --quiet systemd-resolved; then

    mkdir -p /etc/systemd/resolved.conf.d

    cat >/etc/systemd/resolved.conf.d/semperfix.conf <<EOF
[Resolve]
DNS=${DNS1}
FallbackDNS=${DNS2}
EOF

    systemctl restart systemd-resolved || true

    log "DNS configuration verified."

else

    log "systemd-resolved unavailable."

fi

# ---------------------------------------------------------
# Firewall
# ---------------------------------------------------------

if command -v ufw >/dev/null 2>&1; then

    ufw allow 22000/tcp >/dev/null 2>&1 || true
    ufw allow 22000/udp >/dev/null 2>&1 || true

    if [[ "${NODE_ROLE}" =~ SECONDARY ]]; then
        ufw allow 22001/udp >/dev/null 2>&1 || true
    fi

    log "Firewall normalization complete."

fi

# ---------------------------------------------------------
# QUIC responder
# ---------------------------------------------------------

case "${NODE_ROLE}" in

    "SECONDARY-PASSIVE")

        log "Role=${NODE_ROLE} : QUIC responder required."

        if systemctl is-active --quiet semperfix-quic-responder.service; then
            log "QUIC responder already active."
        else
            log "Starting QUIC responder..."
            sudo systemctl restart semperfix-quic-responder.service \
                || log "Responder restart failed."
        fi
        ;;

    "SECONDARY-ACTIVE"|"MASTERZERO-ACTIVE"|"MASTERZERO-DEGRADED"|"MASTERZERO-RECOVER"|"OFFSITE")

        log "Role=${NODE_ROLE} : QUIC responder must be disabled."

        sudo systemctl stop semperfix-quic-responder.service 2>/dev/null || true
        sudo systemctl disable semperfix-quic-responder.service 2>/dev/null || true
        ;;

    *)

        log "Unknown role: ${NODE_ROLE}"

        sudo systemctl stop semperfix-quic-responder.service 2>/dev/null || true
        sudo systemctl disable semperfix-quic-responder.service 2>/dev/null || true
        ;;

esac

# ---------------------------------------------------------
# Export runtime state
# ---------------------------------------------------------

ip route show > "${STATE_DIR}/routes.txt"
ip addr show > "${STATE_DIR}/interfaces.txt"

log "Normalizer complete."