"""Structured context management layer for the harness.

Provides:
1. Automatic handoff artifact generation at round boundaries
2. Context budget tracking (token estimation per round)
3. Structured handoff format that survives context resets
4. Round history with evidence chain

This replaces ad-hoc SESSION_RESUME.md updates with a deterministic
handoff pipeline that guarantees no context is silently lost.
"""

from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from datetime import datetime, UTC
from pathlib import Path
from typing import Any


@dataclass
class RoundRecord:
    """A single harness round's complete record."""
    round_id: str           # e.g. "sprint3", "remediation_r5"
    round_type: str         # "sprint" | "remediation"
    started_at: str
    completed_at: str | None = None
    brief_path: str | None = None
    files_modified: list[str] = field(default_factory=list)
    files_created: list[str] = field(default_factory=list)
    test_count_before: int = 0
    test_count_after: int = 0
    evaluation_passed: bool | None = None
    blockers_found: list[str] = field(default_factory=list)
    blockers_resolved: list[str] = field(default_factory=list)
    codex_model: str = "gpt-5.4"
    evaluator_reports: dict[str, str] = field(default_factory=dict)
    guardrail_violations: list[str] = field(default_factory=list)
    duration_seconds: float = 0.0


@dataclass
class ContextBudget:
    """Track estimated token usage across rounds."""
    rounds: list[dict] = field(default_factory=list)

    def record_round(self, round_id: str, prompt_chars: int, output_chars: int):
        """Estimate tokens (rough: 1 token ≈ 4 chars) and record."""
        est_prompt_tokens = prompt_chars // 4
        est_output_tokens = output_chars // 4
        self.rounds.append({
            "round_id": round_id,
            "est_prompt_tokens": est_prompt_tokens,
            "est_output_tokens": est_output_tokens,
            "est_total_tokens": est_prompt_tokens + est_output_tokens,
            "timestamp": datetime.now(UTC).isoformat(),
        })

    def total_estimated_tokens(self) -> int:
        return sum(r["est_total_tokens"] for r in self.rounds)

    def to_dict(self) -> dict:
        return {
            "total_estimated_tokens": self.total_estimated_tokens(),
            "rounds": self.rounds,
        }


class ContextManager:
    """Manages structured context across harness rounds.

    Unlike SESSION_RESUME.md (manually updated, prose-based),
    this produces machine-readable round records that survive
    context resets and can be consumed by any future session.
    """

    def __init__(self, context_dir: Path):
        self.context_dir = context_dir
        self.rounds_file = context_dir / "round_history.jsonl"
        self.budget = ContextBudget()
        self._current_round: RoundRecord | None = None
        self._round_start_time: float = 0.0

    def begin_round(
        self,
        round_id: str,
        round_type: str,
        brief_path: Path | None = None,
        test_count: int = 0,
    ) -> RoundRecord:
        """Start tracking a new round."""
        self._round_start_time = time.monotonic()
        self._current_round = RoundRecord(
            round_id=round_id,
            round_type=round_type,
            started_at=datetime.now(UTC).isoformat(),
            brief_path=str(brief_path) if brief_path else None,
            test_count_before=test_count,
        )
        return self._current_round

    def complete_round(
        self,
        *,
        test_count: int = 0,
        evaluation_passed: bool | None = None,
        blockers_found: list[str] | None = None,
        files_modified: list[str] | None = None,
        files_created: list[str] | None = None,
        evaluator_reports: dict[str, str] | None = None,
        guardrail_violations: list[str] | None = None,
    ) -> RoundRecord | None:
        """Finalize the current round and persist it."""
        if not self._current_round:
            return None

        r = self._current_round
        r.completed_at = datetime.now(UTC).isoformat()
        r.duration_seconds = round(time.monotonic() - self._round_start_time, 1)
        r.test_count_after = test_count
        r.evaluation_passed = evaluation_passed
        if blockers_found:
            r.blockers_found = blockers_found
        if files_modified:
            r.files_modified = files_modified
        if files_created:
            r.files_created = files_created
        if evaluator_reports:
            r.evaluator_reports = evaluator_reports
        if guardrail_violations:
            r.guardrail_violations = guardrail_violations

        self._persist_round(r)
        self._current_round = None
        return r

    def generate_handoff(self, output_path: Path | None = None) -> str:
        """Generate a structured handoff artifact from all round records.

        This is the ONLY context bridge between sessions.
        Any future session reads this + the codebase. Nothing else carries over.
        """
        rounds = self._load_all_rounds()
        if not rounds:
            return "# Handoff — No rounds recorded yet\n"

        lines = [
            "# Structured Handoff Artifact",
            f"**Generated:** {datetime.now(UTC).isoformat()}",
            f"**Total rounds:** {len(rounds)}",
            "",
        ]

        # Current state summary
        last = rounds[-1]
        lines.extend([
            "## Current State",
            f"- Last round: {last.get('round_id', 'unknown')}",
            f"- Tests: {last.get('test_count_after', '?')}",
            f"- Evaluation: {'PASSED' if last.get('evaluation_passed') else 'BLOCKED' if last.get('evaluation_passed') is False else 'PENDING'}",
            f"- Blockers: {last.get('blockers_found', [])}",
            "",
        ])

        # What worked (rounds that passed)
        passed = [r for r in rounds if r.get("evaluation_passed") is True]
        if passed:
            lines.append("## What worked (with evidence)")
            for r in passed:
                lines.append(
                    f"- **{r['round_id']}**: {r.get('test_count_before', '?')} → "
                    f"{r.get('test_count_after', '?')} tests, "
                    f"duration {r.get('duration_seconds', '?')}s"
                )
            lines.append("")

        # What was blocked (rounds that failed)
        blocked = [r for r in rounds if r.get("evaluation_passed") is False]
        if blocked:
            lines.append("## What was blocked (with evidence)")
            for r in blocked:
                lines.append(
                    f"- **{r['round_id']}**: blockers={r.get('blockers_found', [])}"
                )
            lines.append("")

        # Files modified across all rounds
        all_files = set()
        for r in rounds:
            all_files.update(r.get("files_modified", []))
            all_files.update(r.get("files_created", []))
        if all_files:
            lines.append("## Files touched")
            for f in sorted(all_files):
                lines.append(f"- {f}")
            lines.append("")

        # Guardrail violations
        all_violations = []
        for r in rounds:
            all_violations.extend(r.get("guardrail_violations", []))
        if all_violations:
            lines.append("## Guardrail violations")
            for v in all_violations:
                lines.append(f"- {v}")
            lines.append("")

        # Next priorities
        if last.get("blockers_found"):
            lines.append("## Next priorities")
            for i, b in enumerate(last["blockers_found"], 1):
                lines.append(f"{i}. Fix: {b}")
            lines.append("")

        content = "\n".join(lines)
        if output_path:
            output_path.write_text(content, encoding="utf-8")
        return content

    def _persist_round(self, record: RoundRecord):
        """Append round record as JSONL."""
        data = {
            k: v for k, v in record.__dict__.items()
            if v is not None and v != [] and v != {}
        }
        with self.rounds_file.open("a", encoding="utf-8") as f:
            f.write(json.dumps(data, ensure_ascii=False) + "\n")

    def _load_all_rounds(self) -> list[dict]:
        """Load all round records from JSONL."""
        if not self.rounds_file.exists():
            return []
        rounds = []
        for line in self.rounds_file.read_text(encoding="utf-8").strip().splitlines():
            if line.strip():
                try:
                    rounds.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        return rounds
