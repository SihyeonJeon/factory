import SwiftUI

struct GroupHubView: View {
    var body: some View {
        NavigationStack {
            List(GroupPreview.samples) { group in
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                    HStack {
                        Text(group.name)
                            .font(.headline)
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        Spacer()
                        Text(group.members)
                            .font(UnfadingTheme.Font.captionSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                    Text(group.summary)
                        .font(UnfadingTheme.Font.subheadline())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                .padding(.vertical, UnfadingTheme.Spacing.sm)
            }
            .navigationTitle(UnfadingLocalized.Groups.navTitle)
        }
    }
}

#Preview {
    GroupHubView()
}
