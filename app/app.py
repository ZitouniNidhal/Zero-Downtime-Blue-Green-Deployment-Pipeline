import logging
import os
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("app")

APP_VERSION = os.environ.get("APP_VERSION", "v1")
COLOR = os.environ.get("DEPLOY_COLOR", "unknown")

# DB Configuration
DB_HOST = os.environ.get("DB_HOST", "db")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "appdb")
DB_USER = os.environ.get("DB_USER", "app")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "app")


def check_db_connection():
    """Check database connectivity using psycopg2 or socket fallback."""
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=2
        )
        conn.close()
        return True, "connected"
    except Exception as e:
        logger.warning(f"Database connection check failed: {e}")
        return False, str(e)


@app.route("/")
def index():
    logger.info(f"Root endpoint hit on version={APP_VERSION}, color={COLOR}")
    return jsonify(
        message="Hello from the Blue-Green demo app!",
        version=APP_VERSION,
        color=COLOR,
        time=datetime.now(timezone.utc).isoformat(),
    )



@app.route("/health")
def health():
    db_ok, db_status = check_db_connection()
    status_code = 200 if db_ok else 200  # Soft health check reporting DB status
    
    return jsonify(
        status="healthy" if db_ok else "degraded",
        version=APP_VERSION,
        color=COLOR,
        database={
            "connected": db_ok,
            "details": db_status
        }
    ), status_code


@app.route("/metrics")
def metrics():
    # Prometheus text metrics format
    body = (
        "# HELP app_up App is up\n"
        "# TYPE app_up gauge\n"
        f'app_up{{version="{APP_VERSION}",color="{COLOR}"}} 1\n'
    )
    return body, 200, {"Content-Type": "text/plain; version=0.0.4"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
