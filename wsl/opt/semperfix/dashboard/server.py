#!/usr/bin/env python3
from flask import Flask, jsonify, send_from_directory
import json
import os

app = Flask(__name__)

STATE_DIR = "/var/lib/semperfix/state"
SECONDARY_DIR = f"{STATE_DIR}/secondary"
WIN_DIR = "/mnt/c/semperfix/state"

def load_json(path):
    try:
        with open(path, "r") as f:
            return json.load(f)
    except Exception as e:
        return {"error": str(e), "path": path}

@app.route("/")
def index():
    return send_from_directory("/opt/semperfix/dashboard/templates", "index.html")

@app.route("/logs")
def logs():
    return jsonify({
        "status": "not_implemented"
    })

@app.route("/cluster")
def cluster():
    # Load roles
    master_status = load_json(f"{STATE_DIR}/phoenix-status.json")
    secondary_status = load_json(f"{SECONDARY_DIR}/phoenix-status.json")

    master_role = master_status.get("node", {}).get("role", "UNKNOWN")
    secondary_role = secondary_status.get("node", {}).get("role", "UNKNOWN")

    # MASTERZERO telemetry (always full)
    master = {
        "role": master_role,
        "status": master_status,
        "heartbeat": load_json(f"{STATE_DIR}/phoenix-heartbeat.json"),
        "supervisor": load_json(f"{STATE_DIR}/phoenix-supervisor.json"),
        "mesh": load_json(f"{STATE_DIR}/mesh-status.json"),
        "handshake": load_json(f"{STATE_DIR}/mesh-handshake.json"),
        "verify": load_json(f"{STATE_DIR}/mesh-verify.json"),
        "activate": load_json(f"{STATE_DIR}/mesh-activate.json"),
        "failover": load_json(f"{STATE_DIR}/phoenix-failover.json"),
        "windows": load_json(f"{WIN_DIR}/windows-heartbeat.json"),
        "quic": load_json(f"{STATE_DIR}/quic-client-status.json"),
    }

    # SECONDARY telemetry (role-aware)
    secondary = {
        "role": secondary_role,
        "status": secondary_status,
        "heartbeat": load_json(f"{SECONDARY_DIR}/phoenix-heartbeat.json"),
        "mesh": load_json(f"{SECONDARY_DIR}/mesh-status.json"),
        "handshake": load_json(f"{SECONDARY_DIR}/mesh-handshake.json"),
        "windows": load_json(f"{SECONDARY_DIR}/windows-heartbeat.json"),
    }

    # Only load controller telemetry if SECONDARY is ACTIVE
    if secondary_role == "SECONDARY-ACTIVE":
        secondary["supervisor"] = load_json(f"{SECONDARY_DIR}/phoenix-supervisor.json")
        secondary["verify"] = load_json(f"{SECONDARY_DIR}/mesh-verify.json")
        secondary["activate"] = load_json(f"{SECONDARY_DIR}/mesh-activate.json")
        secondary["failover"] = load_json(f"{SECONDARY_DIR}/phoenix-failover.json")
        secondary["handshake"] = load_json(f"{SECONDARY_DIR}/mesh-handshake.json")
    else:
        secondary["supervisor"] = {"status": "not_applicable"}
        secondary["verify"] = {"status": "not_applicable"}
        secondary["activate"] = {"status": "not_applicable"}
        secondary["failover"] = {"status": "not_applicable"}
        secondary["handshake"] = {"status": "not_applicable"}

    return jsonify({"masterzero": master, "secondary": secondary})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8383, debug=True)
