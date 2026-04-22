import SwiftUI

/// Warm card surface modifier. Provides a consistent card fill + radius + subtle
/// shadow combination derived from `UnfadingTheme`. Prefer this over ad-hoc
/// `RoundedRectangle(cornerRadius:)` + inline color pairs.
///
/// Usage:
///   ```swift
///   VStack { ... }
///       .unfadingCardBackground()
///
///   // Explicit variant with different radius or material-compatible overlay:
///   VStack { ... }
///       .unfadingCardBackground(radius: UnfadingTheme.Radius.sheet, material: .regular)
///   ```
struct UnfadingCardBackground: ViewModifier {
    var fill: Color
    var radius: CGFloat
    var material: Material?
    var shadow: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content
            .background(
                Group {
                    if let material {
                        shape.fill(fill).overlay(shape.fill(material))
                    } else {
                        shape.fill(fill)
                    }
                }
            )
            .clipShape(shape)
            .ifLet(shadow ? () : nil) { view, _ in
                view
                    .shadow(color: UnfadingTheme.Color.shadow, radius: 12, x: 0, y: 6)
            }
    }
}

extension View {
    /// Apply the standard Unfading card background. Pass `material: .regular` to
    /// composite a system material on top of the warm fill (for translucent surfaces
    /// like the memory summary sheet card).
    func unfadingCardBackground(
        fill: Color = UnfadingTheme.Color.card,
        radius: CGFloat = UnfadingTheme.Radius.card,
        material: Material? = nil,
        shadow: Bool = true
    ) -> some View {
        modifier(
            UnfadingCardBackground(fill: fill, radius: radius, material: material, shadow: shadow)
        )
    }
}

// MARK: - Private helpers

private extension View {
    /// Tiny conditional modifier so `shadow` can be applied only when requested
    /// without forking the body. Kept `private` to this file to avoid polluting
    /// the public extension surface.
    @ViewBuilder
    func ifLet<T, V: View>(_ value: T?, @ViewBuilder _ transform: (Self, T) -> V) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
