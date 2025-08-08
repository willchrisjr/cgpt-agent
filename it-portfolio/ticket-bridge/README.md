# Ticket Bridge (Flask)

Receives webhooks from systems like Jira Service Management or Zammad and triggers automations.

## Files

- app.py: Flask application exposing a webhook endpoint
- config.sample.yml: Sample configuration
- requirements.txt: Python dependencies

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export FLASK_APP=app.py
flask run
```