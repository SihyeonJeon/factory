"""Artifact excerpt helpers used when assembling role prompts."""

from __future__ import annotations

import json
from pathlib import Path


def read_artifact_excerpt(path: Path, max_chars: int = 1600) -> str:
    try:
        if path.suffix.lower() == ".json":
            payload = json.loads(path.read_text(encoding="utf-8"))
            text = json.dumps(payload, ensure_ascii=False, indent=2)
        else:
            text = path.read_text(encoding="utf-8")
    except Exception as exc:
        return f"[unreadable artifact: {exc}]"

    compact = text.strip()
    if len(compact) > max_chars:
        compact = compact[:max_chars].rstrip() + "\n...[truncated]"
    return compact


def build_artifact_snapshot(artifacts: dict[str, Path], max_chars_per_artifact: int = 1600) -> str:
    sections: list[str] = []
    for name, path in artifacts.items():
        if not path.exists():
            sections.append(f"## {name}\nPath: {path}\n[missing]")
            continue
        if path.suffix.lower() not in {".md", ".txt", ".json"}:
            sections.append(f"## {name}\nPath: {path}\n[non-text artifact; use path only]")
            continue
        sections.append(f"## {name}\nPath: {path}\n{read_artifact_excerpt(path, max_chars=max_chars_per_artifact)}")
    return "\n\n".join(sections)
