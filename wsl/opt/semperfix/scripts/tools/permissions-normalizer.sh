#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — permissions normalizer
# Version: Phoenix v2.1
# Component: permissions-normalizer
# Role: Monitor / Controller
# Refactor: 2026-10-30
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -e

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

echo "=== SemperFix Permissions Normalizer Script ==="

# -----------------------------
# CONFIG
# -----------------------------
SFX_USER="sfx"
SFX_GROUP="semperfix"

# -----------------------------
# Ensure group exists
# -----------------------------
if ! getent group "$SFX_GROUP" >/dev/null; then
    echo "[+] Creating group: $SFX_GROUP"
    sudo groupadd "$SFX_GROUP"
else
    echo "[=] Group $SFX_GROUP already exists"
fi

# -----------------------------
# Add user to group
# -----------------------------
echo "[+] Adding $SFX_USER to $SFX_GROUP"
sudo usermod -aG "$SFX_GROUP" "$SFX_USER"

# -----------------------------
# Fix /opt permissions
# -----------------------------
echo "[+] Setting /opt to root:root and mode 755"
sudo chown root:root /opt
sudo chmod 755 /opt

# -----------------------------
# Fix SemperFix directories
# -----------------------------
SFX_DIRS=(
    "/opt/semperfix"
    "/opt/semperfix/scripts"
    "/opt/semperfix/logs"
    "/opt/semperfix/monitors"
    "/opt/semperfix/units"
    "/opt/semperfix/config"
    "/opt/semperfix/state"
    "/opt/semperfix/dashboard"
    "/opt/semperfix/dashboard/templates"
    "/var/lib/semperfix"
    "/var/lib/semperfix/state"
    "/var/lib/semperfix/state/secondary"
    "/var/lib/semperfix/state/transfer"
)

for DIR in "${SFX_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        echo "[+] Fixing $DIR"
        sudo chown -R root:"$SFX_GROUP" "$DIR"
        sudo chmod -R 775 "$DIR"
    else
        echo "[!] Directory missing: $DIR"
    fi
done

# -----------------------------
# Normalize JSON file permissions
# -----------------------------
echo "[+] Normalizing JSON file permissions in /var/lib/semperfix/state"
sudo find /var/lib/semperfix/state -type f -name "*.json" -exec chown root:semperfix {} \;
sudo find /var/lib/semperfix/state -type f -name "*.json" -exec chmod 775 {} \;

# -----------------------------
# Normalize LOG file permissions
# -----------------------------
echo "[+] Normalizing LOG file permissions in /opt/semperfix/logs"
sudo find /opt/semperfix/logs -type f -name "*.log" -exec chown root:semperfix {} \;
sudo find /opt/semperfix/logs -type f -name "*.log" -exec chmod 775 {} \;


# -----------------------------
# Summary
# -----------------------------
echo ""
echo "=== Final Permissions Report ==="
for DIR in "${SFX_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        echo ""
        echo ">>> $DIR"
        ls -ld "$DIR"
    fi
done

echo ""
echo "=== SemperFix Permissions Reset Complete ==="
echo "Log out and back in to ensure group membership is active."
