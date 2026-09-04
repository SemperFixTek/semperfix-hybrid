#!/bin/bash
set -e

# Load SemperFix environment
source ~/.semperfix/env

# Run bootstrap
pwsh -NoLogo -NoProfile -File "/mnt/c/SemperFix/Tools/mesh-bootstrap.ps1" \
    | sed 's/\r$//' \
    | jq .
