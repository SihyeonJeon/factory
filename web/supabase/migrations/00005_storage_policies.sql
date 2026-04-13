-- Moment MVP: Supabase Storage bucket + RLS policies for media_timeline
-- Bucket: event-media
-- Path pattern: {event_id}/{uploader_id}/{uuid}.{ext}

-- ============================================================
-- 1. Create the storage bucket
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'event-media',
  'event-media',
  false,
  10485760,  -- 10 MB
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do nothing;

-- ============================================================
-- 2. Storage RLS policies
-- ============================================================

-- READ: Event participants (host or RSVP'd guest) can view media
create policy "event-media: participant read"
  on storage.objects for select
  using (
    bucket_id = 'event-media'
    and (
      -- Extract event_id from path: "{event_id}/{uploader_id}/{filename}"
      exists (
        select 1 from public.events
        where events.id = (storage.foldername(name))[1]::uuid
          and events.host_id = auth.uid()
      )
      or exists (
        select 1 from public.guest_states
        where guest_states.event_id = (storage.foldername(name))[1]::uuid
          and guest_states.user_id = auth.uid()
      )
    )
  );

-- INSERT: Authenticated participants can upload to their own folder
create policy "event-media: participant upload"
  on storage.objects for insert
  with check (
    bucket_id = 'event-media'
    and auth.uid() is not null
    -- Uploader folder must match the authenticated user
    and (storage.foldername(name))[2]::uuid = auth.uid()
    -- User must be host or RSVP'd guest
    and (
      exists (
        select 1 from public.events
        where events.id = (storage.foldername(name))[1]::uuid
          and events.host_id = auth.uid()
      )
      or exists (
        select 1 from public.guest_states
        where guest_states.event_id = (storage.foldername(name))[1]::uuid
          and guest_states.user_id = auth.uid()
      )
    )
  );

-- DELETE: Only the uploader can delete their own files
create policy "event-media: uploader delete"
  on storage.objects for delete
  using (
    bucket_id = 'event-media'
    and (storage.foldername(name))[2]::uuid = auth.uid()
  );
