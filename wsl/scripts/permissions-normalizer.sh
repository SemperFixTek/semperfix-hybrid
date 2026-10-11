#!/bin/bash 
# /opt/semperfix/scripts/permissions-normalizer.sh 
set -euo pipefail  

echo "[$(date -Iseconds)] Starting permissions normalization..."  

# Create state directory if missing 
sudo mkdir -p /opt/semperfix/state  

# Ownership — entire tree to sfx:sfx 
sudo chown -R sfx:sfx /opt/semperfix  

# Directory modes 
sudo chmod 750 /opt/semperfix 
for dir in scripts config logs reports monitors units state;
do sudo chmod 750 /opt/semperfix/$dir 
done  

# Script files — executable by owner only 
find /opt/semperfix/scripts -name "*.sh" -exec sudo chmod 740 {} \; 
find /opt/semperfix/monitors -name "*.sh" -exec sudo chmod 740 {} \;  

# Config and log files — readable by group 
find /opt/semperfix/config -name "*.json" -exec sudo chmod 640 {} \; 
find /opt/semperfix/logs -name "*.log" -exec sudo chmod 640 {} \;  
echo "[$(date -Iseconds)] Permissions normalization complete."
