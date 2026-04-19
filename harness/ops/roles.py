"""Role orchestration primitives: prompt assembly, dispatch, validation.

Extracted from orchestrator.py so other harnesses can reuse the
role-contract-driven runtime without pulling in iOS pipeline code.

The public surface is:

- ``RoleDeps`` — dependency bundle (paths, io, dispatch, ledger writers).
- ``build_role_prompt`` — assembles the prompt from team manifest + artifacts.
- ``validate_role_output`` — pure health check against empty/short/error-payload output.
- ``load_role_contract`` / ``role_output_schema`` / ``product_schema`` / ``plan_schema``
  — declarative per-role contracts living under ``agents/<dir>/contract.json``.
- ``run_role`` — dispatch a role, validate, persist, and record a structured
  ledger entry (with duration, prompt/output sha256, model, health).
"""

from __future__ import annotations

import hashlib
import json
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from harness.ops.artifacts import build_artifact_snapshot
from harness.ops.json_parse import parse_json_output


@dataclass
class RoleDeps:
    reports_dir: Path
    agents_dir: Path
    team_manifest_file: Path
    roles: dict
    dispatch: Callable
    read_blackboard: Callable
    task_type_enum: Any
    save_text: Callable
    save_json: Callable
    load_json: Callable
    append_ledger: Callable
    append_operator_journal: Callable


_ROLE_CONTRACT_CACHE: dict[str, dict[str, Any]] = {}

_ROLE_OUTPUT_ERROR_PATTERNS = (
    "credit balance is too low",
    "out of extra usage",
    "rate limit",
    "quota exceeded",
    "insufficient credit",
    "service unavailable",
    "too many requests",
    "usage limit reached",
    "resets 9pm",
    "resets at",
)


def validate_role_output(
    role_name: str,
    task_type: Any,
    text: str,
    json_schema: dict | None,
) -> None:
    """Fail fast if a role's response is empty, too short, or a provider error payload.

    Guards against the 2026-04-09 class of incident where credit-exhaustion
    strings silently overwrote architecture reports because the CLI returned
    success=True with an error body.
    """
    stripped = (text or "").strip()
    if not stripped:
        raise RuntimeError(
            f"{role_name} produced empty output for {task_type.value}"
        )
    lowered = stripped.lower()
    for pattern in _ROLE_OUTPUT_ERROR_PATTERNS:
        if pattern in lowered:
            raise RuntimeError(
                f"{role_name} returned provider error payload for "
                f"{task_type.value}: {stripped[:200]!r}"
            )
    min_length = 64 if json_schema else 200
    if len(stripped) < min_length:
        raise RuntimeError(
            f"{role_name} output too short ({len(stripped)} chars, "
            f"min {min_length}) for {task_type.value}: {stripped[:200]!r}"
        )


def load_role_contract(deps: RoleDeps, role_id: str) -> dict[str, Any]:
    if role_id in _ROLE_CONTRACT_CACHE:
        return _ROLE_CONTRACT_CACHE[role_id]
    if deps.agents_dir.exists():
        for contract_path in sorted(deps.agents_dir.glob("*/contract.json")):
            data = deps.load_json(contract_path, {})
            if isinstance(data, dict) and data.get("role_id") == role_id:
                _ROLE_CONTRACT_CACHE[role_id] = data
                return data
    _ROLE_CONTRACT_CACHE[role_id] = {}
    return {}


def role_output_schema(deps: RoleDeps, role_id: str) -> dict[str, Any] | None:
    contract = load_role_contract(deps, role_id)
    schema = contract.get("output", {}).get("json_schema") if contract else None
    return schema if isinstance(schema, dict) else None


def product_schema(deps: RoleDeps) -> dict[str, Any]:
    schema = role_output_schema(deps, "product_lead")
    if schema:
        return schema
    raise RuntimeError(
        "product_lead contract is missing agents/product-lead/contract.json "
        "or its output.json_schema. Declarative contracts are required."
    )


def plan_schema(deps: RoleDeps) -> dict[str, Any]:
    schema = role_output_schema(deps, "delivery_lead")
    if schema:
        return schema
    raise RuntimeError(
        "delivery_lead contract is missing agents/delivery-lead/contract.json "
        "or its output.json_schema. Declarative contracts are required."
    )


def build_role_prompt(
    deps: RoleDeps,
    role_name: str,
    brief: str,
    artifacts: dict[str, Path],
    json_schema: dict[str, Any] | None = None,
    task_type: Any | None = None,
) -> str:
    manifest = deps.load_json(deps.team_manifest_file, {})
    role = next((item for item in manifest.get("roles", []) if item.get("id") == role_name), {})
    responsibilities = "\n".join(f"- {item}" for item in role.get("responsibilities", []))
    provider = role.get("provider")
    relevant_artifacts = artifacts
    blackboard_chars = 1800
    artifact_chars = 1600
    TaskType = deps.task_type_enum
    codex_code_tasks = {
        TaskType.IOS_IMPLEMENTATION,
        TaskType.BUG_FIX,
        TaskType.UI_CODING,
        TaskType.BUSINESS_LOGIC,
    }
    if provider == "codex_cli" and task_type in codex_code_tasks:
        preferred_names = [
            "architecture_report",
            "planning_report",
            "product_report",
            "ui_ux_screen_contract",
            "constraints_input",
            "acceptance_input",
            "design_input",
            "hig_guardrails",
            "native_ios_strategy",
            "blackboard_compact",
        ]
        relevant_artifacts = {name: artifacts[name] for name in preferred_names if name in artifacts}
        blackboard_chars = 600
        artifact_chars = 450
    artifact_lines = "\n".join(f"- {name}: {path}" for name, path in relevant_artifacts.items())
    artifact_snapshot = build_artifact_snapshot(relevant_artifacts, max_chars_per_artifact=artifact_chars)
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
    # Inject few-shot calibration for evaluator roles
    calibration_section = ""
    evaluator_roles = {"red_team_reviewer", "hig_guardian", "visual_qa"}
    if role_name in evaluator_roles:
        try:
            from harness.eval_calibration import get_calibration_prompt
            calibration = get_calibration_prompt(role_name)
            if calibration:
                calibration_section = f"\nEVALUATION CALIBRATION:\n{calibration}\n"
        except ImportError:
            pass

    return f"""ROLE: {role.get('title', role_name)}

RESPONSIBILITIES:
{responsibilities or "- Follow the harness contract."}
{calibration_section}
CURRENT BRIEF:
{brief}

RECENT BLACKBOARD:
{deps.read_blackboard(blackboard_chars)}

AVAILABLE ARTIFACTS:
{artifact_lines or "- none"}

ARTIFACT CONTENT SNAPSHOTS:
{artifact_snapshot or "- none"}
{schema_section}
"""


def run_role(
    deps: RoleDeps,
    role_name: str,
    task_type: Any,
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
    prompt = build_role_prompt(deps, role_name, brief, artifacts, json_schema, task_type)
    extension = ".json" if json_schema else ".md"
    stem = report_stem or f"{role_name}_{task_type.value}"
    output_path = deps.reports_dir / f"{stem}{extension}"
    role_config = deps.roles.get(role_name)
    model_name = role_config.model if role_config else None
    prompt_sha = hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:16]
    dispatch_start = time.monotonic()
    result = deps.dispatch(
        task_type,
        prompt,
        cwd=cwd,
        image_path=image_path,
        json_schema=json_schema,
        timeout=timeout,
        preferred_role=role_name,
        allow_fallback_roles=allow_fallback_roles,
    )
    duration_ms = int((time.monotonic() - dispatch_start) * 1000)

    def _ledger_base(health: str, extra: dict[str, Any] | None = None) -> dict[str, Any]:
        base: dict[str, Any] = {
            "type": "role_output",
            "role": role_name,
            "task_type": task_type.value,
            "model": model_name,
            "duration_ms": duration_ms,
            "prompt_sha256_16": prompt_sha,
            "output_bytes": len(result.output or ""),
            "health": health,
            "cwd": str(cwd) if cwd else None,
        }
        if extra:
            base.update(extra)
        return base

    if not result.success:
        failure_path = deps.reports_dir / f"{stem}.error.txt"
        failure_text = result.output.strip() or f"{role_name} failed for {task_type.value} with no stdout/stderr payload."
        deps.save_text(failure_path, failure_text)
        deps.append_ledger(_ledger_base("dispatch_failure", {"report": str(failure_path), "error": failure_text[:240]}))
        raise RuntimeError(f"{role_name} failed for {task_type.value}: {failure_text[:200]}")

    try:
        validate_role_output(role_name, task_type, result.output, json_schema)
    except RuntimeError as exc:
        unhealthy_path = deps.reports_dir / f"{stem}.unhealthy.txt"
        deps.save_text(unhealthy_path, result.output or "[empty]")
        deps.append_ledger(_ledger_base("unhealthy_output", {"report": str(unhealthy_path), "reason": str(exc)[:240]}))
        raise

    if json_schema:
        try:
            parsed = parse_json_output(result.output)
        except Exception as exc:
            raw_output_path = deps.reports_dir / f"{stem}.raw.txt"
            deps.save_text(raw_output_path, result.output)
            deps.append_ledger(_ledger_base("json_parse_failure", {"report": str(raw_output_path), "error": str(exc)[:240]}))
            raise RuntimeError(
                f"{role_name} returned invalid JSON for {task_type.value}. "
                f"Raw output saved to {raw_output_path}. Parser error: {exc}"
            ) from exc
        deps.save_json(output_path, parsed)
    else:
        deps.save_text(output_path, result.output)

    output_sha = hashlib.sha256((result.output or "").encode("utf-8")).hexdigest()[:16]
    deps.append_ledger(_ledger_base("ok", {"report": str(output_path), "output_sha256_16": output_sha}))
    deps.append_operator_journal(f"{role_name} completed {task_type.value} -> {output_path.name}")
    return output_path
