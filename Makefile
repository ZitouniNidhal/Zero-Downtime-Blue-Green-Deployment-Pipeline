# Makefile for Blue-Green Deployment Pipeline
# Provides convenient commands for development and deployment

.PHONY: help setup build up down logs test deploy rollback clean monitor

help:
	@echo "Blue-Green Deployment Pipeline - Available Commands"
	@echo ""
	@echo "Setup & Configuration:"
	@echo "  make setup          - Initial setup and environment configuration"
	@echo "  make build          - Build Docker images"
	@echo ""
	@echo "Local Development:"
	@echo "  make up             - Start all services"
	@echo "  make down           - Stop all services"
	@echo "  make logs           - View service logs (follow mode)"
	@echo "  make ps             - List running services"
	@echo ""
	@echo "Testing & Quality:"
	@echo "  make test           - Run unit tests"
	@echo "  make test-coverage  - Run tests with coverage report"
	@echo "  make lint           - Run linting checks"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-v2      - Deploy version v2 (example)"
	@echo "  make rollback       - Rollback to previous version"
	@echo "  make logs-deploy    - View deployment logs"
	@echo ""
	@echo "Monitoring:"
	@echo "  make monitor-up     - Start monitoring stack (Prometheus, Grafana)"
	@echo "  make monitor-down   - Stop monitoring stack"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Remove containers and volumes (DESTRUCTIVE)"
	@echo "  make reset          - Full reset to clean state"
	@echo ""

setup:
	@echo "Running setup script..."
	@bash scripts/init-env.sh

build:
	@echo "Building Docker images..."
	docker compose build

up:
	@echo "Starting services..."
	docker compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 3
	@docker compose ps

down:
	@echo "Stopping services..."
	docker compose down

ps:
	docker compose ps

logs:
	docker compose logs -f

logs-app:
	docker compose logs -f app-blue app-green

logs-db:
	docker compose logs -f postgres

logs-nginx:
	docker compose logs -f nginx

logs-deploy:
	@tail -50 deployments.log || echo "No deployment log found"

test:
	@echo "Running tests..."
	cd app && pytest test_app.py -v

test-coverage:
	@echo "Running tests with coverage..."
	cd app && pytest test_app.py --cov=. --cov-report=html --cov-report=term
	@echo "Coverage report: app/htmlcov/index.html"

lint:
	@echo "Running linting checks..."
	cd app && flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics || true

shell-app-blue:
	docker compose exec app-blue bash

shell-app-green:
	docker compose exec app-green bash

shell-db:
	docker compose exec postgres psql -U app_user -d bluegreen_db

health-check:
	@echo "Checking service health..."
	@curl -s http://localhost/ > /dev/null && echo "✓ App endpoint: OK" || echo "✗ App endpoint: FAILED"
	@curl -s http://localhost/health > /dev/null && echo "✓ Health endpoint: OK" || echo "✗ Health endpoint: FAILED"
	@curl -s http://localhost/metrics > /dev/null && echo "✓ Metrics endpoint: OK" || echo "✗ Metrics endpoint: FAILED"

verify-traffic:
	@echo "Monitoring traffic (Ctrl+C to stop)..."
	@while true; do \
		echo -n "$$(date +%H:%M:%S) "; \
		curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/; \
		sleep 0.5; \
	done

deploy-v2:
	@echo "Deploying version v2..."
	@./deploy.sh v2
	@echo "Deployment complete"

rollback:
	@echo "Rolling back to previous version..."
	@./rollback.sh
	@echo "Rollback complete"

monitor-up:
	@echo "Starting monitoring stack..."
	cd monitoring && docker compose -f docker-compose.monitoring.yml up -d
	@echo "Monitoring services started:"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin)"
	@echo "  cAdvisor:   http://localhost:8080"

monitor-down:
	@echo "Stopping monitoring stack..."
	cd monitoring && docker compose -f docker-compose.monitoring.yml down

monitor-logs:
	cd monitoring && docker compose -f docker-compose.monitoring.yml logs -f

clean:
	@echo "WARNING: This will remove all containers and volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "Cleanup complete"; \
	else \
		echo "Aborted"; \
	fi

reset: clean build up
	@echo "Reset complete - services are running"

prune:
	@echo "Pruning Docker resources..."
	docker system prune -f

version:
	@echo "Checking deployed versions..."
	@echo "Current active upstream:"
	@cat nginx/conf.d/active_upstream.conf || echo "Not yet initialized"

.DEFAULT_GOAL := help
