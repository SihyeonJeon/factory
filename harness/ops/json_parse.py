"""JSON extraction from possibly-fenced or prose-wrapped model output."""

from __future__ import annotations

import json
import re
from typing import Any


def _extract_json_candidates(text: str) -> list[str]:
    stripped = text.strip()
    candidates: list[str] = []
    if stripped:
        candidates.append(stripped)

    if stripped.startswith("```"):
        unfenced = re.sub(r"^```(?:json)?\s*", "", stripped)
        unfenced = re.sub(r"\s*```$", "", unfenced)
        if unfenced and unfenced not in candidates:
            candidates.append(unfenced.strip())

    decoder = json.JSONDecoder()
    for index, char in enumerate(stripped):
        if char not in "[{":
            continue
        try:
            obj, end = decoder.raw_decode(stripped[index:])
        except json.JSONDecodeError:
            continue
        candidate = stripped[index:index + end]
        if candidate not in candidates:
            candidates.append(candidate)
        if isinstance(obj, (dict, list)):
            normalized = json.dumps(obj, ensure_ascii=False)
            if normalized not in candidates:
                candidates.append(normalized)
    return candidates


def parse_json_output(text: str) -> Any:
    for candidate in _extract_json_candidates(text):
        try:
            return json.loads(candidate)
        except json.JSONDecodeError:
            continue
    raise json.JSONDecodeError(
        "Could not recover valid JSON from model output",
        text,
        0,
    )
