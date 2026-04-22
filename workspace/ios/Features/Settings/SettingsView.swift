import SwiftUI

/// Stub screen for R3 `round_navigation_r1`. Replaced with a full Settings
/// implementation in R11. Exists now so the 5-tab root can route here, and so
/// Group Hub remains reachable after the Groups tab is removed in this round.
struct SettingsView: View {
    @State private var showingGroupHub = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                        Text(UnfadingLocalized.Settings.stubTitle)
                            .font(UnfadingTheme.Font.title3Bold())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        Text(UnfadingLocalized.Settings.stubBody)
                            .font(UnfadingTheme.Font.subheadline())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                    .padding(.vertical, UnfadingTheme.Spacing.sm)
                }

                Section {
                    Button {
                        showingGroupHub = true
                    } label: {
                        HStack {
                            Label(UnfadingLocalized.Settings.groupsRow, systemImage: "person.3")
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.footnote)
                                .foregroundStyle(UnfadingTheme.Color.textTertiary)
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(UnfadingLocalized.Settings.groupsRowHint)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(UnfadingLocalized.Settings.navTitle)
            .sheet(isPresented: $showingGroupHub) {
                GroupHubView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
