#!/usr/bin/env bash
# use in place of the separate wsl-freeze and wsl-export .sh scripts, run this to execute both in consecutive order
set -e

/opt/semperfix/scripts/wsl-freeze.sh
/opt/semperfix/scripts/wsl-export.sh

echo "Freeze + Export complete."
