#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent.parent
HOME = Path.home()


def merge_json(target: Path, patch: dict):
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        try:
            data = json.loads(target.read_text(encoding="utf-8"))
        except Exception:
            data = {}
    else:
        data = {}

    def deep_merge(dst: dict, src: dict):
        for key, value in src.items():
            if isinstance(value, dict) and isinstance(dst.get(key), dict):
                deep_merge(dst[key], value)
            else:
                dst[key] = value

    deep_merge(data, patch)
    target.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def copy_tree(src: Path, dst: Path):
    if not src.exists():
        return
    dst.mkdir(parents=True, exist_ok=True)
    for item in src.iterdir():
        if item.is_dir():
            copy_tree(item, dst / item.name)
        else:
            shutil.copy2(item, dst / item.name)


def main():
    gemini_patch = ROOT_DIR / "home_templates" / "gemini.settings.patch.json"
    claude_patch = ROOT_DIR / "home_templates" / "claude.settings.patch.json"
    claude_agents = ROOT_DIR / "home_templates" / "claude_agents"

    if gemini_patch.exists():
        merge_json(HOME / ".gemini" / "settings.json", json.loads(gemini_patch.read_text(encoding="utf-8")))
    if claude_patch.exists():
        merge_json(HOME / ".claude" / "settings.json", json.loads(claude_patch.read_text(encoding="utf-8")))
    copy_tree(claude_agents, HOME / ".claude" / "agents")


if __name__ == "__main__":
    main()
