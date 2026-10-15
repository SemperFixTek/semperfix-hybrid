Phoenix v2 high‑level flow
text
          ┌────────────────────────────┐
          │  MASTERZERO (WSL)         │
          │  NodeRole=MASTERZERO      │
          └────────────┬──────────────┘
                       │
                       │ systemd timers
                       ▼
        ┌────────────────────────────────────┐
        │ Phoenix Supervisor Cycle           │
        │ phoenix-supervisor.sh              │
        │  - wsl-mesh-handshake.sh           │
        │  - wsl-mesh-verify.sh              │
        │  - wsl-mesh-activate.sh            │
        └────────────┬───────────────────────┘
                     │ writes JSON
                     ▼
        ┌────────────────────────────────────┐
        │ Core State JSONs                  │
        │  /var/lib/semperfix/state         │
        │  - mesh-handshake.json            │
        │  - mesh-verify.json               │
        │  - mesh-activate.json             │
        │  - phoenix-supervisor.json        │
        │  - phoenix-heartbeat.json         │
        │  - phoenix-failover.json          │
        │  - mesh-status.json               │
        │  - mesh-listener.json             │
        │  - quic-client-status.json        │
        │  - phoenix-status.json            │
        └────────────────────────────────────┘
All of those JSON files are written via phoenix-json.sh and then normalized by json-perms.sh so Syncthing + Windows can read them.

Script roles and responsibilities
Core utilities
phoenix-core.sh

Exports: STATE_DIR, LOG_DIR, NODE_ROLE, API_URL, PEER_IP, PEER_PORT, PHOENIX_QUIC_PORT

Provides: phoenix_init, phoenix_log_file

phoenix-json.sh

Provides: json_init, json_set, json_set_raw, json_finalize

json-perms.sh

Fixes: ownership + permissions for JSON artifacts

Mesh lifecycle (MASTERZERO + SECONDARY)
wsl-mesh-handshake.sh

Discovers peers, writes mesh-handshake.json

wsl-mesh-verify.sh

Checks Syncthing API, device IDs, folder health, writes mesh-verify.json

wsl-mesh-activate.sh

MASTERZERO: readiness (API + QUIC), sends QUIC activation probe, writes mesh-activate.json

SECONDARY/OFFSITE: role‑appropriate activation status

phoenix-supervisor.sh

Orchestrates: handshake → verify → activate

Writes phoenix-supervisor.json with:

handshake_status, verify_status, activate_status

backward‑compat fields: handshake, verify, activate

Health + heartbeat + failover
phoenix-heartbeat.sh (you referenced it via HB JSON)

Periodic health snapshot: API, mesh, QUIC, etc.

Writes phoenix-heartbeat.json

mesh-status.sh

Lightweight status: API ping + connections

Writes mesh-status.json

mesh-listener.sh (MASTERZERO)

Continuous Syncthing + QUIC reachability

Writes mesh-listener.json

quic-client.sh (MASTERZERO)

QUIC reachability + latency probe to SECONDARY

Writes quic-client-status.json

quic-responder.sh (SECONDARY)

Listens on PHOENIX_QUIC_PORT, responds to probes

Writes responder logs

phoenix-failover.sh (MASTERZERO)

Reads phoenix-heartbeat.json

Decides failover_needed → writes phoenix-failover.json

Unified status + validation
phoenix-status-write.sh

Reads:

phoenix-heartbeat.json

phoenix-supervisor.json

Writes single canonical status: phoenix-status.json:

.meta → version, timestamp, generator

.node → role, API URL, peer target

.health → api_ok, peer_connected, syncthing_ready, quic_ok, mesh_ok

.supervisor → handshake, verify, activate

phoenix-json-validate.sh

Validates phoenix-status.json structure + fields

phoenix-status-validate.sh

Also validates phoenix-status.json (schema + booleans + supervisor statuses)

These two validators are your “contract enforcers” for the Phoenix v2 JSON schema.

Logging + descalation
phoenix-descalate.sh (MASTERZERO)

Snapshot of last 20 lines from:

phoenix-heartbeat.log

phoenix-supervisor.log

Writes phoenix-descalate.log for post‑incident review

Cross‑boundary flow (Windows ↔ WSL ↔ Syncthing)
text
[WSL /opt/semperfix/scripts/*]
        │
        │ write JSON → json_finalize → json-perms
        ▼
[WSL /var/lib/semperfix/state/*.json]
        │
        │ Syncthing (sfx-admin) syncs state dir
        ▼
[Windows host: synced SemperFix state]
        │
        │ dashboards / tools / PowerShell read phoenix-status.json
        ▼
[Operator view: Phoenix v2 cluster health]