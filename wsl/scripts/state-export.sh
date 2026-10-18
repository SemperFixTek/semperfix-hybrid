#!/usr/bin/env bash
set -euo pipefail

EXPORT_DIR="/var/lib/semperfix/state/export"

cp /var/lib/semperfix/state/phoenix-heartbeat.json "$EXPORT_DIR/" || true
cp /var/lib/semperfix/state/phoenix-supervisor.json "$EXPORT_DIR/" || true
cp /var/lib/semperfix/state/mesh-status.json "$EXPORT_DIR/" || true
cp /var/lib/semperfix/state/quic-client-status.json "$EXPORT_DIR/" || true
cp /var/lib/semperfix/state/phoenix-failover.json "$EXPORT_DIR/" || true
cp /var/lib/semperfix/state/windows-heartbeat.json "$EXPORT_DIR/" || true
