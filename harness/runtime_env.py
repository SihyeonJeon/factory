"""Runtime environment loader — reads .env files for provider auth."""

from __future__ import annotations

import os
from pathlib import Path


def load_project_env(project_root: Path) -> dict[str, str]:
    """Load .env file from project root into os.environ. Returns loaded vars."""
    loaded: dict[str, str] = {}
    env_file = project_root / ".env"
    if not env_file.exists():
        return loaded
    try:
        for line in env_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip("'\"")
            if key:
                os.environ.setdefault(key, value)
                loaded[key] = value
    except Exception:
        pass
    return loaded
