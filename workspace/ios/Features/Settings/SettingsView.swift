import SwiftUI

// vibe-limit-checked: 5 @MainActor settings state objects, 7 Korean UI, 8 44pt rows, 14 reuses preference/store models
struct SettingsView: View {
    @StateObject private var prefs = UserPreferences()
    @StateObject private var memoryStore = MemoryStore()
    @State private var showingGroupHub = false
    @State private var showingPremium = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                preferencesSection
                groupSection
                premiumSection
                infoSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(UnfadingLocalized.Settings.navTitle)
            .sheet(isPresented: $showingGroupHub) {
                GroupHubView()
            }
            .sheet(isPresented: $showingPremium) {
                PremiumPreviewSheet()
            }
        }
    }

    private var accountSection: some View {
        Section(UnfadingLocalized.Settings.accountSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text("시현 (샘플)")
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Text(UnfadingLocalized.Settings.draftCountFormat(memoryStore.drafts.count))
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            .frame(minHeight: 44)
        }
    }

    private var preferencesSection: some View {
        Section(UnfadingLocalized.Settings.preferencesSection) {
            Toggle(isOn: $prefs.reminderEnabled) {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                    Text(UnfadingLocalized.Settings.reminderToggle)
                    Text(UnfadingLocalized.Settings.reminderHint)
                        .font(UnfadingTheme.Font.subheadline())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
            }
            .frame(minHeight: 44)

            Picker(UnfadingLocalized.Settings.themeLabel, selection: $prefs.themePreference) {
                ForEach(ThemePreference.allCases, id: \.self) { preference in
                    Text(preference.koreanTitle).tag(preference)
                }
            }
        }
    }

    private var groupSection: some View {
        Section(UnfadingLocalized.Settings.groupsSection) {
            Button {
                showingGroupHub = true
            } label: {
                Label(UnfadingLocalized.Settings.groupsRow, systemImage: "person.3")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .accessibilityHint(UnfadingLocalized.Settings.groupsRowHint)
        }
    }

    private var premiumSection: some View {
        Section(UnfadingLocalized.Settings.premiumSection) {
            Button {
                showingPremium = true
            } label: {
                Label(UnfadingLocalized.Settings.premiumExplore, systemImage: "sparkles")
                    .foregroundStyle(UnfadingTheme.Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
        }
    }

    private var infoSection: some View {
        Section(UnfadingLocalized.Settings.infoSection) {
            Text(UnfadingLocalized.Settings.versionLabel)
                .frame(minHeight: 44)
            Text(UnfadingLocalized.Settings.licensesRow)
                .frame(minHeight: 44)
        }
    }
}

#Preview {
    SettingsView()
}
