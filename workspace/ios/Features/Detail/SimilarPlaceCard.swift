import SwiftUI

struct SimilarPlaceCard: View {
    let name: String
    let distanceText: String

    var body: some View {
        HStack(spacing: UnfadingTheme.Spacing.md) {
            miniMap
                .frame(width: 92, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous))

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text(name)
                    .font(UnfadingTheme.Font.sectionTitle())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Label(distanceText, systemImage: "figure.walk")
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(UnfadingTheme.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .unfadingCardBackground(fill: UnfadingTheme.Color.card, radius: UnfadingTheme.Radius.button)
        .accessibilityElement(children: .combine)
    }

    private var miniMap: some View {
        ZStack {
            UnfadingTheme.Color.mapBase

            Path { path in
                path.move(to: CGPoint(x: -8, y: 24))
                path.addCurve(to: CGPoint(x: 100, y: 22), control1: CGPoint(x: 22, y: 36), control2: CGPoint(x: 58, y: 8))
                path.move(to: CGPoint(x: 10, y: 58))
                path.addCurve(to: CGPoint(x: 94, y: 50), control1: CGPoint(x: 38, y: 44), control2: CGPoint(x: 62, y: 68))
                path.move(to: CGPoint(x: 34, y: -4))
                path.addCurve(to: CGPoint(x: 42, y: 78), control1: CGPoint(x: 30, y: 24), control2: CGPoint(x: 52, y: 44))
            }
            .stroke(UnfadingTheme.Color.mapRoad, style: StrokeStyle(lineWidth: 9, lineCap: .round))

            Circle()
                .fill(UnfadingTheme.Color.primary)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(UnfadingTheme.Color.textOnPrimary, lineWidth: 3))
                .shadow(style: UnfadingTheme.Shadow.card)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    SimilarPlaceCard(name: "상수 루프톱 근처 산책길", distanceText: "도보 7분")
        .padding()
        .background(UnfadingTheme.Color.sheet)
}
