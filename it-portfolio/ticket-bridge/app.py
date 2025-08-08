from __future__ import annotations
from flask import Flask, request, jsonify
import os
import yaml
import logging
import json
from typing import Any, Dict, Optional


def _load_config(config_path: str) -> Dict[str, Any]:
    if not os.path.exists(config_path):
        return {}

    with open(config_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    if not isinstance(data, dict):
        raise ValueError("Configuration must be a mapping (YAML object)")

    # Minimal schema: if bridge_token is present, it must be a string
    token = data.get("bridge_token")
    if token is not None and not isinstance(token, str):
        raise ValueError("bridge_token must be a string if provided")

    return data


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log: Dict[str, Any] = {
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }
        # Attach request id if available
        try:
            rid = request.headers.get("X-Request-Id") or request.headers.get("X-Request-ID")
            if rid:
                log["request_id"] = rid
        except Exception:
            pass
        return json.dumps(log, ensure_ascii=False)


def _configure_logging() -> logging.Logger:
    logger = logging.getLogger("ticket_bridge")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(JsonFormatter())
        logger.addHandler(handler)
    return logger


def create_app() -> Flask:
    app = Flask(__name__)

    # Configure logging
    logger = _configure_logging()

    # Load configuration once at startup
    cfg_path = os.environ.get("TICKET_BRIDGE_CONFIG", os.path.join(os.path.dirname(__file__), "config.sample.yml"))
    try:
        config_data = _load_config(cfg_path)
        app.config["TICKET_BRIDGE_CONFIG_PATH"] = cfg_path
        app.config["TICKET_BRIDGE_CONFIG_DATA"] = config_data
        logger.info("configuration_loaded")
    except Exception as exc:
        logger.error(f"configuration_error: {exc}")
        raise

    @app.get("/healthz")
    def healthz():
        return jsonify({"status": "ok"}), 200

    @app.post("/webhook")
    def webhook():
        # Optional shared secret validation
        expected_token: Optional[str] = app.config.get("TICKET_BRIDGE_CONFIG_DATA", {}).get("bridge_token")
        if expected_token:
            provided_token = request.headers.get("X-Bridge-Token")
            if provided_token != expected_token:
                logger.warning("unauthorized_webhook")
                return jsonify({"error": "unauthorized"}), 401

        payload = request.get_json(silent=True) or {}
        logger.info("webhook_received")
        return jsonify({"status": "ok", "received": payload}), 200

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))