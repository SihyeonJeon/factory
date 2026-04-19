"""Deterministic guardrails layer for the harness.

Provides:
1. Pre-edit file snapshots — automatic backup before codex touches files
2. Post-edit diff validation — verify codex only modified files listed in brief
3. Rollback mechanism — restore snapshots if tests fail
4. File modification whitelist enforcement
"""

from __future__ import annotations

import hashlib
import shutil
import time
from dataclasses import dataclass, field
from datetime import datetime, UTC
from pathlib import Path


@dataclass
class FileSnapshot:
    """A single file's pre-edit state."""
    path: Path
    sha256: str
    size: int
    timestamp: float
    backup_path: Path


@dataclass
class GuardrailSession:
    """Tracks file states across a single dispatch cycle."""
    session_id: str
    workspace: Path
    snapshot_dir: Path
    whitelist: list[str]  # relative paths that codex is allowed to modify
    snapshots: dict[str, FileSnapshot] = field(default_factory=dict)
    violations: list[str] = field(default_factory=list)

    @staticmethod
    def from_brief(brief_path: Path, workspace: Path) -> "GuardrailSession":
        """Parse a sprint/remediation brief to extract the file whitelist."""
        session_id = f"gr-{int(time.time())}"
        snapshot_dir = workspace / ".guardrail_snapshots" / session_id
        snapshot_dir.mkdir(parents=True, exist_ok=True)

        whitelist: list[str] = []
        if brief_path.exists():
            text = brief_path.read_text(encoding="utf-8")
            # Extract filenames from common patterns in briefs
            import re
            # Match patterns like `FileName.swift`, `Features/Home/X.swift`, etc.
            swift_files = re.findall(
                r'(?:workspace/ios/)?'
                r'((?:Features|Shared|Tests|App|Resources)/[\w/]*\.(?:swift|plist|yml))',
                text,
            )
            # Also match bare filenames like `MemoryDetailView.swift`
            bare_files = re.findall(r'\b(\w+\.(?:swift|plist|yml))\b', text)
            whitelist = list(dict.fromkeys(swift_files + bare_files))

        return GuardrailSession(
            session_id=session_id,
            workspace=workspace,
            snapshot_dir=snapshot_dir,
            whitelist=whitelist,
        )

    def snapshot_workspace(self) -> int:
        """Snapshot all Swift/plist files in workspace before codex runs.
        Returns count of files snapshotted."""
        ios_dir = self.workspace / "workspace" / "ios"
        if not ios_dir.exists():
            return 0

        count = 0
        for ext in ("*.swift", "*.plist", "*.yml"):
            for f in ios_dir.rglob(ext):
                if ".deriveddata" in str(f).lower() or ".build" in str(f).lower():
                    continue
                rel = f.relative_to(ios_dir)
                content = f.read_bytes()
                sha = hashlib.sha256(content).hexdigest()
                backup = self.snapshot_dir / str(rel).replace("/", "__")
                shutil.copy2(f, backup)
                self.snapshots[str(rel)] = FileSnapshot(
                    path=f,
                    sha256=sha,
                    size=len(content),
                    timestamp=f.stat().st_mtime,
                    backup_path=backup,
                )
                count += 1
        return count

    def validate_changes(self) -> list[str]:
        """After codex runs, check which files changed and whether they're whitelisted.
        Returns list of violation descriptions."""
        ios_dir = self.workspace / "workspace" / "ios"
        if not ios_dir.exists():
            return []

        violations: list[str] = []
        for ext in ("*.swift", "*.plist", "*.yml"):
            for f in ios_dir.rglob(ext):
                if ".deriveddata" in str(f).lower() or ".build" in str(f).lower():
                    continue
                rel = str(f.relative_to(ios_dir))
                current_sha = hashlib.sha256(f.read_bytes()).hexdigest()

                if rel in self.snapshots:
                    if current_sha != self.snapshots[rel].sha256:
                        # File was modified — check whitelist
                        if not self._is_whitelisted(rel):
                            violations.append(
                                f"UNAUTHORIZED_EDIT: {rel} was modified but not in brief whitelist"
                            )
                else:
                    # New file — check if creation is expected
                    if not self._is_whitelisted(rel):
                        violations.append(
                            f"UNAUTHORIZED_CREATE: {rel} was created but not in brief whitelist"
                        )

        self.violations = violations
        return violations

    def rollback(self) -> int:
        """Restore all snapshotted files to pre-edit state. Returns count restored."""
        count = 0
        for rel, snap in self.snapshots.items():
            if snap.backup_path.exists() and snap.path.exists():
                shutil.copy2(snap.backup_path, snap.path)
                count += 1
        return count

    def cleanup(self):
        """Remove snapshot directory after successful validation."""
        if self.snapshot_dir.exists():
            shutil.rmtree(self.snapshot_dir, ignore_errors=True)

    def _is_whitelisted(self, rel_path: str) -> bool:
        """Check if a relative path matches any whitelist entry."""
        # Normalize for comparison
        rel_lower = rel_path.lower()
        for entry in self.whitelist:
            entry_lower = entry.lower()
            # Match full path or filename
            if rel_lower == entry_lower or rel_lower.endswith("/" + entry_lower):
                return True
            # Match just the filename part
            if "/" in entry_lower:
                if rel_lower.endswith(entry_lower):
                    return True
            else:
                # Bare filename match
                if rel_lower.endswith("/" + entry_lower) or rel_lower == entry_lower:
                    return True
        # Always allow test files and project.yml
        always_allowed = ("memorymap tests", "memeorymaptests", "project.yml")
        for allowed in always_allowed:
            if allowed in rel_lower:
                return True
        return False

    def summary(self) -> dict:
        """Return a structured summary of the guardrail session."""
        return {
            "session_id": self.session_id,
            "files_snapshotted": len(self.snapshots),
            "whitelist_entries": len(self.whitelist),
            "violations": self.violations,
            "timestamp": datetime.now(UTC).isoformat(),
        }
