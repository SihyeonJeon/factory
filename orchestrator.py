#!/usr/bin/env python3
"""
Company-style multi-agent harness orchestrator.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import plistlib
import re
import shutil
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
OPERATOR_JOURNAL_FILE = CONTEXT_DIR / "operator_journal.md"
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
    hig_report: Path
    visual_report: Path


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


def run_xcode_runtime_probe(repo: Path) -> Path:
    from harness.ops.probes import run_xcode_runtime_probe as _run

    return _run(_build_probe_deps(), repo)


def run_xcode_test_probe(repo: Path) -> Path:
    from harness.ops.probes import run_xcode_test_probe as _run

    return _run(_build_probe_deps(), repo)


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
        "files_hint": len(re.findall(r"\b(app/|components/|store/|types/|screen|module)\b", brief, flags=re.IGNORECASE)),
        "ui_hint": len(re.findall(r"\b(ui|screen|component|layout|animation|hig|design)\b", brief, flags=re.IGNORECASE)),
        "logic_hint": len(re.findall(r"\b(api|logic|state|auth|sync|database|store)\b", brief, flags=re.IGNORECASE)),
        "qa_hint": len(re.findall(r"\b(qa|test|review|audit|screenshot|vision)\b", brief, flags=re.IGNORECASE)),
    }


def evaluate_fork_policy(brief: str) -> ForkDecision:
    policy = load_json(FORK_POLICY_FILE, {})
    thresholds = policy.get("thresholds", {})
    complexity = estimate_complexity(brief)
    reasons: list[str] = []
    lanes: list[str] = ["planner"]

    if complexity["ui_hint"] > 0:
        lanes.append("ui")
    if complexity["logic_hint"] > 0:
        lanes.append("logic")
    if complexity["qa_hint"] > 0:
        lanes.append("qa")

    if complexity["files_hint"] >= thresholds.get("file_scope_hint", 3):
        reasons.append("multiple file domains are implied")
    if complexity["ui_hint"] and complexity["logic_hint"]:
        reasons.append("UI and logic can be split into disjoint lanes")
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
        "native_ios_strategy": CONTEXT_DIR / "architecture" / "native_ios_strategy.md",
        "hig_guardrails": CONTEXT_DIR / "policies" / "ios_hig_guardrails.md",
        "ui_ux_screen_contract": CONTEXT_DIR / "prd" / "ui_ux_screen_contract.md",
        "sprint_contract": CONTEXT_DIR / "sprint_contract.json",
        "idea_input": PRODUCT_INPUTS_DIR / "idea.md",
        "constraints_input": PRODUCT_INPUTS_DIR / "constraints.md",
        "design_input": PRODUCT_INPUTS_DIR / "design.md",
        "acceptance_input": PRODUCT_INPUTS_DIR / "acceptance.md",
    }
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
        lanes = [lane for lane in ("ui", "logic") if ownership.get(lane)]
        if lanes:
            return lanes
    lanes = [lane for lane in fallback_lanes if lane in {"ui", "logic"}]
    return lanes or ["ui"]


def build_lane_delivery_brief(base_brief: str, lane: str, state: dict[str, Any]) -> str:
    lines = [
        base_brief.strip(),
        "",
        f"Current implementation lane: {lane}",
        "",
        "Execution contract:",
        "- Edit only the files required for this lane.",
        "- Keep the app native to iOS and SwiftUI-first.",
        "- Follow the architecture contract and HIG guardrails in the attached artifacts.",
        "- Make concrete code changes, not only a plan.",
        "- If the lane depends on a missing shared contract, create the minimal safe contract and note it in the report.",
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
    if not BLACKBOARD_FILE.exists():
        return
    text = BLACKBOARD_FILE.read_text(encoding="utf-8")
    if not force and len(text) < 6000:
        return

    timestamp = time.strftime("%Y%m%d-%H%M%S")
    archive_path = REPORTS_DIR / f"blackboard_archive_{timestamp}.md"
    save_text(archive_path, text)

    entries = [entry.strip() for entry in text.split("\n---\n") if entry.strip()]
    recent_entries = entries[-8:]
    summary_lines = ["# Blackboard Compact", "", "## Recent entries"]
    for entry in recent_entries:
        first_line = next((line for line in entry.splitlines() if line.strip()), "")
        summary_lines.append(f"- {first_line[:180]}")
    summary = "\n".join(summary_lines)
    save_text(BLACKBOARD_COMPACT_FILE, summary)

    compacted = "# Blackboard - Agent Shared Context\n\n" + summary + "\n\n---\n" + "\n---\n".join(recent_entries[-4:])
    save_text(BLACKBOARD_FILE, compacted)
    append_ledger({"type": "blackboard_compaction", "archive": str(archive_path), "compact": str(BLACKBOARD_COMPACT_FILE)})
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
    lowered = text.lower()
    blockers: list[str] = []
    lanes: list[str] = []

    verdict_match = re.search(r"verdict:\s*\*\*([^*]+)\*\*", lowered)
    verdict = verdict_match.group(1).strip() if verdict_match else ""
    positive_verdict_signals = ["unblocked", "approved", "pass", "provisionally unblocked", "conditionally approved"]
    negative_verdict_signals = ["blocked", "hard block", "rejected", "qa_fail", "changes requested", "failed"]

    if verdict:
        if any(signal in verdict for signal in positive_verdict_signals):
            blockers = []
        elif any(signal in verdict for signal in negative_verdict_signals):
            blockers.append("verdict_blocked")

    blocker_signals = [
        "qa_fail",
        "changes_requested",
        "critical",
        "must fix",
        "block release",
        "hig_fail",
        "failed criteria",
        "overall verdict\nqa_fail",
    ]
    if not verdict or blockers:
        for signal in blocker_signals:
            if signal in lowered:
                blockers.append(signal)

    ui_signals = ["safe area", "touch target", "layout", "screen", "visual", "dark mode", "hig", "spacing"]
    logic_signals = ["state", "store", "auth", "api", "logic", "network", "data flow"]

    if any(signal in lowered for signal in ui_signals):
        lanes.append("ui")
    if any(signal in lowered for signal in logic_signals):
        lanes.append("logic")

    return blockers, list(dict.fromkeys(lanes))


def summarize_evaluation(
    review_report: Path,
    hig_report: Path,
    visual_report: Path,
    *,
    xcode_test_probe: Path | None = None,
) -> EvaluationSummary:
    blockers: list[str] = []
    lanes: list[str] = []
    for path in (review_report, hig_report, visual_report):
        content = path.read_text(encoding="utf-8")
        file_blockers, file_lanes = extract_blockers(content)
        blockers.extend([f"{path.name}:{item}" for item in file_blockers])
        lanes.extend(file_lanes)
    if xcode_test_probe and xcode_test_probe.exists():
        test_payload = load_json(xcode_test_probe, {})
        if not test_payload.get("ok", False):
            blockers.append(f"{xcode_test_probe.name}:test_failed")
    passed = not blockers
    if not lanes:
        lanes = ["ui", "logic"]
    return EvaluationSummary(
        passed=passed,
        blockers=blockers,
        lanes=list(dict.fromkeys(lanes)),
        review_report=review_report,
        hig_report=hig_report,
        visual_report=visual_report,
    )


def run_playwright_smoke(target_workspace: Path) -> Path:
    load_runtime_env()
    report_path = REPORTS_DIR / "playwright_smoke.json"
    if not (target_workspace / "package.json").exists() or not (target_workspace / "app.json").exists():
        payload = {
            "mode": "playwright_smoke",
            "status": "skipped",
            "passed": True,
            "reason": "Expo smoke path retired; native iOS is now the primary evaluation target.",
            "workspace": str(target_workspace),
            "context": str(CONTEXT_DIR),
        }
        save_json(report_path, payload)
        append_ledger({"type": "playwright_smoke", "report": str(report_path), "returncode": 0, "status": "skipped"})
        append_operator_journal(f"Playwright smoke skipped for native-only workspace -> {report_path.name}")
        return report_path

    cmd = [
        str(FACTORY_DIR / "venv" / "bin" / "python"),
        str(FACTORY_DIR / "modules" / "qa_testing" / "auto_qa_loop.py"),
        "--workspace",
        str(target_workspace),
        "--context",
        str(CONTEXT_DIR),
        "--report-file",
        str(report_path),
        "--smoke-only",
    ]
    result = run_shell(cmd, cwd=FACTORY_DIR, timeout=240)
    if result.returncode != 0 and not report_path.exists():
        payload = {
            "mode": "playwright_smoke",
            "passed": False,
            "runner_error": (result.stdout or result.stderr).strip()[:4000],
            "workspace": str(target_workspace),
            "context": str(CONTEXT_DIR),
        }
        save_json(report_path, payload)
    append_ledger({"type": "playwright_smoke", "report": str(report_path), "returncode": result.returncode})
    append_operator_journal(f"Playwright smoke completed with rc={result.returncode} -> {report_path.name}")
    return report_path


def build_feedback_brief(original_brief: str, summary: EvaluationSummary, round_index: int) -> Path:
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
        f"- code review: {summary.review_report}",
        f"- hig audit: {summary.hig_report}",
        f"- visual qa: {summary.visual_report}",
        "",
        "## Required behavior",
        "- Fix only the release blockers first.",
        "- Preserve HIG-safe and native-feeling interactions.",
        "- Prefer the smallest change set that resolves the issue.",
    ]
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
    append_operator_journal("Starting intake")
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
        "ios_architect",
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
        role_name = "ios_ui_builder" if lane == "ui" else "ios_logic_builder"
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
                    TaskType.IOS_IMPLEMENTATION,
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
                TaskType.IOS_IMPLEMENTATION,
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
    return merge_report


def run_evaluation(brief: str, image_path: str | None = None) -> EvaluationSummary:
    ensure_dirs()
    load_runtime_env()
    append_operator_journal("Starting evaluation")
    repo = current_target_repo()
    smoke_report = run_playwright_smoke(repo / "workspace")
    xcode_probe = run_xcode_runtime_probe(repo)
    xcode_test_probe = run_xcode_test_probe(repo)
    xcode_probe_summary = REPORTS_DIR / "xcode_runtime_probe.md"
    xcode_visual_summary = REPORTS_DIR / "xcode_runtime_visual_summary.md"
    probe_payload = load_json(xcode_probe, {})
    visual_image = image_path or probe_payload.get("screenshot") or probe_payload.get("runtime_verification", {}).get("screenshot")
    supplementary_artifacts = {}
    for name, path in {
        "runtime_release_closure_evidence": REPORTS_DIR / "runtime_release_closure_evidence.md",
        "permission_flow_audit": REPORTS_DIR / "permission_flow_audit_20260408.md",
        "accessibility_readiness": REPORTS_DIR / "accessibility_readiness_20260408.md",
    }.items():
        if path.exists():
            supplementary_artifacts[name] = path
    review_report = run_role(
        "red_team_reviewer",
        TaskType.CODE_REVIEW,
        brief,
        {
            "team_manifest": TEAM_MANIFEST_FILE,
            "playwright_smoke": smoke_report,
            "xcode_runtime_probe": xcode_probe,
            "xcode_test_probe": xcode_test_probe,
            "xcode_runtime_summary": xcode_probe_summary,
            "xcode_runtime_visual_summary": xcode_visual_summary,
            **supplementary_artifacts,
        },
        cwd=repo,
    )
    hig_report = run_role(
        "hig_guardian",
        TaskType.HIG_AUDIT,
        brief,
        {
            "review_report": review_report,
            "playwright_smoke": smoke_report,
            "xcode_runtime_probe": xcode_probe,
            "xcode_test_probe": xcode_test_probe,
            "xcode_runtime_summary": xcode_probe_summary,
            "xcode_runtime_visual_summary": xcode_visual_summary,
            **supplementary_artifacts,
        },
        cwd=repo,
    )
    visual_report = run_role(
        "visual_qa",
        TaskType.VISUAL_QA,
        brief,
        {
            "review_report": review_report,
            "hig_report": hig_report,
            "playwright_smoke": smoke_report,
            "xcode_runtime_probe": xcode_probe,
            "xcode_test_probe": xcode_test_probe,
            "xcode_runtime_summary": xcode_probe_summary,
            "xcode_runtime_visual_summary": xcode_visual_summary,
            **supplementary_artifacts,
        },
        cwd=repo,
        image_path=visual_image,
    )
    summary = summarize_evaluation(
        review_report,
        hig_report,
        visual_report,
        xcode_test_probe=xcode_test_probe,
    )
    save_json(
        REPORTS_DIR / "evaluation_summary.json",
        {
            "passed": summary.passed,
            "blockers": summary.blockers,
            "lanes": summary.lanes,
            "playwright_smoke": str(smoke_report),
            "xcode_runtime_probe": str(xcode_probe),
            "xcode_test_probe": str(xcode_test_probe),
            "review_report": str(review_report),
            "hig_report": str(hig_report),
            "visual_report": str(visual_report),
        },
    )
    write_state(
        {
            "evaluation_complete": True,
            "playwright_smoke": str(smoke_report),
            "xcode_runtime_probe": str(xcode_probe),
            "xcode_test_probe": str(xcode_test_probe),
            "review_report": str(review_report),
            "hig_report": str(hig_report),
            "visual_report": str(visual_report),
            "evaluation_passed": summary.passed,
        }
    )
    print(f"playwright smoke: {smoke_report}")
    print(f"xcode runtime probe: {xcode_probe}")
    print(f"xcode test probe: {xcode_test_probe}")
    print(f"review report: {review_report}")
    print(f"hig report: {hig_report}")
    print(f"visual report: {visual_report}")
    print(f"evaluation passed: {summary.passed}")
    append_ledger(
        {
            "type": "evaluation_summary",
            "passed": summary.passed,
            "blockers": summary.blockers,
            "lanes": summary.lanes,
            "playwright_smoke": str(smoke_report),
            "xcode_runtime_probe": str(xcode_probe),
            "xcode_test_probe": str(xcode_test_probe),
            "review_report": str(review_report),
            "hig_report": str(hig_report),
            "visual_report": str(visual_report),
            "evaluator_mode": "playwright_e2e_plus_visual_qa",
        }
    )
    append_operator_journal(f"Evaluation completed with passed={summary.passed}")
    return summary


def run_feedback_loop(brief: str, image_path: str | None = None, max_rounds: int = 2):
    ensure_dirs()
    load_runtime_env()
    doctor_report = run_preflight_doctor(quick=True)
    append_operator_journal(f"Autopilot starting with doctor report {doctor_report.name}")
    run_intake(brief)
    run_delivery(brief, phase_tag="delivery")
    summary = run_evaluation(brief, image_path=image_path)

    round_index = 0
    while not summary.passed and round_index < max_rounds:
        round_index += 1
        compact_blackboard(force=True)
        packet = build_feedback_brief(brief, summary, round_index)
        append_ledger({"type": "remediation_packet", "round": round_index, "packet": str(packet), "lanes": summary.lanes})
        append_operator_journal(f"Starting remediation round {round_index}")
        artifacts = {
            "feedback_packet": packet,
            "evaluation_summary": REPORTS_DIR / "evaluation_summary.json",
            "blackboard_compact": BLACKBOARD_COMPACT_FILE if BLACKBOARD_COMPACT_FILE.exists() else BLACKBOARD_FILE,
        }
        branch_names: list[str] = []
        for lane in summary.lanes:
            role_name = "ios_ui_builder" if lane == "ui" else "ios_logic_builder"
            worktree, branch_name = ensure_lane_worktree(role_name, f"fix-{round_index}", INTEGRATION_BRANCH)
            run_role(role_name, TaskType.BUG_FIX, brief, artifacts, cwd=worktree, report_stem=f"{role_name}_bug_fix_round_{round_index}")
            branch_names.append(branch_name)
        merge_report = merge_delivery_branches(branch_names, f"fix-{round_index}")
        write_state({"latest_feedback_packet": str(packet), "latest_fix_merge_report": str(merge_report)})
        summary = run_evaluation(brief, image_path=image_path)

    return summary


def explain_evaluator_mode() -> Path:
    path = REPORTS_DIR / "evaluator_mode.md"
    body = """# Evaluator Mode

The evaluator lane is intended to test the real app surface, not only static code.

## Current mode

- Native iOS is the primary evaluation path
- Xcode project discovery and native build evidence are the main release signals
- Claude review lane for code and regression checks
- HIG audit lane for iOS-native risk review
- Playwright-style Expo smoke is optional and skipped when the Expo scaffold is absent

## Limits

- Full simulator-driving artifact capture is still being strengthened.
- Expo web is no longer required once the native project becomes the sole source of truth.
"""
    save_text(path, body)
    append_ledger({"type": "evaluator_mode", "report": str(path), "mode": "playwright_e2e_plus_visual_qa"})
    return path


def write_change_record():
    body = """# Change Record

## Before this conversation

- The machine had Codex CLI, Claude Code, and Gemini CLI installed, but the harness behavior was still centered on older triad assumptions.
- Claude was configured mainly as a CLI participant, not as the planning and review API backend.
- The router and runner mixed outdated task names, old model assumptions, and incomplete worktree orchestration.
- iOS tooling was incomplete because full `Xcode.app` was not active, and no explicit release-gate policy tied AI output to Apple HIG review.
- Context separation for token efficiency existed only partially and was not enforced across product, planning, engineering, and evaluation lanes.

## Current state

- The harness is now organized as a company-style team with operations, product, planning, engineering, and evaluation roles.
- Claude is assigned to API-driven planning, architecture, arbitration, review, and operator duties.
- The Claude provider now prefers `claude-agent-sdk`, enabling adaptive thinking, structured outputs, project settings loading, and future MCP/subagent expansion.
- Codex CLI is assigned to implementation and parallel execution work.
- Gemini CLI is assigned to market research and screenshot-heavy visual QA.
- The router now supports explicit preferred-role dispatch instead of only task-type routing.
- The orchestrator now writes structured handoffs, runs delivery in isolated worktrees, merges into a dedicated integration worktree, compacts blackboard context, and supports evaluation-to-remediation loops.
- The orchestrator now includes a preflight doctor, handoff ledger, operator journal, and explicit evaluator-mode documentation.
- The orchestrator now loads project `.env` at runtime so provider authentication survives new subprocesses and restarted sessions.
- The evaluator lane now runs a Playwright-style smoke pass before review and HIG arbitration, and stores the result as a reusable artifact.
- Policy files now define HIG release gates, fork criteria, and install steps.
- User-level shell and CLI settings were aligned for the new harness shape.
- Recommended frontline tools were partially installed; `swiftlint` still awaits full Xcode installation.

## Intent

- Reduce hallucination by separating implementation from evaluation.
- Reduce self-approval bias by requiring an external review lane before release confidence.
- Reduce token waste by passing short handoffs through dedicated directories rather than replaying full history.
- Keep iOS output closer to App Store expectations by treating HIG as a blocking gate instead of a soft guideline.
- Move merge-back and autonomous remediation into the operator lane instead of leaving them implicit.
- Make subagent spawning predictable by enforcing bounded scope, disjoint ownership, and explicit verification artifacts.
"""
    save_text(CHANGE_RECORD_FILE, body)
    print(f"change record: {CHANGE_RECORD_FILE}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Company-style frontier app harness")
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

    compact = sub.add_parser("compact-blackboard")
    compact.set_defaults(func=lambda args: compact_blackboard(force=True))

    doctor = sub.add_parser("doctor")
    doctor.add_argument("--quick", action="store_true")
    doctor.set_defaults(func=lambda args: print(run_preflight_doctor(quick=args.quick)))

    evaluator_mode = sub.add_parser("evaluator-mode")
    evaluator_mode.set_defaults(func=lambda args: print(explain_evaluator_mode()))

    record = sub.add_parser("record-changes")
    record.set_defaults(func=lambda args: write_change_record())

    return parser


if __name__ == "__main__":
    ensure_dirs()
    load_runtime_env()
    arguments = build_parser().parse_args()
    arguments.func(arguments)
