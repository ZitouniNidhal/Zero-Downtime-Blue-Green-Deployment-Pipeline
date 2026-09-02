# Troubleshooting Guide

## Common Issues and Solutions

### Docker & Compose Issues

#### "docker: command not found"
**Problem**: Docker is not installed or not in PATH
```bash
# Verify installation
docker --version
docker compose version

# On Windows, ensure Docker Desktop is running
# Restart Docker Desktop if needed
```

#### "Cannot connect to Docker daemon"
**Problem**: Docker daemon is not running
```bash
# On Linux
sudo systemctl start docker

# On macOS/Windows
# Start Docker Desktop application
```

#### "port 5432 already in use"
**Problem**: PostgreSQL is already running
```bash
# Find and stop the conflicting service
docker ps | grep postgres
docker compose down

# Or change port in docker-compose.yml
```

### Deployment Issues

#### Health Check Failures

**Symptom**: `Health check failed after 10 retries`

**Diagnosis**:
```bash
# Check if the new container is running
docker compose ps

# View container logs
docker compose logs app-green

# Test health endpoint directly
curl http://localhost:8080/health  # or your configured port
```

**Solutions**:
1. Check application logs for startup errors
2. Verify database connection in new version
3. Ensure required environment variables are set
4. Check if new version is compatible with database schema

#### Traffic Not Switching

**Symptom**: Deploy says success but old version still serving

**Diagnosis**:
```bash
# Check which upstream is active
cat nginx/conf.d/active_upstream.conf

# Verify nginx reloaded
docker compose logs nginx | tail -20

# Check nginx configuration
docker exec nginx-container nginx -t
```

**Solutions**:
1. Manually trigger nginx reload: `docker exec nginx-container nginx -s reload`
2. Check nginx error logs
3. Verify upstream configuration files are correct
4. Restart nginx container

#### Deploy Script Hangs

**Symptom**: `./deploy.sh` starts but never completes

**Solutions**:
```bash
# Check for stuck processes
ps aux | grep docker
docker ps -a

# View real-time logs
docker compose logs -f

# Kill and restart containers
docker compose restart app-blue app-green

# Run deploy again with verbose output
bash -x ./deploy.sh v2
```

### Monitoring Issues

#### Prometheus Not Scraping Metrics

**Symptom**: Empty graph in Prometheus, no metrics collected

**Diagnosis**:
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# View Prometheus logs
docker compose -f monitoring/docker-compose.monitoring.yml logs prometheus
```

**Solutions**:
1. Verify app containers expose `/metrics` endpoint
2. Check `monitoring/prometheus.yml` configuration
3. Ensure containers are on the same Docker network
4. Restart Prometheus: `docker compose restart prometheus`

#### Grafana Shows "No Data"

**Symptom**: Dashboard shows "No Data Available" for queries

**Solutions**:
1. Verify Prometheus data source is configured correctly
2. Check query syntax in dashboard panel
3. Ensure metrics exist in Prometheus
4. Wait 1-2 minutes for data to be scraped
5. Try different time range in dashboard

### Network Issues

#### "Cannot reach app from outside container"

**Symptom**: `curl http://localhost/` fails or times out

**Diagnosis**:
```bash
# Check if containers are running
docker compose ps

# Check port mappings
docker compose ps --format "table {{.Names}}\t{{.Ports}}"

# Test from within container
docker compose exec app-blue curl http://localhost:5000/health
```

**Solutions**:
1. Verify docker-compose.yml has correct port mappings
2. Check firewall allows port 80
3. Restart nginx container
4. On Windows: Check if port is blocked by Windows Firewall

#### "Cannot reach database"

**Symptom**: App container fails to start with "cannot connect to database"

**Diagnosis**:
```bash
# Check database container status
docker compose ps postgres

# Test database connectivity
docker compose exec app-blue psql -h postgres -U app_user -d bluegreen_db -c "SELECT 1"

# View database logs
docker compose logs postgres
```

**Solutions**:
1. Verify database container is running: `docker compose up -d postgres`
2. Wait for database to fully initialize (may take 10-15 seconds)
3. Check `DB_HOST` is set to `postgres` (Docker service name)
4. Reset database: `docker compose down -v && docker compose up -d postgres`

### Rollback Issues

#### Rollback Script Fails

**Symptom**: `./rollback.sh` exits with error

**Diagnosis**:
```bash
# Check which version is currently live
cat nginx/conf.d/active_upstream.conf

# View rollback logs
docker compose logs nginx

# Check deployment history
cat deployments.log
```

**Solutions**:
1. Manually switch upstream: `cp nginx/conf.d/upstream_blue.conf nginx/conf.d/active_upstream.conf`
2. Reload nginx: `docker exec nginx-container nginx -s reload`
3. Verify in logs which version should be active
4. Create a new deployment instead of rollback if history is unclear

### CI/CD Pipeline Issues

#### GitHub Actions Workflow Fails

**Symptom**: Red X on GitHub for workflow run

**Check**:
1. Click on the failing job in GitHub Actions
2. Expand failed step to see error message
3. Common issues:
   - Python dependencies not found: Update `requirements.txt`
   - Test fails: Check test_app.py with `pytest app/test_app.py -v`
   - Database not ready: Increase wait time in workflow
   - SSH key not configured: Check GitHub Secrets

#### Build Phase Fails

**Symptom**: "Failed to push image" in Actions log

**Solutions**:
```bash
# Verify GitHub Container Registry token
# Settings > Developer settings > Personal access tokens
# Token should have: write:packages, read:packages

# Test locally
docker login ghcr.io
docker build -t ghcr.io/username/repo:tag app/
docker push ghcr.io/username/repo:tag
```

#### Deploy Phase Fails

**Symptom**: "SSH connection failed" or "Deploy command failed"

**Verify**:
1. `DEPLOY_SSH_KEY` contains the complete private key; if it is encrypted, `DEPLOY_SSH_PASSPHRASE` is also configured
2. `DEPLOY_HOST` resolves to the server and `DEPLOY_PORT` is reachable from GitHub Actions
3. Deploy server is reachable: `ssh -p <DEPLOY_PORT> -i deploy_key deploy_user@your-server`
4. Deploy path exists: `/opt/bluegreen-deploy`
5. Git repo is initialized on server
6. Deploy user has permission to read/write repository

For a connection timeout, verify the server firewall, cloud security group, SSH
listen port, and whether the server accepts connections from GitHub-hosted runners.

### Performance Issues

#### Slow Health Checks

**Symptom**: Deploy takes longer than expected

**Optimization**:
```bash
# In deploy.sh, adjust these values:
HEALTH_CHECK_INTERVAL=2  # seconds between retries (default: 3)
HEALTH_CHECK_RETRIES=5   # max retries (default: 10)

# Or via environment variables
export HEALTH_CHECK_INTERVAL=2
export HEALTH_CHECK_RETRIES=5
./deploy.sh v2
```

#### High Memory Usage

**Symptom**: Containers consuming excessive memory

**Diagnosis**:
```bash
# Check memory usage
docker stats

# View container logs for memory leaks
docker compose logs app-blue | grep -i memory
```

**Solutions**:
1. Add memory limits in docker-compose.yml:
   ```yaml
   services:
     app-blue:
       deploy:
         resources:
           limits:
             memory: 512M
   ```
2. Check application for memory leaks
3. Reduce log verbosity

### Log Analysis

#### View Real-Time Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app-blue

# Last 50 lines
docker compose logs --tail=50

# With timestamps
docker compose logs -f -t
```

#### Search Logs for Errors

```bash
# Find all errors
docker compose logs | grep -i error

# Find specific pattern
docker compose logs | grep "connection refused"

# Export logs to file
docker compose logs > deployment.log 2>&1
```

## When All Else Fails

### Full Reset

```bash
# Stop and remove all containers
docker compose down -v

# Remove volumes to reset database
docker volume prune

# Rebuild and start fresh
docker compose up -d --build

# Check status
docker compose ps
curl http://localhost/health
```

### Debug Mode

```bash
# Run deploy script with verbose output
bash -x ./deploy.sh v2 2>&1 | tee debug.log

# Run container in interactive mode
docker compose run --rm app-blue bash

# Check network connectivity
docker compose exec app-blue ping postgres
docker compose exec app-blue ping nginx
```

### Get Help

1. Check `deployments.log` for audit trail
2. Review application logs: `docker compose logs app-blue`
3. Check Prometheus metrics: `http://localhost:9090`
4. Inspect container state: `docker inspect app-blue`
5. Review GitHub Actions logs for CI/CD issues

## Useful Commands Reference

```bash
# Container management
docker compose ps                    # List all containers
docker compose logs -f               # Follow all logs
docker compose exec app-blue bash    # Shell into container
docker compose restart app-blue      # Restart container

# Deployment
./deploy.sh v2                       # Deploy new version
./rollback.sh                        # Rollback to previous version
cat deployments.log                  # View deployment history

# Health checks
curl http://localhost/               # Test app endpoint
curl http://localhost/health         # Test health endpoint
curl http://localhost/metrics        # View Prometheus metrics

# Database
docker compose exec postgres psql -U app_user -d bluegreen_db  # Connect to DB
docker compose logs postgres         # View DB logs

# Nginx
docker exec nginx-container nginx -t                 # Test config
docker exec nginx-container nginx -s reload         # Reload config
docker compose logs nginx                           # View nginx logs
```
