#!/bin/bash

# Setup script for Blue-Green Deployment Pipeline
# This script helps initialize the development environment

set -e  # Exit on error

echo "================================"
echo "Blue-Green Deployment Setup"
echo "================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "   Please install Docker Desktop from https://www.docker.com"
    exit 1
fi
echo "✓ Docker found: $(docker --version)"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose v2 is not available"
    echo "   Please upgrade Docker to include Docker Compose v2"
    exit 1
fi
echo "✓ Docker Compose found: $(docker compose version | head -1)"

# Check Git
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed"
    echo "   Please install Git from https://git-scm.com"
    exit 1
fi
echo "✓ Git found: $(git --version)"

# Check curl
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed"
    echo "   Please install curl"
    exit 1
fi
echo "✓ curl found"

echo ""
echo "All prerequisites met!"
echo ""

# Setup environment file
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "✓ .env created"
    echo "  Please review and update database credentials and other settings"
else
    echo "✓ .env already exists"
fi

echo ""
echo "Building Docker images..."
docker compose build --quiet

echo ""
echo "Starting services..."
docker compose up -d --quiet-pull

echo ""
echo "Waiting for services to be ready..."
RETRIES=30
RETRY_DELAY=2

while [ $RETRIES -gt 0 ]; do
    if docker compose ps | grep -q "healthy\|running"; then
        # Check if app is responding
        if curl -s http://localhost/health > /dev/null 2>&1; then
            echo "✓ Services are ready"
            break
        fi
    fi
    echo "  Waiting... ($RETRIES retries left)"
    sleep $RETRY_DELAY
    RETRIES=$((RETRIES - 1))
done

if [ $RETRIES -eq 0 ]; then
    echo "⚠ Services may not be ready yet"
    echo "  Run: docker compose logs -f"
    echo "  to check the status"
fi

echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Verify services are running:"
echo "   curl http://localhost/          # Should return 200"
echo "   curl http://localhost/health    # Should return OK"
echo ""
echo "2. Run tests:"
echo "   cd app && pytest test_app.py -v"
echo ""
echo "3. Deploy a new version:"
echo "   ./deploy.sh v2"
echo ""
echo "4. Monitor deployment:"
echo "   docker compose logs -f app-blue app-green"
echo ""
echo "5. Access monitoring stack (optional):"
echo "   cd monitoring && docker compose -f docker-compose.monitoring.yml up -d"
echo "   Prometheus: http://localhost:9090"
echo "   Grafana:    http://localhost:3000"
echo ""
echo "For more information, see DEPLOYMENT_GUIDE.md"
echo ""
