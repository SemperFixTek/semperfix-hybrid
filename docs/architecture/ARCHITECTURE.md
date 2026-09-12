# Phoenix v2 Distributed Cluster Architecture

SemperFix Hybrid Cluster — MASTERZERO · SECONDARY · OFFSITE

## 1. Overview

Phoenix v2 replaces the MASTERZERO‑centric architecture with a distributed, node‑aware model. Each node maintains its own state; one node at a time maintains the cluster view.

Key principles:

* Node‑local truth
* Single authoritative cluster view
* Syncthing distributes state, not writes it

## 2. File Layout

### 2.1 Node‑local state files

Each node writes only its own file:

* `phoenix.masterzero.json`
* `phoenix.secondary.json`
* `phoenix.offsite.json`

Contents:

* NodeRole
* Node’s own ApiUrl / ApiKey / MeshEndpoint
* Node’s own Syncthing health
* Node’s own Status
* Local timestamps
* Local actions

These files are single‑writer authoritative.

### 2.2 Cluster state file

* `phoenix.cluster.json`

Written only by the ACTIVE node.

Contents:

* ClusterName
* MasterNode
* Nodes[]
* Phoenix.Lineage
* Cluster‑level Status
* Cluster‑level Syncthing summary
* Actions.History

All nodes read this file.

## 3. Watchdog

Runs continuously on every node.

Responsibilities:

1. Load node‑local file
2. Identify node entry in `Nodes[]`
3. Ping node’s own Syncthing
4. Update local health
5. Apply node‑local role logic
6. Write node‑local file

Watchdog does not write cluster.json.

## 4. Supervisor

Runs on every node; only ACTIVE node writes cluster.json.

Responsibilities:

1. Read all node‑local files
2. Evaluate cluster health
3. Decide cluster‑level roles
4. Write cluster.json (ACTIVE node only)
5. Log supervisor view

## 5. Syncthing

Syncthing distributes:

* `phoenix.cluster.json`
* Optionally node‑local files (read‑only for other nodes)

Syncthing does not resolve cluster logic or multi‑writer conflicts.

## 6. Migration Plan

1. Freeze phoenix.json → phoenix.cluster.json
2. Create per‑node files
3. Populate NodeRole + ApiUrl
4. Update watchdog
5. Update supervisor
6. Document Phoenix v2
7. Deprecate MASTERZERO‑centric model

## 7. Summary

Phoenix v2 provides:

* Distributed health
* Distributed node truth
* Single authoritative cluster view
* No multi‑writer conflicts
* Resilient failover
* Clean recovery
* Predictable lineage

This architecture is the foundation for a stable, self‑healing SemperFix Hybrid cluster.

