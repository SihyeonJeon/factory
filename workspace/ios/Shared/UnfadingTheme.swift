import SwiftUI

/// Canonical Unfading design token namespace. All colors, radii, spacing, typography,
/// and sheet snap points consumed by the UI layer MUST be read from here. No inline
/// `Color.*` or magic radii are permitted in `App/`, `Features/`, `Shared/` outside
/// this file (enforced by `round_foundation_reset_r1` acceptance and the operator
/// grep lint).
enum UnfadingTheme {

    // MARK: Color

    enum Color {
        /// Primary coral from deepsight token panel (`#F5998C`).
        static let coral: SwiftUI.Color = Self.hex(0xF5, 0x99, 0x8C)

        /// Semantic alias for coral — use this for primary brand accents.
        static var primary: SwiftUI.Color { coral }

        /// Soft coral tint for selected chips, tinted backgrounds, and subtle accents
        /// (≈ `rgba(245,153,140,0.15)`).
        static let primarySoft: SwiftUI.Color = coral.opacity(0.15)

        /// Lavender secondary from deepsight panel (`#C2B0DE`).
        static let lavender: SwiftUI.Color = Self.hex(0xC2, 0xB0, 0xDE)

        /// Warm cream background from deepsight panel (`#FFFAF5`).
        static let cream: SwiftUI.Color = Self.hex(0xFF, 0xFA, 0xF5)

        /// Warm bottom sheet surface (`#FFF8F0`).
        static let sheet: SwiftUI.Color = Self.hex(0xFF, 0xF8, 0xF0)

        /// Card surface (`#FAF2EB`) for content modules on warm backgrounds.
        static let card: SwiftUI.Color = Self.hex(0xFA, 0xF2, 0xEB)

        /// Generic warm surface equal to `card`. Provided as an alias for readability
        /// where a non-card warm fill is used.
        static var surface: SwiftUI.Color { card }

        /// Primary warm text (`#403833`).
        static let textPrimary: SwiftUI.Color = Self.hex(0x40, 0x38, 0x33)

        /// Secondary warm text (`#8C8078`).
        static let textSecondary: SwiftUI.Color = Self.hex(0x8C, 0x80, 0x78)

        /// Tertiary warm text (`#B5A89E`).
        static let textTertiary: SwiftUI.Color = Self.hex(0xB5, 0xA8, 0x9E)

        /// Text/icon foreground on the coral primary fill.
        static let textOnPrimary: SwiftUI.Color = .white

        /// Text/icon foreground on warm overlay surfaces (formerly inline
        /// `Color.white.opacity(...)` surfaces). We keep the base color as white
        /// at 92% opacity so overlays composited over coral preserve legibility.
        static let textOnOverlay: SwiftUI.Color = SwiftUI.Color.white.opacity(0.92)

        /// Subtle card/surface drop-shadow color (warm-neutral, ≈ 6% black).
        /// Replaces inline `Color.black.opacity(0.06)` in card modifiers.
        static let shadow: SwiftUI.Color = SwiftUI.Color.black.opacity(0.06)

        /// Pin marker shadow (slightly stronger than `shadow`).
        static let pinShadow: SwiftUI.Color = SwiftUI.Color.black.opacity(0.18)

        private static func hex(_ r: Int, _ g: Int, _ b: Int) -> SwiftUI.Color {
            SwiftUI.Color(
                red: Double(r) / 255.0,
                green: Double(g) / 255.0,
                blue: Double(b) / 255.0
            )
        }
    }

    // MARK: Radius

    enum Radius {
        /// Card / large content module radius (`20`).
        static let card: CGFloat = 20
        /// Button / medium control radius (`16`).
        static let button: CGFloat = 16
        /// Chip / compact control radius (`12`).
        static let chip: CGFloat = 12
        /// Smallest compact radius (`8`), e.g. inline badges.
        static let compact: CGFloat = 8
        /// Bottom sheet top corner radius when not fully expanded (`28`).
        static let sheet: CGFloat = 28
    }

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    // MARK: Font

    /// Semantic font helpers. We keep Dynamic Type by leaning on `.system` styles
    /// with rounded design. Raw `.font(.system(size:))` is forbidden outside this
    /// file per coding-conventions.
    enum Font {
        static func title() -> SwiftUI.Font { .system(.title, design: .rounded).weight(.bold) }
        static func title3Bold() -> SwiftUI.Font { .title3.weight(.bold) }
        static func subheadline() -> SwiftUI.Font { .subheadline }
        static func subheadlineSemibold() -> SwiftUI.Font { .subheadline.weight(.semibold) }
        static func footnote() -> SwiftUI.Font { .footnote }
        static func footnoteSemibold() -> SwiftUI.Font { .footnote.weight(.semibold) }
        static func captionSemibold() -> SwiftUI.Font { .caption.weight(.semibold) }
        static func caption2Semibold() -> SwiftUI.Font { .caption2.weight(.semibold) }
    }

    // MARK: Sheet snap points

    /// Bottom-sheet snap fractions from deepsight design panel.
    enum Sheet {
        /// Summary-only state (22%).
        static let collapsed: Double = 0.22
        /// Main browsing state (52%).
        static let `default`: Double = 0.52
        /// Cluster/marker filtered browsing state (88%).
        static let expanded: Double = 0.88
    }
}
