import argparse
from pathlib import Path
from actions.core import load_yaml, run_actions


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Runbook Executor")
    parser.add_argument("--runbook", required=True, help="Path to runbook YAML file")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    runbook_path = Path(args.runbook)
    data = load_yaml(runbook_path)
    actions = data.get("actions", [])
    results = run_actions(actions)
    print(f"Executed {len(results)} action(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())