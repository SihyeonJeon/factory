import Foundation

enum ThemePreference: String, CaseIterable, Hashable {
    case system
    case light
    case dark

    var koreanTitle: String {
        switch self {
        case .system: return UnfadingLocalized.Theme.system
        case .light: return UnfadingLocalized.Theme.light
        case .dark: return UnfadingLocalized.Theme.dark
        }
    }
}

// vibe-limit-checked: 5 @MainActor preference state, 6 no silent defaults, 14 reusable settings state
@MainActor
final class UserPreferences: ObservableObject {
    private enum K {
        static let reminderEnabled = "unfading.preferences.reminderEnabled"
        static let themePreference = "unfading.preferences.themePreference"
        static let hasSeenOnboarding = "unfading.preferences.hasSeenOnboarding"
    }

    private let userDefaults: UserDefaults

    @Published var reminderEnabled: Bool {
        didSet { userDefaults.set(reminderEnabled, forKey: K.reminderEnabled) }
    }

    @Published var themePreference: ThemePreference {
        didSet { userDefaults.set(themePreference.rawValue, forKey: K.themePreference) }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { userDefaults.set(hasSeenOnboarding, forKey: K.hasSeenOnboarding) }
    }

    init(userDefaults: UserDefaults = .standard, forceHasSeenOnboarding: Bool? = nil) {
        self.userDefaults = userDefaults
        self.reminderEnabled = userDefaults.bool(forKey: K.reminderEnabled)
        if let raw = userDefaults.string(forKey: K.themePreference),
           let preference = ThemePreference(rawValue: raw) {
            self.themePreference = preference
        } else {
            self.themePreference = .system
        }
        let shouldSkipOnboarding = forceHasSeenOnboarding ?? Self.shouldSkipOnboardingForUITests
        self.hasSeenOnboarding = shouldSkipOnboarding || userDefaults.bool(forKey: K.hasSeenOnboarding)
        if shouldSkipOnboarding {
            userDefaults.set(true, forKey: K.hasSeenOnboarding)
        }
    }

    private static var shouldSkipOnboardingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_SKIP_ONBOARDING")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1"
    }
}
