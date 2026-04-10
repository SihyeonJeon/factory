"""Append-only structured ledger primitive.

Reusable across harnesses: takes an explicit path, stamps every entry
with ``ts`` (ISO8601 UTC) and ``schema_version`` if the caller didn't,
and appends one JSON object per line so downstream replay tooling has
a stable minimum contract regardless of the call site.
"""

from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

LEDGER_SCHEMA_VERSION = 2


def write_ledger_entry(path: Path, entry: dict[str, Any]) -> None:
    enriched: dict[str, Any] = {
        "ts": datetime.now(tz=UTC).isoformat(timespec="seconds"),
        "schema_version": LEDGER_SCHEMA_VERSION,
        **entry,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(enriched, ensure_ascii=False) + "\n")
