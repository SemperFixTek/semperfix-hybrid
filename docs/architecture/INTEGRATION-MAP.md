# SemperFix-Hybrid — Repo Integration Map

| Field | Value |
| --- | --- |
| Project | SemperFix-Hybrid |
| Version | v0.1.3-alpha |
| Type | Architectural Integration Map |
| Maintained in | docs/architecture/ARCHITECTURE.md |
| Updated | 2026-08-13 |
| Author | Bruce Bergdahl |

## 1. Architecture overview

SemperFix-Hybrid uses a three-layer operating model:

- Windows host for GUI, automation, and system config.
- WSL for toolchains, scripts, and local execution.
- Syncthing, Phoenix, Mesh, and the repo/vault model for sync,
  resilience, and source-of-truth control.

```text
Windows Host        WSL2 Ubuntu        Syncthing / Phoenix / Mesh
+-----------------+   +----------------+   +-------------------------+
| GUI apps        |   | Dev toolchain |   | Sync / failover /      |
| PowerShell      |   | Bash scripts  |   | coordination           |
| Task Scheduler  |   | Python checks |   | recovery logic         |
+-----------------+   +----------------+   +-------------------------+
```

## 2. Layer 1 — Windows host

The Windows host is the substrate layer. It owns GUI services,
PowerShell automation, and local system configuration.

### 2.1 Core scripts

| File | Purpose |
| --- | --- |
| semperfix-windows-automation.ps1 | Master orchestration entry point. |
| syncthing-api.ps1 | Validates Syncthing API responses. |
| node-status.ps1 | Captures per-node health and state. |
| log-collector.ps1 | Consolidates host and WSL logs. |
| service-wrapper.ps1 | Wraps Windows service lifecycle actions. |
| phoenix-watchdog.ps1 | Monitors Phoenix health. |
| phoenix-recover.ps1 | Runs recovery procedures. |
| phoenix-role-check.ps1 | Validates NodeRole assignment. |
| phoenix-escalate.ps1 | Escalates alert severity. |
| phoenix-failover.ps1 | Executes failover actions. |
| phoenix-dryrun.ps1 | Simulates recovery and failover without live impact. |
| mesh-bootstrap.ps1 | Captures baseline mesh state. |
| mesh-handshake.ps1 | Confirms node connectivity. |
| mesh-verify.ps1 | Verifies sync completeness. |
| mesh-activate.ps1 | Runs activation workflow. |
| mesh-status.ps1 | Produces mesh health snapshots. |

### 2.2 Runtime paths

| Path | Role |
| --- | --- |
| C:\SemperFix\Tools\ | Shared Windows automation folder. |
| C:\SemperFix\syncthing\ | Syncthing runtime directory. |
| C:\SemperFix\MasterZero\ | Primary-only source folder. |
| C:\SemperFix\Assets\ | Shared assets folder. |
| C:\SemperFix\ConfigBackup\ | Backup distribution folder. |
| C:\SemperFix\package\config\ | Staged config exports and templates. |
| C:\SemperFix\GoldenTemplate\ | Freeze and recovery baseline. |

## 3. Layer 2 — WSL execution

WSL provides the execution environment for bash scripts,
cron tasks, and Python validation.

### 3.1 WSL companion scripts

| File | Role |
| --- | --- |
| wsl-phoenix-dryrun.sh | WSL dry-run companion to Phoenix. |
| wsl-mesh-bootstrap.sh | WSL mesh baseline step. |
| wsl-mesh-handshake.sh | WSL mesh connectivity check. |
| wsl-mesh-verify.sh | WSL sync verification. |
| wsl-mesh-activate.sh | WSL activation mirror. |
| wsl-health-check.sh | WSL health validation. |
| wsl-config-validate.py | WSL config validation utility. |

### 3.2 Local directories

| Path | Purpose |
| --- | --- |
| /opt/semperfix/scripts/ | Central WSL script directory. |
| /opt/semperfix/logs/ | WSL log outputs. |
| ~/.semperfix/env | Runtime env vars and secrets references. |

## 4. Syncthing transport

Syncthing is the file transport layer. It enforces directional
folder rules to avoid overwriting the primary node.

| Folder | Type | Purpose |
| --- | --- | --- |
| MasterZero | Send Only on primary | Source-of-truth content. |
| Assets | Send & Receive | Shared working data. |
| ConfigBackup | Send Only on primary | Backup distribution data. |

### 4.1 Trust rules

- MasterZero and ConfigBackup are not bidirectional by default.
- Secondary and Offsite nodes receive, but do not overwrite the
  primary stream.
- The config export is template-based and should not contain real
  secrets.

## 5. Layer 4 — Phoenix core

Phoenix handles watchdog monitoring, recovery, escalation, and
controlled failover.

### 5.1 Phoenix sequence

| Step | Action |
| --- | --- |
| 1 | Watchdog monitors health. |
| 2 | Recovery attempts restore. |
| 3 | Escalation increases severity if needed. |
| 4 | Failover moves to the next valid node. |
| 5 | Dry-run checks confirm no live service disruption. |

## 6. Layer 5 — Mesh orchestration

Mesh orchestration coordinates cross-node state awareness.

| Step | Script |
| --- | --- |
| 1 | mesh-bootstrap.ps1 / wsl-mesh-bootstrap.sh |
| 2 | mesh-handshake.ps1 / wsl-mesh-handshake.sh |
| 3 | mesh-verify.ps1 / wsl-mesh-verify.sh |
| 4 | mesh-activate.ps1 / wsl-mesh-activate.sh |
| 5 | mesh-status.ps1 |

## 7. Layer 6 — Golden template lineage

Golden Template is the canonical recovery baseline.

| Artifact | Meaning |
| --- | --- |
| Ubuntu.tar | WSL export of the known-good environment. |
| VM snapshot | Full hypervisor image at freeze time. |
| SemperFix config | Runtime role differentiation only. |

## 8. Documentation and repo model

Documentation follows a Vault-to-Repo graduation model.

| Place | Ownership |
| --- | --- |
| Obsidian Vault | Drafts, notes, and working references. |
| Repo | Finalized source docs and configs. |
| WSL local | Generated state and local runtime files. |

## 9. Conventions and rules

1. One canonical home per file.
2. Secrets stay out of the repo.
3. Scripts should remain identical across nodes except for config.
4. NodeRole is the only machine-specific role field.
5. Golden Template updates require a clean validation pass.
6. Documentation advances from Vault to Repo only after review.

## 10. Quick reference

| Area | Primary location |
| --- | --- |
| Windows automation | C:\SemperFix\Tools\ |
| WSL automation | /opt/semperfix/scripts/ |
| Syncthing config | C:\SemperFix\syncthing\config\ |
| Golden template | C:\SemperFix\GoldenTemplate\ |
| Logs | /opt/semperfix/logs/ |
| Repo docs | docs/architecture/ |

---

Last updated: 2026-08-13
