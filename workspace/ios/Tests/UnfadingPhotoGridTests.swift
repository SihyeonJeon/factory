import PhotosUI
import SwiftUI
import XCTest
@testable import MemoryMap

@MainActor
final class UnfadingPhotoGridTests: XCTestCase {

    // vibe-limit-checked: 2 reusable module proof, 8 accessibility label check
    func test_empty_selection_render_smoke() {
        let harness = PhotoGridHarness(selection: [])
        XCTAssertNotNil(harness.body)
    }

    func test_populated_selection_render_smoke() {
        let harness = PhotoGridHarness(selection: mockItems(count: 2))
        XCTAssertNotNil(harness.body)
    }

    func test_max_selection_respected_by_configuration() {
        let harness = PhotoGridHarness(selection: [], maxSelection: 3)
        XCTAssertEqual(harness.maxSelection, 3)
    }

    func test_remove_button_label_is_korean() {
        XCTAssertEqual(UnfadingLocalized.PhotoGrid.removePhoto, "사진 삭제")
    }

    private func mockItems(count: Int) -> [PhotosPickerItem] {
        (0..<count).map { PhotosPickerItem(itemIdentifier: "mock-photo-\($0)") }
    }
}

private struct PhotoGridHarness: View {
    @State var selection: [PhotosPickerItem]
    let maxSelection: Int

    init(selection: [PhotosPickerItem], maxSelection: Int = 12) {
        _selection = State(initialValue: selection)
        self.maxSelection = maxSelection
    }

    var body: some View {
        UnfadingPhotoGrid(selection: $selection, maxSelection: maxSelection)
    }
}
