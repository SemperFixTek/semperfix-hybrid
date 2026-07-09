#!/usr/bin/env bash
set -e

echo "=== SemperFix WSL Export Script ==="

FREEZE_DIR="/opt/semperfix/freeze"
WIN_EXPORT_DIR="/mnt/c/SemperFix/Freeze/WSL"

mkdir -p "$WIN_EXPORT_DIR"

# Find newest freeze bundle
LATEST=$(ls -td "$FREEZE_DIR"/* | head -n 1)

if [ -z "$LATEST" ]; then
    echo "No freeze bundles found."
    exit 1
fi

echo "Latest freeze bundle: $LATEST"

echo "Exporting to Windows..."
cp -r "$LATEST" "$WIN_EXPORT_DIR"

echo "Export complete."
echo "Windows location: $WIN_EXPORT_DIR"
