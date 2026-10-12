⭐ Phoenix v2 Architecture Map
High-Level Overview
Phoenix v2 is a hybrid Windows + WSL2 cluster control plane built around:

Syncthing mesh

QUIC signaling

WSL-based cluster logic

Windows-based host health reporting

Unified JSON state

Deterministic failover

Deterministic descalation

WSL is the brain.
Windows is the host health reporter.
SECONDARY is the standby brain.
OFFSITE is the observer.

⭐ Node Roles (Authoritative)
MASTERZERO
Runs all Phoenix logic

Runs all mesh logic

Runs QUIC responder

Runs QUIC client

Runs failover

Runs descalate

Runs supervisor

Runs heartbeat

Writes all cluster JSON

Decides failover

Decides descalation

SECONDARY
Runs all mesh logic

Runs QUIC client

Runs heartbeat

Runs supervisor

Reacts to failover

Never decides failover

Never runs descalate

Never runs QUIC responder

OFFSITE
Runs heartbeat

Runs supervisor

Observes cluster state

Never participates in mesh

Never participates in QUIC

Never participates in failover

Never participates in descalation

⭐ WSL-Side Modules (Authoritative Control Plane)
1. phoenix-core.sh
Loads config

Loads environment

Provides logging

Provides JSON helpers

Provides role + API + peer info

Required by every other module

2. phoenix-heartbeat.sh
Writes:
/var/lib/semperfix/state/phoenix-heartbeat.json

Fields include:

api_ok

mesh_ok

syncthing_ready

quic_ok

peer_connected

timestamp

node_role

Runs on: all nodes

3. phoenix-supervisor.sh
Writes:
/var/lib/semperfix/state/phoenix-supervisor.json

Fields include:

handshake

verify

activate

failover state

mesh state

timestamp

Runs on: all nodes

4. phoenix-status-write.sh
Writes:
/var/lib/semperfix/state/phoenix-status.json

This is the unified cluster state snapshot.

Runs on: all nodes

5. phoenix-failover.sh
Writes:
/var/lib/semperfix/state/phoenix-failover.json

MASTERZERO: decides failover
SECONDARY: reports “handled_by_master”
OFFSITE: reports “not_applicable”

Runs on: MASTERZERO only

6. phoenix-descalate.sh
Writes:
/opt/semperfix/logs/phoenix-descalate.log

MASTERZERO: captures cluster snapshot
SECONDARY/OFFSITE: disabled

Runs on: MASTERZERO only

⭐ Mesh Modules (WSL Only)
1. wsl-mesh-handshake.sh
Initial peer handshake

Writes handshake status

Logs handshake events

2. wsl-mesh-verify.sh
Verifies peer connectivity

Verifies Syncthing readiness

Writes verify status

3. wsl-mesh-activate.sh
MASTERZERO sends QUIC activation

SECONDARY responds

OFFSITE observes

Writes activation status

4. wsl-mesh-listener.sh
MASTERZERO-only

Monitors Syncthing + QUIC

Writes mesh-listener.json

5. wsl-mesh-status.sh
Unified mesh status

Writes mesh-status.json

⭐ QUIC Modules (WSL Only)
1. phoenix-quic-responder.sh
MASTERZERO-only
Listens on: $PHOENIX_QUIC_PORT  
Responds with: ack

2. phoenix-quic-client.sh
Runs on all nodes
Measures:

QUIC reachability

QUIC latency

Writes:
quic-client-status.json

⭐ Windows-Side Modules (Host Health Layer)
1. windows-heartbeat.ps1
Writes:
C:\SemperFix\state\windows-heartbeat.json

Fields include:

syncthing_ok

syncthing_api_ok

quic_22000_ok

windows_firewall_ok

windows_ip

wsl_ip

peer_ip

peer_port

phoenix_quic_port

Runs on: all Windows hosts

2. windows-supervisor.ps1
Writes:
C:\SemperFix\state\windows-supervisor.json

Aggregates:

Windows heartbeat

WSL heartbeat

Windows health

WSL health

QUIC health

Mesh health

Runs on: all Windows hosts

⭐ JSON State Model (Authoritative)
WSL State Directory
/var/lib/semperfix/state/

Contains:

phoenix-heartbeat.json

phoenix-supervisor.json

phoenix-status.json

phoenix-failover.json

mesh-handshake.json

mesh-verify.json

mesh-activate.json

mesh-listener.json

mesh-status.json

quic-client-status.json

Windows State Directory
C:\SemperFix\state\

Contains:

windows-heartbeat.json

windows-supervisor.json

⭐ Windows ↔ WSL Interaction Model
Windows → WSL
windows-heartbeat reads WSL IP

windows-supervisor reads WSL heartbeat

windows-supervisor reads phoenix.json

windows-supervisor reads WSL mesh state

WSL → Windows
WSL writes all cluster state

Windows reads cluster state

Windows never writes cluster state

Windows never decides failover

Windows never runs mesh logic

⭐ Failover Model (Phoenix v2)
MASTERZERO decides failover based on:
WSL heartbeat

WSL supervisor

QUIC client

mesh status

Syncthing API

Windows heartbeat (via windows-supervisor)

SECONDARY reacts
OFFSITE observes
⭐ Descalation Model (Phoenix v2)
MASTERZERO generates the cluster snapshot.
SECONDARY descalates itself only.
OFFSITE does nothing.

⭐ Why This Architecture Works
No split-brain

No duplicate failover logic

No duplicate mesh logic

No Windows-side cluster decisions

Deterministic failover

Deterministic descalation

Unified JSON state

Unified logging

Unified role model

Predictable behavior

Easy to document

Easy to maintain