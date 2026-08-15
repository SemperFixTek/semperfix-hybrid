SemperFix-Hybrid — Repo Integration Map

 :root { color-scheme: light only; }

 body {
 font-family: Calibri, sans-serif;
 font-size: 11pt;
 line-height: 1.5;
 color: #1a1a1a;
 background: #ffffff;
 max-width: 816px;
 margin: 0 auto;
 padding: 72px;
 }

 h1 { font-family: Calibri, sans-serif; font-size: 26pt; font-weight: bold; color: #0d2b4e; margin-top: 24pt; margin-bottom: 6pt; }
 h2 { font-family: Calibri, sans-serif; font-size: 16pt; font-weight: bold; color: #0d2b4e; margin-top: 20pt; margin-bottom: 4pt; border-bottom: 2px solid #0d2b4e; padding-bottom: 3pt; }
 h3 { font-family: Calibri, sans-serif; font-size: 13pt; font-weight: bold; color: #1a3a5c; margin-top: 14pt; margin-bottom: 4pt; }
 h4 { font-family: Calibri, sans-serif; font-size: 11pt; font-weight: bold; color: #1a1a1a; margin-top: 10pt; margin-bottom: 3pt; }
 p { margin-top: 0; margin-bottom: 7pt; }

 table { border-collapse: collapse; width: 100%; margin: 10pt 0 14pt 0; font-size: 9.5pt; }
 th { font-weight: bold; background-color: #0d2b4e; color: #ffffff; padding: 6px 8px; text-align: left; vertical-align: top; border: 1px solid #0d2b4e; }
 td { border: 1px solid #b0b8c4; padding: 5px 8px; text-align: left; vertical-align: top; }
 tr:nth-child(even) td { background-color: #f0f4f8; }
 tr:nth-child(odd) td { background-color: #ffffff; }

 ul, ol { margin: 6pt 0; padding-left: 36px; }
 li { margin-bottom: 4pt; }

 code, pre {
 font-family: Consolas, monospace;
 font-size: 9pt;
 background-color: #f4f4f4;
 color: #1a1a1a;
 }
 pre {
 padding: 10px 14px;
 border: 1px solid #cccccc;
 margin: 10pt 0;
 white-space: pre;
 overflow-x: auto;
 line-height: 1.4;
 }

 /*Metadata callout*/
 .meta-callout {
 border: 2px solid #0d2b4e;
 background-color: #e8eff7;
 padding: 12px 16px;
 margin-bottom: 18pt;
 }
 .meta-callout table { margin: 0; font-size: 10pt; }
 .meta-callout th { background-color: #0d2b4e; color: #ffffff; font-size: 10pt; }
 .meta-callout td { border: 1px solid #9ab0cc; background-color: transparent; }
 .meta-callout tr:nth-child(even) td { background-color: #dce8f5; }
 .meta-callout tr:nth-child(odd) td { background-color: #e8eff7; }

 /*Layer accent strips*/
 .layer-strip {
 padding: 7px 14px;
 margin: 16pt 0 8pt 0;
 font-family: Calibri, sans-serif;
 font-size: 10.5pt;
 font-weight: bold;
 color: #ffffff;
 }
 .layer-windows { background-color: #1a5296; }
 .layer-wsl { background-color: #b85c00; }
 .layer-syncthing { background-color: #1a7a3a; }
 .layer-phoenix { background-color: #8b1a1a; }
 .layer-mesh { background-color: #5b2082; }
 .layer-golden { background-color: #8a6b00; }
 .layer-docs { background-color: #3a4a5c; }

 /*Left-border section callout*/
 .section-callout {
 border-left: 5px solid #cccccc;
 padding: 8px 14px;
 margin: 10pt 0;
 background-color: #fafafa;
 }
 .callout-windows { border-left-color: #1a5296; background-color: #eef3fa; }
 .callout-wsl { border-left-color: #b85c00; background-color: #fdf3ea; }
 .callout-syncthing { border-left-color: #1a7a3a; background-color: #edf7f0; }
 .callout-phoenix { border-left-color: #8b1a1a; background-color: #faeaea; }
 .callout-mesh { border-left-color: #5b2082; background-color: #f3eefa; }
 .callout-golden { border-left-color: #8a6b00; background-color: #faf6e8; }
 .callout-docslayer { border-left-color: #3a4a5c; background-color: #eef0f3; }

 /* Warning box */
 .warning-box {
 border: 2px solid #8b1a1a;
 background-color: #fdf0f0;
 padding: 9px 14px;
 margin: 10pt 0;
 font-size: 10pt;
 }
 .warning-box strong { color: #8b1a1a; }

 /* Note box */
 .note-box {
 border: 1px solid #8a6b00;
 background-color: #faf6e4;
 padding: 8px 14px;
 margin: 10pt 0;
 font-size: 10pt;
 }

 /* Title block */
 .title-block {
 border-top: 5px solid #0d2b4e;
 border-bottom: 2px solid #0d2b4e;
 padding: 18px 0 14px 0;
 margin-bottom: 20pt;
 }
 .title-block h1 { margin-top: 0; margin-bottom: 4pt; font-size: 28pt; }
 .title-block .subtitle {
 font-size: 12pt;
 color: #3a5a80;
 font-style: italic;
 margin-bottom: 0;
 }

 /* Layer row group label in big matrix table */
 .row-group td {
 background-color: #0d2b4e;
 color: #ffffff;
 font-weight: bold;
 font-size: 10pt;
 padding: 5px 8px;
 }
 .row-group-wsl td { background-color: #b85c00; }
 .row-group-sync td { background-color: #1a7a3a; }
 .row-group-phoenix td { background-color: #8b1a1a; }
 .row-group-mesh td { background-color: #5b2082; }
 .row-group-golden td { background-color: #8a6b00; }
 .row-group-docslay td { background-color: #3a4a5c; }

 /* Quick ref two-column table */
 .qr-table td { font-size: 9.5pt; vertical-align: top; }
 .qr-label { font-weight: bold; color: #0d2b4e; }

 /* Sequence table */
 .seq-table th { background-color: #1a3a5c; }

 /* Numbered conventions list */
 ol.conventions li { margin-bottom: 7pt; }
 ol.conventions li strong { color: #0d2b4e; }

 .page-break { page-break-before: always; }

 @media print { body { padding: 0; max-width: none; } }


# SemperFix-Hybrid — Repo Integration Map

Architectural Integration Map  |  Layer-by-Layer File and Directory Registry

| Document Metadata |
| --- |
| **Project** | SemperFix-Hybrid |
| **Version** | v0.1.3-alpha |
| **Document Type** | Architectural Integration Map |
| **Maintained In** | `docs/architecture/ARCHITECTURE.md` |
| **Last Updated** | August 13, 2026 |
| **Author** | Bruce Bergdahl |
| **Classification** | Internal Reference |

## Section 1 — Architecture Overview

SemperFix-Hybrid is a three-machine Windows 10 deployment using WSL2 (Ubuntu) as an execution companion layer. The system integrates Syncthing for file transport, Phoenix for failover orchestration, and a Mesh layer for cross-node coordination. Every file in the repository belongs to exactly one canonical architectural layer. This document is the authoritative mapping of all files, scripts, configurations, and directories to their respective layers, paths, and node scopes. No file assignment is ambiguous — if a placement question arises, this document and `file-placement-matrix.md` are the arbiters of record.

### 1.1 Layer Stack Diagram

```

┌──────────────────────────────────────────────────────┐
│                 WINDOWS HOST LAYER                   │
│   PowerShell Scripts · Task Scheduler XML · Config   │
│  ┌────────────────────────────────────────────────┐  │
│  │              WSL EXECUTION LAYER               │  │
│  │  Bash Scripts · Cron Jobs · Python Validators  │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │           SYNCTHING TRANSPORT LAYER            │  │
│  │  syncthing.exe · Folder Config · .stignore     │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │             PHOENIX CORE LAYER                 │  │
│  │  Watchdog · Recovery · Role-Check · Failover   │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │          MESH ORCHESTRATION LAYER              │  │
│  │  Bootstrap · Handshake · Verify · Activate     │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │          GOLDEN TEMPLATE LINEAGE               │  │
│  │  Ubuntu.tar Export · VM Snapshot · NodeRole    │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │              DOCUMENTATION LAYER               │  │
│  │  ARCHITECTURE.md · BLUEPRINT.md · Vault Docs   │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘

```

### 1.2 Node Role Definitions

| Node Hostname | Role Name | NodeRole Value | Function |
| --- | --- | --- | --- |
| **SemperFix-Primary** | MASTERZERO | `"MASTERZERO"` | Authoritative source; Send Only for MasterZero & ConfigBackup |
| **SemperFix-Secondary** | SECONDARY | `"SECONDARY"` | Local receiver; Receive Only for MasterZero; Send+Receive for Assets |
| **SemperFix-Offsite** | OFFSITE | `"OFFSITE"` | Offsite backup; identical role to Secondary; different network segment |

Layer 1 — Windows Host  |  The substrate layer: PowerShell automation, Task Scheduler, and per-node configuration
## Section 2 — Layer 1: Windows Host

The substrate layer. All PowerShell automation, Task Scheduler XML definitions, and per-node configuration live here. Location: `C:\SemperFix\Tools\` on every node.

### 2.1 PowerShell Scripts — Automation Core

Sixteen PowerShell scripts form the complete Windows automation layer. All nodes must carry identical copies. These scripts are the operational backbone of the SemperFix-Hybrid system — they orchestrate every subsystem from Syncthing validation to Phoenix failover to Mesh coordination.

| File | Path | Purpose | Trigger | Node Scope |
| --- | --- | --- | --- | --- |
| `semperfix-windows-automation.ps1` | `C:\SemperFix\Tools\` | Master automation entry point; orchestrates all subsystems | Scheduled Task (SemperFix-Automation.xml) | All Nodes |
| `syncthing-api.ps1` | `C:\SemperFix\Tools\` | Syncthing REST API wrapper; validates key, port, JSON response integrity | Called by automation master | All Nodes |
| `node-status.ps1` | `C:\SemperFix\Tools\` | Reports per-node status snapshot; used in pre-freeze validation | Manual / Watchdog | All Nodes |
| `log-collector.ps1` | `C:\SemperFix\Tools\` | Aggregates Windows + WSL logs; ensures logs accessible from Windows side | Manual / Scheduled | All Nodes |
| `service-wrapper.ps1` | `C:\SemperFix\Tools\` | Generic Windows service lifecycle wrapper | Called by automation | All Nodes |
| `phoenix-watchdog.ps1` | `C:\SemperFix\Tools\` | Continuously monitors Phoenix health; triggers recovery on failure | Scheduled Task (Phoenix-Watchdog.xml) | All Nodes |
| `phoenix-recover.ps1` | `C:\SemperFix\Tools\` | Executes Phoenix recovery sequence | Called by watchdog | All Nodes |
| `phoenix-role-check.ps1` | `C:\SemperFix\Tools\` | Validates NodeRole assignment is correct for this machine | Called by Phoenix suite | All Nodes |
| `phoenix-escalate.ps1` | `C:\SemperFix\Tools\` | Escalates Phoenix alert to next severity level | Called by watchdog | All Nodes |
| `phoenix-failover.ps1` | `C:\SemperFix\Tools\` | Executes controlled failover to Secondary or Offsite node | Called on escalation | All Nodes |
| `phoenix-dryrun.ps1` | `C:\SemperFix\Tools\` | Simulates full escalation → failover → recovery without touching live services | Manual / Pre-freeze validation | All Nodes |
| `mesh-bootstrap.ps1` | `C:\SemperFix\Tools\` | Collects system status; prepares mesh coordination layer | Mesh activation sequence | All Nodes |
| `mesh-handshake.ps1` | `C:\SemperFix\Tools\` | Collects device connection status across nodes | Mesh activation sequence | All Nodes |
| `mesh-verify.ps1` | `C:\SemperFix\Tools\` | Validates folder sync state; checks globalBytes vs. inSyncBytes | Mesh activation sequence | All Nodes |
| `mesh-activate.ps1` | `C:\SemperFix\Tools\` | Full mesh activation: runs bootstrap → handshake → verify in sequence | Manual / Post-bootstrap | All Nodes |
| `mesh-status.ps1` | `C:\SemperFix\Tools\` | Real-time mesh health snapshot; confirms all devices connected, all folders in sync, no errors | Health monitoring | All Nodes |

### 2.2 Task Scheduler XML Definitions

Three Scheduled Task XML files that must run under the SYSTEM account with highest privileges. These are the heartbeat of the automation layer — without them, the automation cycle does not execute.

| File | Path | Task Name | Schedule | Privilege | Purpose |
| --- | --- | --- | --- | --- | --- |
| `SemperFix-Automation.xml` | `C:\SemperFix\Tools\` | SemperFix Automation | Every 15 minutes | SYSTEM / Highest | Invokes `semperfix-windows-automation.ps1`; drives the entire automation cycle |
| `Phoenix-Watchdog.xml` | `C:\SemperFix\Tools\` | Phoenix-Watchdog | Continuous / Event-triggered | SYSTEM / Highest | Invokes `phoenix-watchdog.ps1`; monitors Phoenix health continuously |
| `Mesh-Status-Snapshot.xml` | `C:\SemperFix\Tools\` | Mesh-Status-Snapshot | Scheduled interval | SYSTEM / Highest | Invokes `mesh-status.ps1`; captures mesh state snapshots |

### 2.3 Per-Node Configuration File

**Important:** This is the *only* file that changes between nodes. All other files in `C:\SemperFix\Tools\` are identical across MASTERZERO, SECONDARY, and OFFSITE. Any script divergence between nodes is a defect.

| File | Path | Key Fields | Per-Node Value | Notes |
| --- | --- | --- | --- | --- |
| `semperfix-config.json` | `C:\SemperFix\Tools\` | ApiKey, BaseUrl, NodeRole | NodeRole changes per machine | ApiKey and BaseUrl are typically identical; NodeRole is the only differentiator between MASTERZERO / SECONDARY / OFFSITE |

### 2.4 Runtime Folder Tree

The Windows runtime folder structure created on all nodes. The `MasterZero` folder exists only on the Primary machine.

```

C:\SemperFix\
├── syncthing\
│   ├── syncthing.exe         ← Syncthing binary
│   └── config\               ← Syncthing configuration home
├── Tools\
│   ├── *.ps1                 ← All 16 PowerShell scripts
│   ├── *.xml                 ← 3 Scheduled Task definitions
│   └── semperfix-config.json ← Per-node config (only file that differs)
├── MasterZero\               ← Primary only (Send Only source)
├── Assets\                   ← All nodes (Send & Receive)
├── ConfigBackup\             ← All nodes (Send Only on Primary; Receive Only on Secondary/Offsite)
└── package\
    ├── config\
    │   └── SyncthingCloneExport.json
    └── scripts\
        ├── *.sh              ← WSL-side scripts (staged here, executed in WSL)
        └── validate-config.py

```

Layer 2 — WSL Execution  |  The execution layer: bash automation, health checking, Python validation, and cron scheduling
## Section 3 — Layer 2: WSL Execution

The execution layer. All bash automation, health checking, Python validation, and cron scheduling runs inside WSL2 (Ubuntu). WSL scripts act as a lightweight companion to the Windows PowerShell layer — they call Windows scripts via PowerShell interop and validate local configuration state. WSL is installed as standard policy on all three machines. WSL filesystem is accessed from Windows at the `/mnt/c/` mount point.

### 3.1 WSL Companion Scripts

Location: `/opt/semperfix/scripts/`

| File | Path | Paired Windows Script | Purpose | Trigger |
| --- | --- | --- | --- | --- |
| `wsl-phoenix-dryrun.sh` | `/opt/semperfix/scripts/` | `phoenix-dryrun.ps1` | WSL-side Phoenix dry-run; ensures WSL can coordinate with Windows Phoenix modules | Manual / Pre-freeze validation |
| `wsl-mesh-bootstrap.sh` | `/opt/semperfix/scripts/` | `mesh-bootstrap.ps1` | WSL mesh bootstrap; ensures WSL and Windows see the same system state | Mesh activation sequence |
| `wsl-mesh-handshake.sh` | `/opt/semperfix/scripts/` | `mesh-handshake.ps1` | WSL handshake logging; confirms cross-layer consistency | Mesh activation sequence |
| `wsl-mesh-verify.sh` | `/opt/semperfix/scripts/` | `mesh-verify.ps1` | WSL sync state verification; confirms WSL sees same folder sync state as Windows | Mesh activation sequence |
| `wsl-mesh-activate.sh` | `/opt/semperfix/scripts/` | `mesh-activate.ps1` | WSL full mesh activation mirror; WSL mirrors Windows activation sequence | Manual / Post-bootstrap |
| `wsl-health-check.sh` | `/opt/semperfix/scripts/` | `node-status.ps1` | WSL-side health check; validates local config and Syncthing connectivity | Cron (daily) / Manual |
| `wsl-config-validate.py` | `/opt/semperfix/scripts/` | — (Python; no PS1 pair) | Python config validator; checks Syncthing config JSON for errors before pairing | Manual / Pre-freeze validation |

### 3.2 WSL Environment & Cron Configuration

| Artifact | Path | Purpose | Notes |
| --- | --- | --- | --- |
| `.semperfix/env` | `~/.semperfix/env` | Runtime environment variables loaded by all scripts | chmod 600; sourced by cron before each execution; contains SEMPERFIX\_ST\_APIKEY, SEMPERFIX\_LOG\_DIR, SEMPERFIX\_SYNC\_ROOT, SEMPERFIX\_BACKUP\_DEST |
| crontab (WSL) | User crontab via `crontab -e` | Schedules automation.sh every 15 min; backup-config.sh at 2am daily | Must source `~/.semperfix/env` before each invocation |
| `/opt/semperfix/logs/` | `/opt/semperfix/logs/` | WSL-side log output directory | Includes `wsl-phoenix-dryrun.log` and per-script logs |

### 3.3 Python Validator

| File | Path | Invocation | Purpose |
| --- | --- | --- | --- |
| `validate-config.py` | `C:\SemperFix\package\scripts\` (Windows)`/mnt/c/SemperFix/package/scripts/` (WSL) | `python validate-config.py --config SyncthingCloneExport.json` | Validates `SyncthingCloneExport.json` for zero red errors before any pairing begins; requires Python 3.9+ |

Layer 3 — Syncthing Transport  |  The transport layer: file synchronization backbone with enforced asymmetric topology
## Section 4 — Layer 3: Syncthing Transport

The transport layer. Syncthing provides the file synchronization backbone of SemperFix. The topology is deliberately asymmetric — sync direction is enforced by folder type settings, not convention.

### 4.1 Syncthing Binary & Config

| Artifact | Path | Purpose | Notes |
| --- | --- | --- | --- |
| `syncthing.exe` | `C:\SemperFix\syncthing\` | Core sync daemon; must run as background process from command line, not GUI-only | Auto-started via Windows Startup shortcut on all nodes |
| Startup shortcut | `shell:startup\` | Ensures `syncthing.exe --no-browser --home=C:\SemperFix\syncthing\config` starts automatically on Windows boot | Created on all three machines |
| Syncthing config dir | `C:\SemperFix\syncthing\config\` | Syncthing's home directory; stores device certificates, config.xml | Set via `--home` flag at launch |
| GUI / API endpoint | `http://127.0.0.1:8384` | Local web UI and REST API; API key stored in `.semperfix/env` | Validated by `syncthing-api.ps1` and `node-status.ps1` |

### 4.2 Folder Configuration & Sync Topology

Three synced folders with strictly enforced directional roles. Getting folder types wrong is the most common failure mode in a SemperFix deployment.

| Folder Label | Folder ID | Windows Path | Primary Type | Secondary Type | Offsite Type | Sync Direction | Purpose |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Master Zero** | `master-zero` | `C:\SemperFix\MasterZero\` | Send Only | Receive Only | Receive Only | Primary → Secondary, Primary → Offsite (one-way) | Authoritative content distribution; files flow out from Primary only; edits on Secondary/Offsite are reverted |
| **SemperFix Assets** | `semperfix-assets` | `C:\SemperFix\Assets\` | Send & Receive | Send & Receive | Send & Receive | Bidirectional (all nodes) | Shared assets that can be changed from any node; changes propagate in all directions |
| **SemperFix Config Backup** | `semperfix-config-backup` | `C:\SemperFix\ConfigBackup\` | Send Only | Receive Only | Receive Only | Primary → Secondary, Primary → Offsite (one-way) | Config backup distribution; backups are pushed from Primary to receivers |

**⚠ Direction Matters —** These are enforced by Syncthing folder type settings, not convention. If Master Zero or Config Backup is accidentally set to Send & Receive on any node, files can flow backwards and overwrite Primary content. Verify folder types after every node provisioning step.

### 4.3 Ignore Pattern Files (.stignore)

| File | Applied To Folder | Staged Location | Purpose |
| --- | --- | --- | --- |
| `master-zero.stignore` | Master Zero | `C:\SemperFix\package\config\` | Excludes temporary files, OS artifacts, and non-content files from MasterZero sync |
| `media.stignore` | SemperFix Assets | `C:\SemperFix\package\config\` | Excludes transient media artifacts and cache files from Assets sync |
| `global.stignore` | SemperFix Config Backup | `C:\SemperFix\package\config\` | Applies global exclusions to ConfigBackup; prevents log and temp file backup |

### 4.4 Syncthing Configuration Export

| File | Path | Purpose | Key Fields | Pre-Pairing Requirement |
| --- | --- | --- | --- | --- |
| `SyncthingCloneExport.json` | `C:\SemperFix\package\config\` | Master config template with device ID placeholders; must be filled in before pairing | `_variables` block: DEVICE\_PRIMARY, DEVICE\_SECONDARY, DEVICE\_OFFSITE; offsite address `tcp://offsite.semperfix.local:22000` | Must pass `validate-config.py` with zero red errors before pairing any machine |

Layer 4 — Phoenix Core  |  The resilience layer: watchdog monitoring, escalation, recovery, failover, and role validation
## Section 5 — Layer 4: Phoenix Core

The resilience layer. Phoenix manages watchdog monitoring, escalation, recovery, failover, and role validation. Phoenix scripts always run as paired Windows + WSL executions to ensure cross-layer consistency. Log output from both layers is validated before any freeze or deployment action.

### 5.1 Phoenix Windows Scripts

| Script | Path | Role in Phoenix Sequence | Log Output | Invocation Order |
| --- | --- | --- | --- | --- |
| `phoenix-watchdog.ps1` | `C:\SemperFix\Tools\` | Monitors Phoenix health continuously; triggers recovery or escalation on failure | `C:\SemperFix\Tools\phoenix-watchdog.log` | Runs continuously via Phoenix-Watchdog.xml scheduled task |
| `phoenix-role-check.ps1` | `C:\SemperFix\Tools\` | Validates NodeRole value matches this node's expected identity | — | Called at startup and by watchdog |
| `phoenix-recover.ps1` | `C:\SemperFix\Tools\` | Executes recovery sequence; attempts to restore normal operation before escalation | — | Called by watchdog before escalation |
| `phoenix-escalate.ps1` | `C:\SemperFix\Tools\` | Increments alert severity; prepares for failover | — | Called by watchdog on repeated failure |
| `phoenix-failover.ps1` | `C:\SemperFix\Tools\` | Initiates controlled failover to Secondary or Offsite | — | Called after escalation threshold is reached |
| `phoenix-dryrun.ps1` | `C:\SemperFix\Tools\` | Full simulation of escalation → failover → recovery; touches no live services | `C:\SemperFix\Tools\phoenix-dryrun.log` | Manual / Pre-freeze validation (Step 1 of Phoenix activation checklist) |

### 5.2 Phoenix WSL Companion Script

| Script | Path | Windows Counterpart | Purpose | Log Output |
| --- | --- | --- | --- | --- |
| `wsl-phoenix-dryrun.sh` | `/opt/semperfix/scripts/` | `phoenix-dryrun.ps1` | WSL-side Phoenix dry-run; confirms WSL can coordinate with Windows Phoenix layer | `/opt/semperfix/logs/wsl-phoenix-dryrun.log` |

### 5.3 Phoenix Log Validation

After every dry-run, both logs must be checked before proceeding to any deployment or freeze action. A clean dry-run on only one side is insufficient — both must pass.

| Log File | Side | Expected Condition |
| --- | --- | --- |
| `C:\SemperFix\Tools\phoenix-dryrun.log` | Windows | Confirms Windows layer executed escalation → failover → recovery simulation cleanly |
| `/opt/semperfix/logs/wsl-phoenix-dryrun.log` | WSL | Confirms WSL layer coordinated correctly with Windows Phoenix modules |

Layer 5 — Mesh Orchestration  |  The coordination layer: cross-node state awareness with deterministic activation sequence
## Section 6 — Layer 5: Mesh Orchestration

The coordination layer. Mesh scripts coordinate cross-node state awareness — every node must know what the other nodes are doing. The mesh activation sequence is deterministic: Bootstrap → Handshake → Verify → Activate. Each step runs on both Windows and WSL before moving to the next. The final health check (`mesh-status.ps1`) must show all devices connected, all folders in sync, no errors on all three nodes simultaneously.

### 6.1 Mesh Windows Scripts

| Script | Path | Sequence Position | Purpose |
| --- | --- | --- | --- |
| `mesh-bootstrap.ps1` | `C:\SemperFix\Tools\` | Step 1 | Collects system status and prepares the mesh coordination layer; establishes baseline state |
| `mesh-handshake.ps1` | `C:\SemperFix\Tools\` | Step 2 | Collects and validates device-to-device connection status across all nodes |
| `mesh-verify.ps1` | `C:\SemperFix\Tools\` | Step 3 | Validates folder sync state; compares globalBytes vs. inSyncBytes to confirm sync completeness |
| `mesh-activate.ps1` | `C:\SemperFix\Tools\` | Step 4 (Full) | Runs bootstrap → handshake → verify in a single orchestrated sequence; used for full activation |
| `mesh-status.ps1` | `C:\SemperFix\Tools\` | Ongoing / Final health check | Real-time mesh health snapshot; confirms all devices connected, all folders green, no errors |

### 6.2 Mesh WSL Companion Scripts

| Script | Path | Windows Counterpart | Sequence Position | Purpose |
| --- | --- | --- | --- | --- |
| `wsl-mesh-bootstrap.sh` | `/opt/semperfix/scripts/` | `mesh-bootstrap.ps1` | Step 1 | Ensures WSL observes same system state as Windows before mesh coordination begins |
| `wsl-mesh-handshake.sh` | `/opt/semperfix/scripts/` | `mesh-handshake.ps1` | Step 2 | WSL-side handshake logging; confirms cross-layer consistency |
| `wsl-mesh-verify.sh` | `/opt/semperfix/scripts/` | `mesh-verify.ps1` | Step 3 | Ensures WSL sees the same folder sync state as Windows |
| `wsl-mesh-activate.sh` | `/opt/semperfix/scripts/` | `mesh-activate.ps1` | Step 4 (Full) | WSL mirrors the Windows full activation sequence for consistency |

### 6.3 Mesh Activation Sequence — All Three Nodes

| Step | Node | Windows Action | WSL Action | Validation Gate |
| --- | --- | --- | --- | --- |
| 1 | **MASTERZERO** | Run `mesh-bootstrap.ps1` | Run `wsl-mesh-bootstrap.sh` | Both outputs must show same system state |
| 2 | **MASTERZERO** | Run `mesh-handshake.ps1` | Run `wsl-mesh-handshake.sh` | All devices confirmed connected |
| 3 | **MASTERZERO** | Run `mesh-verify.ps1` | Run `wsl-mesh-verify.sh` | All folders confirmed in sync (globalBytes = inSyncBytes) |
| 4 | **SECONDARY** | Set NodeRole = `"SECONDARY"` in `semperfix-config.json` → Run `mesh-activate.ps1` | Run `wsl-mesh-activate.sh` | Activation completes with no errors on both sides |
| 5 | **OFFSITE** | Set NodeRole = `"OFFSITE"` in `semperfix-config.json` → Run `mesh-activate.ps1` | Run `wsl-mesh-activate.sh` | Activation completes with no errors on both sides |
| 6 | **All Nodes** | Run `mesh-status.ps1` | — | All devices connected, all folders in sync, no errors across all three nodes simultaneously |

Layer 6 — Golden Template Lineage  |  The provenance layer: canonical frozen state, versioned deployment baseline, recovery anchor
## Section 7 — Layer 6: Golden Template Lineage

The provenance layer. The Golden Template is the canonical frozen state of the SemperFix environment at a known-good version. It defines what gets cloned to SECONDARY and OFFSITE nodes, and it is the recovery baseline for any catastrophic failure. The template is versioned — current version is **v0.1.2**.

### 7.1 Golden Template Artifacts

| Artifact | Location | Format | Version | Purpose |
| --- | --- | --- | --- | --- |
| `Ubuntu.tar` | `C:\SemperFix\GoldenTemplate\Ubuntu.tar` | WSL export tarball | v0.1.2 | Complete WSL Ubuntu state at freeze time; exported via `wsl --export Ubuntu`; core of the Golden Template |
| VM Snapshot | VM image storage (per-hypervisor) | VM image | SemperFix-GoldenTemplate-v0.1.2 | Full VM image snapshot taken at same moment as Ubuntu.tar; becomes the SECONDARY and OFFSITE baseline |
| SemperFix-GoldenTemplate-v0.1.2 | Snapshot label | Metadata tag | v0.1.2 | Identifies this freeze as the canonical deployment baseline |

### 7.2 Pre-Freeze Validation Requirements

Before any freeze that updates the Golden Template, **ALL** of the following must pass with zero errors. A partial pass does not qualify. No freeze proceeds until every check is green.

| Check | Script / Tool | Expected Result |
| --- | --- | --- |
| Syncthing API validation | `node-status.ps1` | API key valid; port responding; JSON response intact |
| WSL subsystem validation | `wsl.exe -l -v` | Ubuntu running; Version 2 confirmed |
| WSL script validation | `wsl-config-validate.py` + `wsl-health-check.sh` | Both exit with success; no config errors |
| Scheduled Task validation | Task Scheduler GUI | All 3 tasks present; Last Run Result = 0x0 |
| Log validation | `log-collector.ps1` | Windows + WSL logs accessible; no critical errors |
| Phoenix dry-run | `phoenix-dryrun.ps1` + `wsl-phoenix-dryrun.sh` | Both log files show clean simulation — escalation → failover → recovery with no errors |

### 7.3 Freeze Action Sequence

Numbered steps for creating a new Golden Template version. Execute in order. Do not skip steps.

1. Shut down non-essential apps (browsers, installers, anything touching ports or WSL)
2. Stop Syncthing: `net stop syncthing`
3. Export Scheduled Tasks: `schtasks /query /xml /tn "SemperFix Automation"`
4. Export WSL State: `wsl --export Ubuntu C:\SemperFix\GoldenTemplate\Ubuntu.tar`
5. Create VM Snapshot — label: `SemperFix-GoldenTemplate-v[NEW VERSION]`
6. Document NodeRole assignments for this version (MASTERZERO / SECONDARY / OFFSITE)

### 7.4 NodeRole as Template Differentiator

The Golden Template is identical across all three nodes except for one field in `semperfix-config.json`. All PowerShell scripts read NodeRole at runtime to determine their behavior. Changing NodeRole is the only configuration step needed to promote or change a node's identity.

| Node | NodeRole Value |
| --- | --- |
| SemperFix-Primary | `"MASTERZERO"` |
| SemperFix-Secondary | `"SECONDARY"` |
| SemperFix-Offsite | `"OFFSITE"` |

Layer 7 — Documentation  |  The knowledge layer: Vault–Repo graduation model; drafts in Obsidian, finals in the repository
## Section 8 — Layer 7: Documentation

The knowledge layer. All documentation follows the Vault–Repo graduation model: drafts originate in the Obsidian Vault and graduate to the repository when finalized. Once in the Repo, the Vault copy is archived or removed.

### 8.1 Repository Documentation

| File | Repo Path | Status | Purpose |
| --- | --- | --- | --- |
| `ARCHITECTURE.md` | `docs/architecture/ARCHITECTURE.md` | Canonical / Live | Primary architectural reference; layer model, file placement philosophy, security model, conventions |
| `BLUEPRINT.md` | `docs/architecture/BLUEPRINT.md` | Canonical / Live | High-level project blueprint; design intent and system overview |
| `file-placement-matrix.md` | `docs/file-placement-matrix.md` | Canonical / Living document | Authoritative file-to-layer mapping; must be updated in the same PR whenever a new file type is added |
| This Document | `docs/architecture/INTEGRATION-MAP.md` | Canonical / Live | Layer-by-layer integration map; complete file and directory registry |

### 8.2 Operational Documents (Obsidian Vault / OneDrive)

| Document | Version | Format | Purpose |
| --- | --- | --- | --- |
| SemperFix Syncthing Package — Installation Manual | v0.1.3-alpha | DOCX | Step-by-step installation guide for all three machines; Sections 0–9 covering topology, install, config, pairing, automation, verification, troubleshooting |
| SemperFix Syncthing Package — Quick Start Card | v0.1.3-alpha | DOCX | Condensed 6-step install and config reference card |
| DOCUMENT 1 — Golden Template Freeze Checklist | v0.1.2 | DOCX | Operator + Engineering Notes for creating and validating a Golden Template freeze |
| DOCUMENT 2 — Phoenix + Mesh Activation Checklist | v0.1.3-alpha | DOCX | Operator + Engineering Notes for Phoenix dry-run and full Mesh activation sequence |
| Operational Task List | v1.1 | DOCX | Deployment tracking document; machine-by-machine task status across all three nodes; updated as issues are resolved |

### 8.3 Documentation Graduation Workflow

All ADRs, runbooks, and architecture documents follow the Vault → Repo graduation model. The flow is strictly one-directional: once a document has graduated to the repository, it does not return to draft status in the Vault without explicit versioning.

1. **Draft** begins in the Obsidian Vault — informal, work-in-progress, may be incomplete
2. **Review & Finalize** — content is validated, cross-references confirmed, version assigned
3. **Commit to Repo** — finalized document is committed as canonical version under `docs/`
4. **Archive Vault Copy** — original Vault draft is archived in a `_archive/` subfolder or deleted to prevent stale references

## Section 9 — Consolidated Integration Matrix

Single-table view of the entire repository — every significant file and directory mapped to its layer, location, and scope. Use this table as the authoritative quick-reference when locating any artifact. The table is organized by layer group; cross-referenced scripts appear once under their primary layer.

| File / Directory | Layer | Windows Path | WSL Path | Scope | Notes |
| --- | --- | --- | --- | --- | --- |
| LAYER 1 — Windows Host |
| `semperfix-windows-automation.ps1` | Windows Host | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Master automation entry point |
| `syncthing-api.ps1` | Windows Host | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Syncthing REST API wrapper |
| `node-status.ps1` | Windows Host | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Per-node status snapshot |
| `log-collector.ps1` | Windows Host | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Windows + WSL log aggregation |
| `service-wrapper.ps1` | Windows Host | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Generic service lifecycle wrapper |
| `phoenix-watchdog.ps1` | Windows Host / Phoenix | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Phoenix health monitor |
| `phoenix-recover.ps1` | Windows Host / Phoenix | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Phoenix recovery executor |
| `phoenix-role-check.ps1` | Windows Host / Phoenix | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | NodeRole validator |
| `phoenix-escalate.ps1` | Windows Host / Phoenix | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Alert severity escalator |
| `phoenix-failover.ps1` | Windows Host / Phoenix | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Controlled failover executor |
| `phoenix-dryrun.ps1` | Windows Host / Phoenix | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Full Phoenix simulation; no live services touched |
| `mesh-bootstrap.ps1` | Windows Host / Mesh | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Mesh Step 1: baseline state |
| `mesh-handshake.ps1` | Windows Host / Mesh | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Mesh Step 2: device connection validation |
| `mesh-verify.ps1` | Windows Host / Mesh | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Mesh Step 3: sync state validation |
| `mesh-activate.ps1` | Windows Host / Mesh | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Mesh Step 4: full orchestrated activation |
| `mesh-status.ps1` | Windows Host / Mesh | `C:\SemperFix\Tools\` | `/mnt/c/SemperFix/Tools/` | All Nodes | Real-time mesh health snapshot |
| `SemperFix-Automation.xml` | Windows Host | `C:\SemperFix\Tools\` | — | All Nodes | Task Scheduler: every 15 min; SYSTEM |
| `Phoenix-Watchdog.xml` | Windows Host | `C:\SemperFix\Tools\` | — | All Nodes | Task Scheduler: continuous/event; SYSTEM |
| `Mesh-Status-Snapshot.xml` | Windows Host | `C:\SemperFix\Tools\` | — | All Nodes | Task Scheduler: scheduled interval; SYSTEM |
| `semperfix-config.json` | Windows Host | `C:\SemperFix\Tools\` | — | All Nodes | Per-node config; NodeRole is only differentiator |
| `C:\SemperFix\syncthing\syncthing.exe` | Windows Host / Syncthing | `C:\SemperFix\syncthing\` | — | All Nodes | Syncthing binary; started via shell:startup |
| `C:\SemperFix\MasterZero\` | Windows Host / Syncthing | `C:\SemperFix\MasterZero\` | — | Primary Only | Send Only synced folder source |
| `C:\SemperFix\Assets\` | Windows Host / Syncthing | `C:\SemperFix\Assets\` | — | All Nodes | Bidirectional synced folder |
| `C:\SemperFix\ConfigBackup\` | Windows Host / Syncthing | `C:\SemperFix\ConfigBackup\` | — | All Nodes | Send Only on Primary; Receive Only on others |
| LAYER 2 — WSL Execution |
| `wsl-phoenix-dryrun.sh` | WSL Execution | `C:\SemperFix\package\scripts\` (staged) | `/opt/semperfix/scripts/` | All Nodes | Pairs with phoenix-dryrun.ps1 |
| `wsl-mesh-bootstrap.sh` | WSL Execution | `C:\SemperFix\package\scripts\` (staged) | `/opt/semperfix/scripts/` | All Nodes | Pairs with mesh-bootstrap.ps1 |
| `wsl-mesh-handshake.sh` | WSL Execution | `C:\SemperFix\package\scripts\` (staged) | `/opt/semperfix/scripts/` | All Nodes | Pairs with mesh-handshake.ps1 |
| `wsl-mesh-verify.sh` | WSL Execution | `C:\SemperFix\package\scripts\` (staged) | `/opt/semperfix/scripts/` | All Nodes | Pairs with mesh-verify.ps1 |
| `wsl-mesh-activate.sh` | WSL Execution | `C:\SemperFix\package\scripts\` (staged) | `/opt/semperfix/scripts/` | All Nodes | Pairs with mesh-activate.ps1 |
| `wsl-health-check.sh` | WSL Execution | `C:\SemperFix\package\scripts\` (staged) | `/opt/semperfix/scripts/` | All Nodes | Pairs with node-status.ps1 |
| `wsl-config-validate.py` | WSL Execution | `C:\SemperFix\package\scripts\` (staged) | `/opt/semperfix/scripts/` | All Nodes | Python; no PS1 pair; standalone validator |
| `validate-config.py` | WSL Execution | `C:\SemperFix\package\scripts\` | `/mnt/c/SemperFix/package/scripts/` | All Nodes | Pre-pairing JSON config validator; requires Python 3.9+ |
| `~/.semperfix/env` | WSL Execution | — | `~/.semperfix/env` | All Nodes | chmod 600; runtime env vars; gitignored; secrets live here |
| User crontab | WSL Execution | — | `crontab -e` | All Nodes | Schedules automation.sh (15 min) and backup-config.sh (2am) |
| `/opt/semperfix/logs/` | WSL Execution | — | `/opt/semperfix/logs/` | All Nodes | WSL log output directory |
| LAYER 3 — Syncthing Transport |
| `SyncthingCloneExport.json` | Syncthing Transport | `C:\SemperFix\package\config\` | `/mnt/c/SemperFix/package/config/` | All Nodes | Config template; placeholders filled before pairing; committed without values |
| `master-zero.stignore` | Syncthing Transport | `C:\SemperFix\package\config\` | — | All Nodes | Ignore rules for MasterZero folder |
| `media.stignore` | Syncthing Transport | `C:\SemperFix\package\config\` | — | All Nodes | Ignore rules for Assets folder |
| `global.stignore` | Syncthing Transport | `C:\SemperFix\package\config\` | — | All Nodes | Ignore rules for ConfigBackup folder |
| `C:\SemperFix\syncthing\config\` | Syncthing Transport | `C:\SemperFix\syncthing\config\` | — | All Nodes | Syncthing home dir; device certs; config.xml; set via --home flag |
| LAYER 4 — Phoenix Core (cross-reference: Windows scripts listed above; WSL companions below) |
| `wsl-phoenix-dryrun.sh` | Phoenix Core / WSL | — | `/opt/semperfix/scripts/` | All Nodes | WSL Phoenix dry-run companion; logs to /opt/semperfix/logs/wsl-phoenix-dryrun.log |
| `phoenix-dryrun.log` | Phoenix Core | `C:\SemperFix\Tools\` | — | All Nodes | Windows Phoenix dry-run log; must be validated after each run |
| `wsl-phoenix-dryrun.log` | Phoenix Core / WSL | — | `/opt/semperfix/logs/` | All Nodes | WSL Phoenix dry-run log; must be validated after each run |
| `phoenix-watchdog.log` | Phoenix Core | `C:\SemperFix\Tools\` | — | All Nodes | Continuous watchdog output log |
| LAYER 5 — Mesh Orchestration (cross-reference: Windows scripts listed above; WSL companions below) |
| `wsl-mesh-bootstrap.sh` | Mesh / WSL | — | `/opt/semperfix/scripts/` | All Nodes | Step 1 WSL companion |
| `wsl-mesh-handshake.sh` | Mesh / WSL | — | `/opt/semperfix/scripts/` | All Nodes | Step 2 WSL companion |
| `wsl-mesh-verify.sh` | Mesh / WSL | — | `/opt/semperfix/scripts/` | All Nodes | Step 3 WSL companion |
| `wsl-mesh-activate.sh` | Mesh / WSL | — | `/opt/semperfix/scripts/` | All Nodes | Step 4 WSL companion |
| LAYER 6 — Golden Template Lineage |
| `Ubuntu.tar` | Golden Template | `C:\SemperFix\GoldenTemplate\` | — | Primary (source) | WSL export; v0.1.2; core of Golden Template; exported via wsl --export |
| VM Snapshot | Golden Template | VM image storage (per-hypervisor) | — | Primary (source) | Label: SemperFix-GoldenTemplate-v0.1.2; cloned to Secondary and Offsite |
| `C:\SemperFix\GoldenTemplate\` | Golden Template | `C:\SemperFix\GoldenTemplate\` | — | Primary | Container folder for all freeze artifacts |
| LAYER 7 — Documentation |
| `ARCHITECTURE.md` | Documentation | — | `docs/architecture/ARCHITECTURE.md` (repo) | All | Primary architectural reference; canonical / live |
| `BLUEPRINT.md` | Documentation | — | `docs/architecture/BLUEPRINT.md` (repo) | All | High-level design intent; canonical / live |
| `file-placement-matrix.md` | Documentation | — | `docs/file-placement-matrix.md` (repo) | All | Living document; update in same commit as new file additions |
| `INTEGRATION-MAP.md` | Documentation | — | `docs/architecture/INTEGRATION-MAP.md` (repo) | All | This document; canonical / live |
| Installation Manual (DOCX) | Documentation | OneDrive / Vault | — | All | v0.1.3-alpha; Sections 0–9; full install guide |
| Quick Start Card (DOCX) | Documentation | OneDrive / Vault | — | All | v0.1.3-alpha; condensed 6-step reference card |
| Golden Template Freeze Checklist (DOCX) | Documentation | OneDrive / Vault | — | All | v0.1.2; operator + engineering freeze validation notes |
| Phoenix + Mesh Activation Checklist (DOCX) | Documentation | OneDrive / Vault | — | All | v0.1.3-alpha; dry-run and full activation sequence |
| Operational Task List (DOCX) | Documentation | OneDrive / Vault | — | All | v1.1; machine-by-machine deployment task tracking |

## Section 10 — Conventions & Rules

The following conventions are binding for all SemperFix-Hybrid development and operations. They are not suggestions — deviations are defects.

1. **One canonical home.** Every file has exactly one primary layer. The integration map is the authority. If a file could belong to two layers, resolve the ambiguity here before committing.
2. **Scripts are identical across nodes.** Only `semperfix-config.json` differs per machine. Any script divergence between nodes — whether in content, permissions, or path — is a defect requiring immediate correction.
3. **NodeRole is the only per-node differentiator.** MASTERZERO, SECONDARY, and OFFSITE are set exclusively via the `NodeRole` field in `semperfix-config.json`. No other file changes per node.
4. **Mesh activation is always bilateral.** Every mesh operation runs on both Windows (PowerShell) and WSL (bash) in sequence. Never run only one side. A single-side activation is an incomplete activation.
5. **Freeze requires all pre-checks to pass.** No Golden Template snapshot may be taken unless every item in Section 7.2 passes with zero errors. Partial passes do not qualify.
6. **Syncthing folder types are not suggestions.** Never change Master Zero or Config Backup from Receive Only on Secondary/Offsite. This is enforced by design — an incorrect folder type causes content to flow backwards and overwrite Primary data.
7. **Secrets never touch the repository.** API keys, Syncthing API keys, and credentials belong in `~/.semperfix/env` (chmod 600, gitignored) or a password manager. No secret value may appear in any committed file, including `SyncthingCloneExport.json`.
8. **Templates live in Repo; values live in WSL.** `SyncthingCloneExport.json` (with placeholders) is committed to the repository. The filled-in, deployed config with real device IDs is never committed.
9. **Documentation graduates from Vault to Repo.** Drafts begin in the Obsidian Vault. Only finalized, reviewed documents are committed to the repository. Vault copies of graduated documents are archived or deleted.
10. **The integration map is a living document.** When a new script, config file, or directory is added to the project, this document and `file-placement-matrix.md` must be updated in the same commit. The integration map is never allowed to lag behind the actual file inventory.

## Appendix A — Quick Reference

Condensed operational reference for runtime paths and key commands. Suitable for printing as a one-page ops card.

| Runtime Paths | Key Commands |
| --- | --- |
| Windows scripts:`C:\SemperFix\Tools\`
WSL scripts:`/opt/semperfix/scripts/`
Syncthing binary:`C:\SemperFix\syncthing\`
Syncthing config:`C:\SemperFix\syncthing\config\`
MasterZero folder (Primary only):`C:\SemperFix\MasterZero\`
Assets folder (all nodes):`C:\SemperFix\Assets\`
ConfigBackup folder (all nodes):`C:\SemperFix\ConfigBackup\`
Package / config files:`C:\SemperFix\package\config\`
WSL env file:`~/.semperfix/env`
WSL logs:`/opt/semperfix/logs/`
WSL reports:`~/.semperfix/reports/`
Golden Template:`C:\SemperFix\GoldenTemplate\`
Syncthing API & GUI:`http://127.0.0.1:8384` | Start Syncthing:`syncthing.exe serve --no-browser --home=C:\SemperFix\syncthing\config`
Stop Syncthing:`net stop syncthing`
Export WSL state:`wsl --export Ubuntu C:\SemperFix\GoldenTemplate\Ubuntu.tar`
Run config validator:`python validate-config.py --config SyncthingCloneExport.json`
Phoenix dry-run (Windows):`powershell -File C:\SemperFix\Tools\phoenix-dryrun.ps1`
Phoenix dry-run (WSL):`/opt/semperfix/scripts/wsl-phoenix-dryrun.sh`
Mesh activate (Windows):`powershell -File C:\SemperFix\Tools\mesh-activate.ps1`
Mesh activate (WSL):`/opt/semperfix/scripts/wsl-mesh-activate.sh`
Mesh health check:`powershell -File C:\SemperFix\Tools\mesh-status.ps1`
Check WSL version:`wsl.exe -l -v`
Export Scheduled Task:`schtasks /query /xml /tn "SemperFix Automation"` |

**SemperFix-Hybrid — Repo Integration Map**  |  v0.1.3-alpha  |  docs/architecture/INTEGRATION-MAP.md  |  Author: Bruce Bergdahl  |  Last Updated: August 13, 2026  |  Internal Reference