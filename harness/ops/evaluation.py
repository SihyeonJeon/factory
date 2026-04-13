"""Evaluation calibration layer — structured verdict schema, few-shot calibration, traced extraction.

Addresses the 'evaluation calibration' gap in harness engineering:
- JSON verdict schema for machine-readable evaluations
- extract_blockers_v2 that parses structured JSON before falling back to keyword matching
- Traceability: blockers map to acceptance criteria IDs
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# --- Structured verdict schema ---

VERDICT_SCHEMA = {
    "type": "object",
    "required": ["verdict", "findings"],
    "properties": {
        "verdict": {
            "type": "string",
            "enum": ["PASS", "CONDITIONAL_PASS", "BLOCK_RELEASE"],
            "description": "Overall evaluation verdict.",
        },
        "findings": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["id", "severity", "file", "summary"],
                "properties": {
                    "id": {"type": "string", "description": "Finding ID, e.g. C-1, H-2, M-3"},
                    "severity": {
                        "type": "string",
                        "enum": ["critical", "high", "medium", "low"],
                    },
                    "file": {"type": "string", "description": "Primary file path"},
                    "line": {"type": "integer", "description": "Primary line number"},
                    "summary": {"type": "string", "description": "One-line description"},
                    "fix": {"type": "string", "description": "Recommended fix"},
                    "acceptance_ref": {
                        "type": "string",
                        "description": "Reference to acceptance criteria, e.g. 'epic-1', 'release-blocker-3'",
                    },
                    "category": {
                        "type": "string",
                        "enum": ["security", "functionality", "ux", "accessibility", "pwa", "performance", "correctness"],
                    },
                },
            },
        },
        "lanes_impacted": {
            "type": "array",
            "items": {"type": "string", "enum": ["frontend", "backend"]},
        },
        "summary": {"type": "string", "description": "2-3 sentence summary of the evaluation"},
    },
}


@dataclass
class Finding:
    id: str
    severity: str
    file: str
    line: int | None
    summary: str
    fix: str
    acceptance_ref: str
    category: str


@dataclass
class StructuredVerdict:
    verdict: str
    findings: list[Finding]
    lanes_impacted: list[str]
    summary: str
    raw_source: str  # "json" or "markdown_fallback"

    @property
    def passed(self) -> bool:
        return self.verdict == "PASS"

    @property
    def blockers(self) -> list[Finding]:
        return [f for f in self.findings if f.severity in ("critical", "high")]


def parse_structured_verdict(text: str) -> StructuredVerdict | None:
    """Try to parse a JSON verdict from the review text.

    The reviewer may embed JSON in a code block or return it directly.
    Returns None if no valid JSON verdict is found.
    """
    # Try extracting JSON from code blocks first
    json_blocks = re.findall(r"```(?:json)?\s*\n({[\s\S]*?})\s*\n```", text)
    candidates = json_blocks + [text.strip()]

    for candidate in candidates:
        try:
            data = json.loads(candidate)
        except (json.JSONDecodeError, ValueError):
            continue
        if not isinstance(data, dict):
            continue
        if "verdict" not in data or "findings" not in data:
            continue
        findings = []
        for f in data.get("findings", []):
            if not isinstance(f, dict):
                continue
            findings.append(Finding(
                id=f.get("id", "?"),
                severity=f.get("severity", "medium"),
                file=f.get("file", ""),
                line=f.get("line"),
                summary=f.get("summary", ""),
                fix=f.get("fix", ""),
                acceptance_ref=f.get("acceptance_ref", ""),
                category=f.get("category", "correctness"),
            ))
        return StructuredVerdict(
            verdict=data.get("verdict", "BLOCK_RELEASE"),
            findings=findings,
            lanes_impacted=data.get("lanes_impacted", ["frontend", "backend"]),
            summary=data.get("summary", ""),
            raw_source="json",
        )
    return None


def extract_blockers_v2(text: str) -> tuple[list[str], list[str]]:
    """Improved blocker extraction: try structured JSON first, fall back to keyword matching.

    Returns (blockers, lanes) — same signature as extract_blockers for drop-in replacement.
    """
    structured = parse_structured_verdict(text)
    if structured is not None:
        blockers = []
        if structured.verdict == "BLOCK_RELEASE":
            blockers.append("verdict_blocked")
        for finding in structured.findings:
            if finding.severity in ("critical", "high"):
                ref = f":{finding.acceptance_ref}" if finding.acceptance_ref else ""
                blockers.append(f"{finding.id}:{finding.severity}:{finding.category}{ref}")
        lanes = structured.lanes_impacted or _detect_lanes_from_text(text)
        return blockers, lanes

    # Fallback: keyword-based extraction (legacy path)
    return _extract_blockers_keyword(text)


def _detect_lanes_from_text(text: str) -> list[str]:
    lowered = text.lower()
    lanes: list[str] = []
    frontend_signals = ["layout", "responsive", "css", "component", "page", "visual", "spacing", "mobile", "pwa"]
    backend_signals = ["supabase", "rls", "edge function", "api", "auth", "database", "schema", "migration"]
    if any(s in lowered for s in frontend_signals):
        lanes.append("frontend")
    if any(s in lowered for s in backend_signals):
        lanes.append("backend")
    return lanes or ["frontend", "backend"]


def _extract_blockers_keyword(text: str) -> tuple[list[str], list[str]]:
    """Legacy keyword-based extraction — used when reviewer doesn't output structured JSON."""
    lowered = text.lower()
    blockers: list[str] = []

    verdict_match = re.search(r"verdict:\s*\*?\*?([^*\n]+)\*?\*?", lowered)
    verdict = verdict_match.group(1).strip() if verdict_match else ""

    clean_pass_signals = ["unblocked", "approved", "provisionally unblocked", "conditionally approved"]
    negative_verdict_signals = [
        "block release", "block", "blocked", "hard block",
        "rejected", "qa_fail", "changes requested", "failed",
    ]

    verdict_is_clean_pass = False
    if verdict:
        if any(signal in verdict for signal in negative_verdict_signals):
            blockers.append("verdict_blocked")
        elif verdict == "pass":
            verdict_is_clean_pass = True
        elif any(signal in verdict for signal in clean_pass_signals):
            verdict_is_clean_pass = True

    blocker_signals = [
        "qa_fail", "changes_requested", "critical", "must fix",
        "block release", "failed criteria", "rls violation",
        "security issue", "og rendering broken",
    ]
    if not verdict_is_clean_pass or blockers:
        for signal in blocker_signals:
            if signal in lowered:
                blockers.append(signal)

    return blockers, _detect_lanes_from_text(text)


# --- Evaluation directive builder ---

def build_evaluation_directive(
    brief: str,
    acceptance_file: Path | None = None,
    few_shot_dir: Path | None = None,
    repo_path: Path | None = None,
) -> str:
    """Build the evaluation prompt with structured output instructions and optional few-shot examples."""
    parts = [brief, ""]
    parts.append(
        "EVALUATION DIRECTIVE: This is a FRESH code review of the current codebase. "
        "Ignore any prior review results on the blackboard. Read the actual source files "
        "in the repository, assess correctness, security (RLS, XSS, injection), and performance."
    )
    if repo_path:
        parts.append("")
        parts.append(
            f"IMPORTANT: The codebase is at {repo_path}/web/. Use ABSOLUTE paths when "
            f"checking file existence (e.g., {repo_path}/web/public/icons/ not just public/icons/). "
            "The --add-dir flag gives you access to this directory."
        )
    parts.append("")

    # Include acceptance criteria reference
    if acceptance_file and acceptance_file.exists():
        parts.append(
            f"ACCEPTANCE CRITERIA: Reference the acceptance criteria at {acceptance_file}. "
            "Map each finding to a specific acceptance criterion using the 'acceptance_ref' field."
        )
        parts.append("")

    # Structured output instructions
    parts.append(
        "OUTPUT FORMAT: After your detailed markdown review, include a machine-readable "
        "JSON verdict block at the end of your response, wrapped in ```json``` fences. "
        "Use this exact schema:"
    )
    parts.append("")
    parts.append("```json")
    parts.append(json.dumps({
        "verdict": "PASS | CONDITIONAL_PASS | BLOCK_RELEASE",
        "findings": [
            {
                "id": "C-1",
                "severity": "critical | high | medium | low",
                "file": "src/path/to/file.ts",
                "line": 42,
                "summary": "One-line description of the issue",
                "fix": "Recommended fix",
                "acceptance_ref": "epic-1 | release-blocker-3",
                "category": "security | functionality | ux | accessibility | pwa | performance | correctness",
            }
        ],
        "lanes_impacted": ["frontend", "backend"],
        "summary": "2-3 sentence evaluation summary",
    }, indent=2, ensure_ascii=False))
    parts.append("```")
    parts.append("")

    # Few-shot examples
    if few_shot_dir and few_shot_dir.exists():
        examples = sorted(few_shot_dir.glob("*.md"))[:3]
        if examples:
            parts.append("REFERENCE EXAMPLES — calibrate your scoring against these:")
            parts.append("")
            for ex_path in examples:
                content = ex_path.read_text(encoding="utf-8")
                parts.append(f"### Example: {ex_path.stem}")
                parts.append(content[:2000])
                parts.append("")

    parts.append(
        "Return your detailed markdown review FIRST, then the JSON verdict block at the very end. "
        "The JSON must be valid and parseable. Use BLOCK_RELEASE only for critical/high issues "
        "that make the product non-functional or insecure. Use CONDITIONAL_PASS when only "
        "medium/low issues remain. Use PASS only when no issues remain."
    )
    return "\n".join(parts)
