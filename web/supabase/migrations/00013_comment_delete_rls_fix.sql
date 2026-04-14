-- Fix: event_comments DELETE policy uses direct events subquery
-- Should use SECURITY DEFINER helper to avoid future RLS issues (S-017)

-- Helper: check if user is comment author or event host
create or replace function public.can_delete_comment(p_event_id uuid, p_author_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select p_user_id = p_author_id
    or exists (
      select 1 from public.events
      where id = p_event_id and host_id = p_user_id
    )
$$;

-- Replace the old policy
drop policy if exists "event_comments: author or host delete" on public.event_comments;

create policy "event_comments: author or host delete"
  on public.event_comments for delete
  using (public.can_delete_comment(event_id, author_id, auth.uid()));
