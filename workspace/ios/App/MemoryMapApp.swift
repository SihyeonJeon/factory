import SwiftUI

@main
struct MemoryMapApp: App {
    @StateObject private var prefs: UserPreferences
    @StateObject private var authStore: AuthStore
    @StateObject private var groupStore: GroupStore
    @StateObject private var offlineQueue: OfflineQueue
    @StateObject private var memoryStore: MemoryStore
    @StateObject private var subscriptionStore: SubscriptionStore
    @StateObject private var locationPermission: LocationPermissionStore
    @State private var memoryRealtimeTask: Task<Void, Never>?
    @State private var bootstrappedPreferencesUserId: UUID?
    @State private var didRequestLocationOnLaunch = false
    @StateObject private var deepLinkStore = DeepLinkStore()

    private let evidenceMode: MemoryComposerEvidenceMode = {
        guard
            let rawValue = ProcessInfo.processInfo.environment["MEMORYMAP_EVIDENCE_MODE"],
            let mode = MemoryComposerEvidenceMode(rawValue: rawValue)
        else {
            return .none
        }

        return mode
    }()

    init() {
        let offlineQueue = OfflineQueue()
        if ProcessInfo.processInfo.arguments.contains("-UI_TEST_RESET_DEFAULTS"),
           let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        _prefs = StateObject(wrappedValue: UserPreferences(forceHasSeenOnboarding: Self.shouldSkipOnboardingForUITests))
        _authStore = StateObject(wrappedValue: AuthStore())
        _groupStore = StateObject(wrappedValue: Self.makeGroupStore())
        _offlineQueue = StateObject(wrappedValue: offlineQueue)
        _memoryStore = StateObject(wrappedValue: MemoryStore(offlineQueue: offlineQueue))
        _subscriptionStore = StateObject(wrappedValue: SubscriptionStore())
        _locationPermission = StateObject(wrappedValue: LocationPermissionStore())
    }

    private static var shouldSkipOnboardingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_SKIP_ONBOARDING")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1"
    }

    private static var isUITestGroupStubEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_GROUP_STUB")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST_GROUP_STUB"] == "1"
    }

    private static func initialSheetSnap() -> BottomSheetSnap {
        for arg in ProcessInfo.processInfo.arguments {
            if arg.hasPrefix("-UI_TEST_SHEET_SNAP=") {
                let value = String(arg.dropFirst("-UI_TEST_SHEET_SNAP=".count))
                switch value {
                case "collapsed": return .collapsed
                case "expanded": return .expanded
                default: return .default_
                }
            }
        }
        return .default_
    }

    @MainActor
    private static func makeGroupStore() -> GroupStore {
        #if DEBUG
        let store = AuthStore.isUITestAuthStubEnabled ? GroupStore(repo: PreviewGroupRepository()) : GroupStore()
        if isUITestGroupStubEnabled {
            store.applyUITestStub()
        }
        return store
        #else
        return GroupStore()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authStore.state == .unknown {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if case .signedIn = authStore.state {
                    if prefs.hasSeenOnboarding {
                        if groupStore.state == .loading || groupStore.state == .idle {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .task {
                                    await groupStore.bootstrap()
                                }
                        } else if groupStore.groups.isEmpty {
                            GroupOnboardingView()
                                .environmentObject(groupStore)
                        } else {
                            RootTabView(
                                evidenceMode: evidenceMode,
                                initialSheetSnap: Self.initialSheetSnap()
                            )
                                .environmentObject(authStore)
                                .environmentObject(prefs)
                                .environmentObject(groupStore)
                                .environmentObject(offlineQueue)
                                .environmentObject(memoryStore)
                                .environmentObject(deepLinkStore)
                        }
                    } else {
                        OnboardingView {
                            prefs.hasSeenOnboarding = true
                        }
                    }
                } else {
                    AuthLandingView()
                        .environmentObject(authStore)
                }
            }
            .environmentObject(subscriptionStore)
            .environmentObject(locationPermission)
            .preferredColorScheme(prefs.themePreference.colorScheme)
            .task {
                offlineQueue.startMonitoring()
            }
            .task {
                await subscriptionStore.loadProducts()
            }
            .task {
                guard !didRequestLocationOnLaunch else { return }
                didRequestLocationOnLaunch = true
                // UITest 환경에서는 시스템 권한 alert 가 button 테스트를 가리므로 skip.
                if ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1"
                    || ProcessInfo.processInfo.arguments.contains("-UI_TEST_AUTH_STUB")
                    || ProcessInfo.processInfo.arguments.contains("-UI_TEST_SKIP_ONBOARDING") {
                    return
                }
                // F4: 앱 첫 실행 즉시 위치 권한 prompt. notDetermined 일 때만 요청.
                if locationPermission.permissionState == .notDetermined {
                    _ = locationPermission.handleCurrentLocationTap()
                } else {
                    locationPermission.refresh()
                }
            }
            .onReceive(authStore.$state) { state in
                guard case let .signedIn(userId, _) = state else {
                    bootstrappedPreferencesUserId = nil
                    memoryStore.setCurrentUserId(nil)
                    return
                }
                memoryStore.setCurrentUserId(userId)
                if bootstrappedPreferencesUserId != userId {
                    bootstrappedPreferencesUserId = userId
                    Task { await prefs.bootstrap(userId: userId) }
                }
                guard !Self.isUITestGroupStubEnabled else { return }
                Task { await groupStore.bootstrap() }
            }
            .onAppear {
                memoryStore.setCurrentUserId(authStore.currentUserId)
                configureMemorySync(for: groupStore.activeGroupId)
            }
            .onChange(of: groupStore.activeGroupId) { _, activeGroupId in
                configureMemorySync(for: activeGroupId)
            }
            .onOpenURL { url in
                deepLinkStore.pendingDeepLink = DeepLinkRouter.parse(url)
            }
        }
    }

    @MainActor
    private func configureMemorySync(for activeGroupId: UUID?) {
        memoryRealtimeTask?.cancel()
        memoryRealtimeTask = nil

        guard let activeGroupId else { return }

        #if DEBUG
        if Self.isUITestGroupStubEnabled {
            memoryStore.applyUITestStub(groupId: activeGroupId)
            return
        }
        #endif

        Task {
            await memoryStore.loadMemories(for: activeGroupId)
        }
        memoryRealtimeTask = memoryStore.subscribeRealtime(groupId: activeGroupId)
    }
}
