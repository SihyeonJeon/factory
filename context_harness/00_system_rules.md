# Company Harness Constitution

This repository now follows a company-style harness instead of a flat model router.

## 1. Team structure

- Product team
- `market_analyst` uses Gemini CLI for fresh market signals, competitor scans, and community evidence.
- `product_strategist` uses Claude API for PRD synthesis, tradeoffs, and release-scope decisions.

- Planning team
- `delivery_planner` uses Claude API to break work into bounded tasks, define ownership, and decide when forks are justified.

- Engineering team
- `ios_architect` uses Claude API for system design, iOS constraints, and HIG-safe architecture.
- `implementation_lead` uses Codex CLI for long-running code edits, tool use, and parallel implementation.
- `subagent_executor` uses a cheaper Codex model only for bounded, non-blocking subtasks with disjoint ownership.

- Evaluation team
- `vision_auditor` uses Gemini CLI for screenshot review, visual regressions, and HIG layout checks.
- `code_auditor` uses Claude API for spec compliance, regression review, and feedback synthesis.

## 2. Model assignment policy

- Gemini owns web-grounded research and screenshot-heavy QA.
- Claude owns planning, architecture, arbitration, and review loops.
- Codex owns implementation, refactors, and tool-using code execution.
- No single provider may both implement and self-approve a release-critical task without another evaluator.

## 3. HIG release gate

- Every screen must respect safe areas, 44 pt targets, contrast, accessibility labels, and dark mode support.
- AI-generated UI is not considered releasable until it passes both code-level and screenshot-level HIG review.
- If a custom interaction risks violating native iOS expectations, the architect must replace it with a safer native pattern.
- Native iOS is the primary release target. Expo web is only a temporary proving ground until a real `workspace/ios` project exists.

## 4. Token efficiency

- Keep product, plans, reports, and code in separate directories so each agent reads only the relevant slice.
- Use planner-generated task packets instead of replaying the full project history.
- Fork only when the file ownership is disjoint and the parent can continue working.
- Archive stale bug reports and screenshots instead of leaving them in the default prompt path.
- Treat `context_harness/product_inputs/*.md` as the highest-priority user intent inputs during intake.

## 5. Evidence loop

- Product generates sources and assumptions.
- Planning converts them into bounded acceptance criteria.
- Engineering implements against that contract.
- Evaluation returns file-specific bugs and release evidence.
- Engineering only re-enters after feedback is concrete.

## 6. Native strategy

- Follow [`context_harness/architecture/native_ios_strategy.md`](/Users/jeonsihyeon/factory/context_harness/architecture/native_ios_strategy.md) as the default platform plan.
- Once native project artifacts exist, Xcode evidence outranks Expo-only evidence.
