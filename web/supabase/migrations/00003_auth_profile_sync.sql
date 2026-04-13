-- Profile sync trigger: auto-create/update profiles row on OAuth sign-in
-- Extracts kakao_id, display_name, avatar_url from auth.users raw_user_meta_data

-- ============================================================
-- Function: handle_new_user
-- Called by trigger on auth.users after INSERT (new sign-up)
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  _kakao_id text;
  _display_name text;
  _avatar_url text;
  _provider text;
begin
  _provider := coalesce(new.raw_app_meta_data ->> 'provider', '');

  -- Extract profile info based on OAuth provider
  if _provider = 'kakao' then
    -- Kakao: nickname and profile image from kakao_account
    _kakao_id := new.raw_user_meta_data ->> 'sub';
    _display_name := coalesce(
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'preferred_username',
      new.raw_user_meta_data ->> 'full_name',
      ''
    );
    _avatar_url := coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    );
  elsif _provider = 'apple' then
    -- Apple: limited profile info (name may only come on first sign-in)
    _kakao_id := null;
    _display_name := coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'email',
      ''
    );
    _avatar_url := null;
  else
    -- Fallback for any other provider
    _kakao_id := null;
    _display_name := coalesce(
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'email',
      ''
    );
    _avatar_url := new.raw_user_meta_data ->> 'avatar_url';
  end if;

  insert into public.profiles (id, kakao_id, display_name, avatar_url)
  values (new.id, _kakao_id, _display_name, _avatar_url)
  on conflict (id) do update set
    kakao_id = coalesce(excluded.kakao_id, public.profiles.kakao_id),
    display_name = case
      when excluded.display_name = '' then public.profiles.display_name
      else excluded.display_name
    end,
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);

  return new;
end;
$$;

-- ============================================================
-- Trigger: on_auth_user_created
-- Fires after a new user is inserted into auth.users
-- ============================================================
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ============================================================
-- Function: handle_user_updated
-- Called on auth.users UPDATE (e.g., token refresh with new metadata)
-- ============================================================
create or replace function public.handle_user_updated()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  _display_name text;
  _avatar_url text;
  _provider text;
begin
  _provider := coalesce(new.raw_app_meta_data ->> 'provider', '');

  if _provider = 'kakao' then
    _display_name := coalesce(
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'preferred_username',
      new.raw_user_meta_data ->> 'full_name'
    );
    _avatar_url := coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    );
  elsif _provider = 'apple' then
    _display_name := coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    );
    _avatar_url := null;
  else
    _display_name := coalesce(
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name'
    );
    _avatar_url := new.raw_user_meta_data ->> 'avatar_url';
  end if;

  -- Only update if we have new non-null values
  update public.profiles set
    display_name = case
      when _display_name is not null and _display_name != '' then _display_name
      else public.profiles.display_name
    end,
    avatar_url = coalesce(_avatar_url, public.profiles.avatar_url)
  where id = new.id;

  return new;
end;
$$;

-- ============================================================
-- Trigger: on_auth_user_updated
-- Fires after an existing user's metadata is updated
-- ============================================================
create or replace trigger on_auth_user_updated
  after update of raw_user_meta_data on auth.users
  for each row
  when (old.raw_user_meta_data is distinct from new.raw_user_meta_data)
  execute function public.handle_user_updated();
