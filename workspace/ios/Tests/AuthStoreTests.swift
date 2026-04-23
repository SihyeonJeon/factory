import XCTest
@testable import MemoryMap

@MainActor
final class AuthStoreTests: XCTestCase {
    private final class MockAppleSignInCoordinator: AppleSignInCoordinating {
        private(set) var signInCallCount = 0

        func signIn() async throws {
            signInCallCount += 1
        }
    }

    func testAuthStateEquatableConformance() {
        let userId = UUID()

        XCTAssertEqual(AuthState.unknown, .unknown)
        XCTAssertEqual(AuthState.signedOut, .signedOut)
        XCTAssertEqual(
            AuthState.signedIn(userId: userId, email: "test@example.com"),
            .signedIn(userId: userId, email: "test@example.com")
        )
        XCTAssertNotEqual(
            AuthState.signedIn(userId: userId, email: "test@example.com"),
            .signedOut
        )
    }

    func testPreviewInitUsesInjectedState() {
        let userId = UUID()
        let store = AuthStore(preview: .signedIn(userId: userId, email: "preview@example.com"))

        XCTAssertEqual(store.state, .signedIn(userId: userId, email: "preview@example.com"))
    }

    func testPreviewSignOutTransitionsToSignedOut() async throws {
        let store = AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com"))

        try await store.signOut()

        XCTAssertEqual(store.state, .signedOut)
    }

    func testPreviewSignInWithAppleInvokesCoordinatorFlow() async throws {
        let coordinator = MockAppleSignInCoordinator()
        let store = AuthStore(preview: .signedOut, appleSignInCoordinator: coordinator)

        try await store.signInWithApple()

        XCTAssertEqual(coordinator.signInCallCount, 1)
        XCTAssertEqual(store.state, .signedOut)
    }
}
