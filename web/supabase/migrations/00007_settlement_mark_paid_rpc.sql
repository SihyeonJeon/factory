-- Atomic mark_paid function using row-level lock to prevent race conditions
create or replace function public.mark_participant_paid(
  p_event_id uuid,
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_settlement settlements%rowtype;
  v_statuses jsonb;
  v_idx int;
begin
  -- Lock the settlement row to prevent concurrent updates
  select * into v_settlement
  from settlements
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
    end if;
  end loop;

  update settlements
  set participant_statuses = v_statuses
  where id = v_settlement.id;

  return v_statuses;
end;
$$;
