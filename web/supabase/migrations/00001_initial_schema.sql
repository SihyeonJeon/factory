-- Moment MVP: Initial Schema Migration
-- Tables: profiles, events, guest_states, media_timeline, settlements, reminders

-- ============================================================
-- 1. profiles
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  kakao_id text unique,
  display_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now()
);

comment on table public.profiles is '사용자 프로필 (카카오 연동)';

-- ============================================================
-- 2. events
-- ============================================================
create type public.event_mood as enum (
  'birthday', 'running', 'wine', 'book', 'houseparty', 'salon'
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  datetime timestamptz not null,
  location text not null default '',
  mood public.event_mood not null default 'houseparty',
  cover_image_url text,
  color_theme jsonb not null default '{"primary":"#6366f1","bg":"#f5f3ff","accent":"#a78bfa"}'::jsonb,
  description text not null default '',
  has_fee boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table public.events is '모임 이벤트 메타데이터';

create index idx_events_host_id on public.events(host_id);
create index idx_events_datetime on public.events(datetime);

-- ============================================================
-- 3. guest_states
-- ============================================================
create type public.rsvp_status as enum ('attending', 'declined', 'maybe');
create type public.fee_intention as enum ('will_pay', 'undecided');

create table public.guest_states (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status public.rsvp_status not null default 'maybe',
  companion_count int not null default 0 check (companion_count >= 0 and companion_count <= 10),
  fee_intention public.fee_intention,
  responded_at timestamptz not null default now(),

  unique (event_id, user_id)
);

comment on table public.guest_states is '게스트 RSVP 응답 상태';

create index idx_guest_states_event_id on public.guest_states(event_id);
create index idx_guest_states_user_id on public.guest_states(user_id);

-- ============================================================
-- 4. media_timeline
-- ============================================================
create table public.media_timeline (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  uploader_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  thumbnail_path text,
  width int,
  height int,
  uploaded_at timestamptz not null default now()
);

comment on table public.media_timeline is '모임별 사진·미디어 타임라인';

create index idx_media_timeline_event_id on public.media_timeline(event_id);

-- ============================================================
-- 5. settlements
-- ============================================================
create table public.settlements (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  total_amount int not null check (total_amount > 0),
  per_person int not null check (per_person > 0),
  participant_statuses jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),

  unique (event_id)
);

comment on table public.settlements is '정산 (1/N 분할 + 딥링크)';

-- ============================================================
-- 6. reminders
-- ============================================================
create type public.reminder_type as enum ('d1', 'manual');

create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  type public.reminder_type not null default 'd1',
  sent_at timestamptz not null default now(),
  fcm_batch_id text
);

comment on table public.reminders is '리마인더 발송 기록';

create index idx_reminders_event_id on public.reminders(event_id);

-- ============================================================
-- Realtime publication
-- ============================================================
alter publication supabase_realtime add table public.guest_states;
