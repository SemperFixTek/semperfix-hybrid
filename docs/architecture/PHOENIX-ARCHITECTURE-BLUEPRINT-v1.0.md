Phoenix Architecture Blueprint v1.0
1. Purpose
Phoenix is the SemperFix failover + role‑management engine. It validates node identity, simulates failover, executes failover, logs events, and monitors health across Windows + WSL.

2. Core Components
Windows Phoenix Core
phoenix-role-check.ps1 — reads/validates NodeRole.

phoenix-dryrun.ps1 — runs full failover pipeline in safe mode.

phoenix-escalate.ps1 — logs structured Phoenix events.

phoenix-failover.ps1 — conceptual role‑based failover actions.

phoenix-recover.ps1 — placeholder for normalization engine.

phoenix-watchdog.ps1 — 2‑minute heartbeat; health + escalation.

WSL Phoenix Mirror
wsl-phoenix-dryrun.sh — mirrors Windows dry-run; validates cross‑layer behavior.

3. Role Model
Phoenix roles:

MASTERZERO — primary; promotes SECONDARY.

SECONDARY — standby; relies on MASTERZERO/OFFSITE.

OFFSITE — tertiary; continuity only.

Roles are config-driven today; future versions determine roles dynamically.

4. Failover Pipeline
Role Check

Escalation Event

Failover Simulation or Execution

Recovery (future)

Lineage Logging

Dry-run runs the same pipeline with -DryRun.

5. Watchdog Model
Runs every 2 minutes:

Calls node-status.ps1

Logs escalation on failure

Logs escalation if Syncthing API unhealthy

Future: mesh, syncthing, WSL, Windows, drift detection

6. Event Model
Phoenix events contain:

NodeRole

Stage

Reason

Timestamp

Errors

Future additions:

EventType

Severity

EventID

NodeIdentity

Payload

7. Future Phoenix Core
Phoenix evolves into a state machine:

Inputs
Mesh health
Syncthing health
Windows/WSL health
Drift detection
Role consistency
Config consistency

Outputs
ProposedRole
FailoverReady
RecoveryPlan
Unified JSON reports
API + GUI feeds

8. API Layer (Planned)
GET /phoenix/status

POST /phoenix/dryrun

POST /phoenix/failover

POST /phoenix/recover

GET /phoenix/events

GET /phoenix/health

9. GUI Layer (Planned)
Node cards

Mesh topology

Syncthing state

Health dashboard

Drift dashboard

Event timeline

Dry-run + failover buttons

10. Summary
Phoenix v1.0 is a modular, event-driven, hybrid failover engine.
Windows = orchestration + decision.
WSL = execution + validation.
Future = full state machine + API + GUI.