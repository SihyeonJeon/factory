# Manual Dynamic Type Remediation Packet

Round: 4

## Goal

The harness now has:
- native build success
- XCTest hard gate
- evaluator loop

But it still has a concrete accessibility-quality failure:
- large Dynamic Type map-home layout collapses in runtime evidence

This round is dedicated to fixing that issue without regressing build/test gates.

## Current Truth

- build: passing
- tests: passing
- evaluation: can pass
- release quality: still incomplete because large-text map-home evidence is visibly broken

## Primary Evidence

- baseline large-text failure:
  - `context_harness/reports/runtime_large_text_20260408.png`
- post-remediation recapture still not acceptable:
  - local recapture during current session confirmed continued clipping/overlap on map home

## Hard Gates

Do not consider this round complete unless all are true:

1. `xcodebuild ... build` succeeds
2. `xcodebuild ... test` succeeds
3. large-text runtime screenshot for map home is visually readable
4. no catastrophic title/card overlap remains

## Scope

Focus only on the map-home large-text failure:
- top title area
- top filters / group / pin summary
- primary memory summary card
- safe interaction with bottom tab area

## Allowed Strategy

- create a dedicated accessibility-size layout for map home
- reduce information density for accessibility text sizes
- move secondary metadata below the fold
- replace side-by-side rows with stacked sections
- preserve map-first structure where reasonable, but prioritize readability at accessibility sizes

## Not In Scope

- new feature expansion
- visual-polish-only tweaks unrelated to large-text readability
- unrelated permission-flow work

## Deliverables

1. code change that improves large-text map-home layout
2. build success
3. test success
4. new large-text screenshot proving improvement
5. updated release packet note
