All blockers fixed:

1. **H-1 (security)**: `reminders/send/route.ts` — Added `UUID_RE` validation on `event_id` before the Supabase query and edge function call, matching the pattern in `rsvp/route.ts` and `settlement/route.ts`. The check now rejects any non-UUID string with a 400 response.

2. **M-1 (accessibility)**: `photo-upload-button.tsx` — Added `aria-hidden="true"` to the decorative upload SVG icon so screen readers skip it.

3. **M-2 (accessibility)**: `photos-page-view.tsx` — Added `aria-hidden="true"` to the decorative back-arrow SVG, consistent with the rest of the codebase.
