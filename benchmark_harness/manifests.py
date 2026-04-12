from __future__ import annotations

import json
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent


def resolve_repo_path(path_str: str) -> Path:
    path = Path(path_str)
    if path.is_absolute():
        return path
    return REPO_ROOT / path


def load_json(path_str: str) -> dict[str, Any]:
    path = resolve_repo_path(path_str)
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path_str: str, payload: dict[str, Any]) -> None:
    path = resolve_repo_path(path_str)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")


def resolve_num_classes(dataset_manifest: dict[str, Any]) -> int:
    if "num_classes" in dataset_manifest:
        return int(dataset_manifest["num_classes"])
    if "num_submission_species" in dataset_manifest:
        return int(dataset_manifest["num_submission_species"])
    if "num_train_species" in dataset_manifest:
        return int(dataset_manifest["num_train_species"])
    raise KeyError("Dataset manifest must define num_classes or num_submission_species")
