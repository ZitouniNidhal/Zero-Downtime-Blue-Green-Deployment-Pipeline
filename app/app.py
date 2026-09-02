~/.ssh/authorized_keysimport os
from datetime import datetime
from flask import Flask, jsonify

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "v1")
COLOR = os.environ.get("DEPLOY_COLOR", "unknown")


@app.route("/")
def index():
    return jsonify(
        message="Hello from the Blue-Green demo app!",
        version=APP_VERSION,
        color=COLOR,
        time=datetime.utcnow().isoformat(),
    )


@app.route("/health")
def health():
    # In a real app, check DB connectivity, dependencies, etc. here.
    return jsonify(status="healthy", version=APP_VERSION, color=COLOR), 200


@app.route("/metrics")
def metrics():
    # Minimal Prometheus-style metrics exposition (text format).
    body = (
        "# HELP app_up App is up\n"
        "# TYPE app_up gauge\n"
        f'app_up{{version="{APP_VERSION}",color="{COLOR}"}} 1\n'
    )
    return body, 200, {"Content-Type": "text/plain; version=0.0.4"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
