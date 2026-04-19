# Sprint 10 — Supabase DB Schema Alignment + iOS Integration

**Date:** 2026-04-14
**Source:** Human Feedback Round 1 — HF-10, iOS Domain Model alignment
**Goal:** Align Supabase schema with iOS domain model, add missing tables/columns, set up RLS policies

---

## Current Schema (Supabase)

```
profiles (id, email, display_name, photo_url, created_at) — RLS enabled
groups (id, name, invite_code, created_at, created_by) — RLS enabled
group_members (id, group_id, user_id, joined_at) — RLS enabled
memories (id, user_id, group_id, photo_url, caption, location_lat, location_lng, address, date, geohash, created_at, title, category, cost, date_name, photo_urls, categories) — RLS enabled
```

## iOS Domain Model (source of truth)

```swift
DomainGroup: id, name, mode(couple/generalGroup), intro?, memberIDs, ownerID, createdAt
GroupInvitation: id, groupID, code, issuedAt, expiresAt
DomainEvent: id, groupID, title, startDate, endDate, isMultiDay
DomainMemory: id, groupID, eventID?, place(title,lat,lng), note, emotions[], cost?, costLabel?, photoLocalIdentifiers[], capturedAt, createdAt, authorID, reactionCount
EmotionTag: joy, calm, grateful, nostalgic, excited, bittersweet
```

---

## Migration Plan

### Migration 1: Enhance `groups` table
```sql
ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS mode text NOT NULL DEFAULT 'couple',
  ADD COLUMN IF NOT EXISTS intro text;
```

### Migration 2: Create `events` table
```sql
CREATE TABLE IF NOT EXISTS public.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  title text NOT NULL,
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  is_multi_day boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
```

### Migration 3: Create `group_invitations` table
```sql
CREATE TABLE IF NOT EXISTS public.group_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  code text NOT NULL UNIQUE,
  issued_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  expires_at timestamptz NOT NULL,
  created_by uuid REFERENCES public.profiles(id)
);

ALTER TABLE public.group_invitations ENABLE ROW LEVEL SECURITY;
```

### Migration 4: Enhance `memories` table
```sql
ALTER TABLE public.memories
  ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES public.events(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS note text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS place_title text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS cost_label text,
  ADD COLUMN IF NOT EXISTS emotions text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS captured_at timestamptz,
  ADD COLUMN IF NOT EXISTS reaction_count integer NOT NULL DEFAULT 0;

-- Migrate existing data
UPDATE public.memories SET note = COALESCE(caption, '') WHERE note = '';
UPDATE public.memories SET place_title = COALESCE(address, '') WHERE place_title = '';
UPDATE public.memories SET captured_at = COALESCE(date, created_at) WHERE captured_at IS NULL;
```

### Migration 5: Create `memory_reactions` table
```sql
CREATE TABLE IF NOT EXISTS public.memory_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  memory_id uuid NOT NULL REFERENCES public.memories(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji text NOT NULL DEFAULT '❤️',
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE(memory_id, user_id, emoji)
);

ALTER TABLE public.memory_reactions ENABLE ROW LEVEL SECURITY;
```

### Migration 6: RLS Policies

#### events
```sql
CREATE POLICY "Users can view events in their groups"
  ON public.events FOR SELECT
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can create events in their groups"
  ON public.events FOR INSERT
  WITH CHECK (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can update events in their groups"
  ON public.events FOR UPDATE
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete events in their groups"
  ON public.events FOR DELETE
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));
```

#### group_invitations
```sql
CREATE POLICY "Users can view invitations for their groups"
  ON public.group_invitations FOR SELECT
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can create invitations for their groups"
  ON public.group_invitations FOR INSERT
  WITH CHECK (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));
```

#### memory_reactions
```sql
CREATE POLICY "Users can view reactions in their groups"
  ON public.memory_reactions FOR SELECT
  USING (memory_id IN (SELECT id FROM public.memories WHERE group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())));

CREATE POLICY "Users can react to memories in their groups"
  ON public.memory_reactions FOR INSERT
  WITH CHECK (user_id = auth.uid() AND memory_id IN (SELECT id FROM public.memories WHERE group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())));

CREATE POLICY "Users can remove their own reactions"
  ON public.memory_reactions FOR DELETE
  USING (user_id = auth.uid());
```

### Migration 7: Indexes
```sql
CREATE INDEX IF NOT EXISTS idx_events_group_id ON public.events(group_id);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON public.events(start_date);
CREATE INDEX IF NOT EXISTS idx_memories_event_id ON public.memories(event_id);
CREATE INDEX IF NOT EXISTS idx_memories_group_id ON public.memories(group_id);
CREATE INDEX IF NOT EXISTS idx_memories_captured_at ON public.memories(captured_at);
CREATE INDEX IF NOT EXISTS idx_memories_geohash ON public.memories(geohash);
CREATE INDEX IF NOT EXISTS idx_group_invitations_code ON public.group_invitations(code);
CREATE INDEX IF NOT EXISTS idx_group_invitations_group_id ON public.group_invitations(group_id);
CREATE INDEX IF NOT EXISTS idx_memory_reactions_memory_id ON public.memory_reactions(memory_id);
```

---

## iOS Integration (Sprint 10 Part 2)

After schema migration, update iOS app to support Supabase sync:

1. Add `supabase-swift` package dependency
2. Create `SupabaseClient` singleton with project URL + anon key
3. Create `SupabaseMemoryStore` that syncs with local `MemoryStore`
4. Create `SupabaseGroupStore` that syncs with local `GroupStore`
5. Create `SupabaseEventStore` that syncs with local `EventStore`
6. Auth flow: email/password or Apple Sign-In via Supabase Auth

**NOTE:** iOS integration is a separate codex dispatch after schema is applied via MCP.
