import logging
import os
import time
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

def init_db():
    """Initialize the database schema if it doesn't exist."""
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
        cur = conn.cursor()
        cur.execute("CREATE TABLE IF NOT EXISTS visits (id SERIAL PRIMARY KEY, visited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);")
        conn.commit()
        cur.close()
        conn.close()
        logger.info("Database initialized successfully.")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")

# Initialize DB on startup
init_db()


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
    start_time = time.time()
    logger.info(f"Root endpoint hit on version={APP_VERSION}, color={COLOR}")
    
    # Record visit in shared DB
    visit_count = 0
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, connect_timeout=2
        )
        cur = conn.cursor()
        cur.execute("INSERT INTO visits DEFAULT VALUES")
        cur.execute("SELECT count(*) FROM visits")
        visit_count = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        logger.error(f"Failed to record visit: {e}")

    latency = time.time() - start_time
    
    return jsonify(
        message="Hello from the Blue-Green demo app!",
        version=APP_VERSION,
        color=COLOR,
        total_visits=visit_count,
        latency=f"{latency:.4f}s",
        time=datetime.now(timezone.utc).isoformat(),
    )



@app.route("/health")
def health():
    db_ok, db_status = check_db_connection()
    status_code = 200 if db_ok else 503  # Return 503 Service Unavailable if DB is disconnected
    
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
    # In a real app, we would use prometheus_client library
    visit_count = 0
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, connect_timeout=2
        )
        cur = conn.cursor()
        cur.execute("SELECT count(*) FROM visits")
        visit_count = cur.fetchone()[0]
        cur.close()
        conn.close()
    except Exception as e:
        logger.error(f"Failed to fetch metrics: {e}")

    body = (
        "# HELP app_up App is up\n"
        "# TYPE app_up gauge\n"
        f'app_up{{version="{APP_VERSION}",color="{COLOR}"}} 1\n'
        "# HELP app_visits_total Total number of visits\n"
        "# TYPE app_visits_total counter\n"
        f'app_visits_total{{version="{APP_VERSION}",color="{COLOR}"}} {visit_count}\n'
    )
    return body, 200, {"Content-Type": "text/plain; version=0.0.4"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
