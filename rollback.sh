#!/usr/bin/env bash
#
# rollback.sh - Manually flip Nginx traffic back to the alternate color.
# Useful if an issue is detected post-deployment.

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

log "=================================================="
log "Manual Rollback Requested: ${LIVE} -> ${TARGET}"
log "=================================================="

cp "${NGINX_CONF_DIR}/upstream_${TARGET}.conf" "$ACTIVE_CONF"
if docker exec bg-nginx nginx -s reload; then
    log "✓ Rollback complete. Traffic is now served by ${TARGET}."
    log "=================================================="
else
    log "❌ ERROR: Failed to reload Nginx during rollback!"
    exit 1
fi
