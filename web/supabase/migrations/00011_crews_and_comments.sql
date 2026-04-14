-- Migration: Crews, crew memberships, event comments
-- Expands Moment from one-off event management to crew-based recording + feed platform
--
-- Design decisions:
-- - invite_code: 24-char hex (96-bit entropy) — shorter than UUID for KakaoTalk sharing
-- - events.crew_id ON DELETE SET NULL — deleting a crew preserves event history
-- - Comments scoped to events (not crews) — standalone events also get comments
-- - SECURITY DEFINER helpers to avoid RLS recursion (S-017)

-- ============================================================
-- 1. Enum type
-- ============================================================
create type public.crew_role as enum ('admin', 'member');

-- ============================================================
-- 2. Tables
-- ============================================================

create table public.crews (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 50),
  description text not null default '' check (char_length(description) <= 500),
  cover_image_url text,
  invite_code text unique not null default encode(gen_random_bytes(12), 'hex'),
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.crew_members (
  id uuid primary key default gen_random_uuid(),
  crew_id uuid not null references public.crews(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.crew_role not null default 'member',
  joined_at timestamptz not null default now(),
  unique (crew_id, user_id)
);

create table public.event_comments (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

-- Add optional crew link to events
alter table public.events
  add column crew_id uuid references public.crews(id) on delete set null;

-- Indexes
create index idx_events_crew_id on public.events(crew_id) where crew_id is not null;
create index idx_crew_members_user on public.crew_members(user_id);
create index idx_crew_members_crew on public.crew_members(crew_id);
create index idx_event_comments_event on public.event_comments(event_id);
create index idx_event_comments_author on public.event_comments(author_id);

-- ============================================================
-- 3. SECURITY DEFINER helper functions (S-002, S-006, S-017)
-- ============================================================

create or replace function public.is_crew_member(p_crew_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.crew_members
    where crew_id = p_crew_id and user_id = p_user_id
  )
$$;

create or replace function public.is_crew_admin(p_crew_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.crew_members
    where crew_id = p_crew_id and user_id = p_user_id and role = 'admin'
  )
$$;

-- ============================================================
-- 4. RLS policies
-- ============================================================

alter table public.crews enable row level security;
alter table public.crew_members enable row level security;
alter table public.event_comments enable row level security;

-- crews
create policy "crews: member read"
  on public.crews for select
  using (public.is_crew_member(id, auth.uid()));

create policy "crews: authenticated insert"
  on public.crews for insert
  with check (auth.uid() = created_by);

create policy "crews: admin update"
  on public.crews for update
  using (public.is_crew_admin(id, auth.uid()));

create policy "crews: admin delete"
  on public.crews for delete
  using (public.is_crew_admin(id, auth.uid()));

-- crew_members
create policy "crew_members: member read"
  on public.crew_members for select
  using (public.is_crew_member(crew_id, auth.uid()));

create policy "crew_members: self insert"
  on public.crew_members for insert
  with check (auth.uid() = user_id);

create policy "crew_members: admin update"
  on public.crew_members for update
  using (public.is_crew_admin(crew_id, auth.uid()));

create policy "crew_members: self or admin delete"
  on public.crew_members for delete
  using (
    auth.uid() = user_id
    or public.is_crew_admin(crew_id, auth.uid())
  );

-- event_comments
create policy "event_comments: participant read"
  on public.event_comments for select
  using (public.is_event_participant(event_id, auth.uid()));

create policy "event_comments: participant insert"
  on public.event_comments for insert
  with check (
    auth.uid() = author_id
    and public.is_event_participant(event_id, auth.uid())
  );

create policy "event_comments: author or host delete"
  on public.event_comments for delete
  using (
    auth.uid() = author_id
    or exists (
      select 1 from public.events
      where events.id = event_comments.event_id
        and events.host_id = auth.uid()
    )
  );

-- ============================================================
-- 5. RPCs (transactional operations)
-- ============================================================

-- Create crew + auto-join as admin (atomic)
create or replace function public.create_crew(
  p_name text,
  p_description text default ''
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_crew_id uuid;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if char_length(trim(p_name)) = 0 or char_length(p_name) > 50 then
    raise exception 'Invalid crew name';
  end if;

  insert into public.crews (name, description, created_by)
  values (trim(p_name), trim(p_description), v_user_id)
  returning id into v_crew_id;

  insert into public.crew_members (crew_id, user_id, role)
  values (v_crew_id, v_user_id, 'admin');

  return v_crew_id;
end;
$$;

-- Join crew by invite code (idempotent)
create or replace function public.join_crew_by_invite(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_crew_id uuid;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select id into v_crew_id
  from public.crews
  where invite_code = p_invite_code;

  if v_crew_id is null then
    raise exception 'Invalid invite code';
  end if;

  insert into public.crew_members (crew_id, user_id, role)
  values (v_crew_id, v_user_id, 'member')
  on conflict (crew_id, user_id) do nothing;

  return v_crew_id;
end;
$$;

-- ============================================================
-- 6. Realtime for comments
-- ============================================================
alter publication supabase_realtime add table public.event_comments;
