#!/bin/zsh
set -eu

cd /Users/jeonsihyeon/factory

target=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 21:02:00" +%s)
now=$(date +%s)
delay=$(( target > now ? target - now : 0 ))

echo "scheduled_at=$(date '+%Y-%m-%d %H:%M:%S %Z') delay_seconds=${delay}"
sleep "${delay}"
echo "started_at=$(date '+%Y-%m-%d %H:%M:%S %Z')"

env \
  FACTORY_CLAUDE_USE_CLI=1 \
  FACTORY_CLAUDE_STRATEGY_MODEL=claude-sonnet-4-20250514 \
  FACTORY_CLAUDE_DELIVERY_MODEL=claude-sonnet-4-20250514 \
  python3 -u orchestrator.py autopilot \
  "Read context_harness/reports/session_handoff_20260408_release_closure_passed.md first. The current state is evaluation passed and release ready after fixing the test target, wiring the memory composer into the app target, generating denied/manual-picker/large-text runtime evidence, and clearing stale blackboard bias. Continue only from this passed baseline." \
  --max-rounds 2
