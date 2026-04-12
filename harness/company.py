from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class RoleDefinition:
    role_id: str
    team: str
    provider: str
    model: str
    ownership: list[str]
    strengths: list[str]
    evaluation_inputs: list[str]


@dataclass(frozen=True)
class ProviderDefinition:
    provider_id: str
    transport: str
    auth: str
    models: dict[str, str]


@dataclass(frozen=True)
class TaskRoute:
    task: str
    primary_role: str
    fallback_roles: list[str]
    evaluation_roles: list[str]


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_roles(manifest: dict[str, Any]) -> dict[str, RoleDefinition]:
    roles: dict[str, RoleDefinition] = {}
    team_items = manifest.get("teams")
    if team_items:
        for item in team_items:
            roles[item["id"]] = RoleDefinition(
                role_id=item["id"],
                team=item["team"],
                provider=item["provider"],
                model=item["model"],
                ownership=item.get("ownership", []),
                strengths=item.get("strengths", []),
                evaluation_inputs=item.get("evaluation_inputs", []),
            )
        return roles

    for item in manifest.get("roles", []):
        provider = item.get("provider") or item.get("owner", "")
        roles[item["id"]] = RoleDefinition(
            role_id=item["id"],
            team=item.get("team", "unassigned"),
            provider=provider,
            model=item.get("model", ""),
            ownership=item.get("ownership", []),
            strengths=item.get("strengths", item.get("responsibilities", [])),
            evaluation_inputs=item.get("evaluation_inputs", []),
        )
    return roles


def load_providers(manifest: dict[str, Any]) -> dict[str, ProviderDefinition]:
    providers: dict[str, ProviderDefinition] = {}
    for provider_id, item in manifest.get("providers", {}).items():
        transport = item.get("transport") or item.get("mode", "")
        providers[provider_id] = ProviderDefinition(
            provider_id=provider_id,
            transport=transport,
            auth=item.get("auth", ""),
            models=item.get("models", {}),
        )
    return providers


def load_routes(manifest: dict[str, Any]) -> dict[str, TaskRoute]:
    routes: dict[str, TaskRoute] = {}
    for item in manifest.get("routing", []):
        routes[item["task"]] = TaskRoute(
            task=item["task"],
            primary_role=item["primary_role"],
            fallback_roles=item.get("fallback_roles", []),
            evaluation_roles=item.get("evaluation_roles", []),
        )
    return routes
