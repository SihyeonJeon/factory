"""Context management layer — decision log, semantic compaction, protected entries.

Addresses the 'context management' gap in harness engineering:
- Decisions log persists across compaction rounds
- Blackboard entries tagged with semantic types
- Compaction preserves decision/constraint entries
"""

from __future__ import annotations

import json
import time
from dataclasses import asdict, dataclass
from enum import Enum
from pathlib import Path
from typing import Any


class EntryType(str, Enum):
    FINDING = "finding"
    DECISION = "decision"
    CONSTRAINT = "constraint"
    BUG_FIX = "bug_fix"
    REVIEW = "review"
    METRIC = "metric"


@dataclass
class Decision:
    round_index: int
    entry_type: str
    summary: str
    rationale: str
    source_role: str
    timestamp: str
    references: list[str]


def append_decision(
    log_file: Path,
    *,
    round_index: int,
    entry_type: str,
    summary: str,
    rationale: str,
    source_role: str,
    references: list[str] | None = None,
) -> Decision:
    decision = Decision(
        round_index=round_index,
        entry_type=entry_type,
        summary=summary,
        rationale=rationale,
        source_role=source_role,
        timestamp=time.strftime("%Y-%m-%d %H:%M:%S"),
        references=references or [],
    )
    with open(log_file, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(asdict(decision), ensure_ascii=False) + "\n")
    return decision


def load_decisions(log_file: Path) -> list[Decision]:
    if not log_file.exists():
        return []
    decisions: list[Decision] = []
    for line in log_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
            decisions.append(Decision(**data))
        except (json.JSONDecodeError, TypeError):
            continue
    return decisions


def decisions_summary_for_prompt(log_file: Path, max_entries: int = 20) -> str:
    """Build a compact summary of persistent decisions for inclusion in agent prompts."""
    decisions = load_decisions(log_file)
    if not decisions:
        return ""
    recent = decisions[-max_entries:]
    lines = ["## Persistent Decisions & Constraints", ""]
    for d in recent:
        tag = f"[{d.entry_type.upper()}]"
        lines.append(f"- {tag} (R{d.round_index}) {d.summary}")
        if d.rationale:
            lines.append(f"  Rationale: {d.rationale}")
    return "\n".join(lines)


def compact_blackboard_v2(
    blackboard_file: Path,
    compact_file: Path,
    reports_dir: Path,
    decisions_log_file: Path,
    *,
    force: bool = False,
    max_chars: int = 6000,
    keep_recent: int = 8,
    keep_full: int = 4,
) -> Path | None:
    """Improved compaction that preserves decision/constraint entries.

    Returns archive path if compaction occurred, None otherwise.
    """
    if not blackboard_file.exists():
        return None
    text = blackboard_file.read_text(encoding="utf-8")
    if not force and len(text) < max_chars:
        return None

    timestamp = time.strftime("%Y%m%d-%H%M%S")
    archive_path = reports_dir / f"blackboard_archive_{timestamp}.md"
    archive_path.write_text(text, encoding="utf-8")

    entries = [entry.strip() for entry in text.split("\n---\n") if entry.strip()]

    # Classify entries: decisions/constraints are protected
    protected: list[str] = []
    regular: list[str] = []
    decision_keywords = ["decision:", "constraint:", "architectural:", "invariant:"]
    for entry in entries:
        lowered = entry.lower()
        if any(kw in lowered for kw in decision_keywords):
            protected.append(entry)
        else:
            regular.append(entry)

    # Build compact: protected entries first, then recent regular entries
    recent_regular = regular[-keep_recent:]
    summary_lines = ["# Blackboard Compact", ""]

    if protected:
        summary_lines += ["## Protected decisions & constraints"]
        for entry in protected[-10:]:
            first_line = next((l for l in entry.splitlines() if l.strip()), "")
            summary_lines.append(f"- {first_line[:200]}")
        summary_lines.append("")

    # Include decisions from log
    decisions_block = decisions_summary_for_prompt(decisions_log_file)
    if decisions_block:
        summary_lines.append(decisions_block)
        summary_lines.append("")

    summary_lines += ["## Recent entries"]
    for entry in recent_regular:
        first_line = next((l for l in entry.splitlines() if l.strip()), "")
        summary_lines.append(f"- {first_line[:180]}")

    summary = "\n".join(summary_lines)
    compact_file.write_text(summary, encoding="utf-8")

    # Reconstruct blackboard: keep protected + recent full entries
    kept_entries = protected[-5:] + recent_regular[-keep_full:]
    compacted = "# Blackboard - Agent Shared Context\n\n" + summary + "\n\n---\n" + "\n---\n".join(kept_entries)
    blackboard_file.write_text(compacted, encoding="utf-8")

    return archive_path
