-- Fix: guest_states SELECT policy causes infinite recursion
-- The old policy queries guest_states inside its own RLS check,
-- triggering the same policy again → infinite loop.
--
-- Solution: Use a SECURITY DEFINER function to check co-attendance
-- without triggering RLS on the inner query. (S-002, S-006)

-- 1. Helper function: check if user is a participant of the event
create or replace function public.is_event_participant(p_event_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.events
    where id = p_event_id and host_id = p_user_id
  )
  or exists (
    select 1 from public.guest_states
    where event_id = p_event_id and user_id = p_user_id
  )
$$;

-- 2. Drop the old recursive policy
drop policy if exists "guest_states: event participants read" on public.guest_states;

-- 3. Create fixed policy using the helper function
create policy "guest_states: event participants read"
  on public.guest_states for select
  using (
    auth.uid() = user_id
    or public.is_event_participant(event_id, auth.uid())
  );

-- 4. Fix media_timeline and settlements policies that also query guest_states
--    (their inner SELECT on guest_states would trigger guest_states RLS → potential recursion)

-- media_timeline SELECT
drop policy if exists "media_timeline: event participants read" on public.media_timeline;
create policy "media_timeline: event participants read"
  on public.media_timeline for select
  using (public.is_event_participant(event_id, auth.uid()));

-- media_timeline INSERT
drop policy if exists "media_timeline: participant insert" on public.media_timeline;
create policy "media_timeline: participant insert"
  on public.media_timeline for insert
  with check (
    auth.uid() = uploader_id
    and public.is_event_participant(event_id, auth.uid())
  );

-- settlements SELECT
drop policy if exists "settlements: event participants read" on public.settlements;
create policy "settlements: event participants read"
  on public.settlements for select
  using (public.is_event_participant(event_id, auth.uid()));

-- settlements INSERT (host only — check via events table, no recursion risk)
-- No change needed: only queries events table, not guest_states.

-- settlements UPDATE (host only — same, no change needed)
