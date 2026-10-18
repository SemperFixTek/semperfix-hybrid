from flask import Flask, jsonify, render_template
import json
import os
import glob

STATE_DIR = "/var/lib/semperfix/state"
LOG_DIR = "/opt/semperfix/logs"

app = Flask(__name__)

def load_json(path):
    try:
        with open(path, "r") as f:
            return json.load(f)
    except:
        return {}

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/cluster")
def cluster():
    cluster = {
        "masterzero": {
            "heartbeat": load_json(f"{STATE_DIR}/phoenix-heartbeat.json"),
            "supervisor": load_json(f"{STATE_DIR}/phoenix-supervisor.json"),
            "mesh": load_json(f"{STATE_DIR}/mesh-status.json"),
            "quic": load_json(f"{STATE_DIR}/quic-client-status.json"),
            "failover": load_json(f"{STATE_DIR}/phoenix-failover.json"),
            "windows": load_json(f"{STATE_DIR}/windows-heartbeat.json"),
        },
        "secondary": {
            "heartbeat": load_json(f"{STATE_DIR}/secondary/phoenix-heartbeat.json"),
            "supervisor": load_json(f"{STATE_DIR}/secondary/phoenix-supervisor.json"),
            "mesh": load_json(f"{STATE_DIR}/secondary/mesh-status.json"),
            "quic": load_json(f"{STATE_DIR}/secondary/quic-client-status.json"),
            "failover": load_json(f"{STATE_DIR}/secondary/phoenix-failover.json"),
            "windows": load_json(f"{STATE_DIR}/secondary/windows-heartbeat.json"),
        }
    }
    return jsonify(cluster)

@app.route("/logs")
def logs():
    log_files = glob.glob(f"{LOG_DIR}/*.log")
    logs = {}
    for lf in log_files:
        try:
            with open(lf, "r") as f:
                logs[os.path.basename(lf)] = f.read().splitlines()[-200:]
        except:
            logs[os.path.basename(lf)] = ["<unreadable>"]
    return jsonify(logs)

app.run(host="0.0.0.0", port=8080)
