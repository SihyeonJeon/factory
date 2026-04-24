import SwiftUI
import UIKit

/// Canonical Unfading design token namespace. App, feature, and shared UI code
/// should consume colors, radii, spacing, typography, shadows, and sheet snap
/// points from here rather than hard-coding visual values.
enum UnfadingTheme {

    // MARK: Color

    enum Color {
        private static let bgLight: SwiftUI.Color = hex(0xFF, 0xF8, 0xF0)
        private static let sheetLight: SwiftUI.Color = hex(0xFF, 0xFB, 0xF5)
        private static let cardLight: SwiftUI.Color = hex(0xFF, 0xFF, 0xFF)
        private static let surfaceLight: SwiftUI.Color = hex(0xF5, 0xEE, 0xE4)
        private static let primaryLight: SwiftUI.Color = hex(0xF5, 0x99, 0x8C)
        private static let primaryHoverLight: SwiftUI.Color = hex(0xE8, 0x87, 0x7A)
        private static let accentSoftLight: SwiftUI.Color = hex(0xFA, 0xE4, 0xDD)
        private static let secondaryLightToken: SwiftUI.Color = hex(0x8F, 0xB7, 0xA8)
        private static let secondaryBackgroundLight: SwiftUI.Color = hex(0xCD, 0xE2, 0xDA)
        private static let textPrimaryLight: SwiftUI.Color = hex(0x40, 0x38, 0x33)
        private static let textSecondaryLight: SwiftUI.Color = hex(0x76, 0x6D, 0x66)
        private static let textTertiaryLight: SwiftUI.Color = hex(0xB8, 0xAE, 0xA5)
        private static let dividerLight: SwiftUI.Color = hex(0xEB, 0xE1, 0xD4)
        private static let chipBgLight: SwiftUI.Color = hex(0xF5, 0xEE, 0xE4)
        private static let mapBaseLight: SwiftUI.Color = hex(0xFF, 0xF3, 0xE6)
        private static let mapLandLight: SwiftUI.Color = hex(0xFF, 0xE8, 0xD1)
        private static let mapWaterLight: SwiftUI.Color = hex(0xDC, 0xE7, 0xE4)
        private static let mapRoadLight: SwiftUI.Color = hex(0xF5, 0xEE, 0xE0)

        private static let bgDarkToken: SwiftUI.Color = hex(0x1C, 0x17, 0x14)
        private static let sheetDarkToken: SwiftUI.Color = hex(0x22, 0x1C, 0x18)
        private static let cardDarkToken: SwiftUI.Color = hex(0x2B, 0x23, 0x20)
        private static let surfaceDarkToken: SwiftUI.Color = hex(0x32, 0x29, 0x24)
        private static let primaryDarkToken: SwiftUI.Color = hex(0xF5, 0x99, 0x8C)
        private static let textPrimaryDarkToken: SwiftUI.Color = hex(0xF2, 0xEA, 0xE2)
        private static let textSecondaryDarkToken: SwiftUI.Color = hex(0xBB, 0xA8, 0x9C)
        private static let textTertiaryDarkToken: SwiftUI.Color = hex(0x6D, 0x60, 0x5A)
        private static let dividerDarkToken: SwiftUI.Color = hex(0x3A, 0x2F, 0x28)

        static let bg: SwiftUI.Color = adaptive(light: bgLight, dark: bgDarkToken)
        static let sheet: SwiftUI.Color = adaptive(light: sheetLight, dark: sheetDarkToken)
        static let card: SwiftUI.Color = adaptive(light: cardLight, dark: cardDarkToken)
        static let surface: SwiftUI.Color = adaptive(light: surfaceLight, dark: surfaceDarkToken)
        static let primary: SwiftUI.Color = adaptive(light: primaryLight, dark: primaryDarkToken)
        static let primaryHover: SwiftUI.Color = adaptive(light: primaryHoverLight, dark: primaryDarkToken.opacity(0.92))
        static let accentSoft: SwiftUI.Color = adaptive(light: accentSoftLight, dark: surfaceDarkToken)
        static let secondary: SwiftUI.Color = adaptive(light: secondaryLightToken, dark: secondaryLightToken)
        static let secondaryLight: SwiftUI.Color = adaptive(light: secondaryBackgroundLight, dark: surfaceDarkToken)
        static let textPrimary: SwiftUI.Color = adaptive(light: textPrimaryLight, dark: textPrimaryDarkToken)
        static let textSecondary: SwiftUI.Color = adaptive(light: textSecondaryLight, dark: textSecondaryDarkToken)
        static let textTertiary: SwiftUI.Color = adaptive(light: textTertiaryLight, dark: textTertiaryDarkToken)
        static let divider: SwiftUI.Color = adaptive(light: dividerLight, dark: dividerDarkToken)
        static let chipBg: SwiftUI.Color = adaptive(light: chipBgLight, dark: surfaceDarkToken)
        static let mapBase: SwiftUI.Color = adaptive(light: mapBaseLight, dark: bgDarkToken)
        static let mapLand: SwiftUI.Color = adaptive(light: mapLandLight, dark: cardDarkToken)
        static let mapWater: SwiftUI.Color = adaptive(light: mapWaterLight, dark: surfaceDarkToken)
        static let mapRoad: SwiftUI.Color = adaptive(light: mapRoadLight, dark: dividerDarkToken)

        // Compatibility aliases retained for R24/R25 UI surfaces.
        static var coral: SwiftUI.Color { primary }
        static var primarySoft: SwiftUI.Color { accentSoft }
        static let lavender: SwiftUI.Color = adaptive(light: hex(0xC2, 0xB0, 0xDE), dark: hex(0xA1, 0x92, 0xBA))
        static var cream: SwiftUI.Color { bg }
        static let textOnPrimary: SwiftUI.Color = adaptive(light: textPrimaryLight, dark: textPrimaryLight)
        static let textOnOverlay: SwiftUI.Color = adaptive(light: SwiftUI.Color.white.opacity(0.92), dark: textPrimaryDarkToken.opacity(0.92))
        static let overlayBackdrop: SwiftUI.Color = adaptive(light: textPrimaryLight.opacity(0.28), dark: SwiftUI.Color.black.opacity(0.45))
        static let shadow: SwiftUI.Color = adaptive(light: textPrimaryLight.opacity(0.06), dark: SwiftUI.Color.black.opacity(0.22))
        static let pinShadow: SwiftUI.Color = adaptive(light: textPrimaryLight.opacity(0.18), dark: SwiftUI.Color.black.opacity(0.30))

        static let amber: SwiftUI.Color = adaptive(light: hex(0xE4, 0xB9, 0x78), dark: hex(0xD2, 0xA6, 0x67))
        static let mint: SwiftUI.Color = secondary
        static let lavenderMember: SwiftUI.Color = adaptive(light: hex(0xA9, 0xA1, 0xC7), dark: hex(0x95, 0x8D, 0xB6))
        static let blue: SwiftUI.Color = adaptive(light: hex(0x7B, 0x9F, 0xD4), dark: hex(0x69, 0x8D, 0xC2))
        static let rose: SwiftUI.Color = adaptive(light: hex(0xD4, 0x8F, 0xB2), dark: hex(0xC0, 0x7E, 0xA0))
        static let camel: SwiftUI.Color = adaptive(light: hex(0xC7, 0xA7, 0x7B), dark: hex(0xB4, 0x95, 0x6D))
        static let violet: SwiftUI.Color = adaptive(light: hex(0x9A, 0x85, 0xC0), dark: hex(0x88, 0x74, 0xAE))
        static let teal: SwiftUI.Color = adaptive(light: hex(0x7B, 0xAF, 0xB1), dark: hex(0x6A, 0x9D, 0x9F))
        static let sage: SwiftUI.Color = adaptive(light: hex(0x8F, 0xA8, 0x8B), dark: hex(0x7E, 0x97, 0x7A))

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

        static func adaptive(light: SwiftUI.Color, dark: SwiftUI.Color) -> SwiftUI.Color {
            SwiftUI.Color(
                UIColor { traitCollection in
                    let color = traitCollection.userInterfaceStyle == .dark ? dark : light
                    return UIColor(color)
                }
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
            color: Color.shadow,
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
            color: Color.pinShadow,
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
