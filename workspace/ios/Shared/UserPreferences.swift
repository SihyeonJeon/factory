import Foundation

enum ThemePreference: String, CaseIterable, Hashable, Sendable {
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
        static let mapTheme = "unfading.preferences.mapTheme"
        static let hasSeenOnboarding = "unfading.preferences.hasSeenOnboarding"
        static let displayName = "unfading.preferences.displayName"
        static let photoURL = "unfading.preferences.photoURL"
    }

    private let userDefaults: UserDefaults
    private let repository: ProfileRepository
    private var currentUserId: UUID?
    private var isApplyingRemoteState = false
    private var preferencesSyncTask: Task<Void, Never>?
    private var displayNameSyncTask: Task<Void, Never>?
    private var photoURLSyncTask: Task<Void, Never>?

    @Published var reminderEnabled: Bool {
        didSet {
            userDefaults.set(reminderEnabled, forKey: K.reminderEnabled)
            schedulePreferencesSync()
        }
    }

    @Published var themePreference: ThemePreference {
        didSet {
            userDefaults.set(themePreference.rawValue, forKey: K.themePreference)
            schedulePreferencesSync()
        }
    }

    @Published var mapTheme: MapTheme {
        didSet {
            userDefaults.set(mapTheme.rawValue, forKey: K.mapTheme)
            schedulePreferencesSync()
        }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { userDefaults.set(hasSeenOnboarding, forKey: K.hasSeenOnboarding) }
    }

    @Published var displayName: String {
        didSet {
            userDefaults.set(displayName, forKey: K.displayName)
            scheduleDisplayNameSync()
        }
    }

    @Published var photoURL: String? {
        didSet {
            if let photoURL {
                userDefaults.set(photoURL, forKey: K.photoURL)
            } else {
                userDefaults.removeObject(forKey: K.photoURL)
            }
            schedulePhotoURLSync()
        }
    }

    init(
        userDefaults: UserDefaults = .standard,
        forceHasSeenOnboarding: Bool? = nil,
        repository: ProfileRepository = SupabaseProfileRepository()
    ) {
        self.userDefaults = userDefaults
        self.repository = repository
        self.reminderEnabled = userDefaults.bool(forKey: K.reminderEnabled)
        if let raw = userDefaults.string(forKey: K.themePreference),
           let preference = ThemePreference(rawValue: raw) {
            self.themePreference = preference
        } else {
            self.themePreference = .system
        }
        if let raw = userDefaults.string(forKey: K.mapTheme),
           let mapTheme = MapTheme(rawValue: raw) {
            self.mapTheme = mapTheme
        } else {
            self.mapTheme = .default_
        }
        let shouldSkipOnboarding = forceHasSeenOnboarding ?? Self.shouldSkipOnboardingForUITests
        self.hasSeenOnboarding = shouldSkipOnboarding || userDefaults.bool(forKey: K.hasSeenOnboarding)
        self.displayName = userDefaults.string(forKey: K.displayName) ?? ""
        self.photoURL = userDefaults.string(forKey: K.photoURL)
        if shouldSkipOnboarding {
            userDefaults.set(true, forKey: K.hasSeenOnboarding)
        }
    }

    deinit {
        preferencesSyncTask?.cancel()
        displayNameSyncTask?.cancel()
        photoURLSyncTask?.cancel()
    }

    func bootstrap(userId: UUID) async {
        currentUserId = userId
        do {
            let profile = try await repository.fetchCurrent(userId: userId)
            apply(profile: profile)
        } catch {
            NSLog("UserPreferences bootstrap failed: \(String(describing: error))")
        }
    }

    private func apply(profile: DBProfile) {
        isApplyingRemoteState = true
        reminderEnabled = profile.preferences.reminderEnabled
        themePreference = ThemePreference(rawValue: profile.preferences.themePreference) ?? .system
        mapTheme = MapTheme(rawValue: profile.preferences.mapTheme) ?? .default_
        displayName = profile.displayName ?? ""
        photoURL = profile.photoURL
        isApplyingRemoteState = false
    }

    private func schedulePreferencesSync() {
        guard !isApplyingRemoteState, let currentUserId else { return }
        preferencesSyncTask?.cancel()
        let prefs = DBProfilePreferences(
            reminderEnabled: reminderEnabled,
            themePreference: themePreference.rawValue,
            mapTheme: mapTheme.rawValue
        )
        preferencesSyncTask = Task { [repository] in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                _ = try await repository.updatePreferences(prefs, userId: currentUserId)
            } catch is CancellationError {
                return
            } catch {
                NSLog("UserPreferences preferences sync failed: \(String(describing: error))")
            }
        }
    }

    private func scheduleDisplayNameSync() {
        guard !isApplyingRemoteState, let currentUserId else { return }
        displayNameSyncTask?.cancel()
        let name = displayName
        displayNameSyncTask = Task { [repository] in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                _ = try await repository.updateDisplayName(name, userId: currentUserId)
            } catch is CancellationError {
                return
            } catch {
                NSLog("UserPreferences display name sync failed: \(String(describing: error))")
            }
        }
    }

    private func schedulePhotoURLSync() {
        guard !isApplyingRemoteState, let currentUserId else { return }
        photoURLSyncTask?.cancel()
        let url = photoURL
        photoURLSyncTask = Task { [repository] in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                _ = try await repository.updatePhotoURL(url, userId: currentUserId)
            } catch is CancellationError {
                return
            } catch {
                NSLog("UserPreferences photo URL sync failed: \(String(describing: error))")
            }
        }
    }

    private static var shouldSkipOnboardingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_SKIP_ONBOARDING")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1"
    }
}
