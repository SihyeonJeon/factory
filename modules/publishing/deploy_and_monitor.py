#!/usr/bin/env python3
"""
deploy_and_monitor.py — Phase 4: 배포 + Kill/Scale 판단

Fastlane 배포 시뮬레이션 + AI 기반 지표 분석 + 스케일업 PRD 생성.
"""

import os
import sys
import time
import shutil
import random
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from master_router import dispatch, TaskType

WORKSPACE_DIR = PROJECT_ROOT / "workspace"
CONTEXT_DIR = PROJECT_ROOT / "context_harness"
ARCHIVE_DIR = PROJECT_ROOT / "archived_workspaces"

THRESHOLD_D1_RETENTION = 0.30
THRESHOLD_CONVERSION_RATE = 0.15


def trigger_fastlane_deploy() -> bool:
    print("[Publish] Fastlane 스토어 업로드 프로세스...")
    print("[Publish] -> ipa/aab 빌드 및 서명 중...")
    time.sleep(1)
    print("[Publish] -> App Store Connect / Play Console 제출 완료.")
    return True


def monitor_analytics(app_name: str = "MockedApp") -> tuple[float, float]:
    print(f"[Monitor] '{app_name}' D-1 지표 수집 중...")
    time.sleep(1)
    d1 = round(random.uniform(0.10, 0.45), 3)
    cv = round(random.uniform(0.05, 0.20), 3)
    print(f"  => D-1 리텐션 {d1*100:.1f}%, 결제 전환율 {cv*100:.1f}%")
    return d1, cv


def kill_or_scale(d1: float, cv: float):
    print("=" * 50)
    print("  KILL OR SCALE DECISION")
    print("=" * 50)

    if d1 >= THRESHOLD_D1_RETENTION:
        print(f"[Scale] 리텐션 {THRESHOLD_D1_RETENTION*100}% 돌파. 스케일업 진행.")
        scale_project()
    else:
        print(f"[Kill] 리텐션 미달 (기준: {THRESHOLD_D1_RETENTION*100}%). 프로젝트 아카이빙.")
        kill_project()


def kill_project():
    os.makedirs(ARCHIVE_DIR, exist_ok=True)
    archive_name = f"failed_app_{int(time.time())}"
    dest = ARCHIVE_DIR / archive_name

    try:
        shutil.move(str(WORKSPACE_DIR), str(dest))
        print(f"[Kill] Workspace → {dest}")
        os.makedirs(WORKSPACE_DIR, exist_ok=True)
        print("[Kill] 새 아이디어를 위한 빈 workspace 생성됨.")
    except Exception as e:
        print(f"[Kill] 아카이빙 실패: {e}")


def scale_project():
    """Claude Haiku로 스케일업 PRD 생성 (단순 문서 생성 task)."""
    print("[Scale] 업데이트 PRD 생성 중 (Claude Haiku)...")

    insight_file = CONTEXT_DIR / "01_market_insight.md"
    insight = insight_file.read_text(encoding="utf-8")[:1500] if insight_file.exists() else ""

    prompt = f"""앱이 성공적으로 런칭되어 좋은 리텐션 지표를 확보했습니다.

기존 시장 분석:
{insight}

다음 업데이트(v1.1)를 위한 스케일업 PRD를 작성하세요:
- 신규 콘텐츠/기능 (사용자 리텐션 강화)
- 과금 모델 확장
- UI/UX 개선 사항
- 각 항목에 수용 기준(Acceptance Criteria) 포함

마크다운 형식으로 작성.
"""

    result = dispatch(TaskType.DOCUMENTATION, prompt=prompt, timeout=60)

    update_prd = CONTEXT_DIR / "03_update_prd.md"
    if result.success:
        os.makedirs(CONTEXT_DIR, exist_ok=True)
        with open(update_prd, "w", encoding="utf-8") as f:
            f.write(result.output)
        print(f"[Scale] 업데이트 PRD 저장: {update_prd}")
    else:
        print("[Scale] PRD 생성 실패.")


if __name__ == "__main__":
    app_id = sys.argv[1] if len(sys.argv) > 1 else "AutoApp"

    if trigger_fastlane_deploy():
        print("\n(출시 완료. D-1 데이터 수집 가정...)\n")
        d1, cv = monitor_analytics(app_id)
        kill_or_scale(d1, cv)
