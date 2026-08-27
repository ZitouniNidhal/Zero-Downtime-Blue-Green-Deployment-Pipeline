#!/usr/bin/env bash
#
# rollback.sh - Manually flip nginx traffic back to the other color.
# Useful if a bad deploy passed health checks but shows issues in production
# metrics/logs after the switch.

set -euo pipefail

NGINX_CONF_DIR="./nginx/conf.d"
ACTIVE_CONF="${NGINX_CONF_DIR}/active_upstream.conf"
LOG_FILE="./deployments.log"

log() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') | $*" | tee -a "$LOG_FILE"
}

current_color() {
    if grep -q "app-blue" "$ACTIVE_CONF"; then
        echo "blue"
    else
        echo "green"
    fi
}

LIVE=$(current_color)
TARGET=$([ "$LIVE" = "blue" ] && echo "green" || echo "blue")

log "Manual rollback requested: ${LIVE} -> ${TARGET}"
cp "${NGINX_CONF_DIR}/upstream_${TARGET}.conf" "$ACTIVE_CONF"
docker exec bg-nginx nginx -s reload
log "Rollback complete. Traffic now served by ${TARGET}."
