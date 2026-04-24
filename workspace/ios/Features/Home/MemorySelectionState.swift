import Foundation
import SwiftUI

/// Selection + filter + sheet-snap state for the main map surface. Extracted
/// from `MemoryMapHomeView` so behavior is testable without spinning up a
/// SwiftUI host. `@MainActor` because all writes originate from the UI thread
/// (pin taps, chip taps, sheet drag ends).
@MainActor
final class MemorySelectionState: ObservableObject {
    enum Scene: String, Hashable {
        case mapDefault
        case mapSelected
    }

    /// Filter categories shown in the map filter chip row. `all` is the default
    /// non-filtered state.
    enum Filter: String, CaseIterable, Hashable {
        case all
        case memory
        case food
        case cafe
        case experience

        /// Korean display title resolved at render time.
        var title: String {
            switch self {
            case .all: return UnfadingLocalized.Home.filterAll
            case .memory: return "추억"
            case .food: return "밥"
            case .cafe: return "카페"
            case .experience: return "경험"
            }
        }

        var systemImage: String {
            switch self {
            case .all: return "sparkles"
            case .memory: return "heart.fill"
            case .food: return "fork.knife"
            case .cafe: return "cup.and.saucer.fill"
            case .experience: return "safari.fill"
            }
        }
    }

    @Published private(set) var selectedPinID: UUID?
    @Published private(set) var scene: Scene = .mapDefault
    @Published private(set) var activeFilter: Filter = .all
    @Published var sheetSnap: BottomSheetSnap = .default_

    /// Select a pin. Selecting snaps the sheet to default; selecting the
    /// currently-selected pin again clears the selection and keeps default snap.
    func select(pinID: UUID) {
        if selectedPinID == pinID {
            clearSelection()
            return
        }
        selectedPinID = pinID
        scene = .mapSelected
        sheetSnap = .default_
    }

    /// Select the representative pin for a clustered annotation. The selected
    /// cluster is later resolved from the current rendered cluster set.
    func select(cluster: ClusterItem) {
        select(pinID: cluster.representativeMemory.id)
    }

    /// Clear any active pin selection and restore the default sheet snap.
    func clearSelection() {
        selectedPinID = nil
        scene = .mapDefault
        sheetSnap = .default_
    }

    /// Toggle a filter. Selecting the currently-active filter reverts to
    /// `.all`; selecting a different filter replaces the active filter.
    /// Filtering does not modify sheet snap or selection.
    func toggleFilter(_ filter: Filter) {
        activeFilter = activeFilter == filter ? .all : filter
    }

    /// Resolve the currently-selected memory from a rendered set. Returns `nil`
    /// when nothing is selected or when the ID is not in the set (treated as
    /// a no-op rather than an error per honest-agent defensive semantics).
    func selectedMemory(from memories: [DBMemory]) -> DBMemory? {
        guard let id = selectedPinID else { return nil }
        return memories.first(where: { $0.id == id })
    }

    func selectedCluster(from clusters: [ClusterItem]) -> ClusterItem? {
        guard let id = selectedPinID else { return nil }
        return clusters.first { cluster in
            cluster.memories.contains { $0.id == id }
        }
    }
}
