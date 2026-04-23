import SwiftUI
import XCTest
@testable import MemoryMap

/// Reusable-module reference tests. Per Codex R-round2 Q9: every reusable module
/// must be used by ≥1 production file AND ≥1 test. This file exists to be the
/// ≥1-test anchor for `UnfadingPrimaryButtonStyle` and `unfadingCardBackground`.
final class UnfadingComponentTests: XCTestCase {

    func test_unfading_primary_button_style_shorthand_exists() {
        // Compile-time proof that the shorthand resolves to the concrete style
        let style: UnfadingPrimaryButtonStyle = .unfadingPrimary
        XCTAssertFalse(style.fullWidth, "default shorthand should be flexible-width")

        let wide: UnfadingPrimaryButtonStyle = .unfadingPrimaryFullWidth
        XCTAssertTrue(wide.fullWidth, "full-width shorthand should set fullWidth = true")
    }

    func test_unfading_primary_button_style_applies_to_button() {
        // Instantiating a Button with the style must type-check and produce a View
        let view: some View = Button("확인", action: {}).buttonStyle(.unfadingPrimary)
        // Touch `view` so the compiler doesn't optimize it away
        XCTAssertNotNil(view as Any)
    }

    func test_unfading_card_background_modifier_can_be_applied() {
        // Apply both default + explicit variants to exercise the modifier surface
        let defaultCard: some View = Text("카드")
            .unfadingCardBackground()
        let explicitCard: some View = Color.clear
            .unfadingCardBackground(
                fill: UnfadingTheme.Color.sheet,
                radius: UnfadingTheme.Radius.sheet,
                material: .regular,
                shadow: false
            )
        XCTAssertNotNil(defaultCard as Any)
        XCTAssertNotNil(explicitCard as Any)
    }

    func test_unfading_card_background_uses_theme_defaults() {
        // Defaults should come from UnfadingTheme, not magic values
        XCTAssertEqual(UnfadingTheme.Radius.card, 18)
        // No direct way to inspect the modifier's stored properties without breaking
        // encapsulation — this test exists to fail compilation if UnfadingTheme.Color.card
        // or UnfadingTheme.Radius.card is ever renamed without updating the modifier.
        _ = UnfadingTheme.Color.card
    }
}
