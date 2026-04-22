#!/usr/bin/env python3
"""
Operator-round checker for Harness v5.

Commands:
  lock <round_id>            Create operator/locks/<round_id>.lock from contract files
  gates <round_id>           Run Gate 5 process-integrity checks for a round
  audit-operator-layer       Run operator-layer drift audit (standalone)
  lint                       Lint operator docs against lint_config.yaml

Exits 0 on pass, non-zero on any blocker.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

try:
    import tomllib  # Python 3.11+
except ImportError:  # Python < 3.11
    try:
        import tomli as tomllib  # type: ignore
    except ImportError:
        sys.stderr.write(
            "tomllib (Python 3.11+) or tomli package required for TOML parsing.\n"
        )
        sys.exit(2)


REPO = Path(__file__).resolve().parent.parent
OPERATOR_DIR = REPO / "context_harness" / "operator"
LINT_CONFIG = OPERATOR_DIR / "lint_config.toml"
LOCKS_DIR = OPERATOR_DIR / "locks"
CONTRACTS_DIR = OPERATOR_DIR / "contracts"
FILE_INDEX = OPERATOR_DIR / "FILE_INDEX.md"


@dataclass
class CheckReport:
    blockers: list[str] = field(default_factory=list)
    advisories: list[str] = field(default_factory=list)
    passes: list[str] = field(default_factory=list)

    def blocker(self, msg: str) -> None:
        self.blockers.append(msg)

    def advisory(self, msg: str) -> None:
        self.advisories.append(msg)

    def ok(self, msg: str) -> None:
        self.passes.append(msg)

    def exit_code(self) -> int:
        return 1 if self.blockers else 0

    def render(self) -> str:
        lines = []
        for msg in self.passes:
            lines.append(f"  ok       {msg}")
        for msg in self.advisories:
            lines.append(f"  advisory {msg}")
        for msg in self.blockers:
            lines.append(f"  BLOCKER  {msg}")
        lines.append("")
        lines.append(f"blockers:   {len(self.blockers)}")
        lines.append(f"advisories: {len(self.advisories)}")
        lines.append(f"passes:     {len(self.passes)}")
        return "\n".join(lines)


def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    h.update(p.read_bytes())
    return "sha256:" + h.hexdigest()


def load_lint_config() -> dict:
    if not LINT_CONFIG.exists():
        raise SystemExit(f"lint config missing: {LINT_CONFIG}")
    return tomllib.loads(LINT_CONFIG.read_text())


def parse_simple_frontmatter(block: str) -> dict:
    """Minimal YAML-subset parser for meeting frontmatter.
    Supports: `key: value`, `key: [a, b, c]`, `key: value_with_colons_after_first`.
    Strips inline values; no multiline scalars, no anchors, no nested maps.
    """
    out: dict = {}
    for raw in block.splitlines():
        line = raw.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        # Strip surrounding quotes if any
        if value.startswith(("\"", "'")) and value.endswith(value[0]):
            value = value[1:-1]
        # Inline list
        if value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            items = [x.strip().strip("\"'") for x in inner.split(",")] if inner else []
            out[key] = items
        else:
            out[key] = value
    return out


def line_count(p: Path) -> int:
    if not p.exists():
        return 0
    return len(p.read_text().splitlines())


def check_line_caps(cfg: dict, report: CheckReport) -> None:
    caps = cfg.get("line_caps", {})
    warnings = cfg.get("line_warnings", {})
    for rel, cap in caps.items():
        p = REPO / rel
        if not p.exists():
            report.blocker(f"line-cap target missing: {rel}")
            continue
        n = line_count(p)
        if n > cap:
            report.blocker(f"line cap exceeded: {rel} = {n} lines (cap {cap})")
        else:
            report.ok(f"line cap: {rel} = {n}/{cap}")
    for rel, warn in warnings.items():
        p = REPO / rel
        if p.exists():
            n = line_count(p)
            if n > warn:
                report.advisory(f"line warning: {rel} = {n} (warn ≥ {warn})")


def check_loader_pointers(cfg: dict, report: CheckReport) -> None:
    for entry in cfg.get("loader_pointers", []):
        f = REPO / entry["file"]
        must = entry["must_reference"]
        if not f.exists():
            report.blocker(f"loader missing: {entry['file']}")
            continue
        if must not in f.read_text():
            report.blocker(f"loader {entry['file']} does not reference {must}")
        else:
            report.ok(f"loader references target: {entry['file']} → {must}")


def check_file_index_coverage(cfg: dict, report: CheckReport) -> None:
    coverage = cfg.get("file_index_coverage", {})
    if not coverage:
        return
    target = REPO / coverage["target"]
    if not target.exists():
        report.blocker(f"FILE_INDEX target missing: {coverage['target']}")
        return
    index_text = target.read_text()
    exempt_globs = coverage.get("exempt", [])
    candidates: list[Path] = []
    for pattern in coverage.get("required_scan_globs", []):
        candidates.extend(REPO.glob(pattern))

    def is_exempt(p: Path) -> bool:
        rel = p.relative_to(REPO).as_posix()
        for g in exempt_globs:
            # Very simple glob match: accept prefix/** or direct equality.
            if g.endswith("/**"):
                if rel.startswith(g[:-3]):
                    return True
            elif rel == g:
                return True
        return False

    missing: list[str] = []
    for p in sorted(set(candidates)):
        if is_exempt(p):
            continue
        rel = p.relative_to(REPO).as_posix()
        # Match by full rel path OR by the filename at end — more forgiving than strict path match.
        if rel in index_text or p.name in index_text:
            continue
        missing.append(rel)
    if missing:
        for m in missing:
            report.blocker(f"FILE_INDEX missing entry for: {m}")
    else:
        report.ok("FILE_INDEX coverage complete")


def check_meeting_frontmatter(cfg: dict, report: CheckReport) -> None:
    meetings_dir = OPERATOR_DIR / "meetings"
    if not meetings_dir.exists():
        return
    required = cfg.get("meeting_required_frontmatter", [])
    allowed = cfg.get("meeting_frontmatter_allowed", {})
    decided_sections = cfg.get("meeting_required_sections", {}).get("decided", [])
    challenge = cfg.get("challenge_section", {})
    factual_stages = set(challenge.get("factual_stages", []))
    factual_phrase = challenge.get("factual_required_phrase", "")
    decision_keywords = challenge.get("decision_required_keywords", [])

    for mp in sorted(meetings_dir.glob("*.md")):
        if mp.name.startswith("_"):
            continue  # templates
        text = mp.read_text()
        # Extract frontmatter
        fm_match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
        if not fm_match:
            report.blocker(f"meeting missing frontmatter: {mp.name}")
            continue
        try:
            fm = parse_simple_frontmatter(fm_match.group(1))
        except Exception as e:
            report.blocker(f"meeting frontmatter invalid ({mp.name}): {e}")
            continue
        # Required keys
        for k in required:
            if k not in fm:
                report.blocker(f"meeting {mp.name} missing frontmatter key: {k}")
        # Allowed values
        for k, allowed_values in allowed.items():
            v = fm.get(k)
            if v is not None and v not in allowed_values:
                report.blocker(f"meeting {mp.name} frontmatter {k}={v} not in allowed values")
        # Section + Challenge rules
        status = fm.get("status")
        stage = fm.get("stage")
        if status == "decided":
            for sec in decided_sections:
                if sec not in text:
                    report.blocker(f"meeting {mp.name} status=decided missing required section: {sec}")
            # Challenge Section content
            cs_match = re.search(r"## Challenge Section\s*(.*?)(?=\n## |\Z)", text, re.DOTALL)
            cs_body = cs_match.group(1) if cs_match else ""
            if stage in factual_stages:
                if factual_phrase not in cs_body:
                    report.blocker(f"meeting {mp.name} (factual) Challenge missing required phrase")
            else:
                if not any(kw.lower() in cs_body.lower() for kw in decision_keywords):
                    report.blocker(f"meeting {mp.name} Challenge Section lacks any of: {decision_keywords}")
        if stage and allowed.get("stage") and stage not in allowed["stage"]:
            # Already caught above, but double-safety
            pass


def audit_operator_layer(report: CheckReport, cfg: dict) -> None:
    # Docs existence
    for expected in [
        "OPERATOR.md",
        "FILE_INDEX.md",
        "STAGE_CONTRACT.md",
        "MEETING_PROTOCOL.md",
        "REGULATION.md",
        "PROCESS_AUDIT_CHECKLIST.md",
        "CHANGELOG.md",
    ]:
        p = OPERATOR_DIR / expected
        if not p.exists():
            report.blocker(f"operator doc missing: {expected}")
        else:
            report.ok(f"operator doc present: {expected}")
    # Stage name consistency across STAGE_CONTRACT and MEETING_PROTOCOL
    sc = (OPERATOR_DIR / "STAGE_CONTRACT.md").read_text() if (OPERATOR_DIR / "STAGE_CONTRACT.md").exists() else ""
    mp = (OPERATOR_DIR / "MEETING_PROTOCOL.md").read_text() if (OPERATOR_DIR / "MEETING_PROTOCOL.md").exists() else ""
    allowed_stages = cfg.get("meeting_frontmatter_allowed", {}).get("stage", [])
    for st in allowed_stages:
        if st not in mp:
            report.blocker(f"stage '{st}' listed in lint_config but not in MEETING_PROTOCOL")
    # Precedence order consistency
    precedence = cfg.get("precedence", [])
    reg = (OPERATOR_DIR / "REGULATION.md").read_text() if (OPERATOR_DIR / "REGULATION.md").exists() else ""
    if "Precedence Ladder" not in reg:
        report.blocker("REGULATION.md missing Precedence Ladder section")
    for doc in precedence:
        if isinstance(doc, str) and doc.startswith("context_harness/operator/") and doc not in reg:
            report.advisory(f"precedence entry '{doc}' not textually present in REGULATION.md")


def cmd_lint() -> CheckReport:
    cfg = load_lint_config()
    report = CheckReport()
    check_line_caps(cfg, report)
    check_loader_pointers(cfg, report)
    check_file_index_coverage(cfg, report)
    check_meeting_frontmatter(cfg, report)
    return report


def cmd_audit_operator_layer() -> CheckReport:
    cfg = load_lint_config()
    report = CheckReport()
    audit_operator_layer(report, cfg)
    return report


def cmd_lock(round_id: str) -> CheckReport:
    cfg = load_lint_config()
    report = CheckReport()
    round_dir = CONTRACTS_DIR / round_id
    if not round_dir.exists():
        report.blocker(f"contract directory missing: {round_dir}")
        return report
    required = ["spec.md", "file_whitelist.txt", "convention_version.txt", "lint_config.txt", "acceptance.md", "eval_protocol.md"]
    hashes: dict[str, str] = {}
    for f in required:
        p = round_dir / f
        if not p.exists():
            report.blocker(f"contract file missing: {round_id}/{f}")
            continue
        hashes[f] = sha256_file(p)
        report.ok(f"hashed {round_id}/{f}")
    if report.blockers:
        return report
    LOCKS_DIR.mkdir(parents=True, exist_ok=True)
    lock_path = LOCKS_DIR / f"{round_id}.lock"
    if lock_path.exists():
        report.blocker(f"lock already exists: {lock_path}")
        return report
    lock = {
        "round_id": round_id,
        "schema_version": 1,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "status": "active",
        "operators": {
            "claude_code": {"session": "this-session", "role_default": "implementer"},
            "codex": {"session": "", "role_default": "designer_reviewer"},
        },
        "hashes": hashes,
        "amendments": [],
        "stages_completed": [],
        "closed_at": None,
    }
    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    report.ok(f"lock created: {lock_path}")
    return report


def cmd_gates(round_id: str) -> CheckReport:
    cfg = load_lint_config()
    report = CheckReport()
    lock_path = LOCKS_DIR / f"{round_id}.lock"
    if not lock_path.exists():
        report.blocker(f"lock missing: {lock_path}")
        return report
    try:
        lock = json.loads(lock_path.read_text())
    except json.JSONDecodeError as e:
        report.blocker(f"lock JSON invalid: {e}")
        return report
    # Verify contract file hashes match
    round_dir = CONTRACTS_DIR / round_id
    for fname, expected in lock.get("hashes", {}).items():
        p = round_dir / fname
        if not p.exists():
            report.blocker(f"contract file missing (hashed at lock): {fname}")
            continue
        actual = sha256_file(p)
        if actual != expected:
            report.blocker(f"contract file MUTATED after lock: {fname} expected {expected[:20]} got {actual[:20]}")
        else:
            report.ok(f"contract file immutable: {fname}")
    # Lint + operator-layer audit
    lint_report = cmd_lint()
    audit_report = cmd_audit_operator_layer()
    report.blockers.extend(lint_report.blockers)
    report.blockers.extend(audit_report.blockers)
    report.advisories.extend(lint_report.advisories)
    report.advisories.extend(audit_report.advisories)
    report.passes.extend(lint_report.passes)
    report.passes.extend(audit_report.passes)
    return report


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "lint":
        report = cmd_lint()
    elif cmd == "audit-operator-layer":
        report = cmd_audit_operator_layer()
    elif cmd == "lock" and len(argv) >= 3:
        report = cmd_lock(argv[2])
    elif cmd == "gates" and len(argv) >= 3:
        report = cmd_gates(argv[2])
    else:
        print(__doc__)
        return 2
    print(report.render())
    return report.exit_code()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
