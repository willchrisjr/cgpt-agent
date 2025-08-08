# Runbook Executor (Python)

A simple Python CLI that executes declarative YAML runbooks consisting of discrete actions.

## Structure

- runbook.py: CLI entrypoint
- actions/core.py: Core utilities
- actions/graph.py: Microsoft Graph-related actions (placeholder)
- runbooks/compromised_user.yml: Sample runbook
- artifacts/: Output directory (gitignored)
- tests/test_core.py: pytest tests

## Usage

```bash
python runbook.py --runbook runbooks/compromised_user.yml
```

## Development

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest -q
```