# Vibe Coding Limits — 2026

**Scope:** LLM-driven coding and agentic coding limits as of 2026-04-22, compared with senior iOS engineering practice.

**Use:** implementation-dispatch checklist source for Unfading harness regulation.

## Source Notes

This document uses public research and industry reporting available by 2026-04-22, including:

- METR, "Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity" (2025-07-10): https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/
- METR, "We are Changing our Developer Productivity Experiment Design" (2026-02-24): https://metr.org/blog/2026-02-24-uplift-update/
- GitClear, "Coding on Copilot" and "AI Copilot Code Quality: 2025" reports: https://www.gitclear.com/coding_on_copilot_data_shows_ais_downward_pressure_on_code_quality and https://www.gitclear.com/ai_assistant_code_quality_2025_research
- Veracode 2025 GenAI Code Security reporting summarized by TechRadar: https://www.techradar.com/pro/nearly-half-of-all-code-generated-by-ai-found-to-contain-security-flaws-even-big-llms-affected
- TechTarget, "Security risks of AI-generated code and how to manage them" (2025-05-29): https://www.techtarget.com/searchSecurity/tip/Security-risks-of-AI-generated-code-and-how-to-manage-them
- Kaspersky, "Security risks of vibe coding and LLM assistants for developers" (2025): https://www.kaspersky.com/blog/vibe-coding-2025-risks/54584/
- Axios, "Cursor taps new security partner in push to secure vibe coding" (2026-04-21): https://www.axios.com/2026/04/21/cursor-chainguard-ai-code-security
- Business Insider, "Lovable's security stumble shows one big risk in using AI to code" (2026-04): https://www.businessinsider.com/lovable-security-access-vibe-coding-projects-risk-2026-4

## Anti-Patterns And Harness Regulations

| # | Category | Vibe-coding anti-pattern | Real-world failure mode | Senior-dev counter-practice | Proposed Unfading harness regulation |
|---:|---|---|---|---|---|
| 1 | Architecture coherence | Prompting for local patches without preserving system shape | New code compiles but duplicates state, bypasses existing abstractions, or creates parallel UI paths | Start with architecture map, owned modules, dependency boundaries, and explicit non-goals | Every Swift dispatch brief must include "owned files", "reused assets", "forbidden parallel abstractions", and "expected imports". Codex must review for duplicate module creation before implementation merges. |
| 2 | Code reuse | Generating copy-paste variants instead of reusable units | GitClear observed rising code cloning and short-term churn in AI-assisted code; UI components diverge by screen | Extract shared modifiers/styles/types first; write one composable API and tests | Gate 5 implementation criterion: every new UI pattern repeated twice must be a reusable `Shared/` asset or an explicit rejected-abstraction note. |
| 3 | Context mismatch | Trusting stale docs or hallucinated project state | Round 1 found `SESSION_RESUME.md` described 140 tests while workspace had 10; agents would plan against false reality | Verify source tree, test count, active files, and current UI before coding | Every round spec must include a "Reality Snapshot" with file count, test count, tracked/untracked state, and source hashes. Any mismatch with resume docs is a blocker until reconciled. |
| 4 | Memory safety | Missing lifecycle/cancellation/retention checks in generated async/UI code | Retain cycles, tasks outliving views, stale callbacks mutating UI after dismissal | Audit escaping closures, `Task`, observers, timers, and deinit/onDisappear cancellation | Swift review checklist must include `[weak self]`/capture review, task cancellation review, and `@MainActor` boundary review for stores/view models. |
| 5 | Concurrency | Adding async work without actor isolation or race analysis | Data races, UI updates off-main, duplicate network calls, inconsistent selected state | Make state ownership explicit; use `@MainActor` for UI state and isolate stores | Any new stateful Swift type must declare actor assumptions (`@MainActor`, value type, or documented immutable data). Codex review blocks unowned mutable shared state. |
| 6 | Error handling | Using happy-path code or swallowing errors | `try?`, empty catches, failed save/upload silently losing user data | Propagate typed errors, log with context, show user recovery | Grep lint: `try?` in app code requires an inline justification comment or is a review blocker. Save/upload flows require user-visible failure path. |
| 7 | UI/UX fidelity | Treating screenshots as decorative rather than contract | Generated UI "looks close" but misses spacing, hierarchy, target state, or primary action visibility; R4 FAB hidden at runtime | Runtime screenshot every user-facing surface, compare against contract states | Every visual round requires runtime screenshots of each acceptance state, not just static code review. Missing primary CTA in screenshot is a blocker. |
| 8 | Accessibility | Omitting VoiceOver order, labels, Dynamic Type, and 44pt targets | UI works for sighted/default-size users but fails accessibility or large text | Design controls with labels/hints, semantic fonts, `@ScaledMetric`, minimum hit areas | Swift lint forbids hardcoded `.system(size:)` outside theme-approved exceptions. Evidence must include grep for labels/hints on icon-only buttons and screenshots at accessibility size for major surfaces. |
| 9 | Security | Treating AI output as vetted | Veracode/industry reports found high rates of vulnerable AI-generated code; tools can omit auth, validation, secure storage | Threat model before implementation, least privilege, no secret exposure, static security checks | Any auth, storage, network, payment, or invitation feature requires a security subsection in spec and a red-team review before close. AI-generated code is considered untrusted until tests + review pass. |
| 10 | Dependency hygiene | Accepting hallucinated or outdated dependencies | Kaspersky and supply-chain reporting describe fictitious packages/slopsquatting and unsafe imports | Prefer platform APIs; require dependency review and lockfile diff | New dependency requires meeting approval, source URL, maintenance/security check, license note, and lockfile diff. No AI-suggested package may be added silently. |
| 11 | Data modeling | Creating UI-only sample structures that conflict with domain model | Screens ship with mock data that cannot map to `Group -> DateEvent -> Memory -> MemoryPost` | Model first, then view; maintain migration path from sample to persisted data | Any new screen using sample data must state its eventual domain model mapping. Sample English/model strings are allowed only with a future localization/data ticket. |
| 12 | Testing | Writing tests that assert existence rather than behavior | Tests pass while compose tab behavior, gesture routing, or selection flow is untested | Test state transitions, reducers, edge cases, and runtime behavior | Tests must cover at least one behavioral transition per new state object. Pure "enum contains case" tests are advisory only unless paired with behavior evidence. |
| 13 | Performance | Generating layout code that over-renders or blocks main thread | Large SwiftUI bodies, repeated expensive computations, image loading on main thread | Measure/render-scope review, lazy loading, small view decomposition | Review must flag large new `body` implementations, repeated image/data work in body, and non-lazy lists/grids. Performance-sensitive surfaces need Instruments or measured evidence before launch. |
| 14 | Review overload | AI creates more code than humans can review carefully | METR found experienced devs spent time prompting/reviewing; code-volume spikes move bottleneck to review | Smaller slices, narrow whitelists, explicit reviewer focus | Implementation rounds must cap write scope. If touched files exceed whitelist intent, open amendment or split round. Codex verdict must mention review surface size. |
| 15 | Process hallucination | Claiming compliance because a checker says green while checker scope is narrow | Earlier v5 checker passed despite governance drift; false sense of safety | Keep checker claims honest; write evidence of what was and was not checked | Every gate evidence file must include "unchecked assumptions". REGULATION must list not-enforced items explicitly until automated. |

## Minimum Dispatch Checklist

Before any Swift implementation dispatch, the brief must include:

1. Current reality snapshot: test count, touched files, current UI state, tracked/untracked status.
2. Reusable asset plan: existing modules reused and any new module API.
3. Forbidden patterns: colors, hardcoded font sizes, English UI strings, `try?`, new dependencies.
4. Runtime capture plan: screenshots or interaction evidence for changed UI states.
5. Test plan: unit tests for state and at least one behavior test per new state object.
6. Security/accessibility notes if the change touches auth, storage, network, payments, permissions, invitations, or user-generated content.
7. Evidence paths and expected hashes/logs.

## Senior Developer Standard For Unfading

LLM output is acceptable only when it is converted into a small, reviewable, reusable unit with:

- explicit contract,
- narrow whitelist,
- tests,
- runtime evidence,
- accessibility and security checks,
- Codex/Claude cross-validation,
- and honest documentation of remaining uncertainty.
