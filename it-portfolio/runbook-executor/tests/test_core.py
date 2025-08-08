from pathlib import Path
from actions.core import load_yaml, run_actions
import textwrap


def test_load_yaml(tmp_path: Path) -> None:
    content = textwrap.dedent(
        """
        a: 1
        b:
          - x
          - y
        """
    ).strip()
    p = tmp_path / "test.yml"
    p.write_text(content, encoding="utf-8")
    data = load_yaml(p)
    assert data["a"] == 1
    assert data["b"] == ["x", "y"]


def test_run_actions() -> None:
    actions = [
        {"name": "one"},
        {"name": "two"},
    ]
    results = run_actions(actions)
    assert results == ["ok:one", "ok:two"]