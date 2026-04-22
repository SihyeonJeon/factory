import XCTest
@testable import MemoryMap

@MainActor
final class MemorySelectionStateTests: XCTestCase {

    func test_initial_state_has_no_selection_default_filter_default_snap() {
        let state = MemorySelectionState()
        XCTAssertNil(state.selectedPinID)
        XCTAssertEqual(state.activeFilter, .all)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_select_sets_pin_and_expands_sheet() {
        let state = MemorySelectionState()
        let pin = SampleMemoryPin.samples.first!
        state.select(pinID: pin.id)
        XCTAssertEqual(state.selectedPinID, pin.id)
        XCTAssertEqual(state.sheetSnap, .expanded)
    }

    func test_selecting_same_pin_twice_clears_and_restores_default() {
        let state = MemorySelectionState()
        let pin = SampleMemoryPin.samples.first!
        state.select(pinID: pin.id)
        state.select(pinID: pin.id)
        XCTAssertNil(state.selectedPinID)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_selecting_different_pin_switches_selection() {
        let state = MemorySelectionState()
        let a = SampleMemoryPin.samples[0]
        let b = SampleMemoryPin.samples[1]
        state.select(pinID: a.id)
        state.select(pinID: b.id)
        XCTAssertEqual(state.selectedPinID, b.id)
        XCTAssertEqual(state.sheetSnap, .expanded)
    }

    func test_clearSelection_resets_snap_to_default() {
        let state = MemorySelectionState()
        state.select(pinID: SampleMemoryPin.samples.first!.id)
        state.clearSelection()
        XCTAssertNil(state.selectedPinID)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_toggleFilter_activates_then_reverts_to_all() {
        let state = MemorySelectionState()
        state.toggleFilter(.trip)
        XCTAssertEqual(state.activeFilter, .trip)
        state.toggleFilter(.trip)
        XCTAssertEqual(state.activeFilter, .all)
    }

    func test_toggleFilter_swaps_between_filters() {
        let state = MemorySelectionState()
        state.toggleFilter(.date)
        state.toggleFilter(.food)
        XCTAssertEqual(state.activeFilter, .food)
    }

    func test_selectedPin_resolves_id_to_sample() {
        let state = MemorySelectionState()
        let pin = SampleMemoryPin.samples[1]
        state.select(pinID: pin.id)
        XCTAssertEqual(state.selectedPin(from: SampleMemoryPin.samples)?.id, pin.id)
    }

    func test_selectedPin_returns_nil_when_no_selection() {
        let state = MemorySelectionState()
        XCTAssertNil(state.selectedPin(from: SampleMemoryPin.samples))
    }

    func test_filter_has_five_cases_matching_deepsight_plan() {
        XCTAssertEqual(MemorySelectionState.Filter.allCases.count, 5)
        XCTAssertEqual(MemorySelectionState.Filter.all.title, "전체")
        XCTAssertEqual(MemorySelectionState.Filter.date.title, "데이트")
        XCTAssertEqual(MemorySelectionState.Filter.trip.title, "여행")
        XCTAssertEqual(MemorySelectionState.Filter.anniversary.title, "기념일")
        XCTAssertEqual(MemorySelectionState.Filter.food.title, "맛집")
    }
}
