import XCTest
import Supabase
@testable import MemoryMap

final class SupabaseE2ETests: XCTestCase {
    private var env: (email: String, password: String)? {
        let info = ProcessInfo.processInfo.environment
        guard
            let email = info["UNFADING_E2E_EMAIL"],
            let password = info["UNFADING_E2E_PASSWORD"],
            !email.isEmpty,
            !password.isEmpty
        else {
            return nil
        }
        return (email, password)
    }

    override func setUp() async throws {
        try XCTSkipIf(env == nil, "UNFADING_E2E_{EMAIL,PASSWORD} not set; skipping")
    }

    func testSignInAndFetchProfile() async throws {
        let auth = SupabaseService.shared.auth
        _ = try await auth.signIn(email: env!.email, password: env!.password)
        let user = try await auth.user()
        XCTAssertEqual(user.email, env!.email)
        try? await auth.signOut()
    }

    func testCreateAndFetchGroupThenMemory() async throws {
        let auth = SupabaseService.shared.auth
        _ = try await auth.signIn(email: env!.email, password: env!.password)
        do {
            let user = try await auth.user()
            let groupRepo = SupabaseGroupRepository()
            let group = try await groupRepo.createGroup(
                name: "E2E-\(UUID().uuidString.prefix(6))",
                mode: "couple",
                intro: nil,
                coverColorHex: "#F5998C"
            )
            XCTAssertEqual(group.createdBy, user.id)

            let memRepo = SupabaseMemoryRepository()
            let insert = DBMemoryInsert(
                id: UUID(),
                userId: user.id,
                groupId: group.id,
                title: "E2E title",
                note: "note",
                placeTitle: "placeTitle",
                address: nil,
                locationLat: 37.5,
                locationLng: 127.0,
                date: Date(),
                capturedAt: nil,
                photoURL: nil,
                photoURLs: [],
                categories: [],
                emotions: []
            )

            let created = try await memRepo.createMemory(insert)
            XCTAssertEqual(created.groupId, group.id)
            let fetched = try await memRepo.fetchMemories(groupId: group.id)
            XCTAssertTrue(fetched.contains(where: { $0.id == created.id }))
            try await memRepo.deleteMemory(id: created.id)
            try? await auth.signOut()
        } catch {
            try? await auth.signOut()
            throw error
        }
    }
}
