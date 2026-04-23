-- round_supabase_schema_r1 applied migrations (2026-04-23)
-- Captured via: select version, statements from supabase_migrations.schema_migrations where version >= '20260423'

-- 20260423023431 add_groups_cover_color_hex
alter table public.groups
  add column if not exists cover_color_hex text not null default '#F5998C';
comment on column public.groups.cover_color_hex is 'UnfadingTheme cover color for group hub; primary default is Coral';

-- 20260423023438 create_subscriptions_table
create table if not exists public.subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  product_id text not null,
  original_transaction_id text not null,
  purchased_at timestamptz not null,
  expires_at timestamptz,
  status text not null check (status in ('active','expired','in_grace_period','in_billing_retry','revoked')),
  auto_renew boolean not null default true,
  environment text not null default 'production' check (environment in ('production','sandbox')),
  updated_at timestamptz not null default timezone('utc', now())
);
create index if not exists subscriptions_status_expires_idx on public.subscriptions(status, expires_at);
alter table public.subscriptions enable row level security;
create policy subscriptions_select_self on public.subscriptions
  for select to authenticated using (auth.uid() = user_id);

-- 20260423023444 lock_memories_bucket
update storage.buckets
set public = false,
    file_size_limit = 25 * 1024 * 1024,
    allowed_mime_types = array['image/jpeg','image/png','image/heic','image/heif','image/webp']
where id = 'memories';

-- 20260423023449 memories_storage_rls (policies on storage.objects; path = <group_id>/<memory_id>/<filename>)
create policy memories_storage_select on storage.objects
  for select to authenticated using (
    bucket_id = 'memories' and exists (
      select 1 from public.group_members gm
      where gm.user_id = auth.uid()
        and gm.group_id::text = split_part(name, '/', 1)));
create policy memories_storage_insert on storage.objects
  for insert to authenticated with check (
    bucket_id = 'memories' and exists (
      select 1 from public.group_members gm
      where gm.user_id = auth.uid()
        and gm.group_id::text = split_part(name, '/', 1)));
create policy memories_storage_update on storage.objects
  for update to authenticated using (bucket_id='memories' and owner=auth.uid())
  with check (bucket_id='memories' and owner=auth.uid());
create policy memories_storage_delete on storage.objects
  for delete to authenticated using (bucket_id='memories' and owner=auth.uid());

-- 20260423023504 group_helper_rpcs (see migration in DB for full body)
-- Functions: create_group_with_membership(p_name,p_mode,p_intro,p_cover_color_hex)
--            join_group_by_code(p_code)
--            rotate_invite_code(p_group_id)
-- All SECURITY DEFINER with search_path=public; granted to authenticated.

-- 20260423023507 memory_reaction_count_trigger
-- Triggers: trg_memory_reaction_count_ins / _del on public.memory_reactions.

-- 20260423023509 group_members_select_any_same_group
drop policy if exists group_members_select on public.group_members;
create policy group_members_select on public.group_members
  for select to authenticated using (
    group_id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid()));

-- 20260423023528 fix_bump_memory_reaction_count_search_path
-- Re-created function with `set search_path = public, pg_temp` to resolve advisor 0011.
