Round 3 remediation complete. Here's the summary:

**Assessment — most blockers were already resolved in prior rounds:**
- C-1 to C-5 (mock data, missing APIs, open redirect) — all fixed in R1
- H-1 to H-3 (API validation, UUID checks) — all fixed in R2
- H-4 (privacy consent) — already implemented with checkbox + privacy page
- H-5 (error leakage) — already returns generic messages
- H-6 (settlement) — full implementation exists (create, mark_paid, Toss/KakaoPay deep links)
- M-1 (feeIntention validation) — already implemented
- M-2 (photo dot touch targets) — already fixed with 44px min touch area

**Fixes applied in this round (3 remaining items):**

| Finding | Fix | File |
|---------|-----|------|
| M-3: Decorative SVGs missing `aria-hidden` | Added `aria-hidden="true"` to 6 SVG icons | `rsvp-status-selector.tsx`, `photo-swipe-viewer.tsx` |
| M-4: SW caches `/_next/data/` with auth data | Changed to network-only (no caching) for `/_next/data/` routes | `public/sw.js` |
| L-2: Dead code `mock-event.ts` | Deleted (confirmed zero imports) | `src/lib/mock-event.ts` |
