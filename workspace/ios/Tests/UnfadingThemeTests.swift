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
            let components = try resolveRGB(color, style: .light)
            XCTAssertEqual(components.red, red)
            XCTAssertEqual(components.green, green)
            XCTAssertEqual(components.blue, blue)
        }
    }

    func test_dark_palette_matches_round_r47_values() throws {
        let expected: [(SwiftUI.Color, Int, Int, Int)] = [
            (UnfadingTheme.Color.bg, 0x1C, 0x17, 0x14),
            (UnfadingTheme.Color.sheet, 0x22, 0x1C, 0x18),
            (UnfadingTheme.Color.card, 0x2B, 0x23, 0x20),
            (UnfadingTheme.Color.surface, 0x32, 0x29, 0x24),
            (UnfadingTheme.Color.primary, 0xF5, 0x99, 0x8C),
            (UnfadingTheme.Color.textPrimary, 0xF2, 0xEA, 0xE2),
            (UnfadingTheme.Color.textSecondary, 0xBB, 0xA8, 0x9C),
            (UnfadingTheme.Color.textTertiary, 0x6D, 0x60, 0x5A),
            (UnfadingTheme.Color.divider, 0x3A, 0x2F, 0x28)
        ]

        for (color, red, green, blue) in expected {
            let components = try resolveRGB(color, style: .dark)
            XCTAssertEqual(components.red, red)
            XCTAssertEqual(components.green, green)
            XCTAssertEqual(components.blue, blue)
        }
    }

    func test_lavender_matches_deepsight_hex() throws {
        let components = try resolveRGB(UnfadingTheme.Color.lavender, style: .light)
        XCTAssertEqual(components.red, 0xC2)
        XCTAssertEqual(components.green, 0xB0)
        XCTAssertEqual(components.blue, 0xDE)
    }

    func test_cream_matches_deepsight_hex() throws {
        let components = try resolveRGB(UnfadingTheme.Color.cream, style: .light)
        XCTAssertEqual(components.red, 0xFF)
        XCTAssertEqual(components.green, 0xF8)
        XCTAssertEqual(components.blue, 0xF0)
    }

    func test_primary_aliases_coral() throws {
        let coral = try resolveRGB(UnfadingTheme.Color.coral, style: .dark)
        let primary = try resolveRGB(UnfadingTheme.Color.primary, style: .dark)
        XCTAssertEqual(coral.red, primary.red)
        XCTAssertEqual(coral.green, primary.green)
        XCTAssertEqual(coral.blue, primary.blue)
    }

    func test_adaptive_helper_switches_by_interface_style() throws {
        // 정확한 (255,0,0)/(0,0,255) 를 위해 SwiftUI `.red`/`.blue` 대신 명시 RGB 사용
        let adaptive = UnfadingTheme.Color.adaptive(
            light: SwiftUI.Color(red: 1, green: 0, blue: 0),
            dark: SwiftUI.Color(red: 0, green: 0, blue: 1)
        )

        let light = try resolveRGB(adaptive, style: .light)
        XCTAssertEqual(light.red, 255)
        XCTAssertEqual(light.green, 0)
        XCTAssertEqual(light.blue, 0)

        let dark = try resolveRGB(adaptive, style: .dark)
        XCTAssertEqual(dark.red, 0)
        XCTAssertEqual(dark.green, 0)
        XCTAssertEqual(dark.blue, 255)
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

    private func resolveRGB(_ color: Color, style: UIUserInterfaceStyle) throws -> (red: Int, green: Int, blue: Int) {
        let traitCollection = UITraitCollection(userInterfaceStyle: style)
        let uiColor = UIColor(color).resolvedColor(with: traitCollection)
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
