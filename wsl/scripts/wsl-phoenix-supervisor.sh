#!/usr/bin/env bash
set -euo pipefail

# Load Phoenix Core
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

SUPERVISOR_JSON="/opt/semperfix/state/phoenix-supervisor.json"

# Run Handshake
echo "[INFO] Running Phoenix Handshake"
if /opt/semperfix/scripts/wsl-mesh-handshake.sh; then
    HANDSHAKE_STATUS="pass"
else
    HANDSHAKE_STATUS="fail"
fi

# Run Verify
echo "[INFO] Running Phoenix Verify"
if /opt/semperfix/scripts/wsl-mesh-verify.sh; then
    VERIFY_STATUS="pass"
else
    VERIFY_STATUS="fail"
fi

# Run Activation
echo "[INFO] Running Phoenix Activation"
if /opt/semperfix/scripts/wsl-mesh-activate.sh; then
    ACTIVATE_STATUS="pass"
else
    ACTIVATE_STATUS="fail"
fi

# Write Supervisor JSON
mkdir -p /opt/semperfix/state

cat <<EOF > "$SUPERVISOR_JSON"
{
    "timestamp": "$(date -Iseconds)",
    "handshake": "$HANDSHAKE_STATUS",
    "verify": "$VERIFY_STATUS",
    "activate": "$ACTIVATE_STATUS"
}
EOF

echo "[INFO] Supervisor complete"
echo "[INFO] Status written to $SUPERVISOR_JSON"
