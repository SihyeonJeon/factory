# Manual Product Advancement And Release Closure Packet

Round: 3

## Goal

Current status is not a true all-green release, and it is also not a fully realized product.

All evaluators are only at:
- `APPROVED WITH MANDATORY CONDITIONS`
- `CONDITIONALLY APPROVED`
- `UNBLOCKED WITH MANDATORY CONDITIONS`

The next loop must do two things together:

1. convert conditional approval into unconditional approval by closing the remaining evidence and validation gaps
2. continue substantive product improvement so each loop increases actual capability rather than only documentation quality

## Original brief

Use `context_harness/product_inputs/*.md` and `context_harness/prd/ui_ux_screen_contract.md` as the source of truth for the native iOS map-first memory app.

## This Round Is Not

- not a new feature round
- not a broad refactor round
- not an automatic autopilot round

## This Round Is

- a manual operator-directed release-closure round
- a product-advancement round with release closure constraints
- focused on producing both:
  - missing runtime evidence
  - real implementation improvements on still-thin product flows

## Product Reality Check

The app now has:
- a map-first native shell
- native build and runtime proof
- better accessibility labeling
- explicit runtime permission request UI

The app still lacks strong proof or completion for several meaningful product flows:
- memory creation flow
- photo attachment flow
- sharing / couple-group collaboration depth
- denied-state fallback UX
- dark mode / large text runtime polish

The next loop should improve those surfaces, not just describe them.

## Remaining Evaluator Conditions

### Red Team

- accessibility verification
- permission flow testing
- dark mode validation
- stronger evidence for memory creation / photo attachment / sharing flows

### HIG

- VoiceOver navigation order verification
- Dynamic Type verification
- dark mode screenshot evidence
- permission prompt verification

### Visual QA

- dark mode screenshot
- Dynamic Type screenshot
- expanded bottom-sheet evidence
- permission prompt appearance evidence

## Operator Instructions

1. Treat the remaining work as `product advancement under release constraints`.
2. Require every loop to ship at least one real product improvement plus the evidence needed to evaluate it.
3. Ask development lanes for the smallest code changes that:
   - improve real user-facing capability
   - expose testable states
   - reduce evaluator uncertainty
4. Prefer artifacts over prose:
   - screenshots
   - simulator captures
   - explicit audit notes
   - runtime logs
5. Re-run evaluation only after the new evidence set exists.

## Required Product Improvement Themes For This Round

At least one of these must materially improve before the next evaluation:

1. memory creation first step and permission-aware entry UX
2. photo attachment / memory input path
3. denied-state fallback surfaces for location or photos
4. expanded bottom-sheet interaction and navigation depth
5. dark mode / large text layout resilience

## Required Deliverables For Next Manual Loop

1. a concrete product improvement on one of the themes above
2. dark mode runtime screenshot of the map-first home screen
3. large Dynamic Type runtime screenshot of the same screen
4. permission prompt evidence for:
   - location
   - photos
   - notifications
5. expanded bottom-sheet screenshot
6. manual accessibility audit note covering:
   - VoiceOver order
   - touch targets
   - contrast
7. brief note on denied-state handling for permissions

## Acceptance For This Round

The next evaluation should no longer say:
- "mandatory conditions"
- "must complete within"
- "pending verification"
- "missing visual evidence"

The target outcome is:
- plain approval from all evaluator lanes
- plus a visibly more complete product than the previous loop
