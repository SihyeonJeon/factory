Build passes, implementation is complete. Here's the implementation report:

---

## Implementation Report: Supabase Realtime 구독 (guest_states)

### Changed Files

| File | Purpose |
|------|---------|
| `src/hooks/use-realtime-guests.ts` | Replaced mock data with real Supabase Realtime subscription. Initial fetch uses joined query (`guest_states` + `profiles`). Subscribes to `postgres_changes` for INSERT/UPDATE/DELETE on `guest_states` filtered by `event_id`. Deduplication guard on INSERT to handle race with initial fetch. Profile lookup on INSERT for display_name/avatar. Cleanup unsubscribes channel on unmount. |
| `src/components/dashboard/dashboard-view.tsx` | Removed `simulateNewRsvp` demo button and unused `Button` import. Dashboard now consumes live Realtime data. |

### How It Works

1. **Initial load**: Queries `guest_states` joined with `profiles` via `profiles:user_id(display_name, avatar_url)`, ordered by `responded_at`.
2. **Realtime channel**: Subscribes to `event:{eventId}:guests` with three handlers:
   - **INSERT**: Fetches the new guest's profile, maps to `DashboardGuest`, appends with dedup guard.
   - **UPDATE**: Patches status, companion_count, fee_intention, responded_at in-place.
   - **DELETE**: Removes the guest by id.
3. **Cleanup**: `supabase.removeChannel(channel)` on unmount.

### Prerequisites (already met)

- `guest_states` is published to `supabase_realtime` (migration `00001`, line 120).
- RLS policies on `guest_states` allow read access for event participants (migration `00002`).

### Dependencies for Next Subtask

- `calcAttendanceCounts` is still imported from `mock-dashboard.ts` — this utility is production-ready (pure function), but the file name is misleading. A future cleanup could extract it to a dedicated module (e.g., `src/lib/attendance.ts`).
- The `"pending"` guest status concept (invited but not yet RSVP'd) is not tracked in the current schema — `guest_states` only stores actual responses. If an invitations table is added later, the hook can be extended to merge pending invitees.
