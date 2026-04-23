import SwiftUI

struct SheetExpandedHeader: View {
    static let safeTop: CGFloat = 54
    static let headerHeight: CGFloat = 60
    static let totalHeight: CGFloat = safeTop + headerHeight

    let groupName: String
    var memberInitials: [String] = ["시", "지"]
    var showsSearchField = true
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: Self.safeTop)

            HStack(spacing: UnfadingTheme.Spacing.sm) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("이전")
                .accessibilityIdentifier("sheet-expanded-back")

                groupPill

                if showsSearchField {
                    searchField
                }
            }
            .padding(.horizontal, UnfadingTheme.Spacing.md)
            .frame(height: Self.headerHeight)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.totalHeight, alignment: .top)
        .background(UnfadingTheme.Color.sheet)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(UnfadingTheme.Color.divider)
                .frame(height: 0.5)
        }
        .accessibilityIdentifier("sheet-expanded-header")
    }

    private var groupPill: some View {
        HStack(spacing: UnfadingTheme.Spacing.xs) {
            avatarStack
            Text(groupName)
                .font(UnfadingTheme.Font.footnoteSemibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .lineLimit(1)
        }
        .padding(.leading, UnfadingTheme.Spacing.xs)
        .padding(.trailing, UnfadingTheme.Spacing.sm)
        .frame(height: 36)
        .background(UnfadingTheme.Color.accentSoft, in: Capsule())
    }

    private var avatarStack: some View {
        HStack(spacing: -8) {
            ForEach(Array(memberInitials.prefix(3).enumerated()), id: \.offset) { index, initial in
                Text(initial)
                    .font(UnfadingTheme.Font.tag(10))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(width: 24, height: 24)
                    .background(memberColor(index), in: Circle())
                    .overlay(Circle().stroke(UnfadingTheme.Color.sheet, lineWidth: 1.5))
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: UnfadingTheme.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .imageScale(.small)
            Text("검색")
                .font(UnfadingTheme.Font.footnote())
                .lineLimit(1)
        }
        .foregroundStyle(UnfadingTheme.Color.textSecondary)
        .padding(.horizontal, UnfadingTheme.Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(UnfadingTheme.Color.chipBg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("검색")
    }

    private func memberColor(_ index: Int) -> Color {
        let palette = UnfadingTheme.Color.memberPalette
        return palette[index % palette.count]
    }
}
