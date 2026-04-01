#!/bin/bash
# setup_env.sh — Multi-Agent Factory 환경 설정
set -e

echo "=== Multi-Agent Autonomous Publishing Factory Setup ==="

# Python 가상환경
echo "> Python 가상환경 설정..."
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install playwright pydantic requests

# Playwright 브라우저
echo "> Playwright Chromium 설치..."
playwright install chromium

# CLI 도구 확인
echo ""
echo "=== CLI 도구 상태 ==="
echo -n "Claude Code: "; claude --version 2>/dev/null || echo "NOT FOUND"
echo -n "Gemini CLI:  "; gemini --version 2>/dev/null || echo "NOT FOUND"
echo -n "Codex CLI:   "; codex --version 2>/dev/null || echo "NOT FOUND"

# Node.js 글로벌 도구
echo ""
echo "> Node.js 글로벌 도구 확인..."
which npx >/dev/null 2>&1 || { echo "[!] npx not found. Install Node.js first."; exit 1; }

echo ""
echo "=== Setup Complete ==="
echo "사용법: source venv/bin/activate && python run_factory.py [시드아이디어]"
echo "옵션:   --reset (상태 초기화)  --debug-fast (Rate limit 대기 단축)"
