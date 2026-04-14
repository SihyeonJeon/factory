-- Migration: RPC for crew preview by invite code
-- Needed because RLS blocks non-members from reading crews table.
-- Used on the join page to show crew name/description before joining.

create or replace function public.get_crew_preview(p_invite_code text)
returns table (
  id uuid,
  name text,
  description text,
  member_count bigint
)
language sql
security definer
set search_path = ''
as $$
  select
    c.id,
    c.name,
    c.description,
    (select count(*) from public.crew_members cm where cm.crew_id = c.id) as member_count
  from public.crews c
  where c.invite_code = p_invite_code
  limit 1
$$;
