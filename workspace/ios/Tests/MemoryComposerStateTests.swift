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
    }

    func test_set_note_enables_save() {
        let state = MemoryComposerState()
        state.setNote("내용")
        XCTAssertTrue(state.isSaveEnabled)
    }

    func test_add_photo_enables_save() {
        let state = MemoryComposerState()
        state.selectedPhotos = [mockItem()]
        XCTAssertTrue(state.isSaveEnabled)
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

    private func mockItem() -> PhotosPickerItem {
        PhotosPickerItem(itemIdentifier: "mock-photo")
    }
}
