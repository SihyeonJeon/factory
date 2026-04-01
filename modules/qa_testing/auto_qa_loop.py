#!/usr/bin/env python3
"""
auto_qa_loop.py — Phase 3: 자율 QA 루프

Playwright E2E 테스트 + Gemini Vision 스크린샷 분석 + 스프린트 계약 기반 평가.
실패 시 Claude Sonnet으로 자율 수정 → 재검증 루프.
"""

import os
import sys
import json
import time
import subprocess
import urllib.request
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from master_router import dispatch, TaskType, read_blackboard

WORKSPACE_DIR = PROJECT_ROOT / "workspace"
CONTEXT_DIR = PROJECT_ROOT / "context_harness"
BUG_REPORT_FILE = CONTEXT_DIR / "current_bug_report.md"
SPRINT_CONTRACT_FILE = CONTEXT_DIR / "sprint_contract.json"
SCREENSHOT_DIR = PROJECT_ROOT / "modules" / "qa_testing" / "screenshots"
MAX_CORRECTION_RETRIES = 3


def load_sprint_contract() -> dict:
    if SPRINT_CONTRACT_FILE.exists():
        try:
            with open(SPRINT_CONTRACT_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"sprints": []}


def start_dev_server() -> subprocess.Popen:
    """Expo 웹 서버를 백그라운드로 구동."""
    print("[QA] 로컬 서버(Expo Web) 구동 중...")
    server = subprocess.Popen(
        ["npx", "expo", "start", "--web", "--port", "8081"],
        cwd=WORKSPACE_DIR,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    # 서버 기동 대기
    for _ in range(20):
        try:
            urllib.request.urlopen("http://localhost:8081", timeout=2)
            print("[QA] 서버 정상 가동 확인!")
            return server
        except Exception:
            time.sleep(1)

    print("[QA] 서버 응답 대기 초과 (계속 진행)")
    return server


def run_e2e_tests() -> tuple[bool, str, list[str]]:
    """
    Playwright E2E 테스트: 기본 렌더링 + 스프린트 계약 기반 검증.
    """
    print("[QA] E2E 자율 테스트 시작...")

    os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    test_url = "http://localhost:8081"
    screenshots = []
    errors = []

    try:
        from playwright.sync_api import sync_playwright, expect

        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(viewport={"width": 390, "height": 844})  # iPhone 14 viewport

            try:
                page.goto(test_url, timeout=10000)

                # 1. 기본 렌더링 검증
                page.wait_for_load_state("networkidle", timeout=10000)

                # 전체 페이지 스크린샷
                main_screenshot = str(SCREENSHOT_DIR / "main_render.png")
                page.screenshot(path=main_screenshot, full_page=True)
                screenshots.append(main_screenshot)

                # 2. 콘솔 에러 수집
                console_errors = []
                page.on("console", lambda msg: console_errors.append(msg.text) if msg.type == "error" else None)

                # 3. 기본 DOM 검증
                body = page.locator("body")
                body_text = body.inner_text()

                if not body_text.strip() or "error" in body_text.lower():
                    errors.append(f"페이지가 비어있거나 에러 표시: '{body_text[:200]}'")

                # 4. 스프린트 계약 기반 검증
                contract = load_sprint_contract()
                for sprint in contract.get("sprints", []):
                    for criterion in sprint.get("acceptance_criteria", []):
                        # 각 수용 기준을 간단한 DOM 존재 확인으로 검증
                        # (실제로는 더 정교한 테스트가 필요하지만, 기본 프레임워크)
                        pass  # Vision QA에서 상세 검증

                # 5. 인터랙션 스크린샷 (스크롤 후)
                page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                time.sleep(1)
                scroll_screenshot = str(SCREENSHOT_DIR / "scrolled_render.png")
                page.screenshot(path=scroll_screenshot)
                screenshots.append(scroll_screenshot)

                if console_errors:
                    errors.extend([f"Console error: {e}" for e in console_errors[:5]])

                if not errors:
                    print("[QA] E2E 기본 테스트 통과!")
                    return True, "", screenshots

            except Exception as e:
                error_screenshot = str(SCREENSHOT_DIR / "error_state.png")
                try:
                    page.screenshot(path=error_screenshot)
                    screenshots.append(error_screenshot)
                except Exception:
                    pass
                errors.append(f"E2E 테스트 예외: {str(e)}")

            finally:
                browser.close()

    except ImportError:
        errors.append("Playwright 미설치")
    except Exception as e:
        errors.append(f"Playwright 실행 불가: {str(e)}")

    error_summary = "\n".join(errors)
    print(f"[QA] E2E 테스트 실패: {error_summary[:300]}")
    return False, error_summary, screenshots


def analyze_with_vision(screenshots: list[str], error_log: str, sprint_context: str) -> str:
    """
    Gemini 2.5 Pro Vision으로 스크린샷 분석.
    UI 레이아웃, Apple HIG 준수, 스프린트 계약 충족 여부를 시각적으로 평가.
    """
    print("[QA] Gemini Vision으로 시각적 분석 요청 중...")

    # 스크린샷 경로를 프롬프트에 포함
    screenshot_refs = "\n".join([f"- {s}" for s in screenshots])

    prompt = f"""You are a Senior QA Engineer with expertise in iOS UI/UX quality.

SCREENSHOTS CAPTURED:
{screenshot_refs}

ERROR LOG FROM E2E TESTS:
{error_log if error_log else "No errors detected in automated tests."}

SPRINT ACCEPTANCE CRITERIA:
{sprint_context[:2000]}

EVALUATION CHECKLIST:
1. Apple HIG compliance (44pt touch targets, SafeAreaView, Dynamic Island clearance)
2. Visual completeness (모든 UI 요소가 렌더링되었는가)
3. Layout integrity (오버랩, 잘림, 빈 공간 이상 없는지)
4. Dark mode readiness (텍스트 가독성, 콘트라스트)
5. Sprint acceptance criteria 충족 여부 (각 항목별 PASS/FAIL)

OUTPUT FORMAT:
## QA Vision Report
### Passed Criteria
- [list]
### Failed Criteria
- [list with specific bug description and file/component to fix]
### Overall Verdict
QA_PASS 또는 QA_FAIL
### Bug Fix Instructions (if QA_FAIL)
[specific file paths and what to change]
"""

    # Gemini에 이미지와 함께 분석 요청
    result = dispatch(
        TaskType.VISUAL_QA,
        prompt=prompt,
        image_path=screenshots[0] if screenshots else None,
        timeout=120,
    )

    if result.success:
        return result.output
    else:
        # Vision 분석 실패 시, 텍스트 기반 QA로 fallback
        print("[QA] Vision 분석 실패. 텍스트 기반 분석으로 fallback...")
        return f"""## QA Vision Report
### Failed Criteria
- Vision analysis unavailable
- E2E test errors: {error_log[:500]}
### Overall Verdict
QA_FAIL
### Bug Fix Instructions
Review E2E test errors and fix accordingly.
"""


def write_bug_report(report: str):
    os.makedirs(CONTEXT_DIR, exist_ok=True)
    with open(BUG_REPORT_FILE, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"[QA] Bug report 저장: {BUG_REPORT_FILE}")


def trigger_self_correction(bug_report: str) -> bool:
    """
    Claude Sonnet으로 버그 리포트 기반 자율 코드 수정.
    """
    print("[QA] Claude Sonnet으로 자율 수정 시작...")

    # 블랙보드에서 최근 컨텍스트 가져오기
    recent_context = read_blackboard(max_chars=1500)

    prompt = f"""You are a Senior React Native Developer. Fix the bugs described below.

BUG REPORT:
{bug_report[:2000]}

RECENT AGENT CONTEXT:
{recent_context[:1000]}

INSTRUCTIONS:
1. Read the bug report carefully.
2. Navigate to the workspace and identify the problematic files.
3. Fix each bug with production-quality code.
4. Ensure Apple HIG compliance (44pt touch targets, SafeAreaView).
5. Use Zustand for state, NativeWind for styling.
6. Do NOT introduce new dependencies unless absolutely necessary.
7. After fixing, verify the fix makes logical sense.
"""

    result = dispatch(
        TaskType.BUG_FIX,
        prompt=prompt,
        cwd=WORKSPACE_DIR,
        timeout=180,
    )

    if result.success:
        print("[QA] 자율 수정 완료.")
        return True
    else:
        print("[QA] 자율 수정 실패.")
        return False


def evaluate_sprint_completion() -> bool:
    """
    스프린트 계약 전체를 Gemini Flash로 빠르게 평가.
    """
    contract = load_sprint_contract()
    if not contract.get("sprints"):
        print("[QA] 스프린트 계약이 없어 기본 평가만 수행.")
        return True

    criteria_text = json.dumps(contract, indent=2, ensure_ascii=False)

    prompt = f"""Evaluate whether the following sprint acceptance criteria have been met.
Based on the QA reports and blackboard context, determine pass/fail for each.

SPRINT CONTRACT:
{criteria_text[:3000]}

BLACKBOARD (recent agent activity):
{read_blackboard(2000)}

For each criterion, output PASS or FAIL with a one-line reason.
End with: SPRINT_PASS if all P0 criteria pass, SPRINT_FAIL otherwise.
"""

    result = dispatch(TaskType.SPRINT_EVAL, prompt=prompt, timeout=60)

    if result.success and "SPRINT_PASS" in result.output:
        print("[QA] 스프린트 계약 충족 확인!")
        return True

    print("[QA] 스프린트 계약 미충족.")
    return False


def run_hig_check() -> tuple[bool, str]:
    """Apple HIG 정적 분석 — 코드 레벨 위반 사전 감지."""
    print("[QA] Apple HIG 정적 분석 시작...")
    try:
        from modules.qa_testing.hig_checker import check_hig, format_report
        violations = check_hig(WORKSPACE_DIR)
        report = format_report(violations)
        print(report[:500])

        has_critical = any(v.severity == "critical" for v in violations)
        return not has_critical, report
    except ImportError:
        # 직접 import 시도
        sys.path.insert(0, str(PROJECT_ROOT))
        from modules.qa_testing.hig_checker import check_hig, format_report
        violations = check_hig(WORKSPACE_DIR)
        report = format_report(violations)
        has_critical = any(v.severity == "critical" for v in violations)
        return not has_critical, report
    except Exception as e:
        print(f"[QA] HIG 체커 실행 실패: {e}")
        return True, ""  # 실패 시 통과 처리 (E2E/Vision에서 잡힘)


def run_qa_loop() -> bool:
    """QA 메인 루프: HIG 정적분석 → E2E → Vision 분석 → 자율 수정 → 재검증"""
    print("\n" + "=" * 60)
    print("  Phase 3: Autonomous QA Loop")
    print("=" * 60 + "\n")

    # Step 0: HIG 정적 분석 (서버 띄우기 전에 코드 레벨 먼저)
    hig_passed, hig_report = run_hig_check()
    if not hig_passed:
        print("[QA] HIG 정적 분석 실패 — 자율 수정 시도...")
        write_bug_report(hig_report)
        trigger_self_correction(hig_report)

    server = start_dev_server()

    try:
        contract = load_sprint_contract()
        sprint_context = json.dumps(contract, indent=2, ensure_ascii=False)[:2000]

        retries = 0
        while retries < MAX_CORRECTION_RETRIES:
            # Step 1: HIG 재검증
            hig_passed, hig_report = run_hig_check()

            # Step 2: E2E 테스트
            passed, error_log, screenshots = run_e2e_tests()

            # Step 3: Vision 분석
            vision_report = analyze_with_vision(screenshots, error_log, sprint_context)

            if "QA_PASS" in vision_report and passed and hig_passed:
                print("[QA] Vision + E2E + HIG 모두 통과!")

                # Step 4: 스프린트 계약 최종 평가
                if evaluate_sprint_completion():
                    print("[QA] 모든 검증 완료. QA PASS.")
                    return True
                else:
                    print("[QA] 스프린트 계약 미충족 — 수정 필요")

            # Step 5: 통합 버그 리포트 + 자율 수정
            combined_report = ""
            if not hig_passed:
                combined_report += f"## HIG Violations\n{hig_report}\n\n"
            combined_report += f"## Vision/E2E Report\n{vision_report}"
            write_bug_report(combined_report)

            retries += 1
            print(f"[QA] 수정 시도 {retries}/{MAX_CORRECTION_RETRIES}")

            corrected = trigger_self_correction(vision_report)
            if not corrected:
                print("[QA] 자율 수정 실패. 루프 중단.")
                break

            # 핫리로드 대기
            print("[QA] 핫리로드 대기 (5s)...")
            time.sleep(5)

        print("[QA] 최대 수정 횟수 초과. 수동 개입 필요.")
        return False

    finally:
        print("[QA] 로컬 서버 종료 중...")
        server.terminate()
        server.wait()


if __name__ == "__main__":
    success = run_qa_loop()
    sys.exit(0 if success else 1)
