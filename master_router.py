#!/usr/bin/env python3
"""
master_router.py — Triad Multi-Agent Model Router (2026-04-01)

3사(Claude/Gemini/Codex) CLI를 task 유형에 따라 최적 모델로 라우팅한다.
Pro 멤버십 토큰 기반 (API 키 아님). 모든 호출은 subprocess headless 모드.
"""

import os
import time
import re
import subprocess
from pathlib import Path
from dataclasses import dataclass
from typing import Optional
from enum import Enum

FACTORY_DIR = Path(__file__).parent.resolve()
CONTEXT_DIR = FACTORY_DIR / "context_harness"
BLACKBOARD_FILE = CONTEXT_DIR / "blackboard.md"

# ---------------------------------------------------------------------------
# Task → Model 라우팅 테이블
# ---------------------------------------------------------------------------

class TaskType(Enum):
    MARKET_RESEARCH = "market_research"
    PRD_GENERATION = "prd_generation"
    ARCHITECTURE = "architecture"
    UI_CODING = "ui_coding"
    BUSINESS_LOGIC = "business_logic"
    CODE_REVIEW = "code_review"
    VISUAL_QA = "visual_qa"
    E2E_TEST_GEN = "e2e_test_gen"
    BUG_FIX = "bug_fix"
    SPRINT_EVAL = "sprint_eval"
    DOCUMENTATION = "documentation"
    BOILERPLATE = "boilerplate"
    ARBITRATION = "arbitration"


@dataclass
class ModelConfig:
    cli: str            # "claude" | "gemini" | "codex"
    model: str          # model identifier
    tier: str           # "high" | "mid" | "low" | "vision" | "search"
    max_retries: int = 2
    timeout: int = 300  # seconds


# 라우팅 맵: TaskType → 1차 모델 → fallback 모델
ROUTING_TABLE: dict[TaskType, list[ModelConfig]] = {
    # Gemini: 웹 그라운딩 + 실시간 검색 최적
    TaskType.MARKET_RESEARCH: [
        ModelConfig(cli="gemini", model="gemini-2.5-pro", tier="search"),
        ModelConfig(cli="claude", model="opus", tier="high"),
    ],
    # Opus: 장문 추론 + 구조화된 문서 생성
    TaskType.PRD_GENERATION: [
        ModelConfig(cli="claude", model="opus", tier="high"),
        ModelConfig(cli="gemini", model="gemini-2.5-pro", tier="search"),
    ],
    # Opus: 아키텍처 의사결정, 트레이드오프 분석
    TaskType.ARCHITECTURE: [
        ModelConfig(cli="claude", model="opus", tier="high"),
        ModelConfig(cli="codex", model="o3", tier="high"),
    ],
    # Sonnet: 컴포넌트 수준 코딩의 속도/품질 밸런스
    TaskType.UI_CODING: [
        ModelConfig(cli="claude", model="sonnet", tier="mid"),
        ModelConfig(cli="codex", model="o4-mini", tier="mid"),
    ],
    # Sonnet: 도메인 로직 구현
    TaskType.BUSINESS_LOGIC: [
        ModelConfig(cli="claude", model="sonnet", tier="mid"),
        ModelConfig(cli="codex", model="o4-mini", tier="mid"),
    ],
    # Codex review: 코드 리뷰 전용 기능 활용
    TaskType.CODE_REVIEW: [
        ModelConfig(cli="codex", model="o3", tier="high"),
        ModelConfig(cli="claude", model="opus", tier="high"),
    ],
    # Gemini: 멀티모달 비전 최강
    TaskType.VISUAL_QA: [
        ModelConfig(cli="gemini", model="gemini-2.5-pro", tier="vision"),
        ModelConfig(cli="claude", model="opus", tier="high"),
    ],
    # Sonnet: 테스트 코드 생성
    TaskType.E2E_TEST_GEN: [
        ModelConfig(cli="claude", model="sonnet", tier="mid"),
        ModelConfig(cli="codex", model="o4-mini", tier="mid"),
    ],
    # Sonnet: 빠른 턴어라운드, 스택트레이스 분석
    TaskType.BUG_FIX: [
        ModelConfig(cli="claude", model="sonnet", tier="mid"),
        ModelConfig(cli="claude", model="opus", tier="high"),
    ],
    # Gemini Flash: 빠르고 저렴한 체크리스트 검증
    TaskType.SPRINT_EVAL: [
        ModelConfig(cli="gemini", model="gemini-2.5-flash", tier="low"),
        ModelConfig(cli="claude", model="haiku", tier="low"),
    ],
    # Haiku: 단순 산문 생성
    TaskType.DOCUMENTATION: [
        ModelConfig(cli="claude", model="haiku", tier="low"),
        ModelConfig(cli="gemini", model="gemini-2.5-flash", tier="low"),
    ],
    # Haiku: 템플릿/스캐폴딩
    TaskType.BOILERPLATE: [
        ModelConfig(cli="claude", model="haiku", tier="low"),
        ModelConfig(cli="gemini", model="gemini-2.5-flash", tier="low"),
    ],
    # Opus: 교착상태 중재 — 최고 추론력 필요
    TaskType.ARBITRATION: [
        ModelConfig(cli="claude", model="opus", tier="high"),
    ],
}

# ---------------------------------------------------------------------------
# Rate Limit 감지 패턴
# ---------------------------------------------------------------------------

RATE_LIMIT_PATTERNS = [
    re.compile(r"rate\s*limit", re.IGNORECASE),
    re.compile(r"too\s*many\s*requests", re.IGNORECASE),
    re.compile(r"429", re.IGNORECASE),
    re.compile(r"overloaded", re.IGNORECASE),
    re.compile(r"capacity", re.IGNORECASE),
]
RETRY_WAIT_PATTERN = re.compile(r"try\s*again\s*in\s*(\d+)", re.IGNORECASE)


def is_rate_limited(output: str) -> tuple[bool, int]:
    for pat in RATE_LIMIT_PATTERNS:
        if pat.search(output):
            match = RETRY_WAIT_PATTERN.search(output)
            wait = int(match.group(1)) if match else 60
            return True, wait
    return False, 0


# ---------------------------------------------------------------------------
# CLI 빌더: 각 CLI의 headless 명령어 구성
# ---------------------------------------------------------------------------

def build_claude_cmd(
    prompt: str,
    model: str = "sonnet",
    system_prompt: Optional[str] = None,
    json_schema: Optional[str] = None,
    skip_permissions: bool = True,
    fallback_model: Optional[str] = None,
) -> list[str]:
    cmd = ["claude", "-p", prompt, "--model", model, "--output-format", "text"]
    if system_prompt:
        cmd += ["--system-prompt", system_prompt]
    if json_schema:
        cmd += ["--json-schema", json_schema]
    if fallback_model:
        cmd += ["--fallback-model", fallback_model]
    if skip_permissions:
        cmd.append("--dangerously-skip-permissions")
    return cmd


def build_gemini_cmd(
    prompt: str,
    model: str = "gemini-2.5-pro",
    yolo: bool = True,
) -> list[str]:
    cmd = ["gemini", "-p", prompt, "-m", model]
    if yolo:
        cmd.append("-y")
    return cmd


def build_codex_cmd(
    prompt: str,
    model: str = "o3",
    cwd: Optional[Path] = None,
    full_auto: bool = True,
    image_path: Optional[str] = None,
) -> list[str]:
    cmd = ["codex", "exec", prompt, "-m", model]
    if full_auto:
        cmd.append("--full-auto")
    if cwd:
        cmd += ["-C", str(cwd)]
    if image_path:
        cmd += ["-i", image_path]
    return cmd


def build_codex_review_cmd(cwd: Optional[Path] = None) -> list[str]:
    cmd = ["codex", "exec", "review"]
    if cwd:
        cmd += ["-C", str(cwd)]
    cmd.append("--full-auto")
    return cmd


# ---------------------------------------------------------------------------
# 통합 실행기
# ---------------------------------------------------------------------------

@dataclass
class AgentResult:
    success: bool
    output: str
    model_used: str
    cli_used: str
    retries: int = 0


def dispatch(
    task_type: TaskType,
    prompt: str,
    cwd: Optional[Path] = None,
    system_prompt: Optional[str] = None,
    image_path: Optional[str] = None,
    json_schema: Optional[str] = None,
    timeout: Optional[int] = None,
    debug: bool = False,
) -> AgentResult:
    """
    TaskType에 따라 최적 모델을 선택하고, 실패 시 fallback 체인을 따른다.
    """
    models = ROUTING_TABLE.get(task_type, ROUTING_TABLE[TaskType.BUSINESS_LOGIC])

    for model_cfg in models:
        effective_timeout = timeout or model_cfg.timeout

        for attempt in range(model_cfg.max_retries + 1):
            # CLI별 커맨드 빌드
            if model_cfg.cli == "claude":
                cmd = build_claude_cmd(
                    prompt=prompt,
                    model=model_cfg.model,
                    system_prompt=system_prompt,
                    json_schema=json_schema,
                )
            elif model_cfg.cli == "gemini":
                # Vision task: 이미지 경로를 프롬프트에 포함
                effective_prompt = prompt
                if image_path:
                    effective_prompt = f"[Image: {image_path}]\n\n{prompt}"
                cmd = build_gemini_cmd(
                    prompt=effective_prompt,
                    model=model_cfg.model,
                )
            elif model_cfg.cli == "codex":
                if task_type == TaskType.CODE_REVIEW:
                    cmd = build_codex_review_cmd(cwd=cwd)
                else:
                    cmd = build_codex_cmd(
                        prompt=prompt,
                        model=model_cfg.model,
                        cwd=cwd,
                        image_path=image_path,
                    )
            else:
                continue

            tag = f"[Router] {model_cfg.cli}:{model_cfg.model} (attempt {attempt+1})"
            print(f"\n{tag} — {task_type.value}")

            try:
                proc = subprocess.run(
                    cmd,
                    cwd=str(cwd) if cwd else str(FACTORY_DIR),
                    capture_output=True,
                    text=True,
                    timeout=effective_timeout,
                )
                combined = proc.stdout + proc.stderr

                # Rate limit 감지
                limited, wait_sec = is_rate_limited(combined)
                if limited:
                    actual_wait = 5 if debug else wait_sec
                    print(f"{tag} Rate limited. {actual_wait}s 대기 후 재시도...")
                    time.sleep(actual_wait)
                    continue

                if proc.returncode == 0 and proc.stdout.strip():
                    # 블랙보드에 결과 요약 기록
                    _append_blackboard(task_type, model_cfg, proc.stdout[:500])
                    return AgentResult(
                        success=True,
                        output=proc.stdout,
                        model_used=model_cfg.model,
                        cli_used=model_cfg.cli,
                        retries=attempt,
                    )

                # stderr만 있는 경우에도 stdout이 있으면 성공으로 간주
                if proc.stdout.strip():
                    _append_blackboard(task_type, model_cfg, proc.stdout[:500])
                    return AgentResult(
                        success=True,
                        output=proc.stdout,
                        model_used=model_cfg.model,
                        cli_used=model_cfg.cli,
                        retries=attempt,
                    )

                print(f"{tag} 실패 (rc={proc.returncode}). stderr: {proc.stderr[:200]}")

            except subprocess.TimeoutExpired:
                print(f"{tag} 타임아웃 ({effective_timeout}s)")
            except FileNotFoundError:
                print(f"{tag} CLI '{model_cfg.cli}' 를 찾을 수 없습니다. 다음 fallback으로...")
                break  # 이 CLI 전체 스킵
            except Exception as e:
                print(f"{tag} 예외: {e}")

        print(f"[Router] {model_cfg.cli}:{model_cfg.model} 소진. 다음 fallback...")

    return AgentResult(success=False, output="", model_used="none", cli_used="none")


# ---------------------------------------------------------------------------
# Blackboard: 에이전트 간 공유 컨텍스트
# ---------------------------------------------------------------------------

def _append_blackboard(task_type: TaskType, model: ModelConfig, summary: str):
    os.makedirs(CONTEXT_DIR, exist_ok=True)
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    entry = (
        f"\n---\n"
        f"**[{timestamp}]** `{task_type.value}` via `{model.cli}:{model.model}`\n"
        f"{summary.strip()[:300]}\n"
    )
    with open(BLACKBOARD_FILE, "a", encoding="utf-8") as f:
        f.write(entry)


def read_blackboard(max_chars: int = 3000) -> str:
    if BLACKBOARD_FILE.exists():
        text = BLACKBOARD_FILE.read_text(encoding="utf-8")
        return text[-max_chars:] if len(text) > max_chars else text
    return ""


def reset_blackboard():
    os.makedirs(CONTEXT_DIR, exist_ok=True)
    with open(BLACKBOARD_FILE, "w", encoding="utf-8") as f:
        f.write("# Blackboard — Agent Shared Context\n\n")


# ---------------------------------------------------------------------------
# 편의 함수: 특정 task 유형의 원샷 호출
# ---------------------------------------------------------------------------

def research(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.MARKET_RESEARCH, prompt, **kwargs)

def generate_prd(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.PRD_GENERATION, prompt, **kwargs)

def design_architecture(prompt: str, **kwargs) -> AgentResult:
    return dispatch(TaskType.ARCHITECTURE, prompt, **kwargs)

def code_ui(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.UI_CODING, prompt, cwd=cwd, **kwargs)

def code_logic(prompt: str, cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.BUSINESS_LOGIC, prompt, cwd=cwd, **kwargs)

def review_code(cwd: Path = None, **kwargs) -> AgentResult:
    return dispatch(TaskType.CODE_REVIEW, "Review the codebase for bugs and quality issues", cwd=cwd, **kwargs)

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
    # 단독 테스트: 라우팅 테이블 출력
    print("=== Triad Model Routing Table ===\n")
    for task, models in ROUTING_TABLE.items():
        primary = models[0]
        fallbacks = [f"{m.cli}:{m.model}" for m in models[1:]]
        print(f"  {task.value:20s} -> {primary.cli}:{primary.model:20s} | fallback: {', '.join(fallbacks) or 'none'}")
