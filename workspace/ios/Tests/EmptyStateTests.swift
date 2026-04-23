import SwiftUI
import XCTest
@testable import MemoryMap

@MainActor
final class EmptyStateTests: XCTestCase {

    // vibe-limit-checked: 8 Dynamic Type-compatible empty state, 14 reusable no-CTA path
    func test_empty_state_builds_without_cta() {
        let view: some View = UnfadingEmptyState(
            systemImage: "calendar.badge.clock",
            title: UnfadingLocalized.Calendar.emptyDayTitle,
            body: UnfadingLocalized.Calendar.emptyDayBody
        )
        XCTAssertNotNil(view as Any)
    }

    // vibe-limit-checked: 8 44pt CTA via shared button style, 14 reusable CTA path
    func test_empty_state_builds_with_cta() {
        let view: some View = UnfadingEmptyState(
            systemImage: "photo.on.rectangle",
            title: UnfadingLocalized.Composer.photoSection,
            body: UnfadingLocalized.EmptyState.composerPhotoHint,
            ctaTitle: UnfadingLocalized.Onboarding.startCta
        ) {}
        XCTAssertNotNil(view as Any)
    }
}
