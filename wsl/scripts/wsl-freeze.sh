#!/usr/bin/env bash
set -e

echo "=== SemperFix WSL Freeze Script ==="

FREEZE_DIR="/opt/semperfix/freeze"
CONFIG_DIR="/opt/semperfix/config"
SCRIPTS_DIR="/opt/semperfix/scripts"
LOG_DIR="/opt/semperfix/logs"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FREEZE_BUNDLE="$FREEZE_DIR/freeze_$TIMESTAMP"

echo "Creating freeze bundle: $FREEZE_BUNDLE"
mkdir -p "$FREEZE_BUNDLE"

echo "Copying config..."
cp -r "$CONFIG_DIR" "$FREEZE_BUNDLE/config"

echo "Copying scripts..."
cp -r "$SCRIPTS_DIR"