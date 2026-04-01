#!/usr/bin/env python3
"""
run_factory.py — End-to-End Autonomous Publishing Factory (v3)

Phase 1: 시장 조사 → PRD (Gemini 웹 그라운딩 + Claude Opus)
Phase 2: 아키텍처 설계 + Epic별 코딩 (Claude Opus/Sonnet + Codex)
Phase 3: QA 루프 (Playwright + Gemini Vision + HIG 자동검증 + 스프린트 계약)
Phase 4: 배포 + Kill/Scale (Claude Haiku + Gemini Flash)

v3 변경:
- Epic 단위 체크포인트 (중단 후 재개 가능)
- 위험 명령어 차단 (SafeGuard)
- Claude -c (continue) 기반 세션 이어가기
- 시장 조사 교차 검증 (Gemini → Claude 팩트체크)
"""

import os
import sys
import json
import signal
import argparse
import subprocess
from pathlib import Path

FACTORY_DIR = Path(__file__).parent.resolve()
MODULES_DIR = FACTORY_DIR / "modules"
WORKSPACE_DIR = FACTORY_DIR / "workspace"
CONTEXT_DIR = FACTORY_DIR / "context_harness"
STATE_FILE = CONTEXT_DIR / "state.json"
VENV_PYTHON = FACTORY_DIR / "venv" / "bin" / "python"

sys.path.insert(0, str(FACTORY_DIR))
from master_router import (
    read_blackboard, reset_blackboard, dispatch, TaskType,
    arbitrate, review_code, design_architecture, code_ui,
    fix_bug,
)


def get_python():
    return str(VENV_PYTHON) if VENV_PYTHON.exists() else sys.executable


# ---------------------------------------------------------------------------
# SafeGuard: 위험 명령어 차단
# ---------------------------------------------------------------------------

DANGEROUS_PATTERNS = [
    "rm -rf /",
    "rm -rf ~",
    "rm -rf $HOME",
    "mkfs",
    "dd if=",
    "> /dev/sda",
    "chmod -R 777 /",
    ":(){ :|:& };:",  # fork bomb
]


def safeguard_check(output: str) -> bool:
    """에이전트 출력에 위험 명령어가 포함되었는지 검사."""
    for pattern in DANGEROUS_PATTERNS:
        if pattern in output:
            print(f"\n[SAFEGUARD] 위험 명령어 감지됨: '{pattern}'")
            print("[SAFEGUARD] 해당 에이전트 출력을 차단합니다.")
            return False
    return True


# ---------------------------------------------------------------------------
# State Management — Epic 단위 체크포인트
# ---------------------------------------------------------------------------

class FactoryState:
    def __init__(self):
        self.data = {
            "PHASE_1_RESEARCH": False,
            "PHASE_2_ARCH": False,         # 아키텍처 설계 완료
            "PHASE_2_EPICS_DONE": [],      # 완료된 Epic 인덱스 목록
            "PHASE_2_REVIEW": False,       # 코드 리뷰 완료
            "PHASE_3_QA": False,
            "PHASE_4_PUBLISH": False,
            "QA_ROLLBACK_COUNT": 0,
            "last_session_id": None,       # Claude 세션 ID (이어가기용)
        }
        self._load()

    def _load(self):
        if STATE_FILE.exists():
            try:
                with open(STATE_FILE, "r") as f:
                    saved = json.load(f)
                    self.data.update(saved)
            except Exception as e:
                print(f"[!] state.json 파싱 에러: {e}")

    def save(self):
        os.makedirs(CONTEXT_DIR, exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(self.data, f, indent=4, ensure_ascii=False)

    def done(self, key: str) -> bool:
        return self.data.get(key, False)

    def mark_done(self, key: str):
        self.data[key] = True
        self.save()

    def mark_pending(self, key: str):
        self.data[key] = False
        self.save()

    def epic_done(self, idx: int) -> bool:
        return idx in self.data.get("PHASE_2_EPICS_DONE", [])

    def mark_epic_done(self, idx: int):
        done_list = self.data.get("PHASE_2_EPICS_DONE", [])
        if idx not in done_list:
            done_list.append(idx)
        self.data["PHASE_2_EPICS_DONE"] = done_list
        self.save()

    def reset_epics(self):
        self.data["PHASE_2_EPICS_DONE"] = []
        self.save()

    def rollback_count(self) -> int:
        return self.data.get("QA_ROLLBACK_COUNT", 0)

    def increment_rollback(self):
        self.data["QA_ROLLBACK_COUNT"] = self.rollback_count() + 1
        self.save()

    def reset_rollback(self):
        self.data["QA_ROLLBACK_COUNT"] = 0
        self.save()

    def reset_all(self):
        self.data = {
            "PHASE_1_RESEARCH": False,
            "PHASE_2_ARCH": False,
            "PHASE_2_EPICS_DONE": [],
            "PHASE_2_REVIEW": False,
            "PHASE_3_QA": False,
            "PHASE_4_PUBLISH": False,
            "QA_ROLLBACK_COUNT": 0,
            "last_session_id": None,
        }
        self.save()


MAX_QA_ROLLBACKS = 3


# ---------------------------------------------------------------------------
# Graceful Shutdown — Ctrl+C 시 상태 자동 저장
# ---------------------------------------------------------------------------

_state_ref = None

def _signal_handler(_sig, _frame):
    print("\n\n[Factory] Ctrl+C 감지. 현재 상태를 저장합니다...")
    if _state_ref:
        _state_ref.save()
        print(f"[Factory] 상태 저장 완료: {STATE_FILE}")
        print("[Factory] 다음 실행 시 중단된 지점부터 자동 재개됩니다.")
    sys.exit(130)


# ---------------------------------------------------------------------------
# Phase 1: Market Research + PRD + 교차검증
# ---------------------------------------------------------------------------

def phase_1_research(seed_idea: str) -> bool:
    print("\n" + "=" * 65)
    print("  PHASE 1: The Demand Oracle — 시장 조사 + PRD")
    print("=" * 65)

    script = MODULES_DIR / "market_research" / "scraper_and_analyzer.py"
    res = subprocess.run([get_python(), str(script), seed_idea])
    if res.returncode != 0:
        return False

    # 교차 검증: Gemini가 생성한 시장 조사를 Claude가 팩트체크
    insight_file = CONTEXT_DIR / "01_market_insight.md"
    if insight_file.exists():
        insight = insight_file.read_text(encoding="utf-8")
        print("\n[Phase 1] Claude Haiku로 시장 조사 교차 검증 중...")

        verify_result = dispatch(
            TaskType.SPRINT_EVAL,  # Haiku/Flash tier
            prompt=f"""아래 시장 조사 리포트의 신뢰성을 검증하라.

{insight[:3000]}

검증 항목:
1. 언급된 기존 서비스(앱)가 실제로 존재하는가?
2. 사용자 불만 사항이 일반적으로 알려진 것과 일치하는가?
3. 과금 전략이 시장 현실과 부합하는가?
4. 명백한 AI 할루시네이션(존재하지 않는 서비스/기능 날조)이 있는가?

각 항목에 대해 VERIFIED 또는 SUSPICIOUS로 판정하고 근거를 한 줄로.
마지막에 INSIGHT_VERIFIED 또는 INSIGHT_SUSPICIOUS 를 출력.
""",
            timeout=60,
        )

        if verify_result.success:
            if "INSIGHT_SUSPICIOUS" in verify_result.output:
                print("[!] 시장 조사에 의심스러운 내용 감지:")
                print(verify_result.output[:500])
                print("[Phase 1] 경고: 시장 조사 결과에 할루시네이션이 포함될 수 있습니다.")
                # 경고만 하고 진행 (사용자 판단에 맡김)
            else:
                print("[Phase 1] 시장 조사 교차 검증 통과.")

    return True


# ---------------------------------------------------------------------------
# Phase 2: Architecture + Build (Epic 단위 체크포인트)
# ---------------------------------------------------------------------------

def phase_2_build(state: FactoryState) -> bool:
    print("\n" + "=" * 65)
    print("  PHASE 2: Triad Coding Engine — 아키텍처 + 개발")
    print("=" * 65)

    prd_file = CONTEXT_DIR / "02_generated_prd.md"
    insight_file = CONTEXT_DIR / "01_market_insight.md"
    prd_text = prd_file.read_text(encoding="utf-8") if prd_file.exists() else ""
    insight_text = insight_file.read_text(encoding="utf-8") if insight_file.exists() else ""

    # Step 1: Expo 초기화
    init_script = MODULES_DIR / "subagents" / "init_expo_app.sh"
    if init_script.exists() and not (WORKSPACE_DIR / "package.json").exists():
        print("\n[Build] Step 1: Expo 환경 초기화...")
        try:
            subprocess.run([str(init_script), str(WORKSPACE_DIR)], check=True)
        except subprocess.CalledProcessError as e:
            print(f"[!] Expo 초기화 실패: {e}")
            return False
    else:
        print("[Build] Step 1: Expo 환경 존재 — 스킵")

    # Step 2: 아키텍처 설계 (체크포인트)
    if not state.done("PHASE_2_ARCH"):
        print("\n[Build] Step 2: Claude Opus — 아키텍처 설계...")

        arch_prompt = f"""You are the Chief Architect. Design the application architecture.

PRD:
{prd_text[:3000]}

MARKET INSIGHT:
{insight_text[:1500]}

INSTRUCTIONS:
1. Read the PRD carefully. Identify all required screens/features.
2. Design the file structure for an Expo Router project:
   - app/ directory with file-based routing
   - store/ directory with Zustand stores
   - components/ directory for reusable UI
   - theme.ts with design tokens
3. Create ONLY the architecture files:
   - app/_layout.tsx (root layout with SafeAreaProvider)
   - store/ files (global state schemas)
   - theme.ts (NativeWind design tokens, dark mode support)
   - types/ directory with TypeScript interfaces
4. Do NOT implement screens yet — structural skeleton only.
5. CRITICAL Apple HIG requirements to embed in the architecture:
   - SafeAreaView wrapper in _layout.tsx
   - Theme must include minTouchTarget: 44 constant
   - Dark mode color tokens alongside light mode
"""

        arch_result = design_architecture(
            prompt=arch_prompt,
            cwd=WORKSPACE_DIR,
            system_prompt="You are a Senior iOS App Architect. Create files directly in the workspace.",
        )

        if not arch_result.success:
            print("[!] 아키텍처 설계 실패.")
            return False

        if not safeguard_check(arch_result.output):
            return False

        state.mark_done("PHASE_2_ARCH")
        print("[Build] 아키텍처 설계 체크포인트 저장됨.")
    else:
        print("[Build] Step 2: 아키텍처 이미 완료 — 스킵")

    # Step 3: Epic별 코딩 (각 Epic 체크포인트)
    print("\n[Build] Step 3: Epic별 UI 구현...")
    epics = _extract_epics(prd_text)

    if not epics:
        print("[!] PRD에서 Epic 추출 실패. 전체 PRD로 진행.")
        epics = [prd_text[:2000]]

    for i, epic in enumerate(epics):
        if state.epic_done(i):
            print(f"  [Epic {i+1}/{len(epics)}] 이미 완료 — 스킵")
            continue

        print(f"\n  [Epic {i+1}/{len(epics)}] 구현 중...")
        context = read_blackboard(1500)

        code_prompt = f"""Implement this Epic in the React Native Expo project.

EPIC:
{epic}

PREVIOUS WORK CONTEXT:
{context[:1000]}

MANDATORY APPLE HIG RULES (violation = App Store rejection):
- Every Pressable/TouchableOpacity: className must include min-w-[44px] min-h-[44px]
- Every screen root: wrapped in SafeAreaView from react-native-safe-area-context
- Support both light and dark mode via useColorScheme()
- No content under Dynamic Island / notch area
- Back gesture must work (use Expo Router's native stack, no custom)

CODE RULES:
- Import store from store/ (Zustand). NO useState unless purely local.
- Import tokens from theme.ts. NO hardcoded colors/sizes.
- NativeWind className only. NO StyleSheet.create, NO inline styles.
- Reanimated for animations. worklet functions only.
"""

        code_result = code_ui(prompt=code_prompt, cwd=WORKSPACE_DIR)

        if code_result.success:
            if safeguard_check(code_result.output):
                state.mark_epic_done(i)
                print(f"  [Epic {i+1}] 체크포인트 저장됨.")
            else:
                print(f"  [Epic {i+1}] SafeGuard 차단.")
                return False
        else:
            print(f"  [!] Epic {i+1} 실패. (다음 실행 시 이 Epic부터 재개)")
            return False

    # Step 4: 코드 리뷰 (체크포인트)
    if not state.done("PHASE_2_REVIEW"):
        print("\n[Build] Step 4: Codex 코드 리뷰...")
        review_result = review_code(cwd=WORKSPACE_DIR)

        if review_result.success:
            print("[Build] 리뷰 피드백:")
            print(review_result.output[:500])

            if any(w in review_result.output.lower() for w in ["critical", "bug", "error", "crash"]):
                print("[Build] 치명적 이슈 — 자동 수정 중...")
                fix_bug(
                    prompt=f"Fix these code review issues:\n{review_result.output[:1500]}",
                    cwd=WORKSPACE_DIR,
                )

        state.mark_done("PHASE_2_REVIEW")
    else:
        print("[Build] Step 4: 리뷰 이미 완료 — 스킵")

    print("\n[Build] Phase 2 완료.")
    return True


def _extract_epics(prd_text: str) -> list[str]:
    epics = []
    current = []
    in_epic = False

    for line in prd_text.split("\n"):
        if line.startswith("### Epic"):
            if current:
                epics.append("\n".join(current))
            current = [line]
            in_epic = True
        elif in_epic:
            if (line.startswith("### ") and not line.startswith("### Epic")) or line.startswith("---"):
                epics.append("\n".join(current))
                current = []
                in_epic = False
            else:
                current.append(line)

    if current:
        epics.append("\n".join(current))
    return epics


# ---------------------------------------------------------------------------
# Phase 3: QA Loop
# ---------------------------------------------------------------------------

def phase_3_qa() -> bool:
    print("\n" + "=" * 65)
    print("  PHASE 3: Autonomous QA Loop")
    print("=" * 65)

    script = MODULES_DIR / "qa_testing" / "auto_qa_loop.py"
    res = subprocess.run([get_python(), str(script)])
    return res.returncode == 0


# ---------------------------------------------------------------------------
# Phase 4: Publish + Kill/Scale
# ---------------------------------------------------------------------------

def phase_4_publish(app_name: str) -> bool:
    print("\n" + "=" * 65)
    print("  PHASE 4: Publishing & Kill/Scale Analyzer")
    print("=" * 65)

    script = MODULES_DIR / "publishing" / "deploy_and_monitor.py"
    res = subprocess.run([get_python(), str(script), app_name])
    return res.returncode == 0


# ---------------------------------------------------------------------------
# Arbitration
# ---------------------------------------------------------------------------

def resolve_deadlock() -> bool:
    print("\n[Arbitration] 교착 상태 감지! Claude Opus 중재 시작...")

    market_file = CONTEXT_DIR / "01_market_insight.md"
    bug_file = CONTEXT_DIR / "current_bug_report.md"
    blackboard = read_blackboard(3000)

    market_ctx = market_file.read_text(encoding="utf-8")[:1000] if market_file.exists() else "N/A"
    bug_ctx = bug_file.read_text(encoding="utf-8")[:1000] if bug_file.exists() else "N/A"

    prompt = f"""프로젝트가 무한 QA-Build 롤백에 빠졌습니다.

[비즈니스 요구사항]
{market_ctx}

[미해결 버그]
{bug_ctx}

[에이전트 활동 로그]
{blackboard}

결정:
1. 기획 축소 + workaround → QA 통과
2. 구조적 리팩토링 → workspace/ 코드 직접 수정

workspace/ 코드를 직접 수정하여 해결하십시오.
"""

    result = arbitrate(prompt=prompt, cwd=WORKSPACE_DIR)
    return result.success


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Autonomous Publishing Factory v3")
    parser.add_argument("seed_idea", nargs="?",
                        default="현대인을 위한 프라이빗 공간 다이어리 (지도 기반 앱)")
    parser.add_argument("--debug-fast", action="store_true")
    parser.add_argument("--reset", action="store_true", help="상태 초기화 후 처음부터")
    parser.add_argument("--status", action="store_true", help="현재 진행 상태만 출력")
    args = parser.parse_args()

    state = FactoryState()

    # 상태 조회 모드
    if args.status:
        print("=== Factory State ===")
        for k, v in state.data.items():
            print(f"  {k}: {v}")
        return

    # Ctrl+C 핸들러 등록
    global _state_ref
    _state_ref = state
    signal.signal(signal.SIGINT, _signal_handler)

    print("=" * 65)
    print("  Autonomous Publishing Factory v3 (Multi-Agent Triad)")
    print("  Claude Opus/Sonnet/Haiku + Gemini Pro/Flash + Codex")
    print("=" * 65)

    if args.reset:
        state.reset_all()
        reset_blackboard()
        print("[Factory] 전체 초기화 완료.\n")

    # Phase 1
    if not state.done("PHASE_1_RESEARCH"):
        if phase_1_research(args.seed_idea):
            state.mark_done("PHASE_1_RESEARCH")
        else:
            print("[FATAL] Phase 1 실패.")
            state.save()
            sys.exit(1)
    else:
        print("\n[Phase 1] 스킵 (완료됨)")

    # Phase 2 + 3 Loop
    while True:
        if not (state.done("PHASE_2_ARCH") and state.done("PHASE_2_REVIEW")):
            if phase_2_build(state):
                pass  # 개별 체크포인트로 관리
            else:
                print("[!] Phase 2 중단. 다음 실행 시 체크포인트부터 재개.")
                state.save()
                sys.exit(1)
        else:
            print("\n[Phase 2] 스킵 (완료됨)")

        if not state.done("PHASE_3_QA"):
            if phase_3_qa():
                state.mark_done("PHASE_3_QA")
                state.reset_rollback()
                break
            else:
                state.increment_rollback()
                count = state.rollback_count()
                print(f"\n[!] QA 실패. Rollback {count}/{MAX_QA_ROLLBACKS}")

                if count >= MAX_QA_ROLLBACKS:
                    if resolve_deadlock():
                        state.reset_rollback()
                        state.mark_pending("PHASE_2_ARCH")
                        state.mark_pending("PHASE_2_REVIEW")
                        state.reset_epics()
                    else:
                        print("[FATAL] 중재 실패.")
                        state.save()
                        sys.exit(1)
                else:
                    state.mark_pending("PHASE_2_REVIEW")
                    state.reset_epics()
        else:
            print("\n[Phase 3] 스킵 (완료됨)")
            break

    # Phase 4
    if not state.done("PHASE_4_PUBLISH"):
        if phase_4_publish("AutoApp"):
            state.mark_done("PHASE_4_PUBLISH")
        else:
            print("[FATAL] Phase 4 실패.")
            state.save()
            sys.exit(1)
    else:
        print("\n[Phase 4] 스킵 (완료됨)")

    print("\n" + "=" * 65)
    print("  ALL PHASES COMPLETE.")
    print("=" * 65)


if __name__ == "__main__":
    main()
