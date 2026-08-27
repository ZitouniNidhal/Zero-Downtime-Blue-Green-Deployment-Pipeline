#!/usr/bin/env bash
#
# deploy.sh - Blue-Green deployment script
#
# Usage:
#   ./deploy.sh <new_version_tag>
#
# What it does:
#   1. Figures out which color is currently LIVE (blue or green) by
#      reading nginx/conf.d/active_upstream.conf
#   2. Builds/starts the new version in the IDLE color
#   3. Health-checks the idle container until it's ready (with retries)
#   4. Switches nginx to point at the idle (now new-live) color and reloads
#   5. Verifies traffic is flowing correctly through nginx
#   6. Logs the deployment; on failure, leaves the old version live (no-op rollback)
#
# Requires: docker, docker compose (v2 plugin), curl

set -euo pipefail

NEW_TAG="${1:?Usage: ./deploy.sh <new_version_tag>}"
NGINX_CONF_DIR="./nginx/conf.d"
ACTIVE_CONF="${NGINX_CONF_DIR}/active_upstream.conf"
LOG_FILE="./deployments.log"
HEALTH_RETRIES=10
HEALTH_DELAY=3

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

opposite_color() {
    [ "$1" = "blue" ] && echo "green" || echo "blue"
}

health_check() {
    local color="$1"
    local container="app-${color}"
    for i in $(seq 1 "$HEALTH_RETRIES"); do
        if docker exec "$container" python -c \
            "import urllib.request,sys; sys.exit(0) if urllib.request.urlopen('http://localhost:5000/health', timeout=2).status==200 else sys.exit(1)" \
            >/dev/null 2>&1; then
            log "Health check passed for ${container} (attempt ${i}/${HEALTH_RETRIES})"
            return 0
        fi
        log "Health check attempt ${i}/${HEALTH_RETRIES} failed for ${container}, retrying in ${HEALTH_DELAY}s..."
        sleep "$HEALTH_DELAY"
    done
    return 1
}

main() {
    LIVE=$(current_color)
    IDLE=$(opposite_color "$LIVE")

    log "=== Starting deployment ==="
    log "Current LIVE color: ${LIVE} | Deploying version '${NEW_TAG}' to IDLE color: ${IDLE}"

    # Build & start the new version in the idle slot only.
    if [ "$IDLE" = "blue" ]; then
        BLUE_TAG="$NEW_TAG" docker compose build app-blue
        BLUE_TAG="$NEW_TAG" docker compose up -d --no-deps app-blue
    else
        GREEN_TAG="$NEW_TAG" docker compose build app-green
        GREEN_TAG="$NEW_TAG" docker compose up -d --no-deps app-green
    fi

    # Health-check the idle (new) container before sending it traffic.
    if ! health_check "$IDLE"; then
        log "DEPLOY FAILED: ${IDLE} did not become healthy. Leaving ${LIVE} live. No traffic switched."
        exit 1
    fi

    # Switch nginx upstream to the now-healthy idle color.
    log "Switching nginx traffic: ${LIVE} -> ${IDLE}"
    cp "${NGINX_CONF_DIR}/upstream_${IDLE}.conf" "$ACTIVE_CONF"
    docker exec bg-nginx nginx -s reload

    sleep 2

    # Verify traffic is actually reaching the new version through nginx.
    RESPONSE=$(curl -s http://localhost/health || true)
    if echo "$RESPONSE" | grep -q "\"color\": \"${IDLE}\""; then
        log "DEPLOY SUCCESS: traffic now served by ${IDLE} (version ${NEW_TAG})"
    else
        log "WARNING: could not confirm nginx is routing to ${IDLE}. Response: ${RESPONSE}"
        log "Rolling back to ${LIVE}..."
        cp "${NGINX_CONF_DIR}/upstream_${LIVE}.conf" "$ACTIVE_CONF"
        docker exec bg-nginx nginx -s reload
        log "ROLLBACK COMPLETE: traffic restored to ${LIVE}"
        exit 1
    fi

    log "Previous LIVE color (${LIVE}) is still running as the new IDLE slot for the next rollback/deploy."
    log "=== Deployment finished ==="
}

main
