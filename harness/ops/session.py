"""Session/JWT/timestamp helpers used by the preflight doctor."""

from __future__ import annotations

import base64
import json
from datetime import UTC, datetime
from typing import Any


def parse_iso_timestamp(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        normalized = value.replace("Z", "+00:00")
        return datetime.fromisoformat(normalized)
    except ValueError:
        return None


def parse_unix_timestamp(value: Any) -> datetime | None:
    try:
        return datetime.fromtimestamp(int(value), tz=UTC)
    except Exception:
        return None


def decode_jwt_payload(token: str | None) -> dict[str, Any]:
    if not token or "." not in token:
        return {}
    try:
        middle = token.split(".")[1]
        padding = "=" * (-len(middle) % 4)
        raw = base64.urlsafe_b64decode(middle + padding)
        return json.loads(raw.decode("utf-8"))
    except Exception:
        return {}


def describe_session(deadline: datetime | None) -> tuple[str, str]:
    if not deadline:
        return "blocked", "no expiry metadata available"
    now = datetime.now(tz=UTC)
    if deadline <= now:
        return "blocked", f"expired at {deadline.isoformat()}"
    remaining = deadline - now
    minutes = int(remaining.total_seconds() // 60)
    return "ready", f"expires at {deadline.isoformat()} ({minutes} min remaining)"
