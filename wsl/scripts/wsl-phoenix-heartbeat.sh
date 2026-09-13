#!/bin/bash

HB="/mnt/c/SemperFix/ConfigBackup/phoenix-heartbeat.json"

echo "{\"Alive\":true,\"Timestamp\":\"$(date -Iseconds)\"}" > "$HB"
cat "$HB"
