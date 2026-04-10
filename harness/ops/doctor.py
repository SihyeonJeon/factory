"""Preflight doctor — checks every provider, session, and lane readiness.

Extracted from orchestrator.py. The doctor has many dependencies on
orchestrator-level state (roles, providers, path constants, io helpers,
ledger/journal writers) so they are bundled in a ``DoctorDeps`` object
and injected at call time. Orchestrator keeps a thin wrapper that builds
the deps and delegates to ``run_preflight_doctor`` here.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from harness.ops.session import (
    decode_jwt_payload,
    describe_session,
    parse_unix_timestamp,
)


@dataclass
class DoctorDeps:
    factory_dir: Path
    reports_dir: Path
    host_runtime_baseline_file: Path
    roles: dict
    providers: dict
    run_shell: Callable
    run_claude_api: Callable
    run_claude_cli: Callable
    run_cli: Callable
    load_json: Callable
    load_json_from_string: Callable
    save_json: Callable
    save_text: Callable
    append_ledger: Callable
    append_operator_journal: Callable
    load_runtime_env: Callable
    ensure_dirs: Callable
    current_target_workspace: Callable


def _status_from_checks(*flags: bool) -> str:
    return "ready" if all(flags) else "blocked"


def write_doctor_summary(deps: DoctorDeps, report_payload: dict[str, Any]) -> Path:
    summary_path = deps.reports_dir / "preflight_doctor.md"
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

    deps.save_text(summary_path, "\n".join(lines))
    return summary_path


def provider_smoke_report(deps: DoctorDeps) -> Path:
    report_path = deps.reports_dir / "provider_smoke.json"
    smoke_prompt = "Return exactly OK."
    payload: dict[str, Any] = {}

    claude_model = deps.roles["delivery_lead"].model or deps.providers["claude_api"].models.get("default", "claude-sonnet-4")
    claude_cli_enabled = os.environ.get("FACTORY_CLAUDE_USE_CLI", "").strip().lower() in {"1", "true", "yes", "on"}
    try:
        claude_runner = deps.run_claude_cli if claude_cli_enabled else deps.run_claude_api
        claude_result = claude_runner(
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
            "transport": "cli" if claude_cli_enabled else "api",
        }
    except Exception as exc:
        payload["claude_api"] = {
            "success": False,
            "model": claude_model,
            "output": "",
            "error": str(exc)[:240],
            "transport": "cli" if claude_cli_enabled else "api",
        }

    codex_model = deps.roles["ios_ui_builder"].model or deps.providers["codex_cli"].models.get("default", "gpt-5.4")
    try:
        codex_result = deps.run_cli(
            ["codex", "exec", smoke_prompt, "-m", codex_model, "--full-auto"],
            cwd=deps.factory_dir,
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

    deps.save_json(report_path, payload)
    return report_path


def run_preflight_doctor(deps: DoctorDeps, *, quick: bool = False) -> Path:
    deps.ensure_dirs()
    loaded_env = sorted(deps.load_runtime_env().keys())
    host_baseline = deps.load_json(deps.host_runtime_baseline_file, {})
    claude_cli_enabled = os.environ.get("FACTORY_CLAUDE_USE_CLI", "").strip().lower() in {"1", "true", "yes", "on"}
    checks: list[dict[str, Any]] = []

    def add_check(name: str, ok: bool, detail: str) -> None:
        checks.append({"name": name, "ok": ok, "detail": detail})

    xcode = deps.run_shell(["xcodebuild", "-version"])
    add_check("xcodebuild", xcode.returncode == 0, (xcode.stdout or xcode.stderr).strip()[:300])

    simctl = deps.run_shell(["xcrun", "simctl", "list", "devices"])
    simctl_host_ok = bool(host_baseline.get("simctl", {}).get("ok"))
    simctl_ok = simctl.returncode == 0 or simctl_host_ok
    simctl_detail = (simctl.stdout or simctl.stderr).strip()[:300]
    if simctl_host_ok and simctl.returncode != 0:
        simctl_detail = f"sandbox false negative; host ok: {host_baseline['simctl'].get('detail', '')[:220]}"
    add_check("simctl", simctl_ok, simctl_detail)

    codex = deps.run_shell(["codex", "--version"])
    add_check("codex_cli", codex.returncode == 0, (codex.stdout or codex.stderr).strip()[:200])

    claude_sdk = deps.run_shell([str(deps.factory_dir / "venv" / "bin" / "python"), "-c", "import claude_agent_sdk; print('ok')"])
    add_check("claude_agent_sdk", claude_sdk.returncode == 0, (claude_sdk.stdout or claude_sdk.stderr).strip()[:200])

    playwright = deps.run_shell([str(deps.factory_dir / "venv" / "bin" / "python"), "-c", "from playwright.sync_api import sync_playwright; print('ok')"])
    add_check("playwright_python", playwright.returncode == 0, (playwright.stdout or playwright.stderr).strip()[:200])

    anthropic_key = bool(os.environ.get("ANTHROPIC_API_KEY"))
    claude_auth_status = deps.run_shell(["claude", "auth", "status"])
    claude_auth_payload = deps.load_json_from_string(claude_auth_status.stdout) if claude_auth_status.returncode == 0 else {}
    claude_cli_logged_in = bool(claude_auth_payload.get("loggedIn"))
    if claude_cli_enabled:
        add_check("claude_cli_auth", claude_cli_logged_in, "Claude CLI logged in" if claude_cli_logged_in else "Claude CLI not logged in")
    else:
        add_check("anthropic_api_key", anthropic_key, "visible in current process" if anthropic_key else "not visible in current process")

    mcp_project = (deps.factory_dir / ".mcp.json").exists()
    add_check("project_mcp_config", mcp_project, str(deps.factory_dir / ".mcp.json"))

    codex_mcp = deps.run_shell(["codex", "mcp", "list"])
    add_check("codex_mcp_runtime", codex_mcp.returncode == 0, (codex_mcp.stdout or codex_mcp.stderr).strip()[:300])

    claude_mcp = deps.run_shell(["claude", "mcp", "list"])
    add_check("claude_mcp_runtime", claude_mcp.returncode == 0, (claude_mcp.stdout or claude_mcp.stderr).strip()[:300])

    codex_auth = (Path.home() / ".codex" / "auth.json").exists()
    add_check("codex_auth_state", codex_auth, str(Path.home() / ".codex" / "auth.json"))

    claude_settings = (Path.home() / ".claude" / "settings.json").exists()
    add_check("claude_settings_state", claude_settings, str(Path.home() / ".claude" / "settings.json"))

    smoke_report = provider_smoke_report(deps) if not quick else None
    smoke_payload = deps.load_json(smoke_report, {}) if smoke_report else {}
    if not quick:
        add_check("claude_api_smoke", bool(smoke_payload.get("claude_api", {}).get("success")), smoke_payload.get("claude_api", {}).get("error") or smoke_payload.get("claude_api", {}).get("output", ""))
        add_check("codex_cli_smoke", bool(smoke_payload.get("codex_cli", {}).get("success")), smoke_payload.get("codex_cli", {}).get("error") or smoke_payload.get("codex_cli", {}).get("output", ""))

    codex_auth_payload = deps.load_json(Path.home() / ".codex" / "auth.json", {})
    codex_access_payload = decode_jwt_payload(codex_auth_payload.get("tokens", {}).get("access_token"))
    codex_session_status, codex_session_detail = describe_session(parse_unix_timestamp(codex_access_payload.get("exp")))
    if claude_cli_enabled:
        claude_session_status = "ready" if claude_cli_logged_in else "blocked"
        claude_session_detail = "Claude CLI login present" if claude_cli_logged_in else "Claude CLI login missing"
    else:
        claude_session_status = "ready" if anthropic_key else "blocked"
        claude_session_detail = "ANTHROPIC_API_KEY present" if anthropic_key else "ANTHROPIC_API_KEY missing"

    codex_binary_ready = _status_from_checks(codex.returncode == 0)
    claude_binary_ready = _status_from_checks(claude_sdk.returncode == 0)
    xcode_binary_ready = _status_from_checks(xcode.returncode == 0)

    codex_auth_ready = _status_from_checks(codex_auth)
    claude_auth_ready = _status_from_checks(claude_cli_logged_in if claude_cli_enabled else anthropic_key)

    codex_local_ready = _status_from_checks(codex_binary_ready == "ready", codex_auth_ready == "ready", codex_session_status == "ready")
    claude_local_ready = _status_from_checks(claude_binary_ready == "ready", claude_auth_ready == "ready", claude_session_status == "ready")
    codex_live = "skipped" if quick else _status_from_checks(bool(smoke_payload.get("codex_cli", {}).get("success")))
    claude_live = "skipped" if quick else _status_from_checks(bool(smoke_payload.get("claude_api", {}).get("success")))
    codex_ready = codex_local_ready
    claude_ready = claude_local_ready
    xcode_mcp_ready = _status_from_checks(xcode.returncode == 0, mcp_project)

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
            "notes": f"Session={claude_session_detail}. Smoke={'skipped' if quick else ('ok' if smoke_payload.get('claude_api', {}).get('success') else 'failed')}. Active transport={'claude-cli' if claude_cli_enabled else 'claude-api'}.",
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
            "status": _status_from_checks(claude_ready == "ready"),
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
            "status": _status_from_checks(claude_ready == "ready"),
            "blockers": [
                blocker
                for blocker, ok in {
                    "claude_cli_unavailable": claude_ready == "ready",
                    "claude_live_probe_failed": quick or claude_live == "ready",
                }.items()
                if not ok
            ],
        },
        "planning": {
            "status": _status_from_checks(claude_ready == "ready"),
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
            "status": _status_from_checks(codex_ready == "ready"),
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
            "status": _status_from_checks(playwright.returncode == 0, claude_ready == "ready"),
            "blockers": [
                blocker
                for blocker, ok in {
                    "playwright_missing": playwright.returncode == 0,
                    "claude_cli_unavailable": claude_ready == "ready",
                    "simctl_unstable": simctl_ok,
                    "native_ios_project_missing": (deps.current_target_workspace() / "ios").exists(),
                }.items()
                if not ok
            ],
        },
    }

    doctor_report = deps.reports_dir / "preflight_doctor.json"
    report_payload = {
        "all_ok": all(item["ok"] for item in checks),
        "checks": checks,
        "provider_smoke_report": str(smoke_report) if smoke_report else None,
        "providers": providers,
        "lanes": lanes,
        "evaluator_mode": "playwright_e2e_plus_visual_qa",
        "loaded_env_keys": loaded_env,
        "host_runtime_baseline": str(deps.host_runtime_baseline_file) if deps.host_runtime_baseline_file.exists() else None,
        "quick_mode": quick,
    }
    deps.save_json(doctor_report, report_payload)
    doctor_summary = write_doctor_summary(deps, report_payload)
    deps.append_ledger({"type": "doctor", "report": str(doctor_report), "all_ok": all(item["ok"] for item in checks)})
    deps.append_operator_journal(f"Preflight doctor wrote {doctor_report} and {doctor_summary}")
    return doctor_report
