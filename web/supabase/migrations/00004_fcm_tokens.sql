-- Add FCM push token storage to profiles for Firebase Cloud Messaging
-- Used by send-reminder Edge Function for D-1 cron notifications

alter table public.profiles
  add column fcm_token text,
  add column fcm_token_updated_at timestamptz;

create index idx_profiles_fcm_token on public.profiles(id)
  where fcm_token is not null;

comment on column public.profiles.fcm_token is 'Firebase Cloud Messaging device token';
comment on column public.profiles.fcm_token_updated_at is 'Last time FCM token was refreshed';
