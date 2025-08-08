from __future__ import annotations
from pathlib import Path
from typing import Any, Dict, Iterable, List
import yaml


def load_yaml(path: Path | str) -> Dict[str, Any]:
    path_obj = Path(path)
    with path_obj.open("r", encoding="utf-8") as f:
        loaded: Any = yaml.safe_load(f)
        if isinstance(loaded, dict):
            return loaded
        return {}


def run_actions(actions: Iterable[Dict[str, Any]]) -> List[str]:
    results: List[str] = []
    for action in actions:
        name = action.get("name", "unnamed")
        results.append(f"ok:{name}")
    return results