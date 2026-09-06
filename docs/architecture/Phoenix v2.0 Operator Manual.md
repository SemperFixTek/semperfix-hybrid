# **📘 Phoenix v2 Operator Manual**

### **SemperFix Hybrid Cluster — Operational Guide**

Version: **2.0**   Audience: Operators, Maintainers, On‑Call Engineers

## **1. Purpose**

Phoenix v2 is the SemperFix cluster control plane. This manual explains how to operate, monitor, and maintain the Phoenix v2 system in production.

## **2. Node Roles**

Phoenix v2 defines ​**three roles**​:

### **MASTERZERO-ACTIVE**

* Primary authoritative node
* Writes cluster state
* Drives lineage
* Sends Syncthing updates

### **SECONDARY-ACTIVE**

* Temporary master during failover
* Writes cluster state
* Sends Syncthing updates

### **SECONDARY-PASSIVE**

* Standby node
* Receives Syncthing updates
* Ready for promotion

## **3. Phoenix Status States**

Phoenix v2 uses the following states:

| State                       | Meaning                             |
| ----------------------------- | ------------------------------------- |
| **HEALTHY**           | Node fully operational              |
| **DEGRADED**          | Node impaired; escalation triggered |
| **FAILOVER\_ALLOWED** | Supervisor may promote SECONDARY    |
| **RECOVER**           | MASTERZERO may reclaim authority    |
| **ERROR**             | Critical failure                    |

## **4. Transport Layer (Syncthing)**

Phoenix v2 uses Syncthing to synchronize ​**three authoritative folders**​:

| Folder                 | Purpose                              |
| ------------------------ | -------------------------------------- |
| **MasterZero**   | MASTERZERO authoritative data        |
| **ConfigBackup** | Cluster state + lineage + status     |
| **Assets**       | Shared assets required by both nodes |

Operators must ensure:

* Syncthing service is running
* All three folders show **State = idle**
* No folder is stalled or out‑of‑sync

## **5. Core Operational Files**

### **phoenix-status.json v2**

Location:

Code

```
C:\SemperFix\ConfigBackup\phoenix-status.json
```

This is the **single source of truth** for cluster state.

Operators should inspect:

* `Role`
* `Status`
* `Cluster.Lineage`
* `Syncthing.Healthy`
* `Actions.FailoverAllowed`
* `Actions.RecoveryAllowed`

## **6. Supervisor (Cluster Brain)**

### **phoenix-supervisor.ps1**

Runs continuously or via scheduled task.

Responsibilities:

* Read phoenix-status.json
* Read Syncthing health
* Decide promote/demote/recover
* Execute action modules
* Write updated cluster state
* Log all decisions

Operators may run:

Code

```
powershell -File C:\SemperFix\tools\phoenix-supervisor.ps1 -Mode auto
```

or:

Code

```
powershell -File C:\SemperFix\tools\phoenix-supervisor.ps1 -Mode manual
```

Manual mode logs decisions but does not execute them.

## **7. Action Modules**

### **7.1 Promotion**

Code

```
phoenix-promote.ps1
```

SECONDARY-PASSIVE → SECONDARY-ACTIVE

Triggered when:

* Status = FAILOVER\_ALLOWED
* Syncthing healthy
* Phoenix healthy

### **7.2 Demotion**

Code

```
phoenix-demote.ps1
```

SECONDARY-ACTIVE → SECONDARY-PASSIVE

Triggered when:

* Status = RECOVER
* MASTERZERO healthy

### **7.3 Recovery**

Code

```
phoenix-recover.ps1
```

MASTERZERO reclaims authority.

### **7.4 Escalation**

Code

```
phoenix-escalate.ps1
```

Marks node as DEGRADED.

## **8. Operational Procedures**

### **8.1 Checking Cluster Health**

Run:

Code

```
phoenix-dryrun.ps1
```

or inspect:

Code

```
C:\SemperFix\ConfigBackup\phoenix-status.json
```

### **8.2 Forcing Failover (Manual Mode)**

1. Set `Status = FAILOVER_ALLOWED`
2. Run supervisor in manual mode
3. Run `phoenix-promote.ps1` manually if desired

### **8.3 Forcing Recovery**

1. Set `Status = RECOVER`
2. Run supervisor
3. MASTERZERO will reclaim authority

### **8.4 Inspecting Syncthing Health**

Run:

Code

```
phoenix-syncthing-health.ps1
```

Look for:

* `Healthy = true`
* All folders `State = idle`

## **9. Logs**

All Phoenix logs are stored in:

Code

```
C:\SemperFix\Logs\
```

Format:

Code

```
[2026-09-06 04:01:00] [INFO] Message
[2026-09-06 04:01:00] [WARN] Message
[2026-09-06 04:01:00] [ERROR] Message
```

## **10. Operator Responsibilities**

Operators must:

* Ensure Syncthing is running
* Ensure Phoenix service is running
* Monitor phoenix-supervisor logs
* Inspect phoenix-status.json
* Validate cluster lineage
* Respond to DEGRADED states
* Trigger manual failover only when necessary

## **11. Failure Modes**

### **Syncthing Unhealthy**

* Supervisor logs WARN
* Node may enter DEGRADED
* Failover not allowed

### **Phoenix Service Down**

* Node enters DEGRADED
* Supervisor may escalate

### **Status JSON Stale**

* Supervisor logs ERROR
* Node enters DEGRADED

## **12. Recovery Procedures**

### **MASTERZERO Recovery**

1. Ensure MASTERZERO Syncthing is healthy
2. Set Status = RECOVER
3. Run supervisor
4. SECONDARY demotes
5. MASTERZERO becomes ACTIVE

## **13. Summary**

Phoenix v2 provides:

* Deterministic failover
* Deterministic recovery
* Syncthing‑based transport
* SMB‑free architecture
* Unified cluster state
* Modular control plane
* Operator‑friendly workflows

This manual is the operational reference for maintaining Phoenix v2 in production.

