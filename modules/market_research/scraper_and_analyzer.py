#!/usr/bin/env python3
"""
scraper_and_analyzer.py — Phase 1: 시장 조사 + PRD 생성

Gemini CLI의 웹 그라운딩으로 실시간 검색 → Claude Opus로 PRD 구조화.
Playwright는 Gemini가 접근 불가한 커뮤니티 스크래핑 보조용으로만 사용.
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from typing import Optional

PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from master_router import (
    dispatch, TaskType, read_blackboard,
    CONTEXT_DIR, FACTORY_DIR,
)

INSIGHT_FILE = CONTEXT_DIR / "01_market_insight.md"
PRD_FILE = CONTEXT_DIR / "02_generated_prd.md"
TARGET_DECISION_FILE = CONTEXT_DIR / "target_decision.json"
SPLIT_MARKER = "================================SPLIT================================"


def scrape_with_playwright(keyword: str) -> str:
    """
    Playwright 보조 스크래핑: Reddit/커뮤니티에서 실제 이용자 목소리 수집.
    Gemini 웹 그라운딩이 커버하지 못하는 깊은 스레드 데이터 보완용.
    """
    print(f"[Scraper] Playwright로 '{keyword}' 커뮤니티 데이터 수집 중...")
    scraped = []

    try:
        from playwright.sync_api import sync_playwright

        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()
            try:
                url = f"https://old.reddit.com/search?q={keyword}&sort=relevance&t=year"
                page.goto(url, timeout=15000)
                page.wait_for_selector(".search-result", timeout=10000)

                results = page.locator(".search-result").all()
                for res in results[:10]:
                    snippet = res.inner_text()
                    scraped.append(snippet)
            except Exception as e:
                print(f"[Scraper] 크롤링 에러 (non-fatal): {e}")
            finally:
                browser.close()
    except ImportError:
        print("[Scraper] Playwright 미설치 — 건너뜀")
    except Exception as e:
        print(f"[Scraper] Playwright 실행 불가: {e}")

    return "\n---\n".join(scraped) if scraped else ""


def research_with_gemini(keyword: str, scraped_context: str) -> str:
    """
    Gemini 2.5 Pro (웹 그라운딩)를 사용하여 시장 트렌드를 실시간 조사.
    """
    print("[Research] Gemini 웹 그라운딩으로 시장 조사 시작...")

    prompt = f"""You are a top-tier Market Analyst. Research the following topic using web grounding:

TOPIC: "{keyword}"

ADDITIONAL USER COMMUNITY DATA (from Reddit scraping):
{scraped_context[:2000] if scraped_context else "No additional data available."}

INSTRUCTIONS:
1. Search the web for the latest trends, user complaints, and unmet needs related to this topic.
2. Focus on ACTUAL END-USER perspectives (not developers or publishers).
3. Identify: pain points, emotional gaps, UX frustrations, willingness to pay.
4. Analyze competing apps/services and their weaknesses.

OUTPUT FORMAT — Write a comprehensive market insight report in Korean:
- 핵심 사용자 니즈 (구체적 인용 포함)
- 기존 서비스의 아쉬운 점 (최소 5개)
- 과금 의향 분석
- 차별화 기회 요약
"""

    result = dispatch(
        TaskType.MARKET_RESEARCH,
        prompt=prompt,
        timeout=120,
    )
    return result.output if result.success else ""


def generate_prd_with_opus(keyword: str, market_insight: str) -> str:
    """
    Claude Opus로 시장 조사 결과를 기반으로 구조화된 PRD 생성.
    기술적 구현 계획은 배제하고, 서비스 목표와 사용자 경험에만 집중.
    """
    print("[PRD] Claude Opus로 PRD 구조화 시작...")

    prompt = f"""You are a Senior Product Owner. Based on the market research below, generate a PRD.

MARKET RESEARCH:
{market_insight[:4000]}

CRITICAL RULES:
- 기술적 구현 방법은 일절 언급하지 마라 (프레임워크, 라이브러리 이름 금지)
- 서비스의 목표, 사용자 시나리오, 핵심 기능 요구사항에만 집중
- 잠재 이용자의 결핍과 감정에 기반한 기능 설계
- 각 Epic은 사용자 스토리 형태로 작성

OUTPUT: 3개의 파트를 아래 구분선으로 분리하여 작성하라.

파트 1: Market Insight 요약 (01_market_insight.md 용)
{SPLIT_MARKER}
파트 2: PRD 본문 (02_generated_prd.md 용)
- 제품 비전
- 타겟 사용자 페르소나 (최소 2개)
- ### Epic 1: [제목] ~ ### Epic N: [제목] 형태로 기능 명세
- 각 Epic에 수용 기준(Acceptance Criteria) 포함
- 과금 전략
{SPLIT_MARKER}
파트 3: Target Decision JSON
```json
{{
  "project_type": "APP" 또는 "GAME",
  "core_concept": "한줄 요약",
  "monetization_strategy": "전략 요약",
  "target_framework": "APP이면 Expo, GAME이면 Phaser_Capacitor"
}}
```
"""

    result = dispatch(
        TaskType.PRD_GENERATION,
        prompt=prompt,
        timeout=180,
    )
    return result.output if result.success else ""


def save_artifacts(ai_output: str):
    parts = ai_output.split(SPLIT_MARKER)

    insight = parts[0].strip() if len(parts) > 0 else "# Market Insight\n(생성 실패)"
    prd = parts[1].strip() if len(parts) > 1 else "# PRD\n(생성 실패)"
    json_text = parts[2].strip() if len(parts) > 2 else ""

    os.makedirs(CONTEXT_DIR, exist_ok=True)

    with open(INSIGHT_FILE, "w", encoding="utf-8") as f:
        f.write(insight)
    print(f"[+] Saved: {INSIGHT_FILE}")

    with open(PRD_FILE, "w", encoding="utf-8") as f:
        f.write(prd)
    print(f"[+] Saved: {PRD_FILE}")

    if json_text:
        json_content = json_text.replace("```json", "").replace("```", "").strip()
        try:
            parsed = json.loads(json_content)
            with open(TARGET_DECISION_FILE, "w", encoding="utf-8") as f:
                json.dump(parsed, f, indent=2, ensure_ascii=False)
            print(f"[+] Saved: {TARGET_DECISION_FILE}")
        except json.JSONDecodeError as e:
            print(f"[!] JSON 파싱 에러: {e}")


def generate_sprint_contract(prd_text: str):
    """PRD의 Epic들로부터 스프린트 계약(acceptance criteria)을 자동 생성."""
    print("[Sprint] 스프린트 계약 생성 중...")

    prompt = f"""Based on this PRD, generate a sprint contract JSON with acceptance criteria for each Epic.

PRD:
{prd_text[:3000]}

OUTPUT FORMAT (strict JSON, no markdown):
{{
  "sprints": [
    {{
      "epic": "Epic title",
      "acceptance_criteria": [
        "Criterion 1: specific, testable condition",
        "Criterion 2: ..."
      ],
      "priority": "P0" | "P1" | "P2"
    }}
  ]
}}
"""
    result = dispatch(
        TaskType.SPRINT_EVAL,
        prompt=prompt,
        json_schema='{"type":"object","properties":{"sprints":{"type":"array"}},"required":["sprints"]}',
        timeout=60,
    )

    if result.success:
        contract_file = CONTEXT_DIR / "sprint_contract.json"
        try:
            # JSON 블록 추출
            text = result.output
            start = text.find("{")
            end = text.rfind("}") + 1
            if start >= 0 and end > start:
                parsed = json.loads(text[start:end])
                with open(contract_file, "w", encoding="utf-8") as f:
                    json.dump(parsed, f, indent=2, ensure_ascii=False)
                print(f"[+] Sprint contract saved: {contract_file}")
        except Exception as e:
            print(f"[!] Sprint contract 파싱 실패: {e}")


def run_oracle(keyword: str):
    """Phase 1 전체 실행: 스크래핑 → 조사 → PRD → 스프린트 계약"""
    print(f"\n{'='*60}")
    print(f"  Phase 1: The Demand Oracle — '{keyword}'")
    print(f"{'='*60}\n")

    # Step 1: Playwright 보조 스크래핑
    scraped = scrape_with_playwright(keyword)

    # Step 2: Gemini 웹 그라운딩 시장 조사
    market_insight = research_with_gemini(keyword, scraped)
    if not market_insight:
        print("[!] 시장 조사 실패. Fallback 데이터로 진행합니다.")
        market_insight = f"# Market Insight\n{keyword} 관련 시장 데이터 수집 실패. 수동 입력 필요."

    # Step 3: Claude Opus PRD 생성
    prd_output = generate_prd_with_opus(keyword, market_insight)
    if not prd_output:
        print("[!] PRD 생성 실패.")
        return False

    # Step 4: 산출물 저장
    save_artifacts(prd_output)

    # Step 5: 스프린트 계약 생성
    prd_text = PRD_FILE.read_text(encoding="utf-8") if PRD_FILE.exists() else ""
    if prd_text:
        generate_sprint_contract(prd_text)

    print("\n[Oracle] Phase 1 완료.")
    return True


if __name__ == "__main__":
    seed = sys.argv[1] if len(sys.argv) > 1 else "현대인을 위한 프라이빗 공간 다이어리 (지도 기반 앱)"
    success = run_oracle(seed)
    sys.exit(0 if success else 1)
