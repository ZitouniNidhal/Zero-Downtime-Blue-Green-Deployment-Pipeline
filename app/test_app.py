from unittest.mock import patch
import pytest
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_index_route(client):
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert "message" in data
    assert "version" in data
    assert "color" in data
    assert "time" in data


def test_health_check_route(client):
    with patch("app.check_db_connection", return_value=(True, "connected")):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "healthy"
        assert "version" in data
        assert "color" in data
        assert data["database"]["connected"] is True


def test_health_check_degraded(client):
    with patch("app.check_db_connection", return_value=(False, "connection refused")):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "degraded"
        assert data["database"]["connected"] is False


def test_metrics_route(client):
    response = client.get("/metrics")
    assert response.status_code == 200
    assert response.headers["Content-Type"].startswith("text/plain")
    assert b"app_up" in response.data


def test_not_found_route(client):
    response = client.get("/non-existent")
    assert response.status_code == 404

