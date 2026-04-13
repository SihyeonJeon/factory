#!/usr/bin/env python3
"""
Moment harness orchestrator — Planner-Generator-Evaluator architecture.

Three-agent pattern inspired by Anthropic's harness design for long-running
application development. Planner (product_lead + delivery_lead) → Generator
(web_builder) → Evaluator (reviewer).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import time
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from harness.company import load_manifest, load_providers, load_roles
from harness.ops.artifacts import build_artifact_snapshot, read_artifact_excerpt
from harness.ops.json_parse import _extract_json_candidates, parse_json_output
from harness.ops.session import (
    decode_jwt_payload,
    describe_session,
    parse_iso_timestamp,
    parse_unix_timestamp,
)
from harness.providers import run_claude_api, run_claude_cli, run_cli
from harness.runtime_env import load_project_env
from master_router import TaskType, dispatch, read_blackboard

FACTORY_DIR = Path(__file__).parent.resolve()
WORKSPACE_DIR = FACTORY_DIR / "workspace"
AGENTS_DIR = FACTORY_DIR / "agents"
CONTEXT_DIR = FACTORY_DIR / "context_harness"
REPORTS_DIR = CONTEXT_DIR / "reports"
HANDOFFS_DIR = CONTEXT_DIR / "handoffs"
WORKTREES_DIR = FACTORY_DIR / ".worktrees"
TEAM_MANIFEST_FILE = CONTEXT_DIR / "team_manifest.json"
FORK_POLICY_FILE = CONTEXT_DIR / "fork_policy.json"
PRODUCT_INPUTS_DIR = CONTEXT_DIR / "product_inputs"
STATE_FILE = CONTEXT_DIR / "state.json"
CHANGE_RECORD_FILE = REPORTS_DIR / "change_record.md"
HOST_RUNTIME_BASELINE_FILE = REPORTS_DIR / "host_runtime_baseline.json"
BLACKBOARD_FILE = CONTEXT_DIR / "blackboard.md"
BLACKBOARD_COMPACT_FILE = HANDOFFS_DIR / "blackboard_compact.md"
HANDOFF_LEDGER_FILE = CONTEXT_DIR / "handoff_ledger.jsonl"
DECISIONS_LOG_FILE = CONTEXT_DIR / "decisions_log.jsonl"
OPERATOR_JOURNAL_FILE = CONTEXT_DIR / "operator_journal.md"
PROGRESS_FILE = CONTEXT_DIR / "claude-progress.md"
INTEGRATION_WORKTREE = WORKTREES_DIR / "_integration"
INTEGRATION_BRANCH = "harness/integration"
MANIFEST = load_manifest(TEAM_MANIFEST_FILE)
PROVIDERS = load_providers(MANIFEST)
ROLES = load_roles(MANIFEST)


@dataclass
class ForkDecision:
    should_fork: bool
    reasons: list[str]
    lanes: list[str]


@dataclass
class EvaluationSummary:
    passed: bool
    blockers: list[str]
    lanes: list[str]
    review_report: Path
    ux_report: Path


def ensure_dirs():
    for path in (REPORTS_DIR, HANDOFFS_DIR, WORKTREES_DIR):
        path.mkdir(parents=True, exist_ok=True)


def load_runtime_env() -> dict[str, str]:
    return load_project_env(FACTORY_DIR)


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def load_json_from_string(raw: str, default: Any | None = None) -> Any:
    try:
        return json.loads(raw)
    except Exception:
        return {} if default is None else default


def save_json(path: Path, payload: Any):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def save_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


from harness.ops.ledger import LEDGER_SCHEMA_VERSION  # re-exported for smoke test


def append_ledger(entry: dict[str, Any]):
    from harness.ops.ledger import write_ledger_entry

    write_ledger_entry(HANDOFF_LEDGER_FILE, entry)


def append_operator_journal(message: str):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    OPERATOR_JOURNAL_FILE.parent.mkdir(parents=True, exist_ok=True)
    with OPERATOR_JOURNAL_FILE.open("a", encoding="utf-8") as handle:
        handle.write(f"\n- [{timestamp}] {message}\n")


def update_progress(section: str, content: str):
    """Update claude-progress.md for state tracking between sessions."""
    PROGRESS_FILE.parent.mkdir(parents=True, exist_ok=True)
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")

    if PROGRESS_FILE.exists():
        text = PROGRESS_FILE.read_text(encoding="utf-8")
    else:
        text = "# Moment Harness Progress\n\n"

    marker_start = f"## {section}"
    marker_end = "\n## "
    if marker_start in text:
        start = text.index(marker_start)
        end = text.find(marker_end, start + len(marker_start))
        if end == -1:
            text = text[:start]
        else:
            text = text[:start] + text[end:]

    text += f"\n{marker_start}\n_Updated: {timestamp}_\n\n{content.strip()}\n"
    save_text(PROGRESS_FILE, text)


def git(*args: str, check: bool = True, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd or FACTORY_DIR),
        check=check,
        capture_output=True,
        text=True,
        env=os.environ.copy(),
    )


def git_output(*args: str, cwd: Path | None = None) -> str:
    proc = git(*args, cwd=cwd)
    return proc.stdout.strip()


def run_shell(command: list[str], *, cwd: Path | None = None, timeout: int = 12) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            command,
            cwd=str(cwd or FACTORY_DIR),
            capture_output=True,
            text=True,
            timeout=timeout,
            env=os.environ.copy(),
        )
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(command, 124, "", f"timeout after {timeout}s")


def status_from_checks(*flags: bool) -> str:
    return "ready" if all(flags) else "blocked"


def _build_probe_deps():
    from harness.ops.probes import ProbeDeps

    return ProbeDeps(
        reports_dir=REPORTS_DIR,
        host_runtime_baseline_file=HOST_RUNTIME_BASELINE_FILE,
        run_shell=run_shell,
        load_json=load_json,
        save_json=save_json,
        save_text=save_text,
        append_ledger=append_ledger,
        append_operator_journal=append_operator_journal,
    )


def _build_doctor_deps():
    from harness.ops.doctor import DoctorDeps

    return DoctorDeps(
        factory_dir=FACTORY_DIR,
        reports_dir=REPORTS_DIR,
        host_runtime_baseline_file=HOST_RUNTIME_BASELINE_FILE,
        roles=ROLES,
        providers=PROVIDERS,
        run_shell=run_shell,
        run_claude_api=run_claude_api,
        run_claude_cli=run_claude_cli,
        run_cli=run_cli,
        load_json=load_json,
        load_json_from_string=load_json_from_string,
        save_json=save_json,
        save_text=save_text,
        append_ledger=append_ledger,
        append_operator_journal=append_operator_journal,
        load_runtime_env=load_runtime_env,
        ensure_dirs=ensure_dirs,
        current_target_workspace=current_target_workspace,
    )


def run_preflight_doctor(*, quick: bool = False) -> Path:
    from harness.ops.doctor import run_preflight_doctor as _run

    return _run(_build_doctor_deps(), quick=quick)


def estimate_complexity(brief: str) -> dict[str, int]:
    return {
        "files_hint": len(re.findall(r"\b(app/|components/|lib/|api/|pages/|hooks/)\b", brief, flags=re.IGNORECASE)),
        "frontend_hint": len(re.findall(r"\b(ui|page|component|layout|css|tailwind|design|responsive)\b", brief, flags=re.IGNORECASE)),
        "backend_hint": len(re.findall(r"\b(api|edge function|supabase|database|rls|auth|schema|migration)\b", brief, flags=re.IGNORECASE)),
        "qa_hint": len(re.findall(r"\b(qa|test|review|audit|lighthouse|pwa|og|accessibility)\b", brief, flags=re.IGNORECASE)),
    }


def evaluate_fork_policy(brief: str) -> ForkDecision:
    policy = load_json(FORK_POLICY_FILE, {})
    thresholds = policy.get("thresholds", {})
    complexity = estimate_complexity(brief)
    reasons: list[str] = []
    lanes: list[str] = ["planner"]

    if complexity["frontend_hint"] > 0:
        lanes.append("frontend")
    if complexity["backend_hint"] > 0:
        lanes.append("backend")
    if complexity["qa_hint"] > 0:
        lanes.append("qa")

    if complexity["files_hint"] >= thresholds.get("file_scope_hint", 3):
        reasons.append("multiple file domains are implied")
    if complexity["frontend_hint"] and complexity["backend_hint"]:
        reasons.append("frontend and backend can be split into disjoint lanes")
    if complexity["qa_hint"]:
        reasons.append("evaluation can run as an independent lane")
    if len(set(lanes)) >= thresholds.get("lane_count", 3):
        reasons.append("parallel specialist lanes are justified")

    return ForkDecision(bool(reasons), reasons, list(dict.fromkeys(lanes)))


def _build_worktree_deps():
    from harness.ops.worktrees import WorktreeDeps

    return WorktreeDeps(
        factory_dir=FACTORY_DIR,
        integration_worktree=INTEGRATION_WORKTREE,
        integration_branch=INTEGRATION_BRANCH,
        worktrees_dir=WORKTREES_DIR,
        reports_dir=REPORTS_DIR,
        git=git,
        git_output=git_output,
        save_json=save_json,
        append_ledger=append_ledger,
        append_operator_journal=append_operator_journal,
    )


def ensure_integration_worktree() -> Path:
    from harness.ops.worktrees import ensure_integration_worktree as _impl

    return _impl(_build_worktree_deps())


def ensure_lane_worktree(role_name: str, lane_tag: str, start_point: str) -> tuple[Path, str]:
    from harness.ops.worktrees import ensure_lane_worktree as _impl

    return _impl(_build_worktree_deps(), role_name, lane_tag, start_point)


def sync_workspace_overlay(source_repo: Path, target_repo: Path):
    from harness.ops.worktrees import sync_workspace_overlay as _impl

    _impl(source_repo, target_repo)


def find_worktree_for_branch(branch_name: str) -> Path | None:
    from harness.ops.worktrees import find_worktree_for_branch as _impl

    return _impl(_build_worktree_deps(), branch_name)


def current_target_repo() -> Path:
    from harness.ops.worktrees import current_target_repo as _impl

    return _impl(_build_worktree_deps())


def current_target_workspace() -> Path:
    from harness.ops.worktrees import current_target_workspace as _impl

    return _impl(_build_worktree_deps())



def _build_role_deps():
    from harness.ops.roles import RoleDeps

    return RoleDeps(
        reports_dir=REPORTS_DIR,
        agents_dir=AGENTS_DIR,
        team_manifest_file=TEAM_MANIFEST_FILE,
        roles=ROLES,
        dispatch=dispatch,
        read_blackboard=read_blackboard,
        task_type_enum=TaskType,
        save_text=save_text,
        save_json=save_json,
        load_json=load_json,
        append_ledger=append_ledger,
        append_operator_journal=append_operator_journal,
    )


def build_role_prompt(
    role_name: str,
    brief: str,
    artifacts: dict[str, Path],
    json_schema: dict[str, Any] | None = None,
    task_type: TaskType | None = None,
) -> str:
    from harness.ops.roles import build_role_prompt as _impl

    return _impl(_build_role_deps(), role_name, brief, artifacts, json_schema, task_type)


def validate_role_output(
    role_name: str,
    task_type: TaskType,
    text: str,
    json_schema: dict | None,
) -> None:
    from harness.ops.roles import validate_role_output as _impl

    _impl(role_name, task_type, text, json_schema)


def run_role(
    role_name: str,
    task_type: TaskType,
    brief: str,
    artifacts: dict[str, Path],
    *,
    cwd: Path | None = None,
    image_path: str | None = None,
    json_schema: dict | None = None,
    report_stem: str | None = None,
    timeout: int | None = None,
    allow_fallback_roles: bool = True,
) -> Path:
    from harness.ops.roles import run_role as _impl

    return _impl(
        _build_role_deps(),
        role_name,
        task_type,
        brief,
        artifacts,
        cwd=cwd,
        image_path=image_path,
        json_schema=json_schema,
        report_stem=report_stem,
        timeout=timeout,
        allow_fallback_roles=allow_fallback_roles,
    )



def write_state(update: dict[str, Any]):
    state = load_json(STATE_FILE, {})
    state.update(update)
    save_json(STATE_FILE, state)


def collect_intake_artifacts() -> dict[str, Path]:
    artifacts: dict[str, Path] = {}
    preferred_files = {
        "system_rules": CONTEXT_DIR / "00_system_rules.md",
        "sprint_contract": CONTEXT_DIR / "sprint_contract.json",
        "idea_input": PRODUCT_INPUTS_DIR / "idea.md",
        "constraints_input": PRODUCT_INPUTS_DIR / "constraints.md",
        "design_input": PRODUCT_INPUTS_DIR / "design.md",
        "acceptance_input": PRODUCT_INPUTS_DIR / "acceptance.md",
    }
    # Include debate log if available for reference
    debate_log = FACTORY_DIR / "debate_log_20260412_175502.md"
    if debate_log.exists():
        preferred_files["debate_log_reference"] = debate_log
    idea_doc = FACTORY_DIR / "idea_20260412_175502.md"
    if idea_doc.exists():
        preferred_files["idea_full_proposal"] = idea_doc

    for name, path in preferred_files.items():
        if path.exists():
            artifacts[name] = path
    return artifacts


def load_delivery_context() -> tuple[dict[str, Any], dict[str, Path]]:
    state = load_json(STATE_FILE, {})
    artifacts: dict[str, Path] = {
        "fork_policy": HANDOFFS_DIR / "fork_decision.json",
        "team_manifest": TEAM_MANIFEST_FILE,
        "blackboard_compact": BLACKBOARD_COMPACT_FILE if BLACKBOARD_COMPACT_FILE.exists() else BLACKBOARD_FILE,
    }
    for key in ("product_report", "planning_report", "architecture_report"):
        path_value = state.get(key)
        if not path_value:
            continue
        path = Path(path_value)
        if path.exists():
            artifacts[key] = path
    for name, path_str in state.get("intake_artifacts", {}).items():
        path = Path(path_str)
        if path.exists():
            artifacts[name] = path
    return state, artifacts


def select_delivery_lanes(state: dict[str, Any], fallback_lanes: list[str]) -> list[str]:
    plan_path_value = state.get("planning_report")
    if plan_path_value:
        plan_payload = load_json(Path(plan_path_value), {})
        ownership = plan_payload.get("lane_ownership", {})
        lanes = [lane for lane in ("frontend", "backend") if ownership.get(lane)]
        if lanes:
            return lanes
    lanes = [lane for lane in fallback_lanes if lane in {"frontend", "backend"}]
    return lanes or ["frontend"]


def build_lane_delivery_brief(base_brief: str, lane: str, state: dict[str, Any]) -> str:
    lines = [
        base_brief.strip(),
        "",
        f"Current implementation lane: {lane}",
        "",
        "Execution contract:",
        "- Edit only the files required for this lane.",
        "- Use Next.js App Router with TypeScript strict mode.",
        "- Follow Supabase patterns (RLS, Edge Functions, Realtime).",
        "- Ensure PWA compliance and mobile-first responsive design.",
        "- Make concrete code changes, not only a plan.",
        "- If a shared contract is missing, create the minimal safe version and note it.",
    ]

    plan_path_value = state.get("planning_report")
    if plan_path_value:
        plan_payload = load_json(Path(plan_path_value), {})
        tasks = plan_payload.get("lane_ownership", {}).get(lane, [])
        if tasks:
            lines.extend(["", f"{lane.upper()} lane tasks:"])
            for task in tasks:
                lines.append(f"- {task}")

    architecture_path_value = state.get("architecture_report")
    if architecture_path_value:
        lines.extend(
            [
                "",
                "Primary architecture reference:",
                f"- {architecture_path_value}",
            ]
        )

    return "\n".join(lines)


def get_lane_tasks(state: dict[str, Any], lane: str) -> list[str]:
    plan_path_value = state.get("planning_report")
    if not plan_path_value:
        return []
    plan_payload = load_json(Path(plan_path_value), {})
    tasks = plan_payload.get("lane_ownership", {}).get(lane, [])
    return [task for task in tasks if isinstance(task, str) and task.strip()]


def report_is_fresh_for_current_plan(report_path: Path, state: dict[str, Any]) -> bool:
    if not report_path.exists():
        return False

    report_mtime = report_path.stat().st_mtime
    dependency_keys = ("planning_report", "architecture_report", "product_report")
    for key in dependency_keys:
        path_value = state.get(key)
        if not path_value:
            continue
        dependency_path = Path(path_value)
        if dependency_path.exists() and dependency_path.stat().st_mtime > report_mtime:
            return False
    return True


def build_subtask_delivery_brief(base_brief: str, lane: str, task: str, state: dict[str, Any]) -> str:
    lane_brief = build_lane_delivery_brief(base_brief, lane, state)
    return "\n".join(
        [
            lane_brief,
            "",
            "Current subtask:",
            f"- {task}",
            "",
            "Subtask execution rules:",
            "- Complete this subtask now.",
            "- If shared support code is required, add only the smallest safe amount.",
            "- End with a concise implementation report describing changed files and any remaining dependency for the next subtask.",
        ]
    )


from harness.ops.roles import _ROLE_CONTRACT_CACHE  # re-exported for smoke test + legacy callers


def load_role_contract(role_id: str) -> dict[str, Any]:
    from harness.ops.roles import load_role_contract as _impl

    return _impl(_build_role_deps(), role_id)


def role_output_schema(role_id: str) -> dict[str, Any] | None:
    from harness.ops.roles import role_output_schema as _impl

    return _impl(_build_role_deps(), role_id)


def product_schema() -> dict[str, Any]:
    from harness.ops.roles import product_schema as _impl

    return _impl(_build_role_deps())


def plan_schema() -> dict[str, Any]:
    from harness.ops.roles import plan_schema as _impl

    return _impl(_build_role_deps())



def compact_blackboard(force: bool = False):
    from harness.ops.context import compact_blackboard_v2

    archive = compact_blackboard_v2(
        BLACKBOARD_FILE,
        BLACKBOARD_COMPACT_FILE,
        REPORTS_DIR,
        DECISIONS_LOG_FILE,
        force=force,
    )
    if archive:
        append_ledger({"type": "blackboard_compaction", "archive": str(archive), "compact": str(BLACKBOARD_COMPACT_FILE)})
        append_operator_journal(f"Compacted blackboard to {BLACKBOARD_COMPACT_FILE.name}")


def branch_ahead_count(base_ref: str, branch_ref: str, cwd: Path) -> int:
    from harness.ops.worktrees import branch_ahead_count as _impl

    return _impl(_build_worktree_deps(), base_ref, branch_ref, cwd)


def merge_branch_into_integration(branch_name: str) -> tuple[bool, str]:
    from harness.ops.worktrees import merge_branch_into_integration as _impl

    return _impl(_build_worktree_deps(), branch_name)


def merge_delivery_branches(branches: list[str], phase_label: str) -> Path:
    from harness.ops.worktrees import merge_delivery_branches as _impl

    return _impl(_build_worktree_deps(), branches, phase_label)



def extract_blockers(text: str) -> tuple[list[str], list[str]]:
    from harness.ops.evaluation import extract_blockers_v2

    return extract_blockers_v2(text)


def summarize_evaluation(
    review_report: Path,
    ux_report: Path,
) -> EvaluationSummary:
    blockers: list[str] = []
    lanes: list[str] = []
    for path in (review_report, ux_report):
        content = path.read_text(encoding="utf-8")
        file_blockers, file_lanes = extract_blockers(content)
        blockers.extend([f"{path.name}:{item}" for item in file_blockers])
        lanes.extend(file_lanes)
    passed = not blockers
    if not lanes:
        lanes = ["frontend", "backend"]
    return EvaluationSummary(
        passed=passed,
        blockers=blockers,
        lanes=list(dict.fromkeys(lanes)),
        review_report=review_report,
        ux_report=ux_report,
    )


def build_feedback_brief(original_brief: str, summary: EvaluationSummary, round_index: int) -> Path:
    from harness.ops.context import decisions_summary_for_prompt

    lines = [
        "# Remediation Packet",
        "",
        f"Round: {round_index}",
        "",
        "## Original brief",
        original_brief,
        "",
        "## Blockers",
    ]
    for blocker in summary.blockers:
        lines.append(f"- {blocker}")
    lines += [
        "",
        "## Report paths",
        f"- code review + security: {summary.review_report}",
        f"- UX + accessibility audit: {summary.ux_report}",
        "",
        "## Required behavior",
        "- Fix only the release blockers first.",
        "- Preserve mobile-first responsive design.",
        "- Ensure Supabase RLS policies remain intact.",
        "- Prefer the smallest change set that resolves the issue.",
        "- READ the review reports above for specific file paths and line numbers.",
        "- COMMIT your changes with descriptive commit messages.",
    ]

    # Layer 1: Include persistent decisions from prior rounds
    decisions_block = decisions_summary_for_prompt(DECISIONS_LOG_FILE)
    if decisions_block:
        lines += ["", decisions_block]

    packet = HANDOFFS_DIR / f"remediation_round_{round_index}.md"
    save_text(packet, "\n".join(lines))
    return packet


def _intake_cache_fresh(state: dict[str, Any], intake_artifacts: dict[str, Path], brief: str) -> bool:
    """True when prior intake reports exist and are newer than every product_input source."""
    if not state.get("intake_complete"):
        return False
    if state.get("last_brief") != brief:
        return False
    keys = ("product_report", "planning_report", "architecture_report")
    report_paths = [Path(state[key]) for key in keys if state.get(key)]
    if len(report_paths) != 3 or not all(p.exists() for p in report_paths):
        return False
    oldest_report_mtime = min(p.stat().st_mtime for p in report_paths)
    for source in intake_artifacts.values():
        if source.exists() and source.stat().st_mtime > oldest_report_mtime:
            return False
    return True


def run_intake(brief: str):
    ensure_dirs()
    load_runtime_env()
    append_operator_journal("Starting intake for Moment")
    fork = evaluate_fork_policy(brief)
    fork_path = HANDOFFS_DIR / "fork_decision.json"
    save_json(fork_path, {"should_fork": fork.should_fork, "reasons": fork.reasons, "lanes": fork.lanes})
    intake_artifacts = collect_intake_artifacts()

    state = load_json(STATE_FILE, {})
    if _intake_cache_fresh(state, intake_artifacts, brief):
        append_operator_journal("Intake cache fresh; skipping product/planning/architecture re-run")
        print(f"product report: {state['product_report']} (cached)")
        print(f"planning report: {state['planning_report']} (cached)")
        print(f"architecture report: {state['architecture_report']} (cached)")
        return

    product_report = run_role(
        "product_lead",
        TaskType.PRODUCT_RESEARCH,
        brief,
        intake_artifacts,
        json_schema=product_schema(),
        report_stem="product_lead_product_packet",
    )
    planning_report = run_role(
        "delivery_lead",
        TaskType.PLANNING,
        brief,
        {**intake_artifacts, "product_report": product_report, "fork_policy": fork_path},
        json_schema=plan_schema(),
        report_stem="delivery_lead_execution_plan",
    )
    architecture_report = run_role(
        "delivery_lead",
        TaskType.ARCHITECTURE,
        brief,
        {**intake_artifacts, "product_report": product_report, "planning_report": planning_report},
    )

    write_state(
        {
            "intake_complete": True,
            "last_brief": brief,
            "fork_lanes": fork.lanes,
            "intake_artifacts": {name: str(path) for name, path in intake_artifacts.items()},
            "product_report": str(product_report),
            "planning_report": str(planning_report),
            "architecture_report": str(architecture_report),
        }
    )
    update_progress("Intake", f"- Product research: {product_report.name}\n- Planning: {planning_report.name}\n- Architecture: {architecture_report.name}")
    print(f"product report: {product_report}")
    print(f"planning report: {planning_report}")
    print(f"architecture report: {architecture_report}")


def run_delivery(brief: str, phase_tag: str = "delivery") -> Path:
    ensure_dirs()
    load_runtime_env()
    append_operator_journal(f"Starting delivery phase {phase_tag}")
    integration = ensure_integration_worktree()
    fork = evaluate_fork_policy(brief)
    fork_path = HANDOFFS_DIR / "fork_decision.json"
    if not fork_path.exists():
        save_json(fork_path, {"should_fork": fork.should_fork, "reasons": fork.reasons, "lanes": fork.lanes})

    compact_blackboard()
    state, artifacts = load_delivery_context()
    lanes = select_delivery_lanes(state, fork.lanes)
    branch_names: list[str] = []
    outputs: dict[str, str] = {}

    for lane in lanes:
        role_name = "web_builder"
        worktree, branch_name = ensure_lane_worktree(role_name, phase_tag, INTEGRATION_BRANCH)
        lane_tasks = get_lane_tasks(state, lane)
        task_reports: list[str] = []
        if lane_tasks:
            for index, task in enumerate(lane_tasks, start=1):
                existing_report = REPORTS_DIR / f"{role_name}_{phase_tag}_{lane}_{index}.md"
                if report_is_fresh_for_current_plan(existing_report, state):
                    task_reports.append(str(existing_report))
                    append_operator_journal(f"Skipping completed subtask {role_name} {phase_tag} {lane} #{index}")
                    continue
                subtask_brief = build_subtask_delivery_brief(brief, lane, task, state)
                report_path = run_role(
                    role_name,
                    TaskType.WEB_IMPLEMENTATION,
                    subtask_brief,
                    artifacts,
                    cwd=worktree,
                    report_stem=f"{role_name}_{phase_tag}_{lane}_{index}",
                    timeout=1800,
                    allow_fallback_roles=False,
                )
                task_reports.append(str(report_path))
        else:
            lane_brief = build_lane_delivery_brief(brief, lane, state)
            report_path = run_role(
                role_name,
                TaskType.WEB_IMPLEMENTATION,
                lane_brief,
                artifacts,
                cwd=worktree,
                report_stem=f"{role_name}_{phase_tag}_{lane}",
                timeout=1800,
                allow_fallback_roles=False,
            )
            task_reports.append(str(report_path))

        lane_summary = REPORTS_DIR / f"{role_name}_{phase_tag}_{lane}_summary.md"
        save_text(
            lane_summary,
            "\n".join(
                [
                    f"# {role_name} {phase_tag} {lane} summary",
                    "",
                    "Reports:",
                    *[f"- {path}" for path in task_reports],
                ]
            ),
        )
        outputs[lane] = str(lane_summary)
        branch_names.append(branch_name)
        print(f"{lane} delivery report: {lane_summary}")

    merge_report = merge_delivery_branches(branch_names, phase_tag)
    write_state({"delivery_complete": True, "delivery_reports": outputs, "merge_report": str(merge_report), "integration_repo": str(integration)})
    update_progress("Delivery", f"- Phase: {phase_tag}\n- Lanes: {', '.join(lanes)}\n- Merge report: {merge_report.name}")
    return merge_report


def run_evaluation(brief: str, image_path: str | None = None) -> EvaluationSummary:
    from harness.ops.evaluation import build_evaluation_directive
    from harness.ops.guardrails import take_snapshot

    ensure_dirs()
    load_runtime_env()
    compact_blackboard(force=True)
    append_operator_journal("Starting evaluation")
    repo = current_target_repo()
    # Web project root is inside repo/web/ — reviewer needs this as CWD
    # so that relative paths like public/icons/ resolve correctly.
    web_root = repo / "web" if (repo / "web").exists() else repo

    # Layer 2: Pre-dispatch snapshot for crash recovery
    snapshot = take_snapshot(git, cwd=repo, role="reviewer", task_type="evaluation")
    append_ledger({"type": "snapshot", "sha": snapshot.commit_sha, "role": "reviewer", "worktree": str(repo)})

    # Layer 3: Calibrated evaluation directive with structured output + few-shot examples
    acceptance_file = PRODUCT_INPUTS_DIR / "acceptance.md"
    few_shot_dir = AGENTS_DIR / "reviewer" / "examples"

    eval_brief = build_evaluation_directive(
        brief,
        acceptance_file=acceptance_file if acceptance_file.exists() else None,
        few_shot_dir=few_shot_dir if few_shot_dir.exists() else None,
        repo_path=repo,
    )

    # Code review + security audit
    review_report = run_role(
        "reviewer",
        TaskType.CODE_REVIEW,
        eval_brief,
        {
            "team_manifest": TEAM_MANIFEST_FILE,
        },
        cwd=web_root,
        timeout=1200,
    )
    # UX + accessibility audit — same calibrated format
    ux_brief = build_evaluation_directive(
        f"{brief}\n\nFOCUS: UX and accessibility audit. "
        "Check responsive design, accessibility (touch targets, contrast, ARIA), PWA compliance, "
        "카카오톡 OG rendering, and 카카오 인앱 브라우저 handling.",
        acceptance_file=acceptance_file if acceptance_file.exists() else None,
        few_shot_dir=few_shot_dir if few_shot_dir.exists() else None,
        repo_path=repo,
    )
    ux_report = run_role(
        "reviewer",
        TaskType.UX_AUDIT,
        ux_brief,
        {
            "review_report": review_report,
        },
        cwd=web_root,
        image_path=image_path,
        timeout=900,
    )

    summary = summarize_evaluation(review_report, ux_report)
    save_json(
        REPORTS_DIR / "evaluation_summary.json",
        {
            "passed": summary.passed,
            "blockers": summary.blockers,
            "lanes": summary.lanes,
            "review_report": str(review_report),
            "ux_report": str(ux_report),
        },
    )
    write_state(
        {
            "evaluation_complete": True,
            "review_report": str(review_report),
            "ux_report": str(ux_report),
            "evaluation_passed": summary.passed,
        }
    )
    update_progress("Evaluation", f"- Passed: {summary.passed}\n- Blockers: {len(summary.blockers)}\n- Review: {review_report.name}\n- UX: {ux_report.name}")
    print(f"review report: {review_report}")
    print(f"UX report: {ux_report}")
    print(f"evaluation passed: {summary.passed}")
    append_ledger(
        {
            "type": "evaluation_summary",
            "passed": summary.passed,
            "blockers": summary.blockers,
            "lanes": summary.lanes,
            "review_report": str(review_report),
            "ux_report": str(ux_report),
            "evaluator_mode": "code_review_plus_ux_audit",
        }
    )
    append_operator_journal(f"Evaluation completed with passed={summary.passed}")
    return summary


def run_feedback_loop(brief: str, image_path: str | None = None, max_rounds: int = 2, *, resume: bool = False):
    ensure_dirs()
    load_runtime_env()
    doctor_report = run_preflight_doctor(quick=True)
    append_operator_journal(f"Autopilot starting with doctor report {doctor_report.name}")

    state = load_json(STATE_FILE, {})
    if resume and state.get("evaluation_complete") and not state.get("evaluation_passed"):
        append_operator_journal("Resuming from completed evaluation — re-running evaluation with fixed extract_blockers")
        summary = run_evaluation(brief, image_path=image_path)
    else:
        run_intake(brief)
        run_delivery(brief, phase_tag="delivery")
        summary = run_evaluation(brief, image_path=image_path)

    from harness.ops.context import append_decision
    from harness.ops.guardrails import post_agent_audit, take_snapshot

    round_index = 0
    while not summary.passed and round_index < max_rounds:
        round_index += 1
        compact_blackboard(force=True)
        packet = build_feedback_brief(brief, summary, round_index)
        append_ledger({"type": "remediation_packet", "round": round_index, "packet": str(packet), "lanes": summary.lanes})
        append_operator_journal(f"Starting remediation round {round_index}")

        # Layer 1: Record evaluation blockers as persistent decisions
        append_decision(
            DECISIONS_LOG_FILE,
            round_index=round_index,
            entry_type="constraint",
            summary=f"Round {round_index} blockers: {', '.join(summary.blockers[:5])}",
            rationale=f"Evaluation verdict required remediation. Lanes: {summary.lanes}",
            source_role="reviewer",
            references=[str(summary.review_report), str(summary.ux_report)],
        )

        # Layer 1: Include persistent decisions in artifacts
        artifacts = {
            "feedback_packet": packet,
            "evaluation_summary": REPORTS_DIR / "evaluation_summary.json",
            "blackboard_compact": BLACKBOARD_COMPACT_FILE if BLACKBOARD_COMPACT_FILE.exists() else BLACKBOARD_FILE,
        }
        if DECISIONS_LOG_FILE.exists():
            artifacts["decisions_log"] = DECISIONS_LOG_FILE

        branch_names: list[str] = []
        for lane in summary.lanes:
            role_name = "web_builder"
            worktree, branch_name = ensure_lane_worktree(role_name, f"fix-{round_index}", INTEGRATION_BRANCH)

            # Layer 2: Pre-dispatch snapshot for crash recovery
            snapshot = take_snapshot(git, cwd=worktree, role=role_name, task_type="bug_fix")

            try:
                run_role(role_name, TaskType.BUG_FIX, brief, artifacts, cwd=worktree, report_stem=f"{role_name}_bug_fix_round_{round_index}")
            except RuntimeError as exc:
                append_operator_journal(f"Round {round_index} {role_name} failed: {exc}")
                # Don't rollback — auto_commit_worktree will handle partial changes
                continue

            # Layer 2: Post-agent ownership audit
            violations = post_agent_audit(git, snapshot, role_name, TEAM_MANIFEST_FILE, journal_fn=append_operator_journal)
            if violations:
                append_ledger({"type": "ownership_violation", "role": role_name, "round": round_index, "files": violations[:10]})

            branch_names.append(branch_name)

        if not branch_names:
            append_operator_journal(f"Round {round_index}: no successful fixes, skipping merge")
            break

        merge_report = merge_delivery_branches(branch_names, f"fix-{round_index}")
        write_state({"latest_feedback_packet": str(packet), "latest_fix_merge_report": str(merge_report)})

        # Layer 1: Record successful merge as decision
        append_decision(
            DECISIONS_LOG_FILE,
            round_index=round_index,
            entry_type="decision",
            summary=f"Round {round_index} fixes merged into integration ({len(branch_names)} branches)",
            rationale=f"Merge report: {merge_report}",
            source_role="platform_operator",
        )

        summary = run_evaluation(brief, image_path=image_path)

    update_progress("Feedback Loop", f"- Rounds: {round_index}\n- Final verdict: {'PASSED' if summary.passed else 'BLOCKED'}")
    return summary


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Moment harness — Planner-Generator-Evaluator")
    sub = parser.add_subparsers(dest="command", required=True)

    team_report = sub.add_parser("team-report")
    team_report.set_defaults(func=lambda args: print(json.dumps(load_json(TEAM_MANIFEST_FILE, {}), indent=2, ensure_ascii=False)))

    intake = sub.add_parser("intake")
    intake.add_argument("brief")
    intake.set_defaults(func=lambda args: run_intake(args.brief))

    delivery = sub.add_parser("delivery")
    delivery.add_argument("brief")
    delivery.set_defaults(func=lambda args: run_delivery(args.brief))

    evaluation = sub.add_parser("evaluation")
    evaluation.add_argument("brief")
    evaluation.add_argument("--image-path")
    evaluation.set_defaults(func=lambda args: run_evaluation(args.brief, args.image_path))

    autopilot = sub.add_parser("autopilot")
    autopilot.add_argument("brief")
    autopilot.add_argument("--image-path")
    autopilot.add_argument("--max-rounds", type=int, default=2)
    autopilot.set_defaults(func=lambda args: run_feedback_loop(args.brief, args.image_path, args.max_rounds))

    remediate = sub.add_parser("remediate")
    remediate.add_argument("brief")
    remediate.add_argument("--image-path")
    remediate.add_argument("--max-rounds", type=int, default=2)
    remediate.set_defaults(func=lambda args: run_feedback_loop(args.brief, args.image_path, args.max_rounds, resume=True))

    compact = sub.add_parser("compact-blackboard")
    compact.set_defaults(func=lambda args: compact_blackboard(force=True))

    doctor = sub.add_parser("doctor")
    doctor.add_argument("--quick", action="store_true")
    doctor.set_defaults(func=lambda args: print(run_preflight_doctor(quick=args.quick)))

    return parser


if __name__ == "__main__":
    ensure_dirs()
    load_runtime_env()
    arguments = build_parser().parse_args()
    arguments.func(arguments)
