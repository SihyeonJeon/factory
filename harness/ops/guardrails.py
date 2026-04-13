"""Deterministic guardrails — pre-dispatch snapshots, ownership enforcement, crash recovery.

Addresses the 'guardrails' gap in harness engineering:
- Git snapshot before each role dispatch (rollback on failure)
- Post-agent ownership validation
- Structured crash recovery
"""

from __future__ import annotations

import json
import re
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Callable


@dataclass
class Snapshot:
    commit_sha: str
    branch: str
    timestamp: str
    role: str
    task_type: str
    worktree: str


def take_snapshot(
    git_fn: Callable,
    *,
    cwd: Path,
    role: str,
    task_type: str,
) -> Snapshot:
    """Record the current git state before dispatching an agent."""
    sha = git_fn("rev-parse", "HEAD", cwd=cwd).stdout.strip()
    branch = git_fn("rev-parse", "--abbrev-ref", "HEAD", cwd=cwd).stdout.strip()
    return Snapshot(
        commit_sha=sha,
        branch=branch,
        timestamp=time.strftime("%Y-%m-%d %H:%M:%S"),
        role=role,
        task_type=task_type,
        worktree=str(cwd),
    )


def rollback_to_snapshot(
    git_fn: Callable,
    snapshot: Snapshot,
    *,
    journal_fn: Callable | None = None,
) -> bool:
    """Hard-reset worktree to snapshot state. Returns True if rollback occurred."""
    cwd = Path(snapshot.worktree)
    if not cwd.exists():
        return False
    current_sha = git_fn("rev-parse", "HEAD", cwd=cwd).stdout.strip()
    if current_sha == snapshot.commit_sha:
        return False  # Nothing changed, no rollback needed
    git_fn("reset", "--hard", snapshot.commit_sha, cwd=cwd, check=False)
    git_fn("clean", "-fd", cwd=cwd, check=False)
    if journal_fn:
        journal_fn(f"Rolled back {snapshot.worktree} to {snapshot.commit_sha[:8]} (role={snapshot.role})")
    return True


# --- Ownership enforcement ---

_OWNERSHIP_MAP: dict[str, list[str]] | None = None


def _load_ownership(manifest_file: Path) -> dict[str, list[str]]:
    global _OWNERSHIP_MAP
    if _OWNERSHIP_MAP is not None:
        return _OWNERSHIP_MAP
    _OWNERSHIP_MAP = {}
    if not manifest_file.exists():
        return _OWNERSHIP_MAP
    manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
    for role in manifest.get("roles", []):
        role_id = role.get("id", "")
        ownership = role.get("ownership", [])
        _OWNERSHIP_MAP[role_id] = ownership
    return _OWNERSHIP_MAP


def validate_ownership(
    role_id: str,
    changed_files: list[str],
    manifest_file: Path,
) -> list[str]:
    """Return list of files that violate the role's ownership boundary.

    Returns empty list if all changes are within allowed paths.
    """
    ownership = _load_ownership(manifest_file)
    allowed_patterns = ownership.get(role_id, [])
    if not allowed_patterns:
        return []  # No ownership defined = no restrictions

    violations: list[str] = []
    for filepath in changed_files:
        in_boundary = False
        for pattern in allowed_patterns:
            # Pattern can be exact path or directory prefix (ending with /)
            if pattern.endswith("/"):
                if filepath.startswith(pattern) or f"/{pattern}" in filepath:
                    in_boundary = True
                    break
            else:
                if filepath == pattern or filepath.endswith(f"/{pattern}"):
                    in_boundary = True
                    break
        if not in_boundary:
            violations.append(filepath)
    return violations


def get_changed_files(git_fn: Callable, *, cwd: Path, base_sha: str) -> list[str]:
    """Get list of files changed since base_sha."""
    proc = git_fn("diff", "--name-only", base_sha, "HEAD", cwd=cwd, check=False)
    if proc.returncode != 0:
        return []
    return [f.strip() for f in proc.stdout.splitlines() if f.strip()]


def post_agent_audit(
    git_fn: Callable,
    snapshot: Snapshot,
    role_id: str,
    manifest_file: Path,
    *,
    journal_fn: Callable | None = None,
) -> list[str]:
    """Run post-agent ownership check. Returns violations list (empty = clean)."""
    cwd = Path(snapshot.worktree)
    changed = get_changed_files(git_fn, cwd=cwd, base_sha=snapshot.commit_sha)
    if not changed:
        return []
    violations = validate_ownership(role_id, changed, manifest_file)
    if violations and journal_fn:
        journal_fn(
            f"OWNERSHIP VIOLATION: {role_id} modified {len(violations)} files outside boundary: "
            + ", ".join(violations[:5])
        )
    return violations
