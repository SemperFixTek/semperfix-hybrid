#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

SUP_FILE="${STATE_DIR}/phoenix-supervisor.json"
LOGFILE="${LOG_DIR}/phoenix-supervisor.log"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

run_handshake()  { /opt/semperfix/scripts/wsl-mesh-handshake.sh; }
run_verify()     { /opt/semperfix/scripts/wsl-mesh-verify.sh; }
run_activate()   { /opt/semperfix/scripts/wsl-mesh-activate.sh; }

# Normalize legacy roles
normalize_role() {
    case "$NODE_ROLE" in
        MASTERZERO) echo "MASTERZERO-ACTIVE" ;;
        SECONDARY)  echo "SECONDARY-PASSIVE" ;;
        *) echo "$NODE_ROLE" ;;
    esac
}

ROLE="$(normalize_role)"
log "Phoenix v2 Supervisor starting for role: $ROLE"

main() {
    local handshake_status="not_applicable"
    local verify_status="not_applicable"
    local activate_status="not_applicable"

    case "$ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)
            log "$ROLE performing full supervisor cycle"

            if run_handshake; then handshake_status="pass"; else handshake_status="fail"; fi
            if run_verify;    then verify_status="pass";    else verify_status="fail";    fi
            if run_activate;  then activate_status="pass";  else activate_status="fail";  fi
            ;;

        SECONDARY-ACTIVE)
            log "SECONDARY-ACTIVE performing full supervisor cycle (promoted)"

            if run_handshake; then handshake_status="pass"; else handshake_status="fail"; fi
            if run_verify;    then verify_status="pass";    else verify_status="fail";    fi
            if run_activate;  then activate_status="pass";  else activate_status="fail";  fi
            ;;

        SECONDARY-PASSIVE)
            log "SECONDARY-PASSIVE — supervisor disabled"
            handshake_status="not_applicable"
            verify_status="not_applicable"
            activate_status="not_applicable"
            ;;

        OFFSITE)
            log "OFFSITE performing limited supervisor cycle"

            if run_handshake; then handshake_status="pass"; else handshake_status="fail"; fi
            verify_status="not_applicable"
            activate_status="not_applicable"
            ;;

        *)
            log "Unknown node role: ${ROLE}"
            handshake_status="invalid_role"
            verify_status="invalid_role"
            activate_status="invalid_role"
            ;;
    esac

    # Unified JSON Writer
    json_init "$SUP_FILE"

    json_set "$SUP_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$SUP_FILE" "node_role" "$ROLE"
    json_set "$SUP_FILE" "handshake_status" "$handshake_status"
    json_set "$SUP_FILE" "verify_status" "$verify_status"
    json_set "$SUP_FILE" "activate_status" "$activate_status"

    # Backward compatibility
    json_set "$SUP_FILE" "handshake" "$handshake_status"
    json_set "$SUP_FILE" "verify" "$verify_status"
    json_set "$SUP_FILE" "activate" "$activate_status"

    json_finalize "$SUP_FILE"

    /opt/semperfix/scripts/json-perms.sh "$SUP_FILE"

    log "Supervisor state written to $SUP_FILE"
}

main "$@"
