Done. The fix for **H-1** (release-blocker-security) has been committed.

**What changed** (`web/src/app/api/media/upload/route.ts`):
- After UUID validation, the route now queries `events` to confirm the event exists (returns 404 if not)
- If the user is not the host (`event.host_id`), it checks `guest_states` for a matching `user_id` + `event_id`
- Returns 403 with Korean error message if the user is neither host nor guest
- Minimal change set: 30 lines added, no other files touched
