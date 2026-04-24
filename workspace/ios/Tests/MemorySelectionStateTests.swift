import CoreLocation
import MapKit
import XCTest
@testable import MemoryMap

@MainActor
final class MemorySelectionStateTests: XCTestCase {

    func test_initial_state_has_no_selection_default_filter_default_snap() {
        let state = MemorySelectionState()
        XCTAssertNil(state.selectedPinID)
        XCTAssertEqual(state.scene, .mapDefault)
        XCTAssertEqual(state.activeFilter, .all)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_select_sets_pin_and_keeps_default_sheet() {
        let state = MemorySelectionState()
        let pin = SampleMemoryPin.samples.first!
        state.select(pinID: pin.id)
        XCTAssertEqual(state.selectedPinID, pin.id)
        XCTAssertEqual(state.scene, .mapSelected)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_selecting_same_pin_twice_clears_and_restores_default() {
        let state = MemorySelectionState()
        let pin = SampleMemoryPin.samples.first!
        state.select(pinID: pin.id)
        state.select(pinID: pin.id)
        XCTAssertNil(state.selectedPinID)
        XCTAssertEqual(state.scene, .mapDefault)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_selecting_different_pin_switches_selection() {
        let state = MemorySelectionState()
        let a = SampleMemoryPin.samples[0]
        let b = SampleMemoryPin.samples[1]
        state.select(pinID: a.id)
        state.select(pinID: b.id)
        XCTAssertEqual(state.selectedPinID, b.id)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_clearSelection_resets_snap_to_default() {
        let state = MemorySelectionState()
        state.select(pinID: SampleMemoryPin.samples.first!.id)
        state.clearSelection()
        XCTAssertNil(state.selectedPinID)
        XCTAssertEqual(state.scene, .mapDefault)
        XCTAssertEqual(state.sheetSnap, .default_)
    }

    func test_selectCluster_sets_scene_and_resolves_cluster() {
        let state = MemorySelectionState()
        let clusters = MemoryClusterizer().clusterItems(
            for: MemoryStore.uiTestStubMemories(),
            in: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5519, longitude: 126.9215),
                latitudinalMeters: 300,
                longitudinalMeters: 300
            ),
            radiusOverride: 120
        )
        let cluster = clusters.first!
        state.select(cluster: cluster)
        XCTAssertEqual(state.scene, .mapSelected)
        XCTAssertEqual(state.selectedCluster(from: clusters)?.id, cluster.id)
    }

    func test_toggleFilter_activates_then_reverts_to_all() {
        let state = MemorySelectionState()
        state.toggleFilter(.cafe)
        XCTAssertEqual(state.activeFilter, .cafe)
        state.toggleFilter(.cafe)
        XCTAssertEqual(state.activeFilter, .all)
    }

    func test_toggleFilter_swaps_between_filters() {
        let state = MemorySelectionState()
        state.toggleFilter(.memory)
        state.toggleFilter(.food)
        XCTAssertEqual(state.activeFilter, .food)
    }

    func test_selectedMemory_resolves_id_to_memory() {
        let state = MemorySelectionState()
        let memories = MemoryStore.uiTestStubMemories()
        let memory = memories[1]
        state.select(pinID: memory.id)
        XCTAssertEqual(state.selectedMemory(from: memories)?.id, memory.id)
    }

    func test_selectedMemory_returns_nil_when_no_selection() {
        let state = MemorySelectionState()
        XCTAssertNil(state.selectedMemory(from: MemoryStore.uiTestStubMemories()))
    }

    func test_filter_has_five_cases_matching_deepsight_plan() {
        XCTAssertEqual(MemorySelectionState.Filter.allCases.count, 5)
        XCTAssertEqual(MemorySelectionState.Filter.all.title, "전체")
        XCTAssertEqual(MemorySelectionState.Filter.memory.title, "추억")
        XCTAssertEqual(MemorySelectionState.Filter.food.title, "밥")
        XCTAssertEqual(MemorySelectionState.Filter.cafe.title, "카페")
        XCTAssertEqual(MemorySelectionState.Filter.experience.title, "경험")
    }
}
