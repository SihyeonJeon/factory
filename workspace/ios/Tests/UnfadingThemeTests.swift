import SwiftUI
import XCTest
@testable import MemoryMap

/// Token + reusable-module unit tests for the Unfading theme namespace.
final class UnfadingThemeTests: XCTestCase {

    // MARK: Color tokens

    func test_design_handoff_color_tokens_match_hex_values() throws {
        let expected: [(SwiftUI.Color, Int, Int, Int)] = [
            (UnfadingTheme.Color.bg, 0xFF, 0xF8, 0xF0),
            (UnfadingTheme.Color.sheet, 0xFF, 0xFB, 0xF5),
            (UnfadingTheme.Color.card, 0xFF, 0xFF, 0xFF),
            (UnfadingTheme.Color.surface, 0xF5, 0xEE, 0xE4),
            (UnfadingTheme.Color.primary, 0xF5, 0x99, 0x8C),
            (UnfadingTheme.Color.primaryHover, 0xE8, 0x87, 0x7A),
            (UnfadingTheme.Color.accentSoft, 0xFA, 0xE4, 0xDD),
            (UnfadingTheme.Color.secondary, 0x8F, 0xB7, 0xA8),
            (UnfadingTheme.Color.secondaryLight, 0xCD, 0xE2, 0xDA),
            (UnfadingTheme.Color.textPrimary, 0x40, 0x38, 0x33),
            (UnfadingTheme.Color.textSecondary, 0x8C, 0x82, 0x7A),
            (UnfadingTheme.Color.textTertiary, 0xB8, 0xAE, 0xA5),
            (UnfadingTheme.Color.divider, 0xEB, 0xE1, 0xD4),
            (UnfadingTheme.Color.chipBg, 0xF5, 0xEE, 0xE4),
            (UnfadingTheme.Color.mapBase, 0xFF, 0xF3, 0xE6),
            (UnfadingTheme.Color.mapLand, 0xFF, 0xE8, 0xD1),
            (UnfadingTheme.Color.mapWater, 0xDC, 0xE7, 0xE4),
            (UnfadingTheme.Color.mapRoad, 0xF5, 0xEE, 0xE0)
        ]

        for (color, red, green, blue) in expected {
            let components = try resolveRGB(color)
            XCTAssertEqual(components.red, red)
            XCTAssertEqual(components.green, green)
            XCTAssertEqual(components.blue, blue)
        }
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
        XCTAssertEqual(components.green, 0xF8)
        XCTAssertEqual(components.blue, 0xF0)
    }

    func test_primary_aliases_coral() throws {
        let coral = try resolveRGB(UnfadingTheme.Color.coral)
        let primary = try resolveRGB(UnfadingTheme.Color.primary)
        XCTAssertEqual(coral.red, primary.red)
        XCTAssertEqual(coral.green, primary.green)
        XCTAssertEqual(coral.blue, primary.blue)
    }

    func test_member_palette_contains_ten_design_handoff_colors() {
        XCTAssertEqual(UnfadingTheme.Color.memberPalette.count, 10)
    }

    // MARK: Radius tokens

    func test_radius_covers_deepsight_scale() {
        XCTAssertEqual(UnfadingTheme.Radius.card, 18)
        XCTAssertEqual(UnfadingTheme.Radius.sheet, 28)
        XCTAssertEqual(UnfadingTheme.Radius.chip, 18)
        XCTAssertEqual(UnfadingTheme.Radius.segment, 12)
        XCTAssertEqual(UnfadingTheme.Radius.button, 16)
        XCTAssertEqual(UnfadingTheme.Radius.compact, 8)
    }

    // MARK: Sheet snap points

    func test_sheet_snap_points_match_deepsight() {
        XCTAssertEqual(UnfadingTheme.Sheet.collapsed, 0.08, accuracy: 0.0001)
        XCTAssertEqual(UnfadingTheme.Sheet.default, 0.50, accuracy: 0.0001)
        XCTAssertEqual(UnfadingTheme.Sheet.expanded, 1.0, accuracy: 0.0001)
    }

    // MARK: Spacing scale

    func test_spacing_is_monotonic() {
        let scale: [CGFloat] = [
            UnfadingTheme.Spacing.xxs,
            UnfadingTheme.Spacing.xs2,
            UnfadingTheme.Spacing.xs,
            UnfadingTheme.Spacing.xs1,
            UnfadingTheme.Spacing.sm,
            UnfadingTheme.Spacing.sm2,
            UnfadingTheme.Spacing.md,
            UnfadingTheme.Spacing.md2,
            UnfadingTheme.Spacing.lg,
            UnfadingTheme.Spacing.xl,
            UnfadingTheme.Spacing.xl2,
            UnfadingTheme.Spacing.xl3,
            UnfadingTheme.Spacing.sheetBottom,
            UnfadingTheme.Spacing.tabBarClear
        ]
        for (a, b) in zip(scale, scale.dropFirst()) {
            XCTAssertLessThan(a, b, "spacing scale must increase monotonically")
        }
        XCTAssertEqual(UnfadingTheme.Spacing.xxl, UnfadingTheme.Spacing.xl2)
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
