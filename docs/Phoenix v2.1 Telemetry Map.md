Phoenix v2.1 Telemetry Map
Unified Telemetry Architecture · Role‑Aware · Cluster‑Grade
1. Overview
Phoenix v2.1 consolidates all telemetry into a single, role‑aware, cluster‑grade status file:

Code
phoenix-status.json
All other telemetry JSON files are internal, produced by workhorse scripts and consumed by aggregators.

This document maps:

Telemetry producers

Intermediate telemetry

Aggregators

Final output

Role execution matrix

Data flow

Failure propagation

2. Telemetry Producers (Raw Signals)
These scripts generate raw telemetry.
They do not aggregate or interpret roles.

phoenix-heartbeat
Produces:

api_ok

syncthing_ready

peer_connected

quic_ok

mesh_ok

heartbeat_ok (SECONDARY-PASSIVE only)

Writes → phoenix-heartbeat.json

mesh-handshake
Produces:

handshake_status

quic_status

syncthing_api

peer_dump

Writes → mesh-handshake.json

mesh-verify
Produces:

verify_status

Writes → mesh-verify.json

mesh-activate
Produces:

activate_status

Writes → mesh-activate.json

quic-client
Produces:

QUIC reachability

QUIC probe logs

Writes → phoenix-quic-client.log

quic-responder
Produces:

QUIC responder logs

QUIC ack responses

Writes → phoenix-quic-responder.log

3. Intermediate Telemetry Files (Raw → Structured)
These files are not final telemetry.
They are consumed by aggregators.

phoenix-heartbeat.json

phoenix-supervisor.json

mesh-handshake.json

mesh-verify.json

mesh-activate.json

mesh-status.json

4. Aggregators (Role‑Aware)
These scripts combine raw telemetry into structured telemetry.

phoenix-supervisor
Aggregates:

handshake_status

verify_status

activate_status

Writes → phoenix-supervisor.json

mesh-status
Aggregates:

api_ok

peer_connected

handshake_status

verify_status

activate_status

Writes → mesh-status.json

5. Final Aggregator (Cluster‑Grade)
phoenix-status-write
Consumes:

phoenix-heartbeat.json

phoenix-supervisor.json

mesh-status.json

mesh-handshake.json

mesh-verify.json

mesh-activate.json

phoenix-failover.json

Produces:

phoenix-status.json
The single source of truth for:

role

health

mesh

supervisor

failover

degraded state

promotion state

API state

QUIC state

peer connectivity

syncthing readiness

Validated by:

phoenix-status-validate
6. Telemetry Flow Diagram
Code
┌──────────────────────────┐
                │   phoenix-heartbeat.sh   │
└──────────────┬──────────┘
                               ▼
                     phoenix-heartbeat.json
                               │
                               ▼
                ┌──────────────────────────┐
                │    phoenix-supervisor    │
                └──────────────┬──────────┘
                               ▼
                     phoenix-supervisor.json
                               │
                               ▼
                ┌──────────────────────────┐
                │       mesh-handshake     │
                └──────────────┬──────────┘
                               ▼
                       mesh-handshake.json
                               │
                               ▼
                ┌──────────────────────────┐
                │        mesh-verify       │
                └──────────────┬──────────┘
                               ▼
                        mesh-verify.json
                               │
                               ▼
                ┌──────────────────────────┐
                │       mesh-activate      │
                └──────────────┬──────────┘
                               ▼
                       mesh-activate.json
                               │
                               ▼
                ┌──────────────────────────┐
                │        mesh-status       │
                └──────────────┬──────────┘
                               ▼
                        mesh-status.json
                               │
                               ▼
                ┌──────────────────────────┐
                │    phoenix-status-write  │
                └──────────────┬──────────┘
                               ▼
                       phoenix-status.json
7. Role‑Aware Execution Matrix
Role	heartbeat	supervisor	mesh-status	handshake	verify	activate	quic-client	quic-responder
MASTERZERO-ACTIVE	✔	✔	✔	✔	✔	✔	✔	✖
MASTERZERO-DEGRADED	✔	✔	✔	✔	✔	✔	✔	✖
MASTERZERO-RECOVER	✔	✔	✔	✔	✔	✔	✔	✖
SECONDARY-ACTIVE	✔	✔	✔	✔	✔	✔	✔	✖
SECONDARY-PASSIVE	✔	✖	✔	✔	✖	✖	✖	✔
OFFSITE	✔	✖	✔	✔	✖	✖	✖	✖


8. Failure Propagation Model
QUIC failure
heartbeat.quic_ok = false

mesh-status.peer_connected = false

supervisor.activate_status = fail

phoenix-status.health.quic_ok = false

phoenix-status.health.mesh_ok = false

Syncthing API failure
heartbeat.api_ok = false

handshake.syncthing_api = unreachable

mesh-status.api_ok = false

phoenix-status.health.api_ok = false

Supervisor failure
supervisor.* = fail

mesh-status.* = fail

phoenix-status.health.mesh_ok = false

Promotion
phoenix-failover.promoted = true

phoenix-status.role = SECONDARY-ACTIVE

Degraded MASTERZERO
mesh-status.* != pass

phoenix-status.role = MASTERZERO-DEGRADED

9. Summary
Phoenix v2.1 telemetry is:

Unified

Role‑aware

Deterministic

Cluster‑grade

Fully validated

Fully normalized

All telemetry flows into:

Code
phoenix-status.json
And is validated by:

Code
phoenix-status-validate.sh
This is the authoritative cluster health snapshot.