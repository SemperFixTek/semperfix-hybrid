#!/bin/bash
set -e

# Load SemperFix environment
source ~/.semperfix/env

# Run verify
pwsh -NoLogo -NoProfile -File "/mnt/c/SemperFix/Tools/mesh-verify.ps1" \
    | sed 's/\r$//' \
    | jq .
