-- Moment MVP: Row Level Security Policies
-- All tables must have RLS enabled per project constraints.

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.guest_states enable row level security;
alter table public.media_timeline enable row level security;
alter table public.settlements enable row level security;
alter table public.reminders enable row level security;

-- ============================================================
-- profiles
-- ============================================================

-- Anyone can read profiles (needed for guest lists, host info)
create policy "profiles: public read"
  on public.profiles for select
  using (true);

-- Users can insert their own profile (triggered on first login)
create policy "profiles: self insert"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Users can update only their own profile
create policy "profiles: self update"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ============================================================
-- events
-- ============================================================

-- Anyone can read events (public event pages for OG/SSR)
create policy "events: public read"
  on public.events for select
  using (true);

-- Authenticated users can create events (they become host)
create policy "events: authenticated insert"
  on public.events for insert
  with check (auth.uid() = host_id);

-- Only the host can update their event
create policy "events: host update"
  on public.events for update
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

-- Only the host can delete their event
create policy "events: host delete"
  on public.events for delete
  using (auth.uid() = host_id);

-- ============================================================
-- guest_states
-- ============================================================

-- Host can see all guests for their event; guests can see co-attendees
create policy "guest_states: event participants read"
  on public.guest_states for select
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.events
      where events.id = guest_states.event_id
        and events.host_id = auth.uid()
    )
    or exists (
      select 1 from public.guest_states gs2
      where gs2.event_id = guest_states.event_id
        and gs2.user_id = auth.uid()
    )
  );

-- Authenticated users can RSVP to any event
create policy "guest_states: self insert"
  on public.guest_states for insert
  with check (auth.uid() = user_id);

-- Users can update only their own RSVP
create policy "guest_states: self update"
  on public.guest_states for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Users can delete only their own RSVP
create policy "guest_states: self delete"
  on public.guest_states for delete
  using (auth.uid() = user_id);

-- ============================================================
-- media_timeline
-- ============================================================

-- Anyone who RSVPed or is the host can view event media
create policy "media_timeline: event participants read"
  on public.media_timeline for select
  using (
    exists (
      select 1 from public.events
      where events.id = media_timeline.event_id
        and events.host_id = auth.uid()
    )
    or exists (
      select 1 from public.guest_states
      where guest_states.event_id = media_timeline.event_id
        and guest_states.user_id = auth.uid()
    )
  );

-- Authenticated event participants can upload photos
create policy "media_timeline: participant insert"
  on public.media_timeline for insert
  with check (
    auth.uid() = uploader_id
    and (
      exists (
        select 1 from public.events
        where events.id = media_timeline.event_id
          and events.host_id = auth.uid()
      )
      or exists (
        select 1 from public.guest_states
        where guest_states.event_id = media_timeline.event_id
          and guest_states.user_id = auth.uid()
      )
    )
  );

-- Users can delete only their own uploads
create policy "media_timeline: self delete"
  on public.media_timeline for delete
  using (auth.uid() = uploader_id);

-- ============================================================
-- settlements
-- ============================================================

-- Host and event participants can read settlement
create policy "settlements: event participants read"
  on public.settlements for select
  using (
    exists (
      select 1 from public.events
      where events.id = settlements.event_id
        and events.host_id = auth.uid()
    )
    or exists (
      select 1 from public.guest_states
      where guest_states.event_id = settlements.event_id
        and guest_states.user_id = auth.uid()
    )
  );

-- Only host can create/update settlement
create policy "settlements: host insert"
  on public.settlements for insert
  with check (
    exists (
      select 1 from public.events
      where events.id = settlements.event_id
        and events.host_id = auth.uid()
    )
  );

create policy "settlements: host update"
  on public.settlements for update
  using (
    exists (
      select 1 from public.events
      where events.id = settlements.event_id
        and events.host_id = auth.uid()
    )
  );

-- ============================================================
-- reminders
-- ============================================================

-- Host can read reminders for their events
create policy "reminders: host read"
  on public.reminders for select
  using (
    exists (
      select 1 from public.events
      where events.id = reminders.event_id
        and events.host_id = auth.uid()
    )
  );

-- Reminders are created by Edge Functions (service_role key),
-- so no insert policy for regular users.
-- Manual reminders from host use an Edge Function that validates host ownership.
