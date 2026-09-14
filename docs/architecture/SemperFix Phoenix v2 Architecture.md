# **📘 SemperFix Phoenix v2 Architecture Document**

### **Hybrid Cluster Control Plane — Syncthing Transport Edition**

Version: **2.0**   Status: **Production Architecture**   Author: **Bruce (SemperFix)**   Generated: **2026‑09‑06**

## **1. Overview**

Phoenix v2 is the **cluster control plane** for SemperFix hybrid deployments. It manages:

* Node roles
* Failover
* Recovery
* Promotion/demotion
* Cluster health
* Transport integrity
* Status propagation

Phoenix v2 replaces all SMB/UNC dependencies with ​**Syncthing‑based transport**​, ensuring:

* Reliable cross‑node state propagation
* Encrypted, resilient file sync
* Zero reliance on Windows networking
* Zero reliance on vSwitch ACLs
* Zero reliance on SMB shares

Phoenix v2 operates entirely on ​**local Syncthing‑synced folders**​, making the cluster transport layer:

* Deterministic
* Predictable
* Network‑agnostic
* Failover‑safe

## **2. Phoenix v2 Components**

Phoenix v2 consists of ​**eight modules**​:

### **2.1 Core Modules**

| Module                                 | Purpose                                    |
| ---------------------------------------- | -------------------------------------------- |
| **phoenix-supervisor.ps1**       | Continuous cluster brain (role controller) |
| **phoenix-syncthing-health.ps1** | Transport health module                    |
| **phoenix-status-write.ps1**     | Writes phoenix-status.json v2              |
| **phoenix-status-validate.ps1**  | Validates phoenix-status.json v2           |

### **2.2 Action Modules**

| Module                         | Purpose                       |
| -------------------------------- | ------------------------------- |
| **phoenix-promote.ps1**  | SECONDARY → ACTIVE           |
| **phoenix-demote.ps1**   | ACTIVE → PASSIVE             |
| **phoenix-recover.ps1**  | MASTERZERO recovery           |
| **phoenix-escalate.ps1** | Mark node degraded / escalate |

### **2.3 Utility Modules**

| Module                           | Purpose                            |
| ---------------------------------- | ------------------------------------ |
| **phoenix-role-check.ps1** | Returns current role               |
| **phoenix-dryrun.ps1**     | Non-destructive cluster validation |

## **3. Transport Layer (Syncthing)**

Phoenix v2 uses Syncthing to synchronize ​**three authoritative folders**​:

| Folder                 | MASTERZERO     | SECONDARY      |
| ------------------------ | ---------------- | ---------------- |
| **MasterZero**   | Send Only      | Receive Only   |
| **ConfigBackup** | Send Only      | Receive Only   |
| **Assets**       | Send & Receive | Send & Receive |

These folders contain:

* Phoenix status
* Cluster lineage
* Failover markers
* Recovery markers
* Config backups
* Assets required for cluster operation

All Phoenix scripts read/write ​**local paths only**​:

Code

```
C:\SemperFix\MasterZero
C:\SemperFix\ConfigBackup
C:\SemperFix\Assets
```

Syncthing ensures these folders remain synchronized across nodes.

## **4. Phoenix Status Document (phoenix-status.json v2)**

Phoenix v2 uses a unified cluster state document stored at:

Code

```
C:\SemperFix\ConfigBackup\phoenix-status.json
```

### **4.1 Status Schema**

The v2 schema contains:

* Role
* Status
* Node identity
* Cluster lineage
* Syncthing health
* Phoenix health
* Action flags
* Metadata

This document is the **single source of truth** for Phoenix cluster state.

## **5. Phoenix v2 Role Model**

Phoenix v2 defines ​**three roles**​:

### **5.1 MASTERZERO-ACTIVE**

* Authoritative node
* Writes cluster state
* Sends Syncthing updates
* Controls lineage

### **5.2 SECONDARY-ACTIVE**

* Temporary master during failover
* Writes cluster state
* Sends Syncthing updates

### **5.3 SECONDARY-PASSIVE**

* Standby node
* Receives Syncthing updates
* Ready for promotion

## **6. Phoenix v2 State Model**

Phoenix v2 defines ​**five states**​:

| State                       | Meaning                             |
| ----------------------------- | ------------------------------------- |
| **HEALTHY**           | Node fully operational              |
| **DEGRADED**          | Node impaired; escalation triggered |
| **FAILOVER\_ALLOWED** | Supervisor may promote SECONDARY    |
| **RECOVER**           | MASTERZERO may reclaim authority    |
| **ERROR**             | Critical failure                    |

## **7. Phoenix v2 Decision Logic**

Phoenix v2 decision logic is executed by:

Code

```
phoenix-supervisor.ps1
```

### **7.1 Promotion Conditions**

SECONDARY-PASSIVE → SECONDARY-ACTIVE when:

* Status = `FAILOVER_ALLOWED`
* Syncthing = Healthy
* Phoenix = Healthy

### **7.2 Demotion Conditions**

SECONDARY-ACTIVE → SECONDARY-PASSIVE when:

* Status = `RECOVER`
* MASTERZERO = Healthy
* Syncthing = Healthy

### **7.3 Recovery Conditions**

MASTERZERO-ACTIVE restored when:

* Status = `RECOVER`
* MASTERZERO = Healthy
* Syncthing = Healthy

### **7.4 Escalation Conditions**

Node marked `DEGRADED` when:

* Syncthing unhealthy
* Phoenix service unhealthy
* Status JSON stale
* Supervisor detects critical failure

## **8. Phoenix v2 Module Interactions**

Code

```
phoenix-supervisor
    ├── phoenix-syncthing-health
    ├── phoenix-status-validate
    ├── phoenix-promote
    ├── phoenix-demote
    ├── phoenix-recover
    ├── phoenix-escalate
    └── phoenix-status-write
```

Supervisor is the ​**brain**​. Syncthing is the ​**transport**​. phoenix-status.json is the ​**truth**​.

## **9. Phoenix v2 Execution Flow**

### **9.1 Normal Operation**

MASTERZERO-ACTIVE ↓ Syncthing syncs state ↓ SECONDARY-PASSIVE monitors

### **9.2 Failover**

MASTERZERO → DEGRADED ↓ Status = FAILOVER\_ALLOWED ↓ SECONDARY-PASSIVE → SECONDARY-ACTIVE ↓ Cluster lineage updated

### **9.3 Recovery**

MASTERZERO returns ↓ Status = RECOVER ↓ SECONDARY-ACTIVE → SECONDARY-PASSIVE ↓ MASTERZERO-ACTIVE restored

## **10. Phoenix v2 Logging**

All modules use SemperFix logging format:

Code

```
[2026-09-06 04:01:00] [INFO] Message
[2026-09-06 04:01:00] [WARN] Message
[2026-09-06 04:01:00] [ERROR] Message
```

Logs stored in:

Code

```
C:\SemperFix\Logs\
```

## **11. Phoenix v2 Guarantees**

Phoenix v2 guarantees:

* **SMB-free operation**
* **Deterministic failover**
* **Deterministic recovery**
* **Consistent cluster state**
* **Syncthing-backed transport**
* **No reliance on Windows networking**
* **No reliance on UNC paths**
* **No reliance on vSwitch ACLs**
* **No reliance on SMB shares**

This is the most stable, predictable, and resilient Phoenix architecture to date.

## **12. Phoenix v2 Future Extensions**

* Multi-node cluster support
* Offsite node integration
* Syncthing QUIC priority mode
* Phoenix heartbeat service
* Phoenix cluster dashboard
* Phoenix v2 REST API

