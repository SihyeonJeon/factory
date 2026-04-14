-- Harden mark_participant_paid RPC:
-- 1. Pin search_path to prevent search_path injection (SECURITY DEFINER best practice)
-- 2. Raise exception when target user_id is not found in participant_statuses
create or replace function public.mark_participant_paid(
  p_event_id uuid,
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_settlement public.settlements%rowtype;
  v_statuses jsonb;
  v_idx int;
  v_host_id uuid;
  v_found boolean := false;
begin
  -- Verify caller is the event host
  select host_id into v_host_id
  from public.events
  where id = p_event_id;

  if v_host_id is null or v_host_id != auth.uid() then
    raise exception 'unauthorized';
  end if;

  -- Lock the settlement row to prevent concurrent updates
  select * into v_settlement
  from public.settlements
  where event_id = p_event_id
  for update;

  if v_settlement is null then
    raise exception 'settlement_not_found';
  end if;

  v_statuses := v_settlement.participant_statuses;

  -- Find and update the target user's paid status
  for v_idx in 0..jsonb_array_length(v_statuses) - 1 loop
    if v_statuses->v_idx->>'user_id' = p_user_id::text then
      v_statuses := jsonb_set(
        v_statuses,
        array[v_idx::text, 'paid'],
        'true'::jsonb
      );
      v_found := true;
    end if;
  end loop;

  if not v_found then
    raise exception 'participant_not_found';
  end if;

  update public.settlements
  set participant_statuses = v_statuses
  where id = v_settlement.id;

  return v_statuses;
end;
$$;
