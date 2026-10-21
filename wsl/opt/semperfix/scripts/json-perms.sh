#!/usr/bin/env bash
set -euo pipefail

target="$1"

chown root:semperfix "$target"
chmod 664 "$target"
