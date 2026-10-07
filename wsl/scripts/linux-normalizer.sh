#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------
# 0. Phoenix core + config
# ---------------------------------------------------------
umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

dos2unix "$0" 2>/dev/null || true

LOG="/opt/semperfix/logs/linux-normalizer.log"

log() {
    echo "[INFO] $1" | tee -a "$LOG"
}

CONFIG_DIR="/opt/semperfix/config"
CONFIG_JSON="${CONFIG_DIR}/phoenix.json"
CONFIG_CONF="${CONFIG_DIR}/phoenix.conf"

# shellcheck disable=SC1090
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

log "SemperFix Linux Normalizer starting for node role: ${NODE_ROLE}"

DNS="1.1.1.1"
DNS2="1.0.0.1"

# ---------------------------------------------------------
# 1. Determine primary interface (default route)
# ---------------------------------------------------------
IFACE=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1 || true)

if [[ -z "${IFACE}" ]]; then
    log "No default route interface found — skipping IP/route normalization."
else
    log "Using interface: ${IFACE}"
fi

# ---------------------------------------------------------
# 2. Ensure static IP is present
# ---------------------------------------------------------
if [[ -n "${IFACE}" ]]; then
    EXPECTED_IP="${NODE_IP}"
    CURRENT_IP=$(ip -4 addr show "${IFACE}" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)

    if [[ -z "${CURRENT_IP}" ]]; then
        log "No IPv4 address found on ${IFACE}."
    fi

    if [[ "${CURRENT_IP}" != "${EXPECTED_IP}" ]]; then
        log "IP mismatch: expected ${EXPECTED_IP}, found ${CURRENT_IP:-none} — correcting..."
        sudo ip addr flush dev "${IFACE}"
        sudo ip addr add "${EXPECTED_IP}/24" dev "${IFACE}"
    else
        log "IP address correct: ${CURRENT_IP}"
    fi
fi

# ---------------------------------------------------------
# 2b. Export WSL IP for Windows-side scripts
# ---------------------------------------------------------
WSL_IP=$(hostname -I | awk '{print $1}')
echo "$WSL_IP" > /opt/semperfix/state/wsl-ip.txt
echo "[$(date -Iseconds)] WSL IP normalized: $WSL_IP" >> /opt/semperfix/logs/network.log
log "WSL IP exported for Windows-side scripts: ${WSL_IP}"


# ---------------------------------------------------------
# 3. Ensure default route exists
# ---------------------------------------------------------
GATEWAY="${PHOENIX_GATEWAY:-192.168.1.1}"

if ip route show default 2>/dev/null | grep -q "${GATEWAY}"; then
    log "Default route OK via ${GATEWAY}"
else
    log "Default route missing or incorrect — adding route via ${GATEWAY}"
    sudo ip route add default via "${GATEWAY}" || log "Failed to add default route via ${GATEWAY}"
fi

# ---------------------------------------------------------
# 4. Firewall rules (role-aware)
# ---------------------------------------------------------
if command -v ufw >/dev/null 2>&1; then
    log "Evaluating firewall rules for node role: ${NODE_ROLE}"

    # Syncthing QUIC (22000) — required on ALL nodes
    sudo ufw status | grep -q "22000/udp" || sudo ufw allow 22000/udp >/dev/null 2>&1
    sudo ufw status | grep -q "22000/tcp" || sudo ufw allow 22000/tcp >/dev/null 2>&1

    if [[ "${NODE_ROLE}" == "SECONDARY" ]]; then
        # Phoenix QUIC responder (22001) — only SECONDARY
        sudo ufw status | grep -q "22001/udp" || sudo ufw allow 22001/udp >/dev/null 2>&1
        log "Firewall rules ensured for SECONDARY."
    else
        # MASTERZERO + OFFSITE — remove Phoenix QUIC if present
        sudo ufw delete allow 22001/udp >/dev/null 2>&1 || true
        log "Firewall rules pruned for ${NODE_ROLE}."
    fi
else
    log "UFW not installed — skipping firewall rules."
fi

# ---------------------------------------------------------
# 5. QUIC responder (role-aware)
# ---------------------------------------------------------
log "Evaluating QUIC responder requirements for node role: ${NODE_ROLE}"

if [[ "${NODE_ROLE}" == "SECONDARY" ]]; then
    log "Node is SECONDARY — QUIC responder should be active."

    if systemctl is-active --quiet phoenix-quic-responder.service; then
        log "QUIC responder service is active."
    else
        log "QUIC responder NOT active — restarting service..."
        sudo systemctl restart phoenix-quic-responder.service || log "Responder restart failed."
    fi
else
    log "Node is ${NODE_ROLE} — QUIC responder must NOT run here."

    systemctl disable --now phoenix-quic-responder.service 2>/dev/null || true
    systemctl mask phoenix-quic-responder.service 2>/dev/null || true

    log "QUIC responder disabled and masked on ${NODE_ROLE}."
fi

# ---------------------------------------------------------
# 6. Ensure systemd-resolved DNS stability
# ---------------------------------------------------------
if systemctl is-active --quiet systemd-resolved; then
    log "Ensuring DNS stability via systemd-resolved..."

    sudo sed -i "s/^DNS=.*/DNS=${DNS}/" /etc/systemd/resolved.conf || true
    sudo sed -i "s/^FallbackDNS=.*/FallbackDNS=${DNS2}/" /etc/systemd/resolved.conf || true

    sudo systemctl restart systemd-resolved || log "systemd-resolved restart failed."
    log "DNS stabilized via systemd-resolved."
else
    log "systemd-resolved inactive — skipping DNS stabilization."
fi

# ---------------------------------------------------------
# 7. WSL2 awareness (no destructive edits)
# ---------------------------------------------------------
if grep -q "WSL" /proc/version; then
    log "WSL detected — verifying config persistence policy."

    if [[ -f /etc/wsl.conf ]]; then
        if grep -q "systemd=true" /etc/wsl.conf; then
            log "wsl.conf contains systemd=true — respecting immutable config policy."
        else
            log "systemd=true missing in wsl.conf — NOT modifying due to protection policy."
        fi
    else
        log "wsl.conf not found — WSL may be using defaults."
    fi

    if systemctl is-active --quiet systemd-resolved; then
        log "WSL DNS persistence handled via systemd-resolved; not touching /etc/resolv.conf."
    else
        log "systemd-resolved inactive under WSL — DNS behavior may be non-standard."
    fi
fi

log "SemperFix Linux Normalizer complete for node role: ${NODE_ROLE}"
