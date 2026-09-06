# **📐 Phoenix v2 Cluster Diagram (Syncthing Transport Edition)**

Below is the **ASCII architecture diagram** you can drop directly into your repo. It shows the full Phoenix v2 control plane, transport layer, and module interactions.

Code

```
┌───────────────────────────────────────┐
│        SemperFix Phoenix v2 Cluster   │
└───────────────────────────────────────┘

┌──────────────────────────────┐                 ┌──────────────────────────────┐
│        MASTERZERO Node       │                 │        SECONDARY Node        │
│        Role: ACTIVE          │                 │        Role: PASSIVE/ACTIVE  │
└──────────────────────────────┘                 └──────────────────────────────┘
```

LOCAL FILESYSTEM                               LOCAL FILESYSTEM
(Authoritative)                                 (Replica / Standby)

```
C:\SemperFix\MasterZero     <─────Syncthing─────>     C:\SemperFix\MasterZero
C:\SemperFix\ConfigBackup   <─────Syncthing─────>     C:\SemperFix\ConfigBackup
C:\SemperFix\Assets         <─────Syncthing─────>     C:\SemperFix\Assets

                 (Encrypted, resilient, SMB‑free transport)
```

```
───────────────────────────────────────────────────────────────────────────────────────
CONTROL PLANE (Phoenix v2)
───────────────────────────────────────────────────────────────────────────────────────
```

┌──────────────────────────────────────────┐
│        phoenix-supervisor.ps1                                              │
│   Continuous cluster brain (role logic)  │
└──────────────────────────────────────────┘
│
▼
┌──────────────────────────────────────────┐
│     phoenix-syncthing-health.ps1         │
│   Transport health (folder + device)     │
└──────────────────────────────────────────┘
│
▼
┌──────────────────────────────────────────┐
│     phoenix-status.json (v2)             │
│   Single source of truth (cluster state) │
└──────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────────────────┐
│                           ACTION MODULES                                   │
└────────────────────────────────────────────────────────────────────────────┘

```
phoenix-promote.ps1      → SECONDARY → ACTIVE
phoenix-demote.ps1       → ACTIVE → PASSIVE
phoenix-recover.ps1      → MASTERZERO recovery
phoenix-escalate.ps1     → Mark node DEGRADED
phoenix-role-check.ps1   → Return current role
phoenix-dryrun.ps1       → Non-destructive validation
```

```
───────────────────────────────────────────────────────────────────────────────────────
FAILOVER FLOW (Phoenix v2)
───────────────────────────────────────────────────────────────────────────────────────

MASTERZERO becomes DEGRADED
│
▼
phoenix-supervisor sets Status = FAILOVER_ALLOWED
│
▼
SECONDARY-PASSIVE → phoenix-promote → SECONDARY-ACTIVE
│
▼
Cluster lineage updated in phoenix-status.json

───────────────────────────────────────────────────────────────────────────────────────
RECOVERY FLOW (Phoenix v2)
───────────────────────────────────────────────────────────────────────────────────────

MASTERZERO returns healthy
│
▼
phoenix-supervisor sets Status = RECOVER
│
▼
SECONDARY-ACTIVE → phoenix-demote → SECONDARY-PASSIVE
│
▼
MASTERZERO-ACTIVE restored
```

```

```

