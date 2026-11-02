#!/usr/bin/env bash 

# =====================================================================
# Phoenix Automation Suite — permissions reset v1
# Version: Phoenix v2.1
# Component: permissions-reset-v1
# Role: Controller / Responder
# Refactor: 2026-10-25
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail  

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

echo "[$(date -Iseconds)] Starting permissions normalization..."  

# Create state directory if missing 
sudo mkdir -p /opt/semperfix/state  

# Ownership — entire tree to root:semperfix 
sudo chown -R root:semperfix /opt/semperfix  

# Directory modes 
sudo chmod 775 /opt/semperfix 
for dir in scripts config logs reports monitors units state;
do sudo chmod 775 /opt/semperfix/$dir 
done  

# Script files — executable by owner only 
find /opt/semperfix/scripts -name "*.sh" -exec sudo chmod 775 {} \; 
find /opt/semperfix/monitors -name "*.sh" -exec sudo chmod 775 {} \;  

# Config and log files — readable by group 
find /opt/semperfix/config -name "*.json" -exec sudo chmod 775 {} \; 
find /opt/semperfix/logs -name "*.log" -exec sudo chmod 775 {} \;  
echo "[$(date -Iseconds)] Permissions normalization complete."
