# Zero-Downtime Blue-Green Deployment Pipeline

A hands-on implementation deploy a new version of an app into an idle container,
health-check it, then atomically switch live traffic to it via Nginx — with
zero downtime and zero dropped requests.

## Architecture

```
Internet ──▶ Nginx (port 80) ──▶ [ app-blue OR app-green ]  (only one is "live" at a time)
                                          │
                                          ▼
                                    Shared Postgres DB
```

- **app-blue / app-green**: two identical containers built from the same Flask
  app, running different versions/tags.
- **nginx**: reverse proxy. Its active upstream (`nginx/conf.d/active_upstream.conf`)
  determines which color receives traffic. Switching is a file swap + `nginx -s reload`
  (no restart, no dropped connections).
- **db**: a single shared Postgres instance so switching colors never loses data.

## Prerequisites

- Docker + Docker Compose v2
- `curl`
- (For CI/CD) a server reachable via SSH, and a GitHub repo with secrets configured

## Quick Start (local)

```bash
git clone <your-repo-url>
cd bluegreen-deploy
cp .env.example .env

docker compose up -d --build
curl http://localhost/          # -> served by app-blue (v1), the initial live color
curl http://localhost/health
```

## Deploying a New Version (the blue-green switch)

```bash
./deploy.sh v2
```

What happens:
1. Detects the current live color (e.g. blue).
2. Builds and starts `v2` in the idle color (green).
3. Health-checks green's `/health` endpoint (10 retries, 3s apart).
4. If healthy: swaps Nginx's upstream to green and reloads Nginx.
5. Verifies traffic is actually reaching green.
6. Logs every step to `deployments.log`.
7. If the health check or the post-switch verification fails, it automatically
   rolls back (or never switches in the first place) — the old version keeps
   serving traffic throughout.

To prove zero downtime, run this in a second terminal while deploying:
```bash
while true; do curl -s -o /dev/null -w "%{http_code} " http://localhost/; sleep 0.2; done
```
You should see an unbroken stream of `200`s through the entire deploy.

## Manual Rollback

```bash
./rollback.sh
```
Flips traffic back to whichever color was previously live.

## CI/CD Pipeline (Bonus)

`.github/workflows/deploy.yml`:
1. On push to `main`, builds the Docker image and pushes it to GHCR, tagged
   with the short git SHA.
2. SSHes into the production server and runs `./deploy.sh <sha>`.
3. Uses a GitHub **Environment** (`production`) so you can require manual
   approval before the deploy step runs.

**Required GitHub secrets:**
Add these as secrets under **Settings > Environments > production**. Repository-level
secrets are not available here unless they are also configured for the environment.

| Secret | Description |
|---|---|
| `DEPLOY_HOST` | Server IP/hostname |
| `DEPLOY_USER` | SSH user |
| `DEPLOY_SSH_KEY` | Private key with access to the server |

On the server, this repo should be cloned to `/opt/bluegreen-deploy` (or update the path in the workflow).

## Monitoring (Bonus)

```bash
docker compose up -d    # main stack must be running first (creates the shared network)
cd monitoring
docker compose -f docker-compose.monitoring.yml up -d
```

- **Prometheus** → http://localhost:9090 — scrapes `/metrics` from both
  app-blue and app-green, labeled by `color` and `version`, plus container
  metrics via cAdvisor.
- **Grafana** → http://localhost:3000 (admin/admin) — build a dashboard
  filtering by the `color` label to visually watch traffic shift from blue
  to green during a deploy.
- **cAdvisor** → http://localhost:8080 — per-container CPU/memory.

## Project Structure

```
bluegreen-deploy/
├── app/                          # Demo Flask app (swap for your own service)
│   ├── app.py
│   ├── test_app.py               # Unit & health check tests
│   ├── requirements.txt
│   ├── requirements-dev.txt      # Test dependencies (pytest)
│   └── Dockerfile
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── active_upstream.conf  # swapped by deploy.sh — the traffic switch
│       ├── upstream_blue.conf
│       └── upstream_green.conf
├── monitoring/
│   ├── prometheus.yml
│   └── docker-compose.monitoring.yml
├── .github/workflows/
│   ├── ci.yml                    # Automated unit tests on push/PR
│   └── deploy.yml                # Build, attest provenance & deploy
├── docker-compose.yml
├── deploy.sh                     # core blue-green deploy logic
├── rollback.sh
└── deployments.log               # generated audit log of every switch
```

## What This Demonstrates

- Zero-downtime deployment via reverse-proxy traffic switching
- Automated pre-switch health checks (fail-safe: bad deploys never go live)
- Automated rollback on failed verification
- Auditable deployment history
- CI/CD from git push to production
- Observability into which version is serving traffic in real time
