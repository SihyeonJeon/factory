import Foundation
import SwiftUI

/// Selection + filter + sheet-snap state for the main map surface. Extracted
/// from `MemoryMapHomeView` so behavior is testable without spinning up a
/// SwiftUI host. `@MainActor` because all writes originate from the UI thread
/// (pin taps, chip taps, sheet drag ends).
@MainActor
final class MemorySelectionState: ObservableObject {

    /// Filter categories shown in the map filter chip row. `all` is the default
    /// non-filtered state.
    enum Filter: String, CaseIterable, Hashable {
        case all
        case date
        case trip
        case anniversary
        case food

        /// Korean display title resolved at render time.
        var title: String {
            switch self {
            case .all: return UnfadingLocalized.Home.filterAll
            case .date: return UnfadingLocalized.Home.filterDate
            case .trip: return UnfadingLocalized.Home.filterTrip
            case .anniversary: return UnfadingLocalized.Home.filterAnniversary
            case .food: return UnfadingLocalized.Home.filterFood
            }
        }
    }

    @Published private(set) var selectedPinID: UUID?
    @Published private(set) var activeFilter: Filter = .all
    @Published var sheetSnap: BottomSheetSnap = .default_

    /// Select a pin. Selecting snaps the sheet to expanded; selecting the
    /// currently-selected pin again clears the selection and returns the sheet
    /// to its default snap.
    func select(pinID: UUID) {
        if selectedPinID == pinID {
            clearSelection()
            return
        }
        selectedPinID = pinID
        sheetSnap = .expanded
    }

    /// Clear any active pin selection and restore the default sheet snap.
    func clearSelection() {
        selectedPinID = nil
        sheetSnap = .default_
    }

    /// Toggle a filter. Selecting the currently-active filter reverts to
    /// `.all`; selecting a different filter replaces the active filter.
    /// Filtering does not modify sheet snap or selection.
    func toggleFilter(_ filter: Filter) {
        activeFilter = activeFilter == filter ? .all : filter
    }

    /// Resolve the currently-selected pin from a sample set. Returns `nil`
    /// when nothing is selected or when the ID is not in the set (treated as
    /// a no-op rather than an error per honest-agent defensive semantics).
    func selectedPin(from pins: [SampleMemoryPin]) -> SampleMemoryPin? {
        guard let id = selectedPinID else { return nil }
        return pins.first(where: { $0.id == id })
    }
}
