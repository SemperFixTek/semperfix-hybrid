#!/bin/bash
set -e

# Load SemperFix environment
source ~/.semperfix/env

# Run status
pwsh -NoLogo -NoProfile -File "/mnt/c/SemperFix/Tools/mesh-status.ps1" \
    | sed 's/\r$//' \
    | jq .
