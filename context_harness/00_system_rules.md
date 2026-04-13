# Company Harness Constitution

This repository follows a three-agent harness inspired by Anthropic's Planner-Generator-Evaluator architecture for long-running application development.

## 1. Three-agent architecture

The harness uses three core agent roles, each with clear separation of concerns:

- **Planner** (product_lead + delivery_lead)
  - `product_lead` uses Claude API (opus-4-6) for market research, product strategy, and PRD synthesis.
  - `delivery_lead` uses Claude API (sonnet-4-6) for sprint planning, task decomposition, and architecture decisions.

- **Generator** (web_builder)
  - `web_builder` uses Claude CLI (opus-4-6) for full-stack implementation (Next.js frontend + Supabase backend + Edge Functions).
  - Operates in worktrees for isolated implementation lanes.
  - Produces concrete code artifacts against acceptance criteria.

- **Evaluator** (reviewer)
  - `reviewer` uses Claude API (opus-4-6) for code review, UX audit, accessibility check, and release gating.
  - Must not share context with the generator to ensure independent evaluation.
  - Returns file-specific, actionable feedback.

## 2. Model assignment policy

- Claude (opus/sonnet/haiku tiered) owns all roles: research, planning, architecture, implementation, review.
- Tier routing: opus for heavy reasoning + implementation + review, sonnet for standard planning, haiku for ops/compaction.
- No single agent may both implement and self-approve a release-critical task.
- Codex CLI is available as a secondary implementation provider when Claude is unavailable.

## 3. Web release gate

- Every page must be responsive (mobile 375px, tablet 768px, desktop 1280px).
- Lighthouse Performance >= 90, PWA score >= 80.
- 카카오톡 OG 미리보기가 커버 이미지 + 제목 + 날짜로 정상 렌더링.
- Supabase RLS 정책이 모든 테이블에 적용.
- 접근성: 터치 타겟 44px+, 명암비 4.5:1+, 폰트 크기 16px+ 기본.
- 개인정보 수집 동의 절차 포함.

## 4. Sprint contract pattern

Each sprint follows the Anthropic harness contract negotiation pattern:
1. Planner defines sprint scope with acceptance criteria.
2. Generator and Evaluator negotiate a testable contract before implementation begins.
3. Generator implements against the contract.
4. Evaluator grades against the contract criteria, not subjective taste.
5. Generator re-enters only after Evaluator provides concrete, localized feedback.

## 5. Context management

- Use `claude-progress.md` to track state between sessions (what's done, what's next, known issues).
- Structured handoff artifacts between agent turns (compressed, max 800 words).
- Keep product, plans, reports, and code in separate directories for token efficiency.
- Archive stale artifacts instead of leaving them in the active context path.
- Treat `context_harness/product_inputs/*.md` as the highest-priority user intent inputs.

## 6. Evidence loop

- Product generates sources and assumptions.
- Planning converts them into bounded acceptance criteria.
- Engineering implements against that contract.
- Evaluation returns file-specific bugs and release evidence.
- Engineering only re-enters after feedback is concrete.

## 7. Technology strategy

- Next.js 15+ (App Router) with SSR for OG meta optimization.
- PWA for zero-install guest experience.
- Supabase for auth, database, realtime, storage, and edge functions.
- TypeScript strict mode throughout.
- Vercel deployment.
- Follow specification-driven development: PRD in markdown → agent reads → implements.
