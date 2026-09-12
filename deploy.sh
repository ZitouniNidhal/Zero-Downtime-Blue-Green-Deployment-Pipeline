#!/usr/bin/env bash
#
# deploy.sh - Zero-Downtime Blue-Green Deployment Script
# Usage: ./deploy.sh [version_tag]
# Example: ./deploy.sh v2

set -euo pipefail

TARGET_TAG="${1:-v2}"
NGINX_CONF_DIR="./nginx/conf.d"
ACTIVE_CONF="${NGINX_CONF_DIR}/active_upstream.conf"
LOG_FILE="./deployments.log"
HEALTH_CHECK_RETRIES=10
HEALTH_CHECK_DELAY=3

log() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') | $*" | tee -a "$LOG_FILE"
}

# Ensure nginx conf directory exists
mkdir -p "$NGINX_CONF_DIR"

# Ensure active_upstream.conf exists, default to blue if missing
if [ ! -f "$ACTIVE_CONF" ]; then
    log "active_upstream.conf missing. Initializing default to app-blue."
    cp "${NGINX_CONF_DIR}/upstream_blue.conf" "$ACTIVE_CONF"
fi

# Detect current live color
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
log "Starting Deployment of Tag: ${TARGET_TAG}"
log "Current Live Color : ${LIVE}"
log "Deploying to Idle  : ${TARGET}"
log "=================================================="

# Export tag for docker-compose based on target color
if [ "$TARGET" = "green" ]; then
    export GREEN_TAG="$TARGET_TAG"
    export BLUE_TAG="${BLUE_TAG:-v1}"
else
    export BLUE_TAG="$TARGET_TAG"
    export GREEN_TAG="${GREEN_TAG:-v1}"
fi

# 1. Build and start target service container
log "Building and starting container app-${TARGET} with tag ${TARGET_TAG}..."
docker compose up -d --build "app-${TARGET}"

# 2. Perform Health Check on Target Service
log "Performing health checks on target container (app-${TARGET})..."
HEALTHY=false

for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
    log "Health check attempt ${i}/${HEALTH_CHECK_RETRIES} for app-${TARGET}..."
    
    # Check if app container endpoint responds with 200 OK
    HTTP_STATUS=$(docker exec bg-nginx curl -s -o /dev/null -w "%{http_code}" "http://app-${TARGET}:5000/health" || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        log "✓ Target container app-${TARGET} passed health check (HTTP 200)."
        HEALTHY=true
        break
    fi
    
    log "  Attempt ${i} failed (HTTP ${HTTP_STATUS}). Retrying in ${HEALTH_CHECK_DELAY}s..."
    sleep "$HEALTH_CHECK_DELAY"
done

if [ "$HEALTHY" = false ]; then
    log "❌ ERROR: Health checks failed for app-${TARGET} with tag ${TARGET_TAG}."
    log "Deployment aborted. Traffic remains routed to ${LIVE}."
    exit 1
fi

# 3. Swap Nginx Upstream & Reload (Atomic Traffic Switch)
log "Swapping Nginx upstream configuration to ${TARGET}..."
cp "${NGINX_CONF_DIR}/upstream_${TARGET}.conf" "$ACTIVE_CONF"

log "Reloading Nginx proxy..."
if docker exec bg-nginx nginx -s reload; then
    log "✓ Nginx reloaded successfully."
else
    log "❌ ERROR: Failed to reload Nginx. Rolling back upstream configuration."
    cp "${NGINX_CONF_DIR}/upstream_${LIVE}.conf" "$ACTIVE_CONF"
    docker exec bg-nginx nginx -s reload || true
    exit 1
fi

# 4. Post-Switch Verification
log "Verifying post-switch live traffic..."
# Verify that the response contains the TARGET_TAG
RESPONSE_BODY=$(docker exec bg-nginx curl -s http://localhost/)
VERIFY_STATUS=$(docker exec bg-nginx curl -s -o /dev/null -w "%{http_code}" "http://localhost/health" || echo "000")

if [ "$VERIFY_STATUS" = "200" ] && echo "$RESPONSE_BODY" | grep -q "$TARGET_TAG"; then
    log "✓ Deployment successful! Traffic is now served by ${TARGET} (${TARGET_TAG})."
    log "=================================================="
else
    log "⚠️ Post-switch verification failed (HTTP ${VERIFY_STATUS} or version mismatch). Triggering automatic rollback to ${LIVE}!"
    cp "${NGINX_CONF_DIR}/upstream_${LIVE}.conf" "$ACTIVE_CONF"
    docker exec bg-nginx nginx -s reload
    log "Automatic rollback to ${LIVE} complete."
    exit 1
fi
