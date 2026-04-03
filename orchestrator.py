#!/usr/bin/env python3
"""
Company-style multi-agent harness orchestrator.
"""

from __future__ import annotations

import argparse
import base64
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
from harness.providers import run_claude_api, run_cli
from harness.runtime_env import load_project_env
from master_router import TaskType, dispatch, read_blackboard

FACTORY_DIR = Path(__file__).parent.resolve()
WORKSPACE_DIR = FACTORY_DIR / "workspace"
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


def save_json(path: Path, payload: Any):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def save_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def append_ledger(entry: dict[str, Any]):
    HANDOFF_LEDGER_FILE.parent.mkdir(parents=True, exist_ok=True)
    with HANDOFF_LEDGER_FILE.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry, ensure_ascii=False) + "\n")


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


def parse_iso_timestamp(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        normalized = value.replace("Z", "+00:00")
        return datetime.fromisoformat(normalized)
    except ValueError:
        return None


def parse_unix_timestamp(value: Any) -> datetime | None:
    try:
        return datetime.fromtimestamp(int(value), tz=UTC)
    except Exception:
        return None


def decode_jwt_payload(token: str | None) -> dict[str, Any]:
    if not token or "." not in token:
        return {}
    try:
        middle = token.split(".")[1]
        padding = "=" * (-len(middle) % 4)
        raw = base64.urlsafe_b64decode(middle + padding)
        return json.loads(raw.decode("utf-8"))
    except Exception:
        return {}


def describe_session(deadline: datetime | None) -> tuple[str, str]:
    if not deadline:
        return "blocked", "no expiry metadata available"
    now = datetime.now(tz=UTC)
    if deadline <= now:
        return "blocked", f"expired at {deadline.isoformat()}"
    remaining = deadline - now
    minutes = int(remaining.total_seconds() // 60)
    return "ready", f"expires at {deadline.isoformat()} ({minutes} min remaining)"


def write_doctor_summary(report_payload: dict[str, Any]) -> Path:
    summary_path = REPORTS_DIR / "preflight_doctor.md"
    lines = [
        "# Preflight Doctor",
        "",
        f"- all_ok: {report_payload['all_ok']}",
        f"- evaluator_mode: {report_payload['evaluator_mode']}",
        "",
        "## Provider readiness",
    ]

    for provider_name, provider in report_payload.get("providers", {}).items():
        lines.append(f"### {provider_name}")
        lines.append(f"- status: {provider.get('status', 'unknown')}")
        lines.append(f"- binary: {provider.get('binary_ready', 'unknown')}")
        lines.append(f"- auth: {provider.get('auth_ready', 'unknown')}")
        lines.append(f"- session: {provider.get('session_ready', 'unknown')}")
        lines.append(f"- local readiness: {provider.get('local_readiness', 'unknown')}")
        lines.append(f"- live connectivity: {provider.get('live_connectivity', 'unknown')}")
        lines.append(f"- runtime: {provider.get('runtime', 'unknown')}")
        lines.append(f"- mcp: {provider.get('mcp', 'unknown')}")
        lines.append(f"- lane impact: {provider.get('lane_impact', 'unknown')}")
        if provider.get("notes"):
            lines.append(f"- notes: {provider['notes']}")
        lines.append("")

    lines.append("## Lane readiness")
    for lane_name, lane in report_payload.get("lanes", {}).items():
        lines.append(f"### {lane_name}")
        lines.append(f"- status: {lane.get('status', 'unknown')}")
        lines.append(f"- blockers: {', '.join(lane.get('blockers', [])) or 'none'}")
        lines.append("")

    save_text(summary_path, "\n".join(lines))
    return summary_path


def provider_smoke_report() -> Path:
    report_path = REPORTS_DIR / "provider_smoke.json"
    smoke_prompt = "Return exactly OK."
    payload: dict[str, Any] = {}

    claude_model = ROLES["delivery_lead"].model or PROVIDERS["claude_api"].models.get("default", "claude-sonnet-4")
    try:
        claude_result = run_claude_api(
            smoke_prompt,
            model=claude_model,
            system_prompt="Return exactly OK.",
            timeout=30,
            max_retries=0,
        )
        payload["claude_api"] = {
            "success": claude_result.success,
            "model": claude_model,
            "output": claude_result.output.strip()[:120],
            "error": claude_result.error[:240],
        }
    except Exception as exc:
        payload["claude_api"] = {"success": False, "model": claude_model, "output": "", "error": str(exc)[:240]}

    codex_model = ROLES["ios_ui_builder"].model or PROVIDERS["codex_cli"].models.get("default", "gpt-5.4")
    try:
        codex_result = run_cli(
            ["codex", "exec", smoke_prompt, "-m", codex_model, "--full-auto"],
            cwd=FACTORY_DIR,
            timeout=30,
            max_retries=0,
        )
        payload["codex_cli"] = {
            "success": codex_result.success,
            "model": codex_model,
            "output": codex_result.output.strip()[:120],
            "error": codex_result.error[:240],
        }
    except Exception as exc:
        payload["codex_cli"] = {"success": False, "model": codex_model, "output": "", "error": str(exc)[:240]}

    gemini_model = ROLES["product_lead"].model or PROVIDERS["gemini_cli"].models.get("default", "gemini-2.5-pro")
    try:
        gemini_result = run_cli(
            ["gemini", "-p", smoke_prompt, "-m", gemini_model, "-y"],
            cwd=FACTORY_DIR,
            timeout=30,
            max_retries=0,
        )
        payload["gemini_cli"] = {
            "success": gemini_result.success,
            "model": gemini_model,
            "output": gemini_result.output.strip()[:120],
            "error": gemini_result.error[:240],
        }
    except Exception as exc:
        payload["gemini_cli"] = {"success": False, "model": gemini_model, "output": "", "error": str(exc)[:240]}

    save_json(report_path, payload)
    return report_path


def run_xcode_runtime_probe(repo: Path) -> Path:
    report_path = REPORTS_DIR / "xcode_runtime_probe.json"
    host_baseline = load_json(HOST_RUNTIME_BASELINE_FILE, {})
    workspace = repo / "workspace"
    ios_dir = workspace / "ios"
    xcworkspace = next(iter(sorted(ios_dir.glob("*.xcworkspace"))), None) if ios_dir.exists() else None
    xcodeproj = next(iter(sorted(ios_dir.glob("*.xcodeproj"))), None) if ios_dir.exists() else None

    payload: dict[str, Any] = {
        "workspace_root": str(workspace),
        "ios_dir_exists": ios_dir.exists(),
        "xcworkspace": str(xcworkspace) if xcworkspace else None,
        "xcodeproj": str(xcodeproj) if xcodeproj else None,
    }

    xcode_version = run_shell(["xcodebuild", "-version"], timeout=20)
    simctl = run_shell(["xcrun", "simctl", "list", "devices"], timeout=20)
    simctl_host_ok = bool(host_baseline.get("simctl", {}).get("ok"))
    payload["xcodebuild_version"] = (xcode_version.stdout or xcode_version.stderr).strip()[:300]
    payload["simctl"] = {
        "ok": simctl.returncode == 0 or simctl_host_ok,
        "detail": (
            (simctl.stdout or simctl.stderr).strip()[:500]
            if simctl.returncode == 0 or not simctl_host_ok
            else f"sandbox false negative; host ok: {host_baseline['simctl'].get('detail', '')[:420]}"
        ),
    }

    if xcworkspace:
        build_list = run_shell(["xcodebuild", "-list", "-workspace", str(xcworkspace)], cwd=ios_dir, timeout=30)
        payload["project_discovery"] = {"ok": build_list.returncode == 0, "detail": (build_list.stdout or build_list.stderr).strip()[:1000]}
    elif xcodeproj:
        build_list = run_shell(["xcodebuild", "-list", "-project", str(xcodeproj)], cwd=ios_dir, timeout=30)
        payload["project_discovery"] = {"ok": build_list.returncode == 0, "detail": (build_list.stdout or build_list.stderr).strip()[:1000]}
    else:
        payload["project_discovery"] = {
            "ok": False,
            "detail": "No native iOS project detected under workspace/ios. Current evaluation remains Expo web plus visual QA.",
        }

    save_json(report_path, payload)
    append_ledger({"type": "xcode_runtime_probe", "report": str(report_path)})
    append_operator_journal(f"Xcode runtime probe wrote {report_path.name}")
    return report_path


def run_preflight_doctor(*, quick: bool = False) -> Path:
    ensure_dirs()
    loaded_env = sorted(load_runtime_env().keys())
    host_baseline = load_json(HOST_RUNTIME_BASELINE_FILE, {})
    checks = []

    def add_check(name: str, ok: bool, detail: str):
        checks.append({"name": name, "ok": ok, "detail": detail})

    xcode = run_shell(["xcodebuild", "-version"])
    add_check("xcodebuild", xcode.returncode == 0, (xcode.stdout or xcode.stderr).strip()[:300])

    simctl = run_shell(["xcrun", "simctl", "list", "devices"])
    simctl_host_ok = bool(host_baseline.get("simctl", {}).get("ok"))
    simctl_ok = simctl.returncode == 0 or simctl_host_ok
    simctl_detail = (simctl.stdout or simctl.stderr).strip()[:300]
    if simctl_host_ok and simctl.returncode != 0:
        simctl_detail = f"sandbox false negative; host ok: {host_baseline['simctl'].get('detail', '')[:220]}"
    add_check("simctl", simctl_ok, simctl_detail)

    codex = run_shell(["codex", "--version"])
    add_check("codex_cli", codex.returncode == 0, (codex.stdout or codex.stderr).strip()[:200])

    gemini = run_shell(["gemini", "--version"])
    gemini_host_ok = bool(host_baseline.get("gemini_version", {}).get("ok"))
    gemini_ok = gemini.returncode == 0 or gemini_host_ok
    gemini_detail = (gemini.stdout or gemini.stderr).strip()[:200]
    if gemini_host_ok and gemini.returncode != 0:
        gemini_detail = f"sandbox false negative; host ok: {host_baseline['gemini_version'].get('detail', '')[:120]}"
    add_check("gemini_cli", gemini_ok, gemini_detail)

    claude_sdk = run_shell([str(FACTORY_DIR / "venv" / "bin" / "python"), "-c", "import claude_agent_sdk; print('ok')"])
    add_check("claude_agent_sdk", claude_sdk.returncode == 0, (claude_sdk.stdout or claude_sdk.stderr).strip()[:200])

    playwright = run_shell([str(FACTORY_DIR / "venv" / "bin" / "python"), "-c", "from playwright.sync_api import sync_playwright; print('ok')"])
    add_check("playwright_python", playwright.returncode == 0, (playwright.stdout or playwright.stderr).strip()[:200])

    anthropic_key = bool(os.environ.get("ANTHROPIC_API_KEY"))
    add_check("anthropic_api_key", anthropic_key, "visible in current process" if anthropic_key else "not visible in current process")

    mcp_project = (FACTORY_DIR / ".mcp.json").exists()
    add_check("project_mcp_config", mcp_project, str(FACTORY_DIR / ".mcp.json"))

    codex_mcp = run_shell(["codex", "mcp", "list"])
    add_check("codex_mcp_runtime", codex_mcp.returncode == 0, (codex_mcp.stdout or codex_mcp.stderr).strip()[:300])

    claude_mcp = run_shell(["claude", "mcp", "list"])
    add_check("claude_mcp_runtime", claude_mcp.returncode == 0, (claude_mcp.stdout or claude_mcp.stderr).strip()[:300])

    codex_auth = (Path.home() / ".codex" / "auth.json").exists()
    add_check("codex_auth_state", codex_auth, str(Path.home() / ".codex" / "auth.json"))

    gemini_auth = (Path.home() / ".gemini" / "oauth_creds.json").exists()
    add_check("gemini_auth_state", gemini_auth, str(Path.home() / ".gemini" / "oauth_creds.json"))

    claude_settings = (Path.home() / ".claude" / "settings.json").exists()
    add_check("claude_settings_state", claude_settings, str(Path.home() / ".claude" / "settings.json"))

    smoke_report = provider_smoke_report() if not quick else None
    smoke_payload = load_json(smoke_report, {}) if smoke_report else {}
    if not quick:
        add_check("claude_api_smoke", bool(smoke_payload.get("claude_api", {}).get("success")), smoke_payload.get("claude_api", {}).get("error") or smoke_payload.get("claude_api", {}).get("output", ""))
        add_check("codex_cli_smoke", bool(smoke_payload.get("codex_cli", {}).get("success")), smoke_payload.get("codex_cli", {}).get("error") or smoke_payload.get("codex_cli", {}).get("output", ""))
        add_check("gemini_cli_smoke", bool(smoke_payload.get("gemini_cli", {}).get("success")), smoke_payload.get("gemini_cli", {}).get("error") or smoke_payload.get("gemini_cli", {}).get("output", ""))

    codex_auth_payload = load_json(Path.home() / ".codex" / "auth.json", {})
    gemini_auth_payload = load_json(Path.home() / ".gemini" / "oauth_creds.json", {})
    codex_access_payload = decode_jwt_payload(codex_auth_payload.get("tokens", {}).get("access_token"))
    codex_session_status, codex_session_detail = describe_session(parse_unix_timestamp(codex_access_payload.get("exp")))
    gemini_session_status, gemini_session_detail = describe_session(parse_unix_timestamp(gemini_auth_payload.get("expiry_date")))
    claude_session_status = "ready" if anthropic_key else "blocked"
    claude_session_detail = "ANTHROPIC_API_KEY present" if anthropic_key else "ANTHROPIC_API_KEY missing"

    codex_binary_ready = status_from_checks(codex.returncode == 0)
    gemini_binary_ready = status_from_checks(gemini_ok)
    claude_binary_ready = status_from_checks(claude_sdk.returncode == 0)
    xcode_binary_ready = status_from_checks(xcode.returncode == 0)

    codex_auth_ready = status_from_checks(codex_auth)
    gemini_auth_ready = status_from_checks(gemini_auth)
    claude_auth_ready = status_from_checks(anthropic_key)

    codex_local_ready = status_from_checks(codex_binary_ready == "ready", codex_auth_ready == "ready", codex_session_status == "ready")
    gemini_local_ready = status_from_checks(gemini_ok, gemini_auth_ready == "ready")
    claude_local_ready = status_from_checks(claude_binary_ready == "ready", claude_auth_ready == "ready", claude_session_status == "ready")
    codex_live = "skipped" if quick else status_from_checks(bool(smoke_payload.get("codex_cli", {}).get("success")))
    gemini_live = "skipped" if quick else status_from_checks(bool(smoke_payload.get("gemini_cli", {}).get("success")))
    claude_live = "skipped" if quick else status_from_checks(bool(smoke_payload.get("claude_api", {}).get("success")))
    codex_ready = codex_local_ready
    gemini_ready = gemini_local_ready
    claude_ready = claude_local_ready
    xcode_mcp_ready = status_from_checks(xcode.returncode == 0, mcp_project)

    providers = {
        "claude_api": {
            "status": claude_ready,
            "binary_ready": claude_binary_ready,
            "auth_ready": claude_auth_ready,
            "session_ready": claude_session_status,
            "local_readiness": claude_local_ready,
            "live_connectivity": claude_live,
            "runtime": "claude-agent-sdk ok" if claude_sdk.returncode == 0 else "claude-agent-sdk unavailable",
            "mcp": "claude mcp runtime ok" if claude_mcp.returncode == 0 else "claude mcp runtime unavailable",
            "lane_impact": "planning, architecture, review, operator",
            "notes": f"Session={claude_session_detail}. Smoke={'skipped' if quick else ('ok' if smoke_payload.get('claude_api', {}).get('success') else 'failed')}. Claude API path is usable even if Claude CLI MCP runtime is not.",
        },
        "codex_cli": {
            "status": codex_ready,
            "binary_ready": codex_binary_ready,
            "auth_ready": codex_auth_ready,
            "session_ready": codex_session_status,
            "local_readiness": codex_local_ready,
            "live_connectivity": codex_live,
            "runtime": (codex.stdout or codex.stderr).strip()[:120] if codex.returncode == 0 else "codex CLI unavailable",
            "mcp": (codex_mcp.stdout or codex_mcp.stderr).strip()[:160],
            "lane_impact": "implementation, refactor, parallel worktrees",
            "notes": f"Session={codex_session_detail}. Smoke={'skipped' if quick else ('ok' if smoke_payload.get('codex_cli', {}).get('success') else 'failed')}. Project is trusted in ~/.codex/config.toml.",
        },
        "gemini_cli": {
            "status": gemini_ready,
            "binary_ready": gemini_binary_ready,
            "auth_ready": gemini_auth_ready,
            "session_ready": gemini_session_status,
            "local_readiness": gemini_local_ready,
            "live_connectivity": gemini_live,
            "runtime": (gemini.stdout or gemini.stderr).strip()[:120] if gemini.returncode == 0 else f"host baseline ok: {host_baseline.get('gemini_version', {}).get('detail', 'gemini CLI unavailable or slow')[:120]}",
            "mcp": "project .mcp.json available" if mcp_project else "missing project .mcp.json",
            "lane_impact": "product research, visual QA, multimodal critique",
            "notes": f"Session={gemini_session_detail}. Smoke={'skipped' if quick else ('ok' if smoke_payload.get('gemini_cli', {}).get('success') else 'failed')}. Host baseline={'ok' if gemini_host_ok else 'missing'}.",
        },
        "xcode_mcp": {
            "status": xcode_mcp_ready,
            "binary_ready": xcode_binary_ready,
            "auth_ready": "ready",
            "session_ready": "ready",
            "local_readiness": xcode_mcp_ready,
            "live_connectivity": "unknown",
            "runtime": (xcode.stdout or xcode.stderr).strip()[:120],
            "mcp": "project .mcp.json configured" if mcp_project else "missing project .mcp.json",
            "lane_impact": "native build, simulator, preview, UI testing",
            "notes": "Global client registration may still be missing even with project fallback config.",
        },
    }

    lanes = {
        "operations": {
            "status": status_from_checks(claude_ready == "ready"),
            "blockers": [
                blocker
                for blocker, ok in {
                    "claude_api_unavailable": claude_ready == "ready",
                    "claude_live_probe_failed": quick or claude_live == "ready",
                }.items()
                if not ok
            ],
        },
        "product": {
            "status": status_from_checks(gemini_auth),
            "blockers": [
                blocker
                for blocker, ok in {
                    "gemini_auth_missing": gemini_auth,
                    "gemini_live_probe_failed": quick or gemini_live == "ready",
                }.items()
                if not ok
            ],
        },
        "planning": {
            "status": status_from_checks(claude_ready == "ready"),
            "blockers": [
                blocker
                for blocker, ok in {
                    "claude_api_unavailable": claude_ready == "ready",
                    "claude_live_probe_failed": quick or claude_live == "ready",
                }.items()
                if not ok
            ],
        },
        "development": {
            "status": status_from_checks(codex_ready == "ready"),
            "blockers": [
                blocker
                for blocker, ok in {
                    "codex_cli_unavailable": codex_ready == "ready",
                    "codex_live_probe_failed": quick or codex_live == "ready",
                }.items()
                if not ok
            ],
        },
        "evaluation": {
            "status": status_from_checks(playwright.returncode == 0, gemini_auth),
            "blockers": [
                blocker
                for blocker, ok in {
                    "playwright_missing": playwright.returncode == 0,
                    "gemini_auth_missing": gemini_auth,
                    "simctl_unstable": simctl_ok,
                    "native_ios_project_missing": (current_target_workspace() / "ios").exists(),
                }.items()
                if not ok
            ],
        },
    }

    doctor_report = REPORTS_DIR / "preflight_doctor.json"
    report_payload = {
        "all_ok": all(item["ok"] for item in checks),
        "checks": checks,
        "provider_smoke_report": str(smoke_report) if smoke_report else None,
        "providers": providers,
        "lanes": lanes,
        "evaluator_mode": "playwright_e2e_plus_visual_qa",
        "loaded_env_keys": loaded_env,
        "host_runtime_baseline": str(HOST_RUNTIME_BASELINE_FILE) if HOST_RUNTIME_BASELINE_FILE.exists() else None,
        "quick_mode": quick,
    }
    save_json(doctor_report, report_payload)
    doctor_summary = write_doctor_summary(report_payload)
    append_ledger({"type": "doctor", "report": str(doctor_report), "all_ok": all(item["ok"] for item in checks)})
    append_operator_journal(f"Preflight doctor wrote {doctor_report} and {doctor_summary}")
    return doctor_report


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


def ensure_integration_worktree() -> Path:
    if INTEGRATION_WORKTREE.exists():
        return INTEGRATION_WORKTREE
    git("worktree", "add", "-B", INTEGRATION_BRANCH, str(INTEGRATION_WORKTREE), "HEAD")
    return INTEGRATION_WORKTREE


def ensure_lane_worktree(role_name: str, lane_tag: str, start_point: str) -> tuple[Path, str]:
    worktree_dir = WORKTREES_DIR / f"{role_name}-{lane_tag}"
    branch_name = f"harness/{role_name}-{lane_tag}"
    if worktree_dir.exists():
        return worktree_dir, branch_name
    git("worktree", "add", "-B", branch_name, str(worktree_dir), start_point)
    return worktree_dir, branch_name


def current_target_repo() -> Path:
    return INTEGRATION_WORKTREE if INTEGRATION_WORKTREE.exists() else FACTORY_DIR


def current_target_workspace() -> Path:
    repo = current_target_repo()
    return repo / "workspace"


def read_artifact_excerpt(path: Path, max_chars: int = 1600) -> str:
    try:
        if path.suffix.lower() == ".json":
            payload = json.loads(path.read_text(encoding="utf-8"))
            text = json.dumps(payload, ensure_ascii=False, indent=2)
        else:
            text = path.read_text(encoding="utf-8")
    except Exception as exc:
        return f"[unreadable artifact: {exc}]"

    compact = text.strip()
    if len(compact) > max_chars:
        compact = compact[:max_chars].rstrip() + "\n...[truncated]"
    return compact


def build_artifact_snapshot(artifacts: dict[str, Path]) -> str:
    sections: list[str] = []
    for name, path in artifacts.items():
        if not path.exists():
            sections.append(f"## {name}\nPath: {path}\n[missing]")
            continue
        if path.suffix.lower() not in {".md", ".txt", ".json"}:
            sections.append(f"## {name}\nPath: {path}\n[non-text artifact; use path only]")
            continue
        sections.append(f"## {name}\nPath: {path}\n{read_artifact_excerpt(path)}")
    return "\n\n".join(sections)


def build_role_prompt(
    role_name: str,
    brief: str,
    artifacts: dict[str, Path],
    json_schema: dict[str, Any] | None = None,
) -> str:
    manifest = load_json(TEAM_MANIFEST_FILE, {})
    role = next((item for item in manifest.get("roles", []) if item.get("id") == role_name), {})
    responsibilities = "\n".join(f"- {item}" for item in role.get("responsibilities", []))
    artifact_lines = "\n".join(f"- {name}: {path}" for name, path in artifacts.items())
    artifact_snapshot = build_artifact_snapshot(artifacts)
    schema_section = ""
    if json_schema:
        schema_section = f"""
RESPONSE CONTRACT:
- Return only valid JSON.
- Do not wrap the JSON in markdown fences.
- Do not add commentary before or after the JSON.
- The JSON must satisfy this schema exactly:
{json.dumps(json_schema, indent=2, ensure_ascii=False)}
"""
    return f"""ROLE: {role.get('title', role_name)}

RESPONSIBILITIES:
{responsibilities or "- Follow the harness contract."}

CURRENT BRIEF:
{brief}

RECENT BLACKBOARD:
{read_blackboard(1800)}

AVAILABLE ARTIFACTS:
{artifact_lines or "- none"}

ARTIFACT CONTENT SNAPSHOTS:
{artifact_snapshot or "- none"}
{schema_section}
"""


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
    prompt = build_role_prompt(role_name, brief, artifacts, json_schema)
    extension = ".json" if json_schema else ".md"
    stem = report_stem or f"{role_name}_{task_type.value}"
    output_path = REPORTS_DIR / f"{stem}{extension}"
    result = dispatch(
        task_type,
        prompt,
        cwd=cwd,
        image_path=image_path,
        json_schema=json_schema,
        timeout=timeout,
        preferred_role=role_name,
        allow_fallback_roles=allow_fallback_roles,
    )
    if not result.success:
        raise RuntimeError(f"{role_name} failed for {task_type.value}: {result.output[:200]}")

    if json_schema:
        try:
            parsed = parse_json_output(result.output)
        except Exception as exc:
            raw_output_path = REPORTS_DIR / f"{stem}.raw.txt"
            save_text(raw_output_path, result.output)
            raise RuntimeError(
                f"{role_name} returned invalid JSON for {task_type.value}. "
                f"Raw output saved to {raw_output_path}. Parser error: {exc}"
            ) from exc
        save_json(output_path, parsed)
    else:
        save_text(output_path, result.output)
    append_ledger(
        {
            "type": "role_output",
            "role": role_name,
            "task_type": task_type.value,
            "report": str(output_path),
            "cwd": str(cwd) if cwd else None,
        }
    )
    append_operator_journal(f"{role_name} completed {task_type.value} -> {output_path.name}")
    return output_path


def _extract_json_candidates(text: str) -> list[str]:
    stripped = text.strip()
    candidates: list[str] = []
    if stripped:
        candidates.append(stripped)

    if stripped.startswith("```"):
        unfenced = re.sub(r"^```(?:json)?\s*", "", stripped)
        unfenced = re.sub(r"\s*```$", "", unfenced)
        if unfenced and unfenced not in candidates:
            candidates.append(unfenced.strip())

    decoder = json.JSONDecoder()
    for index, char in enumerate(stripped):
        if char not in "[{":
            continue
        try:
            obj, end = decoder.raw_decode(stripped[index:])
        except json.JSONDecodeError:
            continue
        candidate = stripped[index:index + end]
        if candidate not in candidates:
            candidates.append(candidate)
        if isinstance(obj, (dict, list)):
            normalized = json.dumps(obj, ensure_ascii=False)
            if normalized not in candidates:
                candidates.append(normalized)
    return candidates


def parse_json_output(text: str) -> Any:
    errors: list[str] = []
    for candidate in _extract_json_candidates(text):
        try:
            return json.loads(candidate)
        except json.JSONDecodeError as exc:
            errors.append(f"{exc.msg} at line {exc.lineno} column {exc.colno}")
    raise json.JSONDecodeError(
        "Could not recover valid JSON from model output",
        text,
        0,
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


def product_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "properties": {
            "summary": {"type": "string"},
            "user_pains": {"type": "array", "items": {"type": "string"}},
            "hig_risks": {"type": "array", "items": {"type": "string"}},
            "design_references": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["summary", "user_pains", "hig_risks", "design_references"],
        "additionalProperties": False,
    }


def plan_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "properties": {
            "execution_summary": {"type": "string"},
            "milestones": {"type": "array", "items": {"type": "string"}},
            "lane_ownership": {
                "type": "object",
                "properties": {
                    "ui": {"type": "array", "items": {"type": "string"}},
                    "logic": {"type": "array", "items": {"type": "string"}},
                    "qa": {"type": "array", "items": {"type": "string"}}
                },
                "required": ["ui", "logic", "qa"],
                "additionalProperties": False
            },
            "merge_strategy": {"type": "string"},
            "feedback_loop": {"type": "string"}
        },
        "required": ["execution_summary", "milestones", "lane_ownership", "merge_strategy", "feedback_loop"],
        "additionalProperties": False,
    }


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
    proc = git("rev-list", "--count", f"{base_ref}..{branch_ref}", cwd=cwd)
    return int(proc.stdout.strip() or "0")


def merge_branch_into_integration(branch_name: str) -> tuple[bool, str]:
    integration = ensure_integration_worktree()
    if branch_ahead_count(INTEGRATION_BRANCH, branch_name, integration) == 0:
        return True, f"{branch_name} already merged or has no unique commits"

    proc = git("merge", "--no-ff", "--no-edit", branch_name, cwd=integration, check=False)
    if proc.returncode == 0:
        return True, proc.stdout.strip() or f"merged {branch_name}"

    git("merge", "--abort", cwd=integration, check=False)
    return False, proc.stderr.strip() or proc.stdout.strip() or f"merge failed for {branch_name}"


def merge_delivery_branches(branches: list[str], phase_label: str) -> Path:
    results = []
    for branch_name in branches:
        success, detail = merge_branch_into_integration(branch_name)
        results.append({"branch": branch_name, "success": success, "detail": detail})
        if not success:
            break

    merge_report = REPORTS_DIR / f"platform_operator_merge_{phase_label}.json"
    save_json(merge_report, {"integration_branch": INTEGRATION_BRANCH, "results": results})
    append_ledger({"type": "merge", "phase": phase_label, "report": str(merge_report), "branches": branches})
    append_operator_journal(f"Merged delivery branches for {phase_label} -> {merge_report.name}")
    return merge_report


def extract_blockers(text: str) -> tuple[list[str], list[str]]:
    lowered = text.lower()
    blockers: list[str] = []
    lanes: list[str] = []

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


def summarize_evaluation(review_report: Path, hig_report: Path, visual_report: Path) -> EvaluationSummary:
    blockers: list[str] = []
    lanes: list[str] = []
    for path in (review_report, hig_report, visual_report):
        content = path.read_text(encoding="utf-8")
        file_blockers, file_lanes = extract_blockers(content)
        blockers.extend([f"{path.name}:{item}" for item in file_blockers])
        lanes.extend(file_lanes)
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


def run_intake(brief: str):
    ensure_dirs()
    load_runtime_env()
    append_operator_journal("Starting intake")
    fork = evaluate_fork_policy(brief)
    fork_path = HANDOFFS_DIR / "fork_decision.json"
    save_json(fork_path, {"should_fork": fork.should_fork, "reasons": fork.reasons, "lanes": fork.lanes})
    intake_artifacts = collect_intake_artifacts()

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
                subtask_brief = build_subtask_delivery_brief(brief, lane, task, state)
                report_path = run_role(
                    role_name,
                    TaskType.IOS_IMPLEMENTATION,
                    subtask_brief,
                    artifacts,
                    cwd=worktree,
                    report_stem=f"{role_name}_{phase_tag}_{lane}_{index}",
                    timeout=420,
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
                timeout=420,
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
    review_report = run_role(
        "red_team_reviewer",
        TaskType.CODE_REVIEW,
        brief,
        {"team_manifest": TEAM_MANIFEST_FILE, "playwright_smoke": smoke_report, "xcode_runtime_probe": xcode_probe},
        cwd=repo,
    )
    hig_report = run_role(
        "hig_guardian",
        TaskType.HIG_AUDIT,
        brief,
        {"review_report": review_report, "playwright_smoke": smoke_report, "xcode_runtime_probe": xcode_probe},
        cwd=repo,
    )
    visual_report = run_role(
        "visual_qa",
        TaskType.VISUAL_QA,
        brief,
        {"review_report": review_report, "hig_report": hig_report, "playwright_smoke": smoke_report, "xcode_runtime_probe": xcode_probe},
        cwd=repo,
        image_path=image_path,
    )
    summary = summarize_evaluation(review_report, hig_report, visual_report)
    save_json(
        REPORTS_DIR / "evaluation_summary.json",
        {
            "passed": summary.passed,
            "blockers": summary.blockers,
            "lanes": summary.lanes,
            "playwright_smoke": str(smoke_report),
            "xcode_runtime_probe": str(xcode_probe),
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
            "review_report": str(review_report),
            "hig_report": str(hig_report),
            "visual_report": str(visual_report),
            "evaluation_passed": summary.passed,
        }
    )
    print(f"playwright smoke: {smoke_report}")
    print(f"xcode runtime probe: {xcode_probe}")
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
