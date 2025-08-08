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
# or once installed as a package
it-runbook --runbook runbooks/compromised_user.yml
```

## Development

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt

# Lint & format
ruff check .
black --check .

# Type check
mypy .

# Test with coverage
pytest --cov=. --cov-report=term-missing

# Pre-commit
pre-commit install
pre-commit run --all-files
```

## Release

- CI will build on tags matching `runbook-executor-v*`.
- To release:
  - Bump version in `pyproject.toml`.
  - Tag and push: `git tag runbook-executor-v0.1.0 && git push origin --tags`.
  - CI builds and publishes to PyPI using OIDC.