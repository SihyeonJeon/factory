import SwiftUI

/// Primary press style used across Unfading. Coral fill, text-on-primary foreground,
/// button radius from `UnfadingTheme.Radius.button`, 44pt minimum height, and a
/// subtle scale+opacity press feedback that preserves Dynamic Type.
///
/// Usage:
///   ```swift
///   Button("새 추억", systemImage: "plus") { ... }
///       .buttonStyle(.unfadingPrimary)
///   ```
struct UnfadingPrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(UnfadingTheme.Font.subheadlineSemibold())
            .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .padding(.vertical, UnfadingTheme.Spacing.md)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: 44)
            .background(
                UnfadingTheme.Color.primary,
                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
            )
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .interactiveSpring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == UnfadingPrimaryButtonStyle {
    /// Shorthand: `.buttonStyle(.unfadingPrimary)`.
    static var unfadingPrimary: UnfadingPrimaryButtonStyle { .init() }

    /// Full-width variant.
    static var unfadingPrimaryFullWidth: UnfadingPrimaryButtonStyle { .init(fullWidth: true) }
}
