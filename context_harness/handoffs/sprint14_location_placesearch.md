# Sprint 14 — Location Permission on Launch + Place Search API

**Date:** 2026-04-14
**Source:** Human Feedback Round 2 — HF2-8, HF2-11
**Goal:** Request location on first launch, add MKLocalSearch-based place search

---

## Task 1: Location Permission on App Launch (HF2-8)

### Problem
앱 진입 시 위치 허용을 받지 않아 사용자가 직접 위치 버튼을 눌러야 함.

### Implementation

In `App/UnfadingApp.swift`:
- Add a `@StateObject` for `LocationPermissionStore` at the app level
- In the `.task` modifier, call `locationPermissionStore.handleCurrentLocationTap()` to trigger the system permission dialog on first launch when status is `.notDetermined`
- Pass the store via `.environmentObject()` so it's available app-wide

```swift
@StateObject private var locationPermissionStore = LocationPermissionStore()

// In body .task:
.task {
    // Request location on first launch
    locationPermissionStore.handleCurrentLocationTap()
    
    // existing sync + sample data code...
}
.environmentObject(locationPermissionStore)
```

In `Features/Home/UnfadingHomeView.swift`:
- Remove the local `@StateObject private var locationPermissionStore = LocationPermissionStore()` (line ~101)
- Replace with `@EnvironmentObject private var locationPermissionStore: LocationPermissionStore`
- This ensures a single LocationPermissionStore instance is shared app-wide

### Map Controls
- Ensure the map shows the user's current location dot when permission is granted
- The existing compass and location buttons should remain functional

---

## Task 2: Place Search via MKLocalSearch (HF2-11)

### Problem
장소명 검색으로 위치 정보까지 얻지 못함. 현재 검색은 데이트/추억명만 지원.

### Implementation

Create `Shared/PlaceSearchService.swift`:

```swift
import MapKit

@MainActor
final class PlaceSearchService: ObservableObject {
    @Published var results: [MKMapItem] = []
    @Published var isSearching = false
    
    private var searchTask: Task<Void, Never>?
    
    func search(query: String, region: MKCoordinateRegion? = nil) {
        searchTask?.cancel()
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }
        
        isSearching = true
        searchTask = Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = trimmed
                if let region {
                    request.region = region
                }
                request.resultTypes = .pointOfInterest
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                guard !Task.isCancelled else { return }
                results = Array(response.mapItems.prefix(5))
            } catch {
                if !Task.isCancelled {
                    results = []
                }
            }
            isSearching = false
        }
    }
    
    func cancel() {
        searchTask?.cancel()
        results = []
        isSearching = false
    }
}
```

In `Features/Home/UnfadingHomeView.swift`:

Add a third section to the search autocomplete overlay — "장소" section with MKLocalSearch results:

```swift
@StateObject private var placeSearchService = PlaceSearchService()

// In the search autocomplete overlay, after existing 데이트 and 추억 sections:

// Section 3: 장소 검색 결과
if !placeSearchService.results.isEmpty {
    VStack(alignment: .leading, spacing: 2) {
        Text("장소")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(UnfadingTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.top, 6)
        
        ForEach(placeSearchService.results, id: \.self) { item in
            Button {
                selectPlace(item)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(UnfadingTheme.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name ?? "")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(UnfadingTheme.textPrimary)
                        if let address = item.placemark.title {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(UnfadingTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// Trigger place search alongside existing event/memory search:
.onChange(of: searchQuery) { _, newValue in
    isSearchActive = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    placeSearchService.search(query: newValue)
}
```

Add a `selectPlace` function:
```swift
private func selectPlace(_ item: MKMapItem) {
    let coordinate = item.placemark.coordinate
    cameraPosition = .region(MKCoordinateRegion(
        center: coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))
    clearSearch()
}
```

Also clean up search when clearing:
```swift
private func clearSearch() {
    searchQuery = ""
    isSearchActive = false
    placeSearchService.cancel()
    // existing clear logic...
}
```

---

## Files to create/modify

| File | Action |
|---|---|
| `Shared/PlaceSearchService.swift` | **NEW** — MKLocalSearch wrapper |
| `App/UnfadingApp.swift` | MODIFY — add LocationPermissionStore, request on launch |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — use EnvironmentObject for location, add place search section |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- Place search must debounce (cancel previous task on new input).
- Place search must not block UI.
- All new UI text in Korean.
- Use UnfadingTheme.
- All tap targets ≥ 44pt.
- Graceful handling when MKLocalSearch returns no results or errors.
