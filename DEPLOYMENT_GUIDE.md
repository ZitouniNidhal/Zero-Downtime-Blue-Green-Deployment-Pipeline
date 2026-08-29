# Deployment Guide

## Local Development Setup

### Prerequisites
- Docker Desktop (includes Docker Compose v2)
- Git
- curl (for health check testing)
- Python 3.11+ (for local testing)

### Initial Setup

1. **Clone and configure:**
   ```bash
   git clone <your-repo-url>
   cd Zero-Downtime-Blue-Green-Deployment-Pipeline
   cp .env.example .env
   ```

2. **Edit `.env` with your settings:**
   ```bash
   # Update these values for your environment
   DB_PASSWORD=your-secure-password
   FLASK_ENV=development
   ```

3. **Start the stack:**
   ```bash
   docker compose up -d --build
   ```

4. **Verify services are running:**
   ```bash
   curl http://localhost/          # App endpoint
   curl http://localhost/health    # Health check
   curl http://localhost/metrics   # Prometheus metrics
   ```

## Deploying a New Version

### Local Testing

```bash
# Run unit tests
cd app
pytest test_app.py -v

# Run with coverage
pytest test_app.py --cov=. --cov-report=html
```

### Deploy to Production

```bash
# Option 1: SSH into server and deploy manually
ssh deploy_user@your-server
cd /opt/bluegreen-deploy
./deploy.sh v2

# Option 2: Push to main branch (triggers CI/CD)
git commit -am "Release v2"
git push origin main
# Watch GitHub Actions for deployment progress
```

### Monitor Deployment

```bash
# In one terminal, watch real-time traffic
while true; do 
  echo -n "$(date +%H:%M:%S) "
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost/
  sleep 0.5
done

# In another terminal, check logs
docker compose logs -f app-blue app-green
```

## Rollback Procedure

If a deployment fails or needs to be reverted:

```bash
# Automatic rollback (if deployment detected issues)
./rollback.sh

# Or SSH and rollback manually
ssh deploy_user@your-server
cd /opt/bluegreen-deploy
./rollback.sh

# Check deployment log to see what happened
tail -50 deployments.log
```

## Monitoring

### Access Monitoring Stack

```bash
# Start monitoring services
cd monitoring
docker compose -f docker-compose.monitoring.yml up -d

# Access dashboards
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)
# cAdvisor: http://localhost:8080
```

### Create Grafana Dashboard

1. Log in to Grafana (http://localhost:3000)
2. Add Prometheus as data source: `http://prometheus:9090`
3. Create dashboard with queries:
   ```
   app_requests_total{color=~"blue|green"}
   app_deployment_duration_seconds
   container_cpu_usage_seconds_total{name=~"app-blue|app-green"}
   ```

## Production Deployment

### Server Setup

1. **SSH into production server:**
   ```bash
   ssh deploy_user@your-server
   ```

2. **Clone the repository:**
   ```bash
   sudo mkdir -p /opt/bluegreen-deploy
   sudo chown deploy_user:deploy_user /opt/bluegreen-deploy
   cd /opt/bluegreen-deploy
   git clone <your-repo-url> .
   ```

3. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with production values
   nano .env
   ```

4. **Generate SSH keys for GitHub (optional):**
   ```bash
   ssh-keygen -t ed25519 -C "deploy@your-server"
   # Add public key to GitHub deploy keys
   ```

### CI/CD Pipeline Setup

1. **Add GitHub Secrets** (Settings > Environments > production):
   - `DEPLOY_HOST`: Your server IP/hostname
   - `DEPLOY_USER`: SSH username (e.g., `deploy_user`)
   - `DEPLOY_SSH_KEY`: Private SSH key (format: `-----BEGIN OPENSSH PRIVATE KEY-----\n...`)

2. **Verify workflow permissions:**
   - Settings > Actions > General
   - Workflow permissions: "Read and write permissions"
   - Allow GitHub Actions to create and approve pull requests: ✓

3. **Test deployment:**
   - Create a test PR against `main`
   - Merge to main
   - Watch Actions tab for workflow execution

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Rollback Scenarios

| Scenario | Action |
|----------|--------|
| Deploy failed health checks | Automatic rollback, old version stays live |
| Traffic verification failed | Automatic rollback, old version stays live |
| Manual rollback needed | Run `./rollback.sh` on server |
| Database issues | Check logs: `docker compose logs postgres` |
| Nginx config error | Check `/etc/nginx/nginx.conf` or `nginx/nginx.conf` |

## Performance Notes

- Health checks run with 3s interval, 10 retries max
- Nginx reload is non-blocking (no dropped connections)
- Deployments typically complete in 30-60 seconds
- No database migrations run during deploy (manage separately)

## Support

For issues or questions:
1. Check `deployments.log` for deployment history
2. Check container logs: `docker compose logs <service-name>`
3. Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
4. Check GitHub Actions workflow logs for CI/CD issues
