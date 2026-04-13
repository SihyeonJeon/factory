"""Company manifest loader — parses team_manifest.json into typed structures."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class Provider:
    provider_id: str
    transport: str
    auth: str
    primary_use: list[str]
    models: dict[str, str]


@dataclass
class Role:
    role_id: str
    title: str
    team: str
    provider: str
    model: str
    ownership: list[str] = field(default_factory=list)
    responsibilities: list[str] = field(default_factory=list)


def load_manifest(path: Path) -> dict[str, Any]:
    """Load the team_manifest.json file."""
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_providers(manifest: dict[str, Any]) -> dict[str, Provider]:
    """Parse the providers section of the manifest into Provider objects."""
    providers: dict[str, Provider] = {}
    for pid, pdata in manifest.get("providers", {}).items():
        providers[pid] = Provider(
            provider_id=pid,
            transport=pdata.get("transport", "cli"),
            auth=pdata.get("auth", ""),
            primary_use=pdata.get("primary_use", []),
            models=pdata.get("models", {}),
        )
    return providers


def load_roles(manifest: dict[str, Any]) -> dict[str, Role]:
    """Parse the roles section of the manifest into Role objects keyed by role id."""
    roles: dict[str, Role] = {}
    for rdata in manifest.get("roles", []):
        rid = rdata.get("id", "")
        if not rid:
            continue
        roles[rid] = Role(
            role_id=rid,
            title=rdata.get("title", rid),
            team=rdata.get("team", ""),
            provider=rdata.get("provider", ""),
            model=rdata.get("model", ""),
            ownership=rdata.get("ownership", []),
            responsibilities=rdata.get("responsibilities", []),
        )
    return roles
