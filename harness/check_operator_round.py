#!/usr/bin/env python3
"""
Operator-round checker for Harness v5.

Commands:
  lint                              Lint operator docs against lint_config.toml
  audit-operator-layer              Operator-layer drift audit (REG §7)
  lock   <round_id>                 Create lock from contract files + append `created` event
  amend  <round_id> <file> <meeting> v5.5: pre-validate in memory, write lock, append `amended` event.
                                    Enforces basename containment + canonical meeting path; .txt
                                    amendments default supersedes=[target].
  gates  <round_id>                 Gate 5 checks. Post-close revalidates gate_evidence.json sha
                                    AND re-runs load_gate_evidence to catch deliverable mutation.
  close  <round_id>                 Run gates + gate_evidence.json schema; transition to `closed`

Exits 0 on pass, non-zero on any blocker. Pure stdlib (Python 3.11+ tomllib).
"""

from __future__ import annotations

import fnmatch
import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath

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


CODEX_SESSION_ID_RE = re.compile(r"^[A-Za-z0-9._:-]{8,}$")


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
        # v5.3: Codex identity presence — decided meetings with codex in participants need session_id OR transcript
        if status == "decided":
            participants = fm.get("participants", [])
            if isinstance(participants, list) and "codex" in participants:
                sid = fm.get("codex_session_id")
                transcript = fm.get("codex_transcript")
                has_sid = isinstance(sid, str) and bool(CODEX_SESSION_ID_RE.match(sid))
                has_transcript = False
                if isinstance(transcript, str) and transcript:
                    tpath = Path(transcript) if transcript.startswith("/") else REPO / transcript
                    has_transcript = tpath.exists()
                if not (has_sid or has_transcript):
                    report.blocker(f"meeting {mp.name} lists codex participant but provides neither valid `codex_session_id` nor existing `codex_transcript`")
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

    # Referenced file existence — v5.2: missing paths = BLOCKER (with allowlist).
    allowlist = set(cfg.get("path_existence", {}).get("allowlist_placeholders", []))
    path_like = re.compile(r"(?:`|\()((?:context_harness|docs|harness|workspace|reports|operator)/[a-zA-Z0-9_./-]+)(?:`|\))")
    broken: list[tuple[str, str]] = []
    for doc_path in [OPERATOR_DOC, REGULATION_DOC, STAGE_CONTRACT_DOC, MEETING_PROTOCOL_DOC, FILE_INDEX, OPERATOR_DIR / "PROCESS_AUDIT_CHECKLIST.md"]:
        if not doc_path.exists():
            continue
        doc_is_in_operator = OPERATOR_DIR in doc_path.resolve().parents or doc_path.resolve() == OPERATOR_DIR
        for m in path_like.finditer(doc_path.read_text()):
            rel = m.group(1)
            if "<" in rel or ">" in rel or "**" in rel or "*" in rel or "..." in rel:
                continue
            # Build candidate relative paths (raw + shorthand expansion)
            rel_candidates = [rel]
            if rel.startswith("operator/") and doc_is_in_operator:
                rel_candidates.append("context_harness/" + rel)
            # Existence check — any candidate resolving ⇒ OK
            if any((REPO / rc).exists() for rc in rel_candidates):
                continue
            # Allowlist check — any candidate (with or without trailing slash) in allowlist ⇒ advisory
            if any(rc in allowlist or rc.rstrip("/") in allowlist for rc in rel_candidates):
                report.advisory(f"operator doc {doc_path.name} points at allowlisted future/shorthand path: {rel}")
                continue
            broken.append((doc_path.name, rel))
    if broken:
        seen = set()
        for doc_name, rel in broken:
            key = (doc_name, rel)
            if key in seen:
                continue
            seen.add(key)
            report.blocker(f"operator doc {doc_name} references missing path: {rel}")

    # SESSION_RESUME freshness
    check_session_resume_freshness(report)

    # Legacy SUPERSEDED headers
    check_legacy_superseded_headers(cfg, report)

    # v5.6: every CHANGELOG version entry must reference an existing meeting file
    # (or declare itself as a meta-entry via `this-entry` marker)
    check_changelog_meeting_trail(report)


def check_changelog_meeting_trail(report: CheckReport) -> None:
    """v5.6: parse CHANGELOG.md for `## v5.X` headers; each must have a `**Meeting:**` line
    pointing to an existing meeting file (or marked as `this-entry` meta-amendment).
    Enforces REGULATION §11 compliance mechanically.
    """
    cl = OPERATOR_DIR / "CHANGELOG.md"
    if not cl.exists():
        return  # audit_operator_layer separately flags missing CHANGELOG
    text = cl.read_text()
    # Split on `## vX.Y` headers; capture the section body
    sections = re.split(r"\n(?=## v\d+\.\d+)", text)
    for sec in sections:
        m_header = re.match(r"## (v\d+\.\d+)", sec)
        if not m_header:
            continue
        version = m_header.group(1)
        # Look for `**Meeting:**` line
        m_meeting = re.search(r"\*\*Meeting:\*\*\s*(.+?)(?:\n|$)", sec)
        if not m_meeting:
            report.blocker(f"CHANGELOG {version}: missing `**Meeting:**` pointer")
            continue
        meeting_line = m_meeting.group(1).strip()
        # Meta-amendment marker
        if "this-entry" in meeting_line:
            report.ok(f"CHANGELOG {version}: meta-amendment (self-referencing)")
            continue
        # Extract markdown link target `[...](path)` or bare path
        m_link = re.search(r"\(([^)]+\.md)\)", meeting_line)
        if m_link:
            rel = m_link.group(1)
            # Relative to CHANGELOG.md location
            p = (OPERATOR_DIR / rel).resolve() if not rel.startswith("context_harness") else (REPO / rel)
            if not p.exists():
                report.blocker(f"CHANGELOG {version}: referenced meeting not found: {rel}")
            else:
                report.ok(f"CHANGELOG {version}: meeting trail ok → {p.relative_to(REPO)}")
        else:
            # Bare path form
            candidates = [REPO / meeting_line, OPERATOR_DIR / meeting_line]
            if not any(c.exists() for c in candidates):
                report.blocker(f"CHANGELOG {version}: meeting pointer unresolvable: {meeting_line}")
            else:
                report.ok(f"CHANGELOG {version}: meeting trail ok")


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


def _events_path(round_id: str) -> Path:
    return LOCKS_DIR / f"{round_id}.events.jsonl"


def _append_lock_event(round_id: str, action: str, lock_sha: str, base_commit: str | None, amendment_file: str | None = None) -> None:
    ev = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "action": action,
        "lock_sha256": lock_sha,
        "base_commit": base_commit,
        "amendment_file": amendment_file,
    }
    _events_path(round_id).open("a").write(json.dumps(ev) + "\n")


def _last_lock_event(round_id: str) -> dict | None:
    p = _events_path(round_id)
    if not p.exists():
        return None
    lines = [ln for ln in p.read_text().splitlines() if ln.strip()]
    if not lines:
        return None
    try:
        return json.loads(lines[-1])
    except json.JSONDecodeError:
        return None


def cmd_lock(round_id: str) -> CheckReport:
    """v5.3: refuse pre-existing amendment files; append lock_created event."""
    report = CheckReport()
    round_dir = CONTRACTS_DIR / round_id
    if not round_dir.exists():
        report.blocker(f"contract directory missing: {round_dir}")
        return report
    # v5.3: refuse pre-existing amendment files
    pre_existing = list(round_dir.glob("*.amendment.*"))
    if pre_existing:
        for p in pre_existing:
            report.blocker(f"pre-existing amendment file blocks initial lock: {p.name} (delete round dir to restart)")
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
    try:
        base_commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=REPO, text=True
        ).strip()
    except Exception:
        base_commit = None
    lock = {
        "round_id": round_id,
        "schema_version": 2,  # bumped in v5.3
        "started_at": datetime.now(timezone.utc).isoformat(),
        "status": "active",
        "operators": {
            "claude_code": {"session": "this-session", "role_default": "implementer"},
            "codex": {"session": "", "role_default": "designer_reviewer"},
        },
        "base_commit": base_commit,
        "hashes": hashes,
        "amendments": [],
        "stages_completed": [],  # informational only in v5.3
        "gate_evidence_sha256": None,
        "closed_at": None,
    }
    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    # v5.3: append first lock event
    lock_sha = sha256_file(lock_path)
    _append_lock_event(round_id, "created", lock_sha, base_commit, None)
    report.ok(f"lock created: {lock_path} (base_commit={base_commit or 'unknown'})")
    report.ok(f"lock event logged: {_events_path(round_id).name}")
    report.ok("ready")
    return report


def _match_glob(rel: str, pattern: str) -> bool:
    """Glob matcher with strict POSIX-style semantics:
      * = [^/]*    (does NOT cross directory separators)
      ** = .*      (crosses directories; must be a full segment — we normalize `**/` and `/**`)
      ? = [^/]
    Exact match short-circuits. Implementation: escape pattern → substitute glob tokens → regex match.
    """
    if pattern == rel:
        return True
    # Escape pattern then substitute glob tokens back in.
    escaped = re.escape(pattern)
    # Order matters: `**/` and `/**` must be handled before `**` and `*`.
    escaped = escaped.replace(r"\*\*/", "(?:.*/)?")
    escaped = escaped.replace(r"/\*\*", "(?:/.*)?")
    escaped = escaped.replace(r"\*\*", ".*")
    escaped = escaped.replace(r"\*", "[^/]*")
    escaped = escaped.replace(r"\?", "[^/]")
    return re.match("^" + escaped + "$", rel) is not None


def _matches_any(rel: str, patterns) -> bool:
    for pat in patterns:
        if _match_glob(rel, pat):
            return True
    return False


def check_commit_traceability(lock: dict, report: CheckReport) -> None:
    """Item 11 (v5.1) + v5.2 fixes: commits AND uncommitted changes since lock base_commit
    must touch only whitelisted files. Uses proper glob matching."""
    base = lock.get("base_commit")
    round_dir = CONTRACTS_DIR / lock["round_id"]
    wl_path = round_dir / "file_whitelist.txt"
    if not base:
        report.advisory("lock has no base_commit — commit traceability cannot be verified (legacy lock)")
        return
    if not wl_path.exists():
        report.blocker("file_whitelist.txt missing — cannot verify commit traceability")
        return
    # Effective whitelist = base + amendments (additive/subtractive via + / -)
    whitelist: set[str] = set()
    for ln in wl_path.read_text().splitlines():
        ln = ln.strip()
        if ln and not ln.startswith("#"):
            whitelist.add(ln)
    for amend in lock.get("amendments", []):
        fname = amend.get("file", "")
        apath = round_dir / fname
        if apath.exists() and fname.startswith("file_whitelist.amendment."):
            for ln in apath.read_text().splitlines():
                ln = ln.strip()
                if ln.startswith("+"):
                    whitelist.add(ln[1:].strip())
                elif ln.startswith("-"):
                    whitelist.discard(ln[1:].strip())
    # Collect touched files: committed + uncommitted + staged
    touched: set[str] = set()
    try:
        committed = subprocess.check_output(
            ["git", "diff", "--name-only", f"{base}..HEAD"], cwd=REPO, text=True
        ).strip().splitlines()
        touched.update(f for f in committed if f)
    except Exception as e:
        report.blocker(f"git diff base..HEAD failed: {e}")
        return
    try:
        # Uncommitted (working tree + staged). `-uall` expands untracked directories to individual files
        # so we don't miss files hidden inside a bare directory entry.
        # NOTE: do NOT .strip() the whole output — porcelain lines begin with a leading space
        # when only the worktree (not index) is modified, and strip() eats it, corrupting parsing.
        dirty = subprocess.check_output(
            ["git", "status", "--porcelain", "-uall"], cwd=REPO, text=True
        ).splitlines()
        for ln in dirty:
            # porcelain format: XY <filename>[ -> <renamed>]
            if len(ln) < 4:
                continue
            fn = ln[3:].split(" -> ")[-1].strip()
            # Strip surrounding quotes added by git for paths containing spaces or non-ASCII
            if len(fn) >= 2 and fn[0] == '"' and fn[-1] == '"':
                fn = fn[1:-1]
            # Skip bare directory entries (trailing slash) — -uall should prevent these, but be defensive
            if fn.endswith("/"):
                continue
            if fn:
                touched.add(fn)
    except Exception as e:
        report.advisory(f"git status --porcelain unavailable: {e}")
    out_of_scope = [f for f in sorted(touched) if not _matches_any(f, whitelist)]
    if out_of_scope:
        for f in out_of_scope:
            report.blocker(f"commit/working-tree touches out-of-whitelist path: {f}")
    else:
        report.ok(f"commit traceability ok ({len(touched)} file(s) vs whitelist)")


def check_live_pointer_hashes(lock: dict, report: CheckReport) -> None:
    """Item 5 (v5.1) + v5.2: pointer files must be `<path>\\n<sha>` format. Malformed = BLOCKER."""
    round_dir = CONTRACTS_DIR / lock["round_id"]
    for name in ("lint_config.txt", "convention_version.txt"):
        p = round_dir / name
        entry = read_pointer_file(p)
        if entry is None:
            report.blocker(f"{name} malformed (expected `<path>\\n<sha256:...>` 2-line format)")
            continue
        target_rel, expected = entry
        if not expected.startswith("sha256:"):
            report.blocker(f"{name} second line must start with `sha256:` — got `{expected[:20]}...`")
            continue
        target = REPO / target_rel
        if not target.exists():
            report.blocker(f"{name} points at missing target: {target_rel}")
            continue
        actual = sha256_file(target)
        if actual != expected:
            report.blocker(f"{name} target {target_rel} live SHA differs from locked SHA")
        else:
            report.ok(f"{name} live hash matches locked target")


def validate_amendments(lock: dict, report: CheckReport) -> None:
    """v5.3: disk-scan for unregistered amendments + strict lock metadata + .txt support.
    Every amendment:
      - lock entry requires: file, target, sha256 (sha256:...), supersedes, meeting
      - file exists on disk
      - live sha matches lock entry
      - .md: frontmatter target/supersedes/meeting match lock entry
      - referenced meeting: same round, status=decided, stage in amendment-eligible set,
        body contains `## Amendment Detail` and amendment filename
      - no amendment file on disk may be absent from lock.amendments[]
    """
    round_dir = CONTRACTS_DIR / lock["round_id"]
    base_files = set(REQUIRED_CONTRACT_FILES)
    lock_round = lock.get("round_id")
    # Build set of amendment files actually on disk
    on_disk = {p.name for p in round_dir.glob("*.amendment.*") if p.is_file()}
    in_lock: set[str] = set()
    for amend in lock.get("amendments", []):
        fname = amend.get("file")
        if not fname:
            report.blocker(f"amendment entry missing `file`: {amend}")
            continue
        in_lock.add(fname)
        apath = round_dir / fname
        # All required lock metadata (v5.3: applies to both .md and .txt)
        missing_meta = [k for k in ("target", "sha256", "supersedes", "meeting") if not amend.get(k)]
        if missing_meta:
            report.blocker(f"amendment {fname} lock entry missing: {missing_meta}")
            continue
        expected = amend["sha256"]
        if not isinstance(expected, str) or not expected.startswith("sha256:"):
            report.blocker(f"amendment {fname} lock sha256 format invalid: {expected}")
            continue
        if not apath.exists():
            report.blocker(f"amendment file missing on disk: {fname}")
            continue
        if sha256_file(apath) != expected:
            report.blocker(f"amendment {fname} live sha differs from lock")
            continue
        if amend["target"] not in base_files:
            report.blocker(f"amendment {fname} target `{amend['target']}` not a base contract file")
            continue
        # .md: frontmatter must match lock entry
        if fname.endswith(".md"):
            text = apath.read_text()
            fm_match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
            if not fm_match:
                report.blocker(f"amendment {fname} missing frontmatter")
                continue
            fm = parse_simple_frontmatter(fm_match.group(1))
            for k in ("target", "supersedes", "meeting"):
                if k not in fm:
                    report.blocker(f"amendment {fname} frontmatter missing `{k}`")
                    continue
            # target must match lock
            if fm.get("target") != amend["target"]:
                report.blocker(f"amendment {fname} frontmatter target mismatch: lock={amend['target']} file={fm.get('target')}")
            if fm.get("meeting") != amend["meeting"]:
                report.blocker(f"amendment {fname} frontmatter meeting mismatch with lock")
        # .txt: body format sanity
        elif fname.endswith(".txt"):
            body = apath.read_text().splitlines()
            bad = [ln for ln in body if ln.strip() and not ln.strip().startswith("#") and not ln.strip().startswith(("+", "-"))]
            if bad:
                report.blocker(f"amendment {fname} has non-directive lines (expected `+path`/`-path`): {bad[:3]}")
        # Meeting validation (shared between .md and .txt)
        meeting_rel = amend["meeting"]
        mp = REPO / meeting_rel if meeting_rel.startswith("context_harness/") else OPERATOR_DIR / "meetings" / Path(meeting_rel).name
        if not mp.exists():
            report.blocker(f"amendment {fname} meeting not found: {meeting_rel}")
            continue
        mtext = mp.read_text()
        fm_match = re.match(r"^---\n(.*?)\n---\n", mtext, re.DOTALL)
        if not fm_match:
            report.blocker(f"amendment {fname} meeting {mp.name} has no frontmatter")
            continue
        mfm = parse_simple_frontmatter(fm_match.group(1))
        if mfm.get("status") != "decided":
            report.blocker(f"amendment {fname} references non-decided meeting: {mp.name}")
        if mfm.get("round") != lock_round:
            report.blocker(f"amendment {fname} meeting round mismatch: lock={lock_round} meeting={mfm.get('round')}")
        if mfm.get("stage") not in ("operator_amendment", "detailed_design", "eval_protocol", "acceptance", "convention_lock"):
            report.blocker(f"amendment {fname} meeting stage not amendment-eligible: {mfm.get('stage')}")
        if "## Amendment Detail" not in mtext:
            report.blocker(f"amendment {fname} meeting lacks `## Amendment Detail` section")
        elif fname not in mtext:
            report.blocker(f"amendment {fname} meeting body does not reference amendment filename")
        report.ok(f"amendment valid: {fname}")
    # v5.3: every on-disk amendment must be registered in lock
    unregistered = on_disk - in_lock
    for name in sorted(unregistered):
        report.blocker(f"amendment file on disk but not in lock.amendments[]: {name}")


def validate_stages_completed(lock: dict, cfg: dict, report: CheckReport) -> None:
    """v5.2: lock.stages_completed[] entries must be valid stage_ids from lint config."""
    allowed = set(cfg.get("meeting_frontmatter_allowed", {}).get("stage", []))
    for sid in lock.get("stages_completed", []):
        if sid not in allowed:
            report.blocker(f"lock.stages_completed contains invalid stage_id: {sid}")
    if lock.get("stages_completed"):
        report.ok(f"stages_completed structurally valid ({len(lock['stages_completed'])} entries)")


GATE_EVIDENCE_REQUIRED_FIELDS = {
    "gate1": ("status", "command", "exit_code", "test_count", "log"),
    "gate2": ("status", "reports"),
    "gate3": ("status",),  # at minimum; either cross_agreement_note OR summary required (checked below)
    "gate4": ("status", "metrics_source", "remediation_cycles", "blocker_recurrence"),
}


def _validate_path_hash_field(field: dict, round_id: str, gate: str, report: CheckReport, field_name: str) -> bool:
    """Validate a {path, sha256} dict: referenced path exists and sha matches."""
    if not isinstance(field, dict):
        report.blocker(f"gate_evidence.{gate}.{field_name} must be object with path+sha256")
        return False
    rel = field.get("path")
    sha = field.get("sha256")
    if not rel or not isinstance(sha, str) or not sha.startswith("sha256:"):
        report.blocker(f"gate_evidence.{gate}.{field_name} missing path or sha256")
        return False
    p = REPO / rel
    if not p.exists():
        report.blocker(f"gate_evidence.{gate}.{field_name} path missing: {rel}")
        return False
    if sha256_file(p) != sha:
        report.blocker(f"gate_evidence.{gate}.{field_name} sha mismatch for {rel}")
        return False
    return True


def load_gate_evidence(round_id: str, report: CheckReport) -> dict | None:
    """v5.3: strict per-gate schema. Files referenced must exist and match sha."""
    p = CONTRACTS_DIR / round_id / "gate_evidence.json"
    if not p.exists():
        report.blocker(f"gate_evidence.json missing at {p}")
        return None
    try:
        ev = json.loads(p.read_text())
    except json.JSONDecodeError as e:
        report.blocker(f"gate_evidence.json invalid JSON: {e}")
        return None
    for gate, required in GATE_EVIDENCE_REQUIRED_FIELDS.items():
        g_ev = ev.get(gate)
        if not isinstance(g_ev, dict):
            report.blocker(f"gate_evidence.{gate} not present as object")
            continue
        if g_ev.get("status") != "pass":
            report.blocker(f"gate_evidence.{gate}.status != pass (got {g_ev.get('status')})")
        for k in required:
            if k not in g_ev:
                report.blocker(f"gate_evidence.{gate} missing field: {k}")
    # gate1: log path+sha
    if "gate1" in ev and isinstance(ev["gate1"], dict) and "log" in ev["gate1"]:
        _validate_path_hash_field(ev["gate1"]["log"], round_id, "gate1", report, "log")
    # gate2: reports array (3 expected)
    g2 = ev.get("gate2")
    if isinstance(g2, dict):
        reports = g2.get("reports")
        if not isinstance(reports, list) or len(reports) < 3:
            report.blocker("gate_evidence.gate2.reports must be array of 3 objects (path+sha)")
        else:
            for i, r in enumerate(reports):
                _validate_path_hash_field(r, round_id, "gate2", report, f"reports[{i}]")
    # gate3: at least cross_agreement_note OR summary path+sha
    g3 = ev.get("gate3")
    if isinstance(g3, dict):
        if not (g3.get("cross_agreement_note") or isinstance(g3.get("summary"), dict)):
            report.blocker("gate_evidence.gate3 requires `cross_agreement_note` (string) or `summary` (path+sha)")
        elif isinstance(g3.get("summary"), dict):
            _validate_path_hash_field(g3["summary"], round_id, "gate3", report, "summary")
    # gate4: metrics_source path+sha
    g4 = ev.get("gate4")
    if isinstance(g4, dict) and isinstance(g4.get("metrics_source"), dict):
        _validate_path_hash_field(g4["metrics_source"], round_id, "gate4", report, "metrics_source")
    if not any(m.startswith("gate_evidence.") for m in report.blockers):
        report.ok("gate_evidence schema valid (all 4 gates pass + referenced artifacts verified)")
    return ev


def check_lock_tamper_evidence(round_id: str, lock_path: Path, report: CheckReport) -> None:
    """v5.3: current lock sha must match the last authorized event in the event log."""
    last = _last_lock_event(round_id)
    if last is None:
        report.blocker(f"no lock event log found for {round_id} (expected at {_events_path(round_id)})")
        return
    current_sha = sha256_file(lock_path)
    expected = last.get("lock_sha256")
    if current_sha != expected:
        report.blocker(f"lock sha mismatch with last event: current={current_sha[:20]}... expected={(expected or '')[:20]}... (tampering suspected)")
    else:
        report.ok(f"lock tamper-evident check ok (last action={last.get('action')})")


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
    round_dir = CONTRACTS_DIR / round_id
    # v5.3: tamper-evident lock check
    check_lock_tamper_evidence(round_id, lock_path, report)
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
    # v5.3: amendment disk-scan + metadata validation
    validate_amendments(lock, report)
    # v5.3: stages_completed = informational; ID membership only
    validate_stages_completed(lock, cfg, report)
    # Commit traceability (v5.2+: includes uncommitted).
    # v5.4: skip for closed rounds — their whitelist is historical; new work belongs to a new round.
    if lock.get("status") != "closed":
        check_commit_traceability(lock, report)
    else:
        report.ok("commit traceability skipped (closed round; historical whitelist)")
    # v5.4+v5.5: post-close gate_evidence revalidation
    # v5.4: check gate_evidence.json sha itself hasn't been tampered
    # v5.5: also re-run load_gate_evidence() to verify embedded path+sha references
    # (catches post-close deliverable mutation — Codex v5.4 REAL issue #5)
    if lock.get("status") == "closed" and lock.get("gate_evidence_sha256"):
        ev_path = CONTRACTS_DIR / round_id / "gate_evidence.json"
        if not ev_path.exists():
            report.blocker("gate_evidence.json missing after close")
        else:
            actual = sha256_file(ev_path)
            if actual != lock["gate_evidence_sha256"]:
                report.blocker(f"gate_evidence.json tampered after close: locked={lock['gate_evidence_sha256'][:20]}... live={actual[:20]}...")
            else:
                report.ok("gate_evidence.json post-close integrity verified")
                # v5.5: also revalidate embedded artifact hashes (deliverables can't mutate unnoticed)
                load_gate_evidence(round_id, report)
    # Lint + audit
    lint_report = cmd_lint()
    audit_report = cmd_audit_operator_layer()
    report.merge(lint_report)
    report.merge(audit_report)
    return report


def cmd_amend(round_id: str, amendment_file: str, meeting_path: str) -> CheckReport:
    """v5.4: evented amendment flow. Validates amendment, updates lock.amendments[], writes lock,
    then appends `amended` event with post-amend lock sha. Rollback on validation failure.

    Codex R5 blocker #1 fix + R7 adjustments:
    - .txt amendments infer target from filename (<base>.amendment.N.txt → <base>.txt)
    - Reject if gate_evidence_sha256 already set or closed_at non-null (close-state corruption guard)
    - On post-write validate_amendments() failure, restore old lock text BEFORE appending event
    """
    report = CheckReport()
    lock_path = LOCKS_DIR / f"{round_id}.lock"
    if not lock_path.exists():
        report.blocker(f"lock missing: {lock_path}")
        return report
    try:
        old_lock_text = lock_path.read_text()
        lock = json.loads(old_lock_text)
    except json.JSONDecodeError as e:
        report.blocker(f"lock JSON invalid: {e}")
        return report
    # Status guards
    if lock.get("status") != "active":
        report.blocker(f"amend refused: lock status is '{lock.get('status')}', must be 'active'")
        return report
    # Codex R7 Q4: close-state corruption guard
    if lock.get("gate_evidence_sha256") is not None:
        report.blocker("amend refused: lock.gate_evidence_sha256 already set (close-state corruption)")
        return report
    if lock.get("closed_at") is not None:
        report.blocker("amend refused: lock.closed_at already set (close-state corruption)")
        return report
    # Tamper-evident precheck
    check_lock_tamper_evidence(round_id, lock_path, report)
    if report.blockers:
        return report
    # v5.5 fix #2: path containment — amendment_file must be a plain basename (no dir traversal)
    if Path(amendment_file).name != amendment_file:
        report.blocker(f"amendment {amendment_file!r} must be a basename in contracts/<round>/, not a path")
        return report
    # Amendment file presence
    round_dir = CONTRACTS_DIR / round_id
    ap = round_dir / amendment_file
    # Double-check containment after join (defense against symlinks/edge cases)
    try:
        ap_resolved = ap.resolve()
        if ap_resolved.parent != round_dir.resolve():
            report.blocker(f"amendment {amendment_file} resolves outside round dir: {ap_resolved}")
            return report
    except OSError as e:
        report.blocker(f"amendment path resolution failed: {e}")
        return report
    if not ap.exists():
        report.blocker(f"amendment file missing: {round_dir.name}/{amendment_file}")
        return report
    # Duplicate guard
    if any(a.get("file") == amendment_file for a in lock.get("amendments", [])):
        report.blocker(f"amendment {amendment_file} already registered in lock")
        return report
    # v5.5 fix #3: canonicalize meeting path once (used for both storage and comparison)
    if meeting_path.startswith("context_harness/"):
        canonical_meeting = meeting_path
    else:
        # bare filename → repo-relative under operator/meetings/
        canonical_meeting = f"context_harness/operator/meetings/{Path(meeting_path).name}"
    # Determine target + supersedes
    target: str | None = None
    supersedes: list = []
    if amendment_file.endswith(".md"):
        text = ap.read_text()
        fm_match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
        if not fm_match:
            report.blocker(f"amendment {amendment_file} missing frontmatter")
            return report
        fm = parse_simple_frontmatter(fm_match.group(1))
        target = fm.get("target")
        supersedes = fm.get("supersedes", [])
        if not isinstance(supersedes, list):
            supersedes = [supersedes]
        fm_meeting_raw = fm.get("meeting")
        if not target:
            report.blocker(f"amendment {amendment_file} frontmatter missing target")
            return report
        # Canonicalize FM meeting the same way and compare canonical forms
        if fm_meeting_raw:
            if fm_meeting_raw.startswith("context_harness/"):
                fm_canonical = fm_meeting_raw
            else:
                fm_canonical = f"context_harness/operator/meetings/{Path(fm_meeting_raw).name}"
            if fm_canonical != canonical_meeting:
                report.blocker(f"amendment {amendment_file} frontmatter meeting='{fm_meeting_raw}' does not match CLI '{meeting_path}' (canonical: {fm_canonical} vs {canonical_meeting})")
                return report
    elif amendment_file.endswith(".txt"):
        # Infer target: <base>.amendment.N.txt → <base>.txt
        m = re.match(r"^([A-Za-z0-9_]+)\.amendment\.\d+\.txt$", amendment_file)
        if not m:
            report.blocker(f"amendment {amendment_file} filename must match `<base>.amendment.N.txt` (base = alnum/_ only)")
            return report
        target = m.group(1) + ".txt"
        # v5.5 fix #1: .txt amendments default supersedes=[target] so validate_amendments doesn't reject empty list
        supersedes = [target]
    else:
        report.blocker(f"amendment {amendment_file} extension must be .md or .txt")
        return report
    # Target must be a base contract file
    if target not in REQUIRED_CONTRACT_FILES:
        report.blocker(f"amendment target '{target}' not in REQUIRED_CONTRACT_FILES")
        return report
    # Meeting existence (use canonical form)
    mp = REPO / canonical_meeting
    if not mp.exists():
        report.blocker(f"meeting not found: {canonical_meeting}")
        return report
    # Compute amendment sha
    amendment_sha = sha256_file(ap)
    # Build entry with canonical meeting path for storage
    entry = {
        "file": amendment_file,
        "target": target,
        "sha256": amendment_sha,
        "supersedes": supersedes,
        "meeting": canonical_meeting,
    }
    # v5.5 fix #4: PRE-WRITE validation — simulate the new lock in memory and run
    # validate_amendments() before touching disk. Eliminates write-then-rollback disk flicker.
    new_lock = dict(lock)
    new_lock["amendments"] = list(lock.get("amendments", [])) + [entry]
    pre_report = CheckReport()
    validate_amendments(new_lock, pre_report)
    if pre_report.blockers:
        for b in pre_report.blockers:
            report.blocker(f"pre-write validation failed: {b}")
        report.blocker("amend refused; lock unchanged")
        return report
    # Write new lock (validation already passed)
    lock_path.write_text(json.dumps(new_lock, indent=2) + "\n")
    # Append amended event with post-amend lock sha
    try:
        post_sha = sha256_file(lock_path)
        _append_lock_event(round_id, "amended", post_sha, lock.get("base_commit"), amendment_file)
    except Exception as e:
        # Defensive: if event append fails, restore old lock so tamper-evident chain stays consistent
        lock_path.write_text(old_lock_text)
        report.blocker(f"event append failed; rolled back lock: {e}")
        return report
    report.ok(f"amendment registered: {amendment_file} → target={target}")
    report.ok(f"event logged: amended (lock sha advanced to {post_sha[:20]}...)")
    return report


def cmd_close(round_id: str) -> CheckReport:
    """v5.3: close requires Gate 5 + gate_evidence.json (strict schema); records post-close lock sha."""
    report = cmd_gates(round_id)
    # v5.3: strict gate_evidence.json validation
    load_gate_evidence(round_id, report)
    if report.blockers:
        report.blocker(f"close refused: {len(report.blockers)} blocker(s) present")
        return report
    lock_path = LOCKS_DIR / f"{round_id}.lock"
    lock = json.loads(lock_path.read_text())
    if lock.get("status") != "active":
        report.blocker(f"close refused: lock status is '{lock.get('status')}', must be 'active'")
        return report
    # v5.3: record gate_evidence sha in lock before writing close
    ev_path = CONTRACTS_DIR / round_id / "gate_evidence.json"
    lock["gate_evidence_sha256"] = sha256_file(ev_path)
    lock["status"] = "closed"
    lock["closed_at"] = datetime.now(timezone.utc).isoformat()
    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    # v5.3: post-close event records the NEW sha (Codex 6th must-fix)
    post_sha = sha256_file(lock_path)
    _append_lock_event(round_id, "closed", post_sha, lock.get("base_commit"))
    report.ok(f"lock {round_id} transitioned to closed at {lock['closed_at']}")
    report.ok(f"gate_evidence_sha256 recorded: {lock['gate_evidence_sha256'][:20]}...")
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
    elif cmd == "amend" and len(argv) >= 5:
        report = cmd_amend(argv[2], argv[3], argv[4])
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
