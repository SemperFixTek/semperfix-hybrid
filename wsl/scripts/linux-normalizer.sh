#!/usr/bin/env bash
set -euo pipefail

LOG="/opt/semperfix/logs/linux-normalizer.log"
mkdir -p /opt/semperfix/logs

log() {
    echo "[INFO] $1" | tee -a "$LOG"
}

log "SemperFix Linux Normalizer starting..."

# ---------------------------------------------------------
# 1. Ensure correct interface naming (eth0 or ens*)
# ---------------------------------------------------------
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E 'eth0|ens|enp' | head -n1)

if [[ -z "$IFACE" ]]; then
    log "No suitable network interface found."
else
    log "Using interface: $IFACE"
fi

# ---------------------------------------------------------
# 2. Ensure static IP is present (WSL sometimes drops it)
# ---------------------------------------------------------
EXPECTED_IP="${PHOENIX_LAN_IP:-192.168.1.102}"
CURRENT_IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)

if [[ "$CURRENT_IP" != "$EXPECTED_IP" ]]; then
    log "IP mismatch: expected $EXPECTED_IP, found $CURRENT_IP — correcting..."
    sudo ip addr flush dev "$IFACE"
    sudo ip addr add "$EXPECTED_IP"/24 dev "$IFACE"
else
    log "IP address correct: $CURRENT_IP"
fi

# ---------------------------------------------------------
# 3. Ensure default route exists (WSL drops this often)
# ---------------------------------------------------------
GATEWAY="${PHOENIX_GATEWAY:-192.168.1.1}"
HAS_ROUTE=$(ip route | grep -q "default via $GATEWAY" && echo "yes" || echo "no")

if [[ "$HAS_ROUTE" == "no" ]]; then
    log "Default route missing — adding route via $GATEWAY"
    sudo ip route add default via "$GATEWAY" || true
else
    log "Default route OK"
fi

# ---------------------------------------------------------
# 4. Ensure firewall rules (Phoenix QUIC + Syncthing)
# ---------------------------------------------------------
log "Ensuring firewall rules..."

sudo ufw allow 22000/udp >/dev/null 2>&1 || true
sudo ufw allow 22000/tcp >/dev/null 2>&1 || true
sudo ufw allow 22001/udp >/dev/null 2>&1 || true

log "Firewall rules ensured."

# ---------------------------------------------------------
# 5. Ensure QUIC responder can bind to 22001
# ---------------------------------------------------------
log "Checking QUIC responder port availability..."

if ss -u -l | grep -q ":22001"; then
    log "QUIC responder already bound to 22001."
else
    log "QUIC responder NOT running — restarting service..."
    sudo systemctl restart phoenix-quic-responder.service || log "Responder restart failed."
fi

# ---------------------------------------------------------
# 6. Ensure systemd-resolved DNS stability
# ---------------------------------------------------------
log "Ensuring DNS stability..."

sudo sed -i 's/#DNS=/DNS=1.1.1.1/' /etc/systemd/resolved.conf
sudo sed -i 's/#FallbackDNS=/FallbackDNS=8.8.8.8/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

log "DNS stabilized."

# ---------------------------------------------------------
# 7. Ensure WSL2 network persistence (WSL resets routes)
# ---------------------------------------------------------
if grep -q "WSL" /proc/version; then
    log "WSL detected — applying persistence patch..."

    sudo bash -c "cat >/etc/wsl.conf" <<EOF
[network]
generateResolvConf=false
EOF

    sudo bash -c "echo 'nameserver 1.1.1.1' >/etc/resolv.conf"
    log "WSL network persistence applied."
fi

log "SemperFix Linux Normalizer complete."
