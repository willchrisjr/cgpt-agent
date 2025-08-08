import os
import tempfile
import textwrap
import json
import pytest

import importlib.util
import pathlib

# Dynamically import create_app from the file under it-portfolio/ticket-bridge/app.py
_APP_PATH = pathlib.Path(__file__).resolve().parent.parent / "it-portfolio" / "ticket-bridge" / "app.py"
_spec = importlib.util.spec_from_file_location("ticket_bridge_app", str(_APP_PATH))
_module = importlib.util.module_from_spec(_spec)
assert _spec is not None and _spec.loader is not None
_spec.loader.exec_module(_module)  # type: ignore[arg-type]
create_app = getattr(_module, "create_app")


@pytest.fixture
def client():
    # Use temp config file without token
    with tempfile.TemporaryDirectory() as td:
        cfg_path = os.path.join(td, "config.yml")
        with open(cfg_path, "w", encoding="utf-8") as f:
            f.write("{}\n")
        os.environ["TICKET_BRIDGE_CONFIG"] = cfg_path
        app = create_app()
        with app.test_client() as c:
            yield c


def test_healthz(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_webhook_echo_json_body(client):
    payload = {"hello": "world"}
    resp = client.post("/webhook", json=payload)
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["status"] == "ok"
    assert body["received"] == payload


def test_webhook_handles_missing_or_invalid_json(client):
    # Missing body
    resp1 = client.post("/webhook")
    assert resp1.status_code == 200
    assert resp1.get_json()["received"] == {}

    # Invalid JSON (send text/plain)
    resp2 = client.post("/webhook", data="not-json", headers={"Content-Type": "text/plain"})
    assert resp2.status_code == 200
    assert resp2.get_json()["received"] == {}


def test_config_loading_path_and_token_validation():
    with tempfile.TemporaryDirectory() as td:
        cfg_path = os.path.join(td, "config.yml")
        with open(cfg_path, "w", encoding="utf-8") as f:
            f.write(textwrap.dedent(
                """
                bridge_token: test-secret
                """
            ))
        os.environ["TICKET_BRIDGE_CONFIG"] = cfg_path
        app = create_app()

        # Good token
        with app.test_client() as c:
            ok = c.post("/webhook", json={"x": 1}, headers={"X-Bridge-Token": "test-secret"})
            assert ok.status_code == 200
            # Bad token
            bad = c.post("/webhook", json={"x": 1}, headers={"X-Bridge-Token": "wrong"})
            assert bad.status_code == 401