# Sprint 10 — iOS Supabase Integration

**Date:** 2026-04-14
**Source:** HF-10, Supabase schema alignment complete
**Goal:** Add supabase-swift SDK, create sync layer between local stores and Supabase

---

## Prerequisites (DONE)

Supabase schema already deployed via MCP:
- `profiles`, `groups`, `group_members`, `group_invitations`, `events`, `memories`, `memory_reactions`
- All tables have RLS enabled with group-membership policies
- Indexes on foreign keys, dates, geohash

## Supabase Project Config

- URL: `https://umkbjxycdgfhgwcnfbmo.supabase.co`
- Anon/Publishable Key: `sb_publishable_eA_S-ojxFJwFV53VN6k4Nw_KfcGTZm3`

---

## Task 1: Add Supabase Swift Package

In `project.yml`, add the Supabase Swift SDK as a Swift Package dependency:

```yaml
packages:
  Supabase:
    url: https://github.com/supabase/supabase-swift
    from: "2.0.0"
```

And add dependency to the Unfading target:
```yaml
dependencies:
  - sdk: MapKit.framework
  - package: Supabase
    product: Supabase
```

---

## Task 2: Create SupabaseManager

Create `Shared/SupabaseManager.swift`:

```swift
import Supabase
import Foundation

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://umkbjxycdgfhgwcnfbmo.supabase.co")!,
            supabaseKey: "sb_publishable_eA_S-ojxFJwFV53VN6k4Nw_KfcGTZm3"
        )
    }
}
```

---

## Task 3: Create Supabase DTOs (Data Transfer Objects)

Create `Shared/Domain/SupabaseModels.swift`:

Map between Supabase JSON rows and iOS domain models:

```swift
// Supabase row structs (Codable, matching DB column names)
struct SupabaseMemory: Codable {
    let id: UUID
    let user_id: UUID
    let group_id: UUID
    let event_id: UUID?
    let title: String
    let note: String
    let place_title: String
    let location_lat: Double
    let location_lng: Double
    let cost: Int?
    let cost_label: String?
    let emotions: [String]
    let captured_at: Date?
    let created_at: Date
    let reaction_count: Int
    let photo_urls: [String]?
    let date_name: String?
    
    func toDomain(authorID: UUID) -> DomainMemory {
        DomainMemory(
            id: id,
            groupID: group_id,
            eventID: event_id,
            place: PlaceRef(title: place_title, latitude: location_lat, longitude: location_lng),
            note: note,
            emotions: emotions.compactMap { EmotionTag(rawValue: $0) },
            cost: cost.map { Double($0) },
            costLabel: cost_label,
            photoLocalIdentifiers: photo_urls ?? [],
            capturedAt: captured_at ?? created_at,
            createdAt: created_at,
            authorID: authorID,
            reactionCount: reaction_count
        )
    }
}

struct SupabaseEvent: Codable {
    let id: UUID
    let group_id: UUID
    let title: String
    let start_date: Date
    let end_date: Date
    let is_multi_day: Bool
    
    func toDomain() -> DomainEvent {
        DomainEvent(
            id: id,
            groupID: group_id,
            title: title,
            startDate: start_date,
            endDate: end_date
        )
    }
}

struct SupabaseGroup: Codable {
    let id: UUID
    let name: String
    let mode: String
    let intro: String?
    let invite_code: String
    let created_at: Date
    let created_by: UUID
    
    func toDomain() -> DomainGroup {
        DomainGroup(
            id: id,
            name: name,
            mode: GroupMode(rawValue: mode) ?? .couple,
            intro: intro,
            memberIDs: [],
            ownerID: created_by,
            createdAt: created_at
        )
    }
}
```

---

## Task 4: Create SupabaseSync Service

Create `Shared/SupabaseSync.swift`:

A service that syncs local store data with Supabase:

```swift
@MainActor
final class SupabaseSync: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    
    private let client = SupabaseManager.shared.client
    
    // Fetch all memories for current user's groups
    func fetchMemories() async throws -> [DomainMemory] { ... }
    
    // Upload a new memory
    func uploadMemory(_ memory: DomainMemory) async throws { ... }
    
    // Fetch events for a group
    func fetchEvents(groupID: UUID) async throws -> [DomainEvent] { ... }
    
    // Create event
    func createEvent(_ event: DomainEvent) async throws { ... }
    
    // Fetch groups for current user
    func fetchGroups() async throws -> [DomainGroup] { ... }
    
    // Join group by invite code
    func joinGroup(code: String) async throws -> DomainGroup { ... }
}
```

Implement each method using `client.from("table").select/insert/update/delete`.

---

## Task 5: Integrate into App

In `UnfadingApp.swift`:
- Create `@StateObject private var supabaseSync = SupabaseSync()`
- Inject as `.environmentObject(supabaseSync)`

In views that create/modify data:
- After local store changes, call `supabaseSync.uploadMemory()` etc.
- On app launch, call `supabaseSync.fetchMemories()` to hydrate local stores

---

## Task 6: Auth Placeholder

Create `Shared/AuthManager.swift`:
- Basic auth state management
- For now: anonymous/guest mode (no login required)
- Placeholder for future Apple Sign-In integration
- Store a local UUID as "current user ID"

---

## Files to create/modify

| File | Action |
|---|---|
| `project.yml` | MODIFY — add Supabase package dependency |
| `Shared/SupabaseManager.swift` | NEW |
| `Shared/Domain/SupabaseModels.swift` | NEW |
| `Shared/SupabaseSync.swift` | NEW |
| `Shared/AuthManager.swift` | NEW |
| `App/UnfadingApp.swift` | MODIFY — inject SupabaseSync |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All tests must pass (≥79).
- Do NOT break any existing functionality.
- All new UI text in Korean.
- Supabase key is the publishable/anon key — safe to include in client code.
