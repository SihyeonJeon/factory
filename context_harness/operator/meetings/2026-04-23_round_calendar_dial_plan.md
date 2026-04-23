---
round: round_calendar_dial_r1
stage: implementation
status: draft
participants: [codex]
decision_id: r33-calendar-dial-plan
contract_hash: none
---

## Context
- Source contract: `context_harness/operator/contracts/round_calendar_dial_r1/spec.md`.
- Design source: `docs/design-docs/unfading_ref/design_handoff_unfading/README.md` section 7 Calendar.
- `round_calendar_dial_r1.lock` is absent in `context_harness/operator/locks/`; prior `round_calendar_r1.lock` is closed.

## Proposal
- Keep existing chevron month navigation and add tappable month label that opens a month picker sheet.
- Extend `UnfadingMonthGrid` with day kind dots: three primary memory dots and lavender plan dot.
- Build selected Day Detail with date/weather, event list, and general-group-only mint plan card.
- Add client-only `RSVPStore`, local `NotificationBroadcaster`, and bottom toast.
- Add RSVP unit tests and two Calendar UI tests.

## Questions
- Event rows do not currently include a persisted place field, so the plan card uses a Korean fallback place until the DB model expands.

## Counter / Review
- No peer review in this fresh implementation session.

## Convergence
- Implementation follows the contract scope and defers weather API and RSVP DB persistence as specified.

## Decision
- Proceed with local client-only Calendar plan UI for R33.

## Challenge Section
- Risk: local notification authorization can be denied; UI still shows the required toast because the round contract treats DB logging as deferred and asks for toast confirmation.
- Risk: test stability requires deterministic plan data; UI test mode injects a tomorrow plan in `MemoryCalendarStore` without affecting production.
