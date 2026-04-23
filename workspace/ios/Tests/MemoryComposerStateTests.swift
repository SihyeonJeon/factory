import PhotosUI
import SwiftUI
import XCTest
@testable import MemoryMap

@MainActor
final class MemoryComposerStateTests: XCTestCase {

    // vibe-limit-checked: 5 MainActor state, 12 behavioral state-transition tests
    func test_initial_state_is_empty_and_save_disabled() {
        let state = MemoryComposerState()
        XCTAssertTrue(state.note.isEmpty)
        XCTAssertTrue(state.selectedPhotos.isEmpty)
        XCTAssertFalse(state.isSaveEnabled)
        XCTAssertEqual(state.placeState, .needsConfirm)
    }

    func test_set_note_keeps_save_disabled_until_place_confirmed() {
        let state = MemoryComposerState()
        state.setNote("내용")
        XCTAssertFalse(state.isSaveEnabled)
    }

    func test_add_photo_keeps_save_disabled_until_place_confirmed() {
        let state = MemoryComposerState()
        state.selectedPhotos = [mockItem()]
        XCTAssertFalse(state.isSaveEnabled)
    }

    func test_toggle_mood_adds_then_removes() {
        let state = MemoryComposerState()
        let mood = MemoryDraftTag.samples[0]
        state.toggleMood(mood)
        XCTAssertTrue(state.selectedMoods.contains(mood))
        state.toggleMood(mood)
        XCTAssertFalse(state.selectedMoods.contains(mood))
    }

    func test_reset_clears_all_user_input() {
        let state = MemoryComposerState()
        state.setNote("내용")
        state.selectedPhotos = [mockItem()]
        state.toggleMood(MemoryDraftTag.samples[0])
        state.setPlace("다른 장소")

        state.reset()

        XCTAssertTrue(state.note.isEmpty)
        XCTAssertTrue(state.selectedPhotos.isEmpty)
        XCTAssertTrue(state.selectedMoods.isEmpty)
        XCTAssertEqual(state.selectedPlace, UnfadingLocalized.Composer.samplePlace)
        XCTAssertFalse(state.isSaveEnabled)
    }

    func test_confirm_place_enables_save_without_optional_fields() {
        let state = MemoryComposerState()
        state.confirmPlace()
        XCTAssertEqual(state.placeState, .confirmed)
        XCTAssertTrue(state.canSave)
        XCTAssertTrue(state.selectedMoods.isEmpty)
        XCTAssertNil(state.cost)
    }

    func test_needs_confirm_disables_save() {
        let state = MemoryComposerState(placeState: .needsConfirm)
        XCTAssertFalse(state.canSave)
    }

    func test_emotions_empty_save_ok_when_place_confirmed() {
        let state = MemoryComposerState(placeState: .confirmed)
        XCTAssertTrue(state.selectedMoods.isEmpty)
        XCTAssertTrue(state.canSave)
    }

    func test_couple_mode_clears_participants() {
        let state = MemoryComposerState()
        state.defaultParticipantSelection(mode: .couple, memberUserIds: [UUID()])
        XCTAssertTrue(state.participantUserIds.isEmpty)
    }

    func test_general_mode_defaults_participants_to_all_members() {
        let first = UUID()
        let second = UUID()
        let state = MemoryComposerState()
        state.defaultParticipantSelection(mode: .general, memberUserIds: [first, second])
        XCTAssertEqual(state.participantUserIds, Set([first, second]))
    }

    private func mockItem() -> PhotosPickerItem {
        PhotosPickerItem(itemIdentifier: "mock-photo")
    }
}
