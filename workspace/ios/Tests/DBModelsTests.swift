import XCTest
@testable import MemoryMap

final class DBModelsTests: XCTestCase {
    func test_dbGroupRoundTripsSnakeCaseJSON() throws {
        let json = """
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "name": "우리 그룹",
          "invite_code": "ABCD1234",
          "created_at": "2026-04-23T12:00:00Z",
          "created_by": "22222222-2222-4222-8222-222222222222",
          "mode": "couple",
          "intro": "소개",
          "cover_color_hex": "#F5998C"
        }
        """.data(using: .utf8)!

        let group = try decoder.decode(DBGroup.self, from: json)
        let encoded = try encoder.encode(group)
        let decoded = try decoder.decode(DBGroup.self, from: encoded)

        XCTAssertEqual(decoded, group)
        XCTAssertEqual(decoded.inviteCode, "ABCD1234")
        XCTAssertEqual(decoded.createdBy.uuidString.uppercased(), "22222222-2222-4222-8222-222222222222".uppercased())
        XCTAssertEqual(decoded.coverColorHex, "#F5998C")
    }

    func test_dbProfileRoundTripsSnakeCaseJSON() throws {
        let json = """
        {
          "id": "33333333-3333-4333-8333-333333333333",
          "email": "profile@example.com",
          "display_name": "시현",
          "photo_url": "https://example.com/profile.png",
          "created_at": "2026-04-23T12:00:00Z"
        }
        """.data(using: .utf8)!

        let profile = try decoder.decode(DBProfile.self, from: json)
        let encoded = try encoder.encode(profile)
        let decoded = try decoder.decode(DBProfile.self, from: encoded)

        XCTAssertEqual(decoded, profile)
        XCTAssertEqual(decoded.displayName, "시현")
        XCTAssertEqual(decoded.photoURL, "https://example.com/profile.png")
    }

    func test_dbGroupMemberRoundTripsSnakeCaseJSON() throws {
        let json = """
        {
          "id": "44444444-4444-4444-8444-444444444444",
          "group_id": "55555555-5555-4555-8555-555555555555",
          "user_id": "66666666-6666-4666-8666-666666666666",
          "joined_at": "2026-04-23T12:00:00Z"
        }
        """.data(using: .utf8)!

        let member = try decoder.decode(DBGroupMember.self, from: json)
        let encoded = try encoder.encode(member)
        let decoded = try decoder.decode(DBGroupMember.self, from: encoded)

        XCTAssertEqual(decoded, member)
        XCTAssertEqual(decoded.groupId.uuidString.uppercased(), "55555555-5555-4555-8555-555555555555".uppercased())
        XCTAssertEqual(decoded.userId.uuidString.uppercased(), "66666666-6666-4666-8666-666666666666".uppercased())
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
