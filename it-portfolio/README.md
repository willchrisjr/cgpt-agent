# IT Portfolio Monorepo

This repository houses three components used for IT automation and incident response:

- orchestrator: PowerShell module and scripts that coordinate workflows (e.g., provisioning, lifecycle tasks), designed to integrate with Microsoft Graph.
- runbook-executor: Python CLI to execute YAML-defined runbooks and orchestrate discrete actions.
- ticket-bridge: Lightweight Flask app to receive webhooks (e.g., JSM/Zammad) and trigger automations.

## Layout

- .github/workflows: CI pipelines for PowerShell (Pester) and Python (pytest)
- .github/ISSUE_TEMPLATE: Issue templates for bug reports and feature requests
- orchestrator: PowerShell module `Orchestrator` with scripts, samples, and tests
- runbook-executor: Python CLI and actions with tests and sample runbooks
- ticket-bridge: Flask app and sample configuration

## Quickstart

- PowerShell (local):
  - Open `orchestrator/` and run tests with Pester
- Python runbook-executor:
  - cd `runbook-executor/`, create venv, `pip install -r requirements.txt`, run `pytest`
- Ticket bridge:
  - cd `ticket-bridge/`, create venv, `pip install -r requirements.txt`, run locally with `FLASK_APP=app.py flask run`