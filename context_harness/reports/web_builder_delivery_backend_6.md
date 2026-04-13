Build passes, implementation is complete. Here's the implementation report:

---

## Implementation Report: settlement-calc Edge Function (1/N + 딥링크)

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/functions/settlement-calc/index.ts` | Edge Function — 1/N settlement calculation + Toss/KakaoPay deep link generation |

### Function Design

**3 actions via POST `/settlement-calc`:**

| Action | Caller | Description |
|--------|--------|-------------|
| `create` | Host only | Inputs `total_amount`, queries attending guests, calculates `Math.ceil(total / headCount)`, upserts into `settlements` table. Host is auto-included and marked `paid: true`. |
| `mark_paid` | Host only | Marks a specific participant as paid by updating `participant_statuses` JSONB. |
| `get` | Any authenticated participant | Returns settlement data. If the caller is an unpaid participant, includes Toss (`supertoss://`) and KakaoPay (`kakaotalk://kakaopay/`) deep links prefilled with `per_person` amount. |

### Key Decisions

- **Host included in split**: The host is added to `participant_statuses` with `paid: true` (they fronted the bill), so the 1/N denominator includes them.
- **`Math.ceil` rounding**: Per-person amount rounds up to avoid under-collection. The host absorbs any remainder.
- **Upsert on `event_id`**: One settlement per event, re-creating recalculates if guest list changed.
- **Auth**: JWT verified via `supabase.auth.getUser(token)`. Host ownership checked against `events.host_id`.
- **Deep links**: `supertoss://send?amount=N&msg=...` and `kakaotalk://kakaopay/money/to/send?amount=N` — no PG license required, just app-to-app redirect.

### Dependencies for Next Subtask

- The `og-image` Edge Function is the remaining backend lane task.
- Frontend `/dashboard/[id]/settlement` page will consume this function's `get` and `mark_paid` actions.
