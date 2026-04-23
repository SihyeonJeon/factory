import SwiftUI

/// Canonical Unfading design token namespace. App, feature, and shared UI code
/// should consume colors, radii, spacing, typography, shadows, and sheet snap
/// points from here rather than hard-coding visual values.
enum UnfadingTheme {

    // MARK: Color

    enum Color {
        static let bg: SwiftUI.Color = hex(0xFF, 0xF8, 0xF0)
        static let sheet: SwiftUI.Color = hex(0xFF, 0xFB, 0xF5)
        static let card: SwiftUI.Color = hex(0xFF, 0xFF, 0xFF)
        static let surface: SwiftUI.Color = hex(0xF5, 0xEE, 0xE4)
        static let primary: SwiftUI.Color = hex(0xF5, 0x99, 0x8C)
        static let primaryHover: SwiftUI.Color = hex(0xE8, 0x87, 0x7A)
        static let accentSoft: SwiftUI.Color = hex(0xFA, 0xE4, 0xDD)
        static let secondary: SwiftUI.Color = hex(0x8F, 0xB7, 0xA8)
        static let secondaryLight: SwiftUI.Color = hex(0xCD, 0xE2, 0xDA)
        static let textPrimary: SwiftUI.Color = hex(0x40, 0x38, 0x33)
        static let textSecondary: SwiftUI.Color = hex(0x8C, 0x82, 0x7A)
        static let textTertiary: SwiftUI.Color = hex(0xB8, 0xAE, 0xA5)
        static let divider: SwiftUI.Color = hex(0xEB, 0xE1, 0xD4)
        static let chipBg: SwiftUI.Color = hex(0xF5, 0xEE, 0xE4)
        static let mapBase: SwiftUI.Color = hex(0xFF, 0xF3, 0xE6)
        static let mapLand: SwiftUI.Color = hex(0xFF, 0xE8, 0xD1)
        static let mapWater: SwiftUI.Color = hex(0xDC, 0xE7, 0xE4)
        static let mapRoad: SwiftUI.Color = hex(0xF5, 0xEE, 0xE0)

        // Compatibility aliases retained for R24/R25 UI surfaces.
        static var coral: SwiftUI.Color { primary }
        static var primarySoft: SwiftUI.Color { accentSoft }
        static let lavender: SwiftUI.Color = hex(0xC2, 0xB0, 0xDE)
        static var cream: SwiftUI.Color { bg }
        static let textOnPrimary: SwiftUI.Color = .white
        static let textOnOverlay: SwiftUI.Color = SwiftUI.Color.white.opacity(0.92)
        static let shadow: SwiftUI.Color = textPrimary.opacity(0.06)
        static let pinShadow: SwiftUI.Color = textPrimary.opacity(0.18)

        static let amber: SwiftUI.Color = hex(0xE4, 0xB9, 0x78)
        static let mint: SwiftUI.Color = secondary
        static let lavenderMember: SwiftUI.Color = hex(0xA9, 0xA1, 0xC7)
        static let blue: SwiftUI.Color = hex(0x7B, 0x9F, 0xD4)
        static let rose: SwiftUI.Color = hex(0xD4, 0x8F, 0xB2)
        static let camel: SwiftUI.Color = hex(0xC7, 0xA7, 0x7B)
        static let violet: SwiftUI.Color = hex(0x9A, 0x85, 0xC0)
        static let teal: SwiftUI.Color = hex(0x7B, 0xAF, 0xB1)
        static let sage: SwiftUI.Color = hex(0x8F, 0xA8, 0x8B)

        static let memberPalette: [SwiftUI.Color] = [
            coral,
            amber,
            mint,
            lavenderMember,
            blue,
            rose,
            camel,
            violet,
            teal,
            sage
        ]

        static func hex(_ r: Int, _ g: Int, _ b: Int) -> SwiftUI.Color {
            SwiftUI.Color(
                red: Double(r) / 255.0,
                green: Double(g) / 255.0,
                blue: Double(b) / 255.0
            )
        }
    }

    // MARK: Radius

    enum Radius {
        static let card: CGFloat = 18
        static let sheet: CGFloat = 28
        static let chip: CGFloat = 18
        static let segment: CGFloat = 12

        // Compatibility values retained for existing controls.
        static let button: CGFloat = 16
        static let compact: CGFloat = 8
    }

    // MARK: Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs2: CGFloat = 6
        static let xs: CGFloat = 8
        static let xs1: CGFloat = 10
        static let sm: CGFloat = 12
        static let sm2: CGFloat = 14
        static let md: CGFloat = 16
        static let md2: CGFloat = 18
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xl2: CGFloat = 28
        static let xl3: CGFloat = 30
        static let sheetBottom: CGFloat = 80
        static let tabBarClear: CGFloat = 110

        // Compatibility alias for the pre-R26 largest spacing token.
        static let xxl: CGFloat = xl2
    }

    // MARK: Shadow

    struct ShadowStyle {
        let color: SwiftUI.Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    enum Shadow {
        static let card = ShadowStyle(
            color: Color.hex(0x40, 0x38, 0x33).opacity(0.04),
            radius: 6,
            x: 0,
            y: 2
        )
        static let activeCard = ShadowStyle(
            color: Color.primary.opacity(0.40),
            radius: 12,
            x: 0,
            y: 4
        )
        static let overlay = ShadowStyle(
            color: Color.hex(0x40, 0x38, 0x33).opacity(0.25),
            radius: 60,
            x: 0,
            y: 20
        )
        static let tabBarBorder = ShadowStyle(
            color: Color.divider,
            radius: 0.5,
            x: 0,
            y: -0.5
        )
    }

    // MARK: Font

    enum Font {
        static func pageTitle(_ size: CGFloat = 20) -> SwiftUI.Font {
            .custom("GowunDodum-Regular", size: size)
        }

        static func sectionTitle(_ size: CGFloat = 15) -> SwiftUI.Font {
            .custom("GowunDodum-Regular", size: size)
        }

        static func body(_ size: CGFloat = 14) -> SwiftUI.Font {
            .custom("GowunDodum-Regular", size: size)
        }

        static func chip(_ size: CGFloat = 13) -> SwiftUI.Font {
            .custom("GowunDodum-Regular", size: size)
        }

        static func tag(_ size: CGFloat = 10.5) -> SwiftUI.Font {
            .custom("GowunDodum-Regular", size: size)
        }

        static func metaNum(_ size: CGFloat = 12, weight: NunitoWeight = .bold) -> SwiftUI.Font {
            .custom(weight.postScriptName, size: size)
        }

        // Compatibility aliases retained for existing call sites.
        static func title() -> SwiftUI.Font { pageTitle(22) }
        static func title3Bold() -> SwiftUI.Font { pageTitle(20) }
        static func subheadline() -> SwiftUI.Font { body(14) }
        static func subheadlineSemibold() -> SwiftUI.Font { body(14) }
        static func footnote() -> SwiftUI.Font { body(12) }
        static func footnoteSemibold() -> SwiftUI.Font { body(12) }
        static func captionSemibold() -> SwiftUI.Font { body(11) }
        static func caption2Semibold() -> SwiftUI.Font { body(10) }
    }

    enum NunitoWeight: String {
        case regular = "Nunito-Regular"
        case semibold = "Nunito-SemiBold"
        case bold = "Nunito-Bold"
        case black = "Nunito-Black"

        var postScriptName: String { rawValue }
    }

    // MARK: Sheet snap points

    enum Sheet {
        static let collapsed: Double = 0.08
        static let `default`: Double = 0.50
        static let expanded: Double = 1.0
    }
}

extension View {
    func shadow(style: UnfadingTheme.ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
