#!/usr/bin/env python3
"""
master_router.py - Company-style multi-agent model router.

Routing policy (2026-04-10):
- Claude CLI handles all reasoning, planning, review, HIG audit, and visual QA.
  Model tier scales by task difficulty: opus-4-6 for heavy reasoning,
  sonnet-4-6 for standard work, haiku-4-5 for ops/compaction.
- Codex CLI handles iOS implementation (UI + logic) in worktrees.
- Gemini is no longer used.
"""

from __future__ import annotations

import os
import time
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Optional

from harness.company import load_manifest, load_providers, load_roles
from harness.providers import ProviderResult, normalize_claude_model, run_claude_api, run_claude_cli, run_cli

FACTORY_DIR = Path(__file__).parent.resolve()
CONTEXT_DIR = FACTORY_DIR / "context_harness"
BLACKBOARD_FILE = CONTEXT_DIR / "blackboard.md"
MANIFEST_FILE = CONTEXT_DIR / "team_manifest.json"

MANIFEST = load_manifest(MANIFEST_FILE)
PROVIDERS = load_providers(MANIFEST)
ROLES = load_roles(MANIFEST)
TASK_ROLE_ORDER: dict[str, list[str]] = {
    "product_research": ["product_lead", "delivery_lead"],
    "market_research": ["product_lead", "delivery_lead"],
    "planning": ["delivery_lead", "product_lead"],
    "prd_generation": ["delivery_lead", "product_lead"],
    "architecture": ["ios_architect", "delivery_lead"],
    "task_allocation": ["delivery_lead", "ios_architect"],
    "ios_implementation": ["ios_ui_builder", "ios_logic_builder"],
    "ui_coding": ["ios_ui_builder", "ios_logic_builder"],
    "business_logic": ["ios_logic_builder", "ios_ui_builder"],
    "code_review": ["red_team_reviewer", "ios_architect"],
    "hig_audit": ["hig_guardian", "visual_qa"],
    "visual_qa": ["visual_qa", "hig_guardian"],
    "e2e_test_gen": ["ios_logic_builder", "ios_ui_builder"],
    "bug_fix": ["ios_logic_builder", "ios_ui_builder"],
    "sprint_eval": ["red_team_reviewer", "visual_qa"],
    "documentation": ["delivery_lead", "product_lead"],
    "boilerplate": ["ios_ui_builder", "ios_logic_builder"],
    "arbitration": ["delivery_lead", "ios_architect"],
}

class TaskType(Enum):
    PRODUCT_RESEARCH = "product_research"
    MARKET_RESEARCH = "market_research"
    PLANNING = "planning"
    PRD_GENERATION = "prd_generation"
    ARCHITECTURE = "architecture"
    TASK_ALLOCATION = "task_allocation"
    IOS_IMPLEMENTATION = "ios_implementation"
    UI_CODING = "ui_coding"
    BUSINESS_LOGIC = "business_logic"
    CODE_REVIEW = "code_review"
    HIG_AUDIT = "hig_audit"
    VISUAL_QA = "visual_qa"
    E2E_TEST_GEN = "e2e_test_gen"
    BUG_FIX = "bug_fix"
    SPRINT_EVAL = "sprint_eval"
    DOCUMENTATION = "documentation"
    BOILERPLATE = "boilerplate"
    ARBITRATION = "arbitration"


TASK_TIMEOUTS: dict[TaskType, int] = {
    TaskType.PRODUCT_RESEARCH: 180,
    TaskType.MARKET_RESEARCH: 180,
    TaskType.PLANNING: 240,
    TaskType.PRD_GENERATION: 240,
    TaskType.ARCHITECTURE: 900,
    TaskType.TASK_ALLOCATION: 240,
    TaskType.IOS_IMPLEMENTATION: 900,
    TaskType.UI_CODING: 900,
    TaskType.BUSINESS_LOGIC: 900,
    TaskType.CODE_REVIEW: 720,
    TaskType.HIG_AUDIT: 600,
    TaskType.VISUAL_QA: 600,
    TaskType.E2E_TEST_GEN: 600,
    TaskType.BUG_FIX: 1200,
    TaskType.SPRINT_EVAL: 300,
    TaskType.DOCUMENTATION: 180,
    TaskType.BOILERPLATE: 600,
    TaskType.ARBITRATION: 240,
}


@dataclass
class AgentResult:
    success: bool
    output: str
    model_used: str
    cli_used: str
    retries: int = 0
    role_used: str = ""


def _provider_name(provider_id: str) -> str:
    if provider_id == "claude_api":
        return "claude-cli" if _claude_cli_enabled() else "claude-api"
    if provider_id == "codex_cli":
        return "codex"
    return provider_id


def _claude_cli_enabled() -> bool:
    return os.environ.get("FACTORY_CLAUDE_USE_CLI", "").strip().lower() in {"1", "true", "yes", "on"}


def _resolve_model(role_id: str) -> str:
    role = ROLES[role_id]
    overrides = {
        "product_lead": os.environ.get("FACTORY_CLAUDE_STRATEGY_MODEL"),
        "delivery_lead": os.environ.get("FACTORY_CLAUDE_DELIVERY_MODEL"),
        "ios_architect": os.environ.get("FACTORY_CLAUDE_STRATEGY_MODEL"),
        "ios_ui_builder": os.environ.get("FACTORY_CODEX_PRIMARY_MODEL"),
        "ios_logic_builder": os.environ.get("FACTORY_CODEX_PRIMARY_MODEL"),
        "red_team_reviewer": os.environ.get("FACTORY_CLAUDE_DELIVERY_MODEL"),
        "hig_guardian": os.environ.get("FACTORY_CLAUDE_DELIVERY_MODEL"),
        "visual_qa": os.environ.get("FACTORY_CLAUDE_DELIVERY_MODEL"),
        "platform_operator": os.environ.get("FACTORY_CLAUDE_OPS_MODEL"),
    }
    if overrides.get(role_id):
        model = overrides[role_id]
        if role.provider == "claude_api":
            return normalize_claude_model(model)
        return model

    provider = PROVIDERS.get(role.provider)
    if not provider:
        return role.model or "unknown"

    provider_models = provider.models
    if role.model:
        if role.provider == "claude_api":
            return normalize_claude_model(role.model)
        return role.model
    if role.provider == "claude_api":
        model = provider_models.get("default") or "claude-sonnet-4-6"
        return normalize_claude_model(model)
    if role.provider == "codex_cli":
        env_override = provider_models.get("override_env")
        if env_override and os.environ.get(env_override):
            return os.environ[env_override]
        return provider_models.get("default") or "gpt-5.4"
    return role.model or "unknown"


# Claude model tier by task difficulty. Heavy reasoning → opus, standard → sonnet,
# ops/compaction → haiku. Codex is not tiered here (codex roles own their model).
_CLAUDE_HEAVY_TASKS = {
    TaskType.PRODUCT_RESEARCH,
    TaskType.MARKET_RESEARCH,
    TaskType.ARCHITECTURE,
    TaskType.ARBITRATION,
    TaskType.CODE_REVIEW,
}
_CLAUDE_OPS_TASKS = {
    TaskType.DOCUMENTATION,
}


def _resolve_model_for_task(role_id: str, task_type: TaskType) -> str:
    role = ROLES[role_id]
    model = _resolve_model(role_id)
    if role.provider != "claude_api":
        return model

    provider = PROVIDERS.get(role.provider)
    provider_models = provider.models if provider else {}
    heavy = os.environ.get("FACTORY_CLAUDE_STRATEGY_MODEL") or provider_models.get("deep_review") or "claude-opus-4-6"
    ops = os.environ.get("FACTORY_CLAUDE_OPS_MODEL") or provider_models.get("ops") or "claude-haiku-4-5-20251001"
    if task_type in _CLAUDE_HEAVY_TASKS:
        return normalize_claude_model(heavy)
    if task_type in _CLAUDE_OPS_TASKS:
        return normalize_claude_model(ops)
    return model


def _build_codex_cmd(
    prompt: str,
    *,
    model: str,
    cwd: Optional[Path],
    image_path: Optional[str],
    full_auto: bool = True,
) -> list[str]:
    cmd = ["codex", "exec", prompt, "-m", model]
    if full_auto:
        cmd.append("--full-auto")
    if cwd:
        cmd += ["-C", str(cwd)]
    if image_path:
        cmd += ["-i", image_path]
    return cmd


def _build_codex_review_cmd(*, cwd: Optional[Path], model: str) -> list[str]:
    cmd = ["codex", "exec", "review", "-m", model]
    if cwd:
        cmd += ["-C", str(cwd)]
    cmd.append("--full-auto")
    return cmd


def _run_role(
    role_id: str,
    prompt: str,
    *,
    cwd: Optional[Path],
    system_prompt: Optional[str],
    image_path: Optional[str],
    json_schema: Optional[str],
    timeout: int,
    task_type: TaskType,
) -> AgentResult:
    role = ROLES[role_id]
    provider = PROVIDERS[role.provider]
    model = _resolve_model_for_task(role_id, task_type)

    result: ProviderResult
    if provider.provider_id == "claude_api":
        effective_prompt = prompt
        if image_path:
            effective_prompt = f"[Image attachment: {image_path}]\n\n{prompt}"
        if _claude_cli_enabled() or provider.transport == "cli":
            result = run_claude_cli(
                effective_prompt,
                model=model,
                system_prompt=system_prompt,
                cwd=cwd,
                json_schema=json_schema,
                timeout=timeout,
            )
        else:
            result = run_claude_api(
                effective_prompt,
                model=model,
                system_prompt=system_prompt,
                cwd=cwd,
                json_schema=json_schema,
                timeout=timeout,
            )
    elif provider.provider_id == "codex_cli":
        if task_type == TaskType.CODE_REVIEW:
            cmd = _build_codex_review_cmd(cwd=cwd, model=model)
        else:
            cmd = _build_codex_cmd(
                prompt,
                model=model,
                cwd=cwd,
                image_path=image_path,
            )
        result = run_cli(cmd, cwd=cwd, timeout=timeout)
    else:
        result = ProviderResult(False, "", error=f"Unsupported provider: {provider.provider_id}")

    if result.success:
        _append_blackboard(task_type, role_id, model, result.output[:500])
        return AgentResult(
            success=True,
            output=result.output,
            model_used=model,
            cli_used=_provider_name(provider.provider_id),
            retries=result.retries,
            role_used=role_id,
        )

    return AgentResult(
        success=False,
        output=result.error,
        model_used=model,
        cli_used=_provider_name(provider.provider_id),
        retries=result.retries,
        role_used=role_id,
    )


def dispatch(
    task_type: TaskType,
    prompt: str,
    cwd: Optional[Path] = None,
    system_prompt: Optional[str] = None,
    image_path: Optional[str] = None,
    json_schema: Optional[str] = None,
    timeout: Optional[int] = None,
    preferred_role: Optional[str] = None,
    allow_fallback_roles: bool = True,
    debug: bool = False,
) -> AgentResult:
    del debug

    role_order = list(TASK_ROLE_ORDER.get(task_type.value, []))
    if not role_order:
        return AgentResult(False, f"No route configured for {task_type.value}", "none", "none")

    if preferred_role:
        if not allow_fallback_roles and preferred_role in ROLES:
            role_order = [preferred_role]
        elif preferred_role in role_order:
            role_order = [preferred_role] + [role for role in role_order if role != preferred_role]
        elif preferred_role in ROLES:
            role_order = [preferred_role] + role_order

    effective_timeout = timeout or TASK_TIMEOUTS.get(task_type, 300)

    for role_id in role_order:
        tag = f"[Router] {task_type.value} -> {role_id}:{_resolve_model_for_task(role_id, task_type)}"
        print(f"\n{tag}")
        result = _run_role(
            role_id,
            prompt,
            cwd=cwd,
            system_prompt=system_prompt,
            image_path=image_path,
            json_schema=json_schema,
            timeout=effective_timeout,
            task_type=task_type,
        )
        if result.success:
            return result
        print(f"{tag} failed: {result.output[:200]}")

    return AgentResult(False, "", model_used="none", cli_used="none")


def _append_blackboard(task_type: TaskType, role_id: str, model: str, summary: str):
    os.makedirs(CONTEXT_DIR, exist_ok=True)
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    entry = (
        f"\n---\n"
        f"**[{timestamp}]** `{task_type.value}` via `{role_id}:{model}`\n"
        f"{summary.strip()[:300]}\n"
    )
    with open(BLACKBOARD_FILE, "a", encoding="utf-8") as handle:
        handle.write(entry)


def read_blackboard(max_chars: int = 3000) -> str:
    if BLACKBOARD_FILE.exists():
        text = BLACKBOARD_FILE.read_text(encoding="utf-8")
        return text[-max_chars:] if len(text) > max_chars else text
    return ""


def reset_blackboard():
    os.makedirs(CONTEXT_DIR, exist_ok=True)
    with open(BLACKBOARD_FILE, "w", encoding="utf-8") as handle:
        handle.write("# Blackboard - Agent Shared Context\n\n")


def research(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.MARKET_RESEARCH, prompt, **kwargs)


def product_research(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.PRODUCT_RESEARCH, prompt, **kwargs)


def plan_work(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.PLANNING, prompt, **kwargs)


def generate_prd(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.PRD_GENERATION, prompt, **kwargs)


def design_architecture(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.ARCHITECTURE, prompt, **kwargs)


def allocate_tasks(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.TASK_ALLOCATION, prompt, **kwargs)


def implement_ios(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.IOS_IMPLEMENTATION, prompt, cwd=cwd, **kwargs)


def code_ui(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.UI_CODING, prompt, cwd=cwd, **kwargs)


def code_logic(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.BUSINESS_LOGIC, prompt, cwd=cwd, **kwargs)


def review_code(prompt: str = "Review the codebase for bugs, HIG regressions, and release risks.", cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(
        TaskType.CODE_REVIEW,
        prompt,
        cwd=cwd,
        **kwargs,
    )


def audit_hig(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.HIG_AUDIT, prompt, **kwargs)


def visual_qa(prompt: str, image_path: str = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.VISUAL_QA, prompt, image_path=image_path, **kwargs)


def generate_tests(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.E2E_TEST_GEN, prompt, cwd=cwd, **kwargs)


def fix_bug(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.BUG_FIX, prompt, cwd=cwd, **kwargs)


def evaluate_sprint(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.SPRINT_EVAL, prompt, **kwargs)


def write_docs(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.DOCUMENTATION, prompt, **kwargs)


def scaffold(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.BOILERPLATE, prompt, cwd=cwd, **kwargs)


def arbitrate(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.ARBITRATION, prompt, **kwargs)


if __name__ == "__main__":
    print("=== Company Harness Routing Table ===\n")
    for task_name, role_order in TASK_ROLE_ORDER.items():
        primary = role_order[0]
        fallbacks = ", ".join(role_order[1:]) or "none"
        print(f"  {task_name:20s} -> {primary:20s} | fallback: {fallbacks}")
