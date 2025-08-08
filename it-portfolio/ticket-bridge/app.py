from __future__ import annotations
from flask import Flask, request, jsonify
import os
import yaml


def create_app() -> Flask:
    app = Flask(__name__)

    @app.post("/webhook")
    def webhook():
        _cfg_path = os.environ.get("TICKET_BRIDGE_CONFIG", "config.sample.yml")
        try:
            with open(_cfg_path, "r", encoding="utf-8") as f:
                _ = yaml.safe_load(f) or {}
        except FileNotFoundError:
            pass

        payload = request.get_json(silent=True) or {}
        return jsonify({"status": "ok", "received": payload}), 200

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))