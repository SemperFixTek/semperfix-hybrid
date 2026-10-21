@app.route("/cluster")
def cluster():
    # Load roles
    master_role = load_json(f"{STATE_DIR}/phoenix-status.json").get("node", {}).get("role", "UNKNOWN")
    secondary_role = load_json(f"{STATE_DIR}/secondary/phoenix-status.json").get("node", {}).get("role", "UNKNOWN")

    # MASTERZERO telemetry (always full)
    master = {
        "role": master_role,
        "heartbeat": load_json(f"{STATE_DIR}/phoenix-heartbeat.json"),
        "supervisor": load_json(f"{STATE_DIR}/phoenix-supervisor.json"),
        "mesh": load_json(f"{STATE_DIR}/mesh-status.json"),
        "quic": load_json(f"{STATE_DIR}/quic-client-status.json"),
        "failover": load_json(f"{STATE_DIR}/phoenix-failover.json"),
        "windows": load_json(f"{STATE_DIR}/windows-heartbeat.json"),
    }

    # SECONDARY telemetry (role-aware)
    secondary_base = f"{STATE_DIR}/secondary"

    secondary = {
        "role": secondary_role,
        "heartbeat": load_json(f"{secondary_base}/phoenix-heartbeat.json"),
        "mesh": load_json(f"{secondary_base}/mesh-status.json"),
        "quic": load_json(f"{secondary_base}/quic-client-status.json"),
        "windows": load_json(f"{secondary_base}/windows-heartbeat.json"),
    }

    # Only load controller telemetry if SECONDARY is ACTIVE
    if secondary_role == "SECONDARY-ACTIVE":
        secondary["supervisor"] = load_json(f"{secondary_base}/phoenix-supervisor.json")
        secondary["failover"] = load_json(f"{secondary_base}/phoenix-failover.json")
    else:
        secondary["supervisor"] = {"status": "not_applicable"}
        secondary["failover"] = {"status": "not_applicable"}

    return jsonify({"masterzero": master, "secondary": secondary})
