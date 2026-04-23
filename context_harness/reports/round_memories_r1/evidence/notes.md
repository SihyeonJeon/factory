# round_memories_r1 evidence notes

## Realtime subscription design

`MemoryStore.subscribeRealtime(groupId:)` creates one `RealtimeChannelV2` per active group using topic `memories:<groupId>`. It registers INSERT, UPDATE, and DELETE streams on `public.memories` with `RealtimePostgresFilter.eq("group_id", value: groupId)`, then subscribes with `subscribeWithError()`.

The app owns the returned `Task<Void, Never>`. `MemoryMapApp` cancels the old task whenever `GroupStore.activeGroupId` changes, then loads the new group and opens a fresh subscription. This keeps one live group subscription per app scene.

## Filter cardinality and leak semantics

The chosen design uses server-side group filtering instead of subscribing to all memory changes and filtering in Swift. This keeps event volume proportional to the active group and aligns with RLS: authenticated users should only see memories for groups they belong to. RLS remains the security boundary; the client filter is a bandwidth and correctness guard, not an authorization mechanism.

The tradeoff is churn when users switch groups. That is acceptable for R19 because only one active group is visible at a time. A future multi-group inbox could add one aggregate channel per visible group or a dedicated feed RPC.

## Dedup-on-reconnect

Create/update events use id-based `upsert`, so local optimistic mutation and realtime echo converge to a single row. Reconnect replay or duplicate INSERT events replace the existing row by id, then sort by `date` descending.

Delete events decode `oldRecord` as `DBMemory` and remove by id. This assumes the realtime payload includes enough old-row data. If Postgres replica identity only sends the primary key, the delete decode will fail and log; local `deleteMemory(id:)` still removes rows initiated by this client, and a later reload repairs stale rows from server state.

## Offline cache

Successful `loadMemories(for:)` writes plain JSON to `Documents/memory-cache-<groupId>.json` using `JSONEncoder.dateEncodingStrategy = .iso8601`. On fetch failure, the store attempts to decode the same file with `.iso8601` and reports `.loaded` if cache is restored. If both network and cache fail, state becomes `.error`.

Tests inject an explicit temp cache URL to prove fetch → cache write → forced repo error → cache restore.

## SDK surface decisions

The implementation uses Supabase Swift 2.x APIs already present in R18 derived data:

- PostgREST: `db.from("memories").select().eq(...).order(...).execute().value`
- Inserts/updates: `.insert(..., returning: .representation).select().single()`
- Realtime: `SupabaseService.shared.realtime.channel(...)`, `channel.postgresChange(InsertAction.self, schema: "public", table: "memories", filter: ...)`, `subscribeWithError()`, and `removeChannel(_:)`.

## Verification

`xcodegen generate` completed successfully.

The requested test command was attempted:

```sh
xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,id=00FCC049-D60A-4426-8EE3-EA743B48CCF9' -derivedDataPath .deriveddata/r19 -resultBundlePath .deriveddata/r19/Test-R19.xcresult
```

It stopped with exit code 74 before compilation because SPM package resolution could not reach GitHub (`Could not resolve host: github.com`). The same run also reported CoreSimulatorService connection failures in the sandbox.
