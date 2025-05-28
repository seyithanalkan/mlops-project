# tests/test_serve.py

import yaml

from fastapi.testclient import TestClient

from src.serve.app import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()

    assert data["status"] == "ok"
    assert "timestamp" in data


def test_predict_endpoint(monkeypatch, tmp_path):
    cfg = {"model_path": str(tmp_path / "dummy.h5")}
    config_file = tmp_path / "config.yaml"
    with open(config_file, "w") as f:
        yaml.safe_dump(cfg, f)

    monkeypatch.setenv("CONFIG_PATH", str(config_file))

    response = client.post(
        "/predict",
        json={"lag_1": 1.0, "rolling_mean_7": 2.0},
    )
    assert response.status_code == 200
    assert "prediction" in response.json()
