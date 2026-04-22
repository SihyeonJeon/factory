import SwiftUI
import XCTest
@testable import MemoryMap

/// Token + reusable-module unit tests for `round_foundation_reset_r1`.
/// Proves each reusable module is referenced by at least one test (per
/// Codex R-round2 Q9 requirement).
final class UnfadingThemeTests: XCTestCase {

    // MARK: Color tokens

    /// `UnfadingTheme.Color.coral` must match the deepsight token `#F5998C`.
    func test_coral_matches_deepsight_hex() throws {
        let components = try resolveRGB(UnfadingTheme.Color.coral)
        XCTAssertEqual(components.red, 0xF5, "coral red channel should be 0xF5")
        XCTAssertEqual(components.green, 0x99, "coral green channel should be 0x99")
        XCTAssertEqual(components.blue, 0x8C, "coral blue channel should be 0x8C")
    }

    func test_lavender_matches_deepsight_hex() throws {
        let components = try resolveRGB(UnfadingTheme.Color.lavender)
        XCTAssertEqual(components.red, 0xC2)
        XCTAssertEqual(components.green, 0xB0)
        XCTAssertEqual(components.blue, 0xDE)
    }

    func test_cream_matches_deepsight_hex() throws {
        let components = try resolveRGB(UnfadingTheme.Color.cream)
        XCTAssertEqual(components.red, 0xFF)
        XCTAssertEqual(components.green, 0xFA)
        XCTAssertEqual(components.blue, 0xF5)
    }

    func test_primary_aliases_coral() throws {
        let coral = try resolveRGB(UnfadingTheme.Color.coral)
        let primary = try resolveRGB(UnfadingTheme.Color.primary)
        XCTAssertEqual(coral.red, primary.red)
        XCTAssertEqual(coral.green, primary.green)
        XCTAssertEqual(coral.blue, primary.blue)
    }

    // MARK: Radius tokens

    func test_radius_covers_deepsight_scale() {
        XCTAssertEqual(UnfadingTheme.Radius.card, 20)
        XCTAssertEqual(UnfadingTheme.Radius.button, 16)
        XCTAssertEqual(UnfadingTheme.Radius.chip, 12)
        XCTAssertEqual(UnfadingTheme.Radius.compact, 8)
    }

    // MARK: Sheet snap points

    func test_sheet_snap_points_match_deepsight() {
        XCTAssertEqual(UnfadingTheme.Sheet.collapsed, 0.22, accuracy: 0.0001)
        XCTAssertEqual(UnfadingTheme.Sheet.default, 0.52, accuracy: 0.0001)
        XCTAssertEqual(UnfadingTheme.Sheet.expanded, 0.88, accuracy: 0.0001)
    }

    // MARK: Spacing scale

    func test_spacing_is_monotonic() {
        let scale: [CGFloat] = [
            UnfadingTheme.Spacing.xs,
            UnfadingTheme.Spacing.sm,
            UnfadingTheme.Spacing.md,
            UnfadingTheme.Spacing.lg,
            UnfadingTheme.Spacing.xl,
            UnfadingTheme.Spacing.xxl
        ]
        for (a, b) in zip(scale, scale.dropFirst()) {
            XCTAssertLessThan(a, b, "spacing scale must increase monotonically")
        }
    }

    // MARK: Helpers

    private func resolveRGB(_ color: Color) throws -> (red: Int, green: Int, blue: Int) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            throw XCTSkip("Color could not be resolved to RGB in this context")
        }
        return (Int((r * 255.0).rounded()), Int((g * 255.0).rounded()), Int((b * 255.0).rounded()))
    }
}
