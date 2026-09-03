#!/bin/bash
set -e

# Load SemperFix environment
source ~/.semperfix/env

# Run handshake
pwsh -NoLogo -NoProfile -File "/mnt/c/SemperFix/Tools/mesh-handshake.ps1" \
    | sed 's/\r$//' \
    | jq .
