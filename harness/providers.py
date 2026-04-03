from __future__ import annotations

import asyncio
import json
import os
import re
import subprocess
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from harness.runtime_env import load_project_env


RATE_LIMIT_PATTERNS = [
    re.compile(r"rate\s*limit", re.IGNORECASE),
    re.compile(r"too\s*many\s*requests", re.IGNORECASE),
    re.compile(r"429", re.IGNORECASE),
    re.compile(r"overloaded", re.IGNORECASE),
    re.compile(r"capacity", re.IGNORECASE),
]
RETRY_WAIT_PATTERN = re.compile(r"try\s*again\s*in\s*(\d+)", re.IGNORECASE)
CLAUDE_MODEL_ALIASES = {
    "claude-sonnet-4": "claude-sonnet-4-20250514",
    "claude-opus-4": "claude-opus-4-20250514",
    "claude-opus-4-1": "claude-opus-4-1-20250805",
}


def normalize_claude_model(model: str) -> str:
    return CLAUDE_MODEL_ALIASES.get(model, model)


@dataclass
class ProviderResult:
    success: bool
    output: str
    retries: int = 0
    error: str = ""


def is_rate_limited(output: str) -> tuple[bool, int]:
    for pattern in RATE_LIMIT_PATTERNS:
        if pattern.search(output):
            match = RETRY_WAIT_PATTERN.search(output)
            wait_seconds = int(match.group(1)) if match else 60
            return True, wait_seconds
    return False, 0


def run_claude_api(
    prompt: str,
    model: str,
    *,
    system_prompt: str | None = None,
    cwd: Path | None = None,
    json_schema: str | dict | None = None,
    timeout: int = 300,
    max_retries: int = 2,
) -> ProviderResult:
    project_root = Path(__file__).resolve().parent.parent
    load_project_env(project_root)
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return ProviderResult(False, "", error="ANTHROPIC_API_KEY is not set")
    model = normalize_claude_model(model)

    try:
        from claude_agent_sdk import ClaudeAgentOptions, query as sdk_query
    except ImportError:
        return _run_claude_rest_fallback(
            prompt,
            model,
            system_prompt=system_prompt,
            timeout=timeout,
            max_retries=max_retries,
        )

    sdk_timeout = min(timeout, 15)
    try:
        output = asyncio.run(
            asyncio.wait_for(
                _run_claude_agent_sdk_query(
                    sdk_query=sdk_query,
                    options_cls=ClaudeAgentOptions,
                    prompt=prompt,
                    model=model,
                    system_prompt=system_prompt,
                    cwd=cwd,
                    json_schema=json_schema,
                    api_key=api_key,
                ),
                timeout=sdk_timeout,
            )
        )
        if output:
            return ProviderResult(True, output, retries=0)
    except Exception as sdk_exc:
        print(f"[providers] SDK failed ({type(sdk_exc).__name__}), falling back to REST API")

    return _run_claude_rest_fallback(
        prompt,
        model,
        system_prompt=system_prompt,
        timeout=timeout,
        max_retries=max_retries,
    )


async def _run_claude_agent_sdk_query(
    *,
    sdk_query,
    options_cls,
    prompt: str,
    model: str,
    system_prompt: str | None,
    cwd: Path | None,
    json_schema: str | dict | None,
    api_key: str,
) -> str:
    options_kwargs: dict = {
        "model": model,
        "setting_sources": ["project", "local"],
        "thinking": {"type": "adaptive"},
        "effort": "high" if "opus" in model else "medium",
        "max_turns": 8,
        "system_prompt": {
            "type": "preset",
            "preset": "claude_code",
            **({"append": system_prompt} if system_prompt else {}),
        },
        "disallowed_tools": ["Write", "Edit", "MultiEdit", "Bash"],
        "env": {"ANTHROPIC_API_KEY": api_key},
    }

    if cwd:
        options_kwargs["cwd"] = str(cwd)
        options_kwargs["allowed_tools"] = ["Read", "Glob", "Grep"]
        options_kwargs["permission_mode"] = "default"
    else:
        options_kwargs["permission_mode"] = "plan"

    parsed_schema = _parse_json_schema(json_schema)
    if parsed_schema is not None:
        options_kwargs["output_format"] = {"type": "json_schema", "schema": parsed_schema}

    options = options_cls(**options_kwargs)
    chunks: list[str] = []

    async for message in sdk_query(prompt=prompt, options=options):
        content = getattr(message, "content", None)
        if not content:
            continue
        for block in content:
            if hasattr(block, "text") and getattr(block, "text", None):
                chunks.append(block.text)

    return "\n".join(chunk.strip() for chunk in chunks if chunk and chunk.strip()).strip()


def _parse_json_schema(json_schema: str | dict | None) -> dict | None:
    if json_schema is None:
        return None
    if isinstance(json_schema, dict):
        return json_schema
    try:
        return json.loads(json_schema)
    except json.JSONDecodeError:
        return None


def _run_claude_rest_fallback(
    prompt: str,
    model: str,
    *,
    system_prompt: str | None = None,
    timeout: int = 300,
    max_retries: int = 2,
    prior_error: str | None = None,
) -> ProviderResult:
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return ProviderResult(False, "", error="ANTHROPIC_API_KEY is not set")
    model = normalize_claude_model(model)

    request_body = {
        "model": model,
        "max_tokens": 4096,
        "messages": [{"role": "user", "content": prompt}],
    }
    if system_prompt:
        request_body["system"] = system_prompt

    payload = json.dumps(request_body).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
    }

    for attempt in range(max_retries + 1):
        req = urllib.request.Request(
            "https://api.anthropic.com/v1/messages",
            data=payload,
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                raw = response.read().decode("utf-8")
                data = json.loads(raw)
                text_chunks = [
                    block.get("text", "")
                    for block in data.get("content", [])
                    if block.get("type") == "text"
                ]
                output = "\n".join(chunk for chunk in text_chunks if chunk).strip()
                if output:
                    return ProviderResult(True, output, retries=attempt)
                return ProviderResult(False, "", retries=attempt, error="Empty Claude API response")
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            limited, wait_seconds = is_rate_limited(body)
            if limited and attempt < max_retries:
                time.sleep(wait_seconds)
                continue
            detail = body or str(exc)
            if prior_error:
                detail = f"{prior_error}\nREST fallback HTTP error: {detail}"
            return ProviderResult(False, "", retries=attempt, error=detail)
        except urllib.error.URLError as exc:
            detail = str(exc)
            if prior_error:
                detail = f"{prior_error}\nREST fallback URL error: {detail}"
            return ProviderResult(False, "", retries=attempt, error=detail)
        except Exception as exc:
            detail = str(exc)
            if prior_error:
                detail = f"{prior_error}\nREST fallback exception: {detail}"
            return ProviderResult(False, "", retries=attempt, error=detail)

    error = "Claude REST fallback retries exhausted"
    if prior_error:
        error = f"{prior_error}\n{error}"
    return ProviderResult(False, "", retries=max_retries, error=error)


def run_cli(
    cmd: list[str],
    *,
    cwd: Path | None = None,
    timeout: int = 300,
    max_retries: int = 2,
) -> ProviderResult:
    for attempt in range(max_retries + 1):
        try:
            proc = subprocess.run(
                cmd,
                cwd=str(cwd) if cwd else None,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
        except FileNotFoundError as exc:
            return ProviderResult(False, "", retries=attempt, error=str(exc))
        except subprocess.TimeoutExpired:
            return ProviderResult(False, "", retries=attempt, error=f"timeout after {timeout}s")
        except Exception as exc:
            return ProviderResult(False, "", retries=attempt, error=str(exc))

        combined = proc.stdout + proc.stderr
        limited, wait_seconds = is_rate_limited(combined)
        if limited and attempt < max_retries:
            time.sleep(wait_seconds)
            continue

        if proc.returncode == 0 and proc.stdout.strip():
            return ProviderResult(True, proc.stdout, retries=attempt)
        if proc.stdout.strip():
            return ProviderResult(True, proc.stdout, retries=attempt)
        if proc.returncode == 0 and proc.stderr.strip():
            return ProviderResult(True, proc.stderr, retries=attempt)

        if attempt == max_retries:
            return ProviderResult(False, "", retries=attempt, error=combined.strip())

    return ProviderResult(False, "", retries=max_retries, error="CLI retries exhausted")
