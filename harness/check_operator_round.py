#!/usr/bin/env python3
"""
Operator-round checker for Harness v5.

Commands:
  lint                       Lint operator docs against lint_config.toml (line caps, loader pointers, FILE_INDEX coverage, meeting frontmatter + Challenge Section)
  audit-operator-layer       Operator-layer drift audit (REG §7): stage IDs, path existence, SESSION_RESUME freshness, legacy SUPERSEDED headers, file index coverage
  lock <round_id>            Create operator/locks/<round_id>.lock from contract files (sha256 of all base files)
  gates <round_id>           Gate 5 process-integrity checks for a round (contract immutability, live lint/convention hash, commit traceability, meeting integrity, operator-layer drift)
  close <round_id>           Run gates; if all pass, transition lock status to `closed` with closed_at timestamp

Exits 0 on pass, non-zero on any blocker. Pure stdlib (Python 3.11+ tomllib).
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

try:
    import tomllib  # Python 3.11+
except ImportError:  # pragma: no cover
    try:
        import tomli as tomllib  # type: ignore
    except ImportError:
        sys.stderr.write("tomllib (Python 3.11+) or tomli package required.\n")
        sys.exit(2)


REPO = Path(__file__).resolve().parent.parent
OPERATOR_DIR = REPO / "context_harness" / "operator"
LINT_CONFIG = OPERATOR_DIR / "lint_config.toml"
LOCKS_DIR = OPERATOR_DIR / "locks"
CONTRACTS_DIR = OPERATOR_DIR / "contracts"
FILE_INDEX = OPERATOR_DIR / "FILE_INDEX.md"
STAGE_CONTRACT_DOC = OPERATOR_DIR / "STAGE_CONTRACT.md"
REGULATION_DOC = OPERATOR_DIR / "REGULATION.md"
OPERATOR_DOC = OPERATOR_DIR / "OPERATOR.md"
MEETING_PROTOCOL_DOC = OPERATOR_DIR / "MEETING_PROTOCOL.md"
SESSION_RESUME = REPO / "context_harness" / "SESSION_RESUME.md"
PROCESS_LOG = REPO / "docs" / "exec-plans" / "process-log.jsonl"

# Normative decision stages — factual meetings may not use these.
NORMATIVE_STAGES = {
    "overall_planning",
    "detailed_design",
    "convention_lock",
    "eval_protocol",
    "acceptance",
    "round_lock",
    "coding_1st",
    "evaluation_verdict",
    "coding_2nd",
    "retro",
    "regulation_update",
    "operator_amendment",
}

FACTUAL_EVIDENCE_PATTERN = re.compile(
    r"Evidence\s*:\s*\n((?:\s*[-*]\s+.+\n?)+)",
    re.MULTILINE,
)
EVIDENCE_REF_PATTERN = re.compile(r"[-*]\s+.*?(?:`[^`]+`|\b\S+/\S+|\.(?:md|py|txt|yaml|yml|toml|json|swift|sh)\b|sha256:)")


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

    def merge(self, other: "CheckReport") -> None:
        self.blockers.extend(other.blockers)
        self.advisories.extend(other.advisories)
        self.passes.extend(other.passes)

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
    Supports: `key: value`, `key: [a, b, c]`. No multiline or anchors.
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
        if value.startswith(("\"", "'")) and value.endswith(value[0]):
            value = value[1:-1]
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


# -----------------------------------------------------------------
# lint
# -----------------------------------------------------------------


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
            if n >= warn:
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


def _match_glob_exempt(rel_path: str, exempt_globs: list[str]) -> bool:
    for g in exempt_globs:
        if g.endswith("/**"):
            if rel_path.startswith(g[:-3]):
                return True
        elif rel_path == g:
            return True
    return False


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

    missing: list[str] = []
    for p in sorted(set(candidates)):
        rel = p.relative_to(REPO).as_posix()
        if _match_glob_exempt(rel, exempt_globs):
            continue
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
            continue
        text = mp.read_text()
        fm_match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
        if not fm_match:
            report.blocker(f"meeting missing frontmatter: {mp.name}")
            continue
        try:
            fm = parse_simple_frontmatter(fm_match.group(1))
        except Exception as e:
            report.blocker(f"meeting frontmatter invalid ({mp.name}): {e}")
            continue
        for k in required:
            if k not in fm:
                report.blocker(f"meeting {mp.name} missing frontmatter key: {k}")
        for k, vals in allowed.items():
            v = fm.get(k)
            if v is not None and v not in vals:
                report.blocker(f"meeting {mp.name} frontmatter {k}={v} not in allowed")
        status = fm.get("status")
        stage = fm.get("stage")
        if status == "decided":
            for sec in decided_sections:
                if sec not in text:
                    report.blocker(f"meeting {mp.name} status=decided missing: {sec}")
            cs_match = re.search(r"## Challenge Section\s*(.*?)(?=\n## |\Z)", text, re.DOTALL)
            cs_body = cs_match.group(1) if cs_match else ""
            if stage in factual_stages:
                if factual_phrase not in cs_body:
                    report.blocker(f"meeting {mp.name} (factual) Challenge missing required phrase")
                else:
                    # Require Evidence: section with ≥1 path/command reference
                    ev_match = FACTUAL_EVIDENCE_PATTERN.search(cs_body)
                    if not ev_match:
                        report.blocker(f"meeting {mp.name} (factual) missing Evidence: section with bullet list")
                    else:
                        bullets = ev_match.group(1)
                        if not EVIDENCE_REF_PATTERN.search(bullets):
                            report.blocker(f"meeting {mp.name} (factual) Evidence bullets lack any path/command/hash reference")
            else:
                if stage in NORMATIVE_STAGES and not any(kw.lower() in cs_body.lower() for kw in decision_keywords):
                    report.blocker(f"meeting {mp.name} Challenge Section lacks any of: {decision_keywords}")


def cmd_lint() -> CheckReport:
    cfg = load_lint_config()
    report = CheckReport()
    check_line_caps(cfg, report)
    check_loader_pointers(cfg, report)
    check_file_index_coverage(cfg, report)
    check_meeting_frontmatter(cfg, report)
    return report


# -----------------------------------------------------------------
# audit-operator-layer  (REG §7)
# -----------------------------------------------------------------


def parse_stage_ids_from_stage_contract() -> set[str]:
    """Extract `stage_id` values from the stage matrix table in STAGE_CONTRACT.md."""
    if not STAGE_CONTRACT_DOC.exists():
        return set()
    text = STAGE_CONTRACT_DOC.read_text()
    ids: set[str] = set()
    # backtick-quoted snake_case ids in table rows
    for m in re.finditer(r"`([a-z][a-z0-9_]+)`", text):
        ids.add(m.group(1))
    # Filter by ones that look like stage_ids — cross-check with known set at call site.
    return ids


def check_session_resume_freshness(report: CheckReport) -> None:
    if not SESSION_RESUME.exists():
        report.blocker("SESSION_RESUME.md missing")
        return
    mtime = datetime.fromtimestamp(SESSION_RESUME.stat().st_mtime, tz=timezone.utc)
    age_hours = (datetime.now(timezone.utc) - mtime).total_seconds() / 3600
    if age_hours > 168:  # 7 days
        report.blocker(f"SESSION_RESUME.md stale > 7d ({age_hours:.1f}h)")
    elif age_hours > 48:
        report.advisory(f"SESSION_RESUME.md stale > 48h ({age_hours:.1f}h)")
    else:
        report.ok(f"SESSION_RESUME.md fresh ({age_hours:.1f}h)")


def check_legacy_superseded_headers(cfg: dict, report: CheckReport) -> None:
    for rel in cfg.get("superseded_docs", []):
        p = REPO / rel
        if not p.exists():
            report.advisory(f"superseded doc missing on disk: {rel}")
            continue
        head = "\n".join(p.read_text().splitlines()[:10])
        if "SUPERSEDED" not in head and "ACTIVE" not in head:
            report.blocker(f"legacy doc {rel} lacks SUPERSEDED/ACTIVE marker in first 10 lines")
        elif "SUPERSEDED" in head:
            report.ok(f"legacy doc marked SUPERSEDED: {rel}")
        else:
            report.advisory(f"legacy doc marked ACTIVE: {rel} — verify intentional")


def audit_operator_layer(report: CheckReport, cfg: dict) -> None:
    # Doc existence
    required_docs = [
        "OPERATOR.md",
        "FILE_INDEX.md",
        "STAGE_CONTRACT.md",
        "MEETING_PROTOCOL.md",
        "REGULATION.md",
        "PROCESS_AUDIT_CHECKLIST.md",
        "CHANGELOG.md",
    ]
    for d in required_docs:
        p = OPERATOR_DIR / d
        if not p.exists():
            report.blocker(f"operator doc missing: {d}")
        else:
            report.ok(f"operator doc present: {d}")

    # Stage ID consistency
    allowed_stages = set(cfg.get("meeting_frontmatter_allowed", {}).get("stage", []))
    if allowed_stages and STAGE_CONTRACT_DOC.exists():
        sc_text = STAGE_CONTRACT_DOC.read_text()
        missing_in_sc = [s for s in allowed_stages if s not in sc_text]
        if missing_in_sc:
            for s in missing_in_sc:
                report.blocker(f"stage_id '{s}' in lint_config.stage but absent from STAGE_CONTRACT.md")
        else:
            report.ok(f"stage_ids consistent across lint_config + STAGE_CONTRACT.md ({len(allowed_stages)})")

    # Stage IDs referenced in MEETING_PROTOCOL
    if allowed_stages and MEETING_PROTOCOL_DOC.exists():
        mp_text = MEETING_PROTOCOL_DOC.read_text()
        missing_in_mp = [s for s in allowed_stages if s not in mp_text]
        if missing_in_mp:
            for s in missing_in_mp:
                report.blocker(f"stage_id '{s}' not documented in MEETING_PROTOCOL.md")
        else:
            report.ok("stage_ids all present in MEETING_PROTOCOL.md")

    # Precedence — REGULATION lists all precedence entries from lint config
    precedence = cfg.get("precedence", [])
    if REGULATION_DOC.exists():
        reg = REGULATION_DOC.read_text()
        if "Precedence Ladder" not in reg:
            report.blocker("REGULATION.md missing Precedence Ladder section")
        else:
            for doc in precedence:
                if isinstance(doc, str) and doc.startswith("context_harness/operator/") and doc not in reg:
                    report.advisory(f"precedence entry '{doc}' not textually present in REGULATION.md")

    # Referenced file existence — any path-like token inside operator docs that points at a real location should resolve.
    path_like = re.compile(r"(?:`|\()((?:context_harness|docs|harness|workspace|reports|operator)/[a-zA-Z0-9_./-]+)(?:`|\))")
    broken: list[tuple[str, str]] = []
    for doc_path in [OPERATOR_DOC, REGULATION_DOC, STAGE_CONTRACT_DOC, MEETING_PROTOCOL_DOC, FILE_INDEX, OPERATOR_DIR / "PROCESS_AUDIT_CHECKLIST.md"]:
        if not doc_path.exists():
            continue
        doc_is_in_operator = OPERATOR_DIR in doc_path.resolve().parents or doc_path.resolve() == OPERATOR_DIR
        for m in path_like.finditer(doc_path.read_text()):
            rel = m.group(1)
            # Skip placeholders and wildcards
            if "<" in rel or ">" in rel or "**" in rel or "*" in rel or "..." in rel:
                continue
            # Skip known future-path directories referenced with trailing slash
            if rel.endswith("/"):
                continue
            # Try two resolutions: repo-root, and (for bare `operator/...` from inside operator docs) context_harness/
            candidates = [REPO / rel]
            if rel.startswith("operator/") and doc_is_in_operator:
                candidates.append(REPO / "context_harness" / rel)
            if any(c.exists() for c in candidates):
                continue
            broken.append((doc_path.name, rel))
    if broken:
        seen = set()
        for doc_name, rel in broken:
            key = (doc_name, rel)
            if key in seen:
                continue
            seen.add(key)
            report.advisory(f"operator doc {doc_name} points at missing path: {rel}")

    # SESSION_RESUME freshness
    check_session_resume_freshness(report)

    # Legacy SUPERSEDED headers
    check_legacy_superseded_headers(cfg, report)


def cmd_audit_operator_layer() -> CheckReport:
    cfg = load_lint_config()
    report = CheckReport()
    audit_operator_layer(report, cfg)
    return report


# -----------------------------------------------------------------
# lock / gates / close
# -----------------------------------------------------------------


REQUIRED_CONTRACT_FILES = [
    "spec.md",
    "file_whitelist.txt",
    "convention_version.txt",
    "lint_config.txt",
    "acceptance.md",
    "eval_protocol.md",
]


def read_pointer_file(p: Path) -> tuple[str, str] | None:
    """Read `lint_config.txt` or `convention_version.txt` — expects `<path>\\n<sha256:...>`."""
    if not p.exists():
        return None
    lines = [ln.strip() for ln in p.read_text().splitlines() if ln.strip() and not ln.strip().startswith("#")]
    if len(lines) < 2:
        return None
    return lines[0], lines[1]


def cmd_lock(round_id: str) -> CheckReport:
    report = CheckReport()
    round_dir = CONTRACTS_DIR / round_id
    if not round_dir.exists():
        report.blocker(f"contract directory missing: {round_dir}")
        return report
    hashes: dict[str, str] = {}
    for f in REQUIRED_CONTRACT_FILES:
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
    # base_commit for commit traceability (item 11)
    try:
        base_commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=REPO, text=True
        ).strip()
    except Exception:
        base_commit = None
    lock = {
        "round_id": round_id,
        "schema_version": 1,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "status": "active",
        "operators": {
            "claude_code": {"session": "this-session", "role_default": "implementer"},
            "codex": {"session": "", "role_default": "designer_reviewer"},
        },
        "base_commit": base_commit,
        "hashes": hashes,
        "amendments": [],
        "stages_completed": [],
        "closed_at": None,
    }
    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    report.ok(f"lock created: {lock_path} (base_commit={base_commit or 'unknown'})")
    report.ok("ready")
    return report


def check_commit_traceability(lock: dict, report: CheckReport) -> None:
    """Item 11: commits since lock base_commit must touch only whitelisted files."""
    base = lock.get("base_commit")
    round_dir = CONTRACTS_DIR / lock["round_id"]
    wl_path = round_dir / "file_whitelist.txt"
    if not base:
        report.advisory("lock has no base_commit — commit traceability cannot be verified (legacy lock)")
        return
    if not wl_path.exists():
        report.blocker("file_whitelist.txt missing — cannot verify commit traceability")
        return
    # Effective whitelist = base + amendments
    whitelist: set[str] = set()
    for ln in wl_path.read_text().splitlines():
        ln = ln.strip()
        if ln and not ln.startswith("#"):
            whitelist.add(ln)
    for amend in lock.get("amendments", []):
        apath = round_dir / amend.get("file", "")
        if apath.exists() and apath.name.startswith("file_whitelist.amendment."):
            for ln in apath.read_text().splitlines():
                ln = ln.strip()
                if ln.startswith("+"):
                    whitelist.add(ln[1:].strip())
                elif ln.startswith("-"):
                    whitelist.discard(ln[1:].strip())
    try:
        diff_files = subprocess.check_output(
            ["git", "diff", "--name-only", f"{base}..HEAD"], cwd=REPO, text=True
        ).strip().splitlines()
    except Exception as e:
        report.advisory(f"git diff unavailable: {e}")
        return
    out_of_scope: list[str] = []

    def _matches_whitelist(rel: str) -> bool:
        for pat in whitelist:
            if pat.endswith("/**") and rel.startswith(pat[:-3]):
                return True
            if pat.endswith("/*") and rel.startswith(pat[:-2]) and "/" not in rel[len(pat) - 2:]:
                return True
            if pat == rel:
                return True
        return False

    for f in diff_files:
        if not f:
            continue
        if not _matches_whitelist(f):
            out_of_scope.append(f)
    if out_of_scope:
        for f in out_of_scope:
            report.blocker(f"commit touches out-of-whitelist path: {f}")
    else:
        report.ok(f"commit traceability ok ({len(diff_files)} files vs whitelist)")


def check_live_pointer_hashes(lock: dict, report: CheckReport) -> None:
    """Item 5: lint_config.txt / convention_version.txt hold `<path>\\n<sha>`. Recompute and compare."""
    round_dir = CONTRACTS_DIR / lock["round_id"]
    for name in ("lint_config.txt", "convention_version.txt"):
        p = round_dir / name
        entry = read_pointer_file(p)
        if entry is None:
            report.advisory(f"{name} does not follow `<path>\\n<sha256:...>` format — live hash check skipped")
            continue
        target_rel, expected = entry
        target = REPO / target_rel
        if not target.exists():
            report.blocker(f"{name} points at missing target: {target_rel}")
            continue
        actual = sha256_file(target)
        if actual != expected:
            report.blocker(f"{name} target {target_rel} live SHA differs from locked SHA")
        else:
            report.ok(f"{name} live hash matches locked target")


def cmd_gates(round_id: str) -> CheckReport:
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
    round_dir = CONTRACTS_DIR / round_id
    # Contract immutability
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
    # Live pointer hashes (lint/convention)
    check_live_pointer_hashes(lock, report)
    # Commit traceability
    check_commit_traceability(lock, report)
    # Lint + audit
    lint_report = cmd_lint()
    audit_report = cmd_audit_operator_layer()
    report.merge(lint_report)
    report.merge(audit_report)
    return report


def cmd_close(round_id: str) -> CheckReport:
    report = cmd_gates(round_id)
    if report.blockers:
        report.blocker(f"close refused: {len(report.blockers)} gate blocker(s) present")
        return report
    lock_path = LOCKS_DIR / f"{round_id}.lock"
    lock = json.loads(lock_path.read_text())
    if lock.get("status") != "active":
        report.blocker(f"close refused: lock status is '{lock.get('status')}', must be 'active'")
        return report
    lock["status"] = "closed"
    lock["closed_at"] = datetime.now(timezone.utc).isoformat()
    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    report.ok(f"lock {round_id} transitioned to closed at {lock['closed_at']}")
    return report


# -----------------------------------------------------------------
# main
# -----------------------------------------------------------------


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
    elif cmd == "close" and len(argv) >= 3:
        report = cmd_close(argv[2])
    else:
        print(__doc__)
        return 2
    print(report.render())
    return report.exit_code()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
