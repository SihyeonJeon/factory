-- Fix C-2: Move fcm_token out of publicly-readable profiles table
-- into a dedicated fcm_tokens table with restrictive RLS.
-- Only the owning user can read/write their token; service_role can read all.

-- 1. Create dedicated FCM tokens table
create table if not exists public.fcm_tokens (
  user_id uuid primary key references auth.users(id) on delete cascade,
  token text not null,
  updated_at timestamptz not null default now()
);

comment on table public.fcm_tokens is 'FCM push tokens — isolated from public profiles read policy';

-- 2. Migrate existing data
insert into public.fcm_tokens (user_id, token, updated_at)
select id, fcm_token, coalesce(fcm_token_updated_at, now())
from public.profiles
where fcm_token is not null
on conflict (user_id) do nothing;

-- 3. Drop columns from profiles
alter table public.profiles
  drop column if exists fcm_token,
  drop column if exists fcm_token_updated_at;

-- 4. Enable RLS
alter table public.fcm_tokens enable row level security;

-- Users can read only their own token
create policy "fcm_tokens: self read"
  on public.fcm_tokens for select
  using (auth.uid() = user_id);

-- Users can insert their own token
create policy "fcm_tokens: self insert"
  on public.fcm_tokens for insert
  with check (auth.uid() = user_id);

-- Users can update their own token
create policy "fcm_tokens: self update"
  on public.fcm_tokens for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Users can delete their own token
create policy "fcm_tokens: self delete"
  on public.fcm_tokens for delete
  using (auth.uid() = user_id);
