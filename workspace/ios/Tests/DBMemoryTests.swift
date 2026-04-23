import XCTest
@testable import MemoryMap

final class DBMemoryTests: XCTestCase {
    func test_dbMemoryRoundTripsSnakeCaseJSON() throws {
        let json = """
        {
          "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
          "user_id": "00000000-0000-0000-0000-000000000017",
          "group_id": "11111111-1111-4111-8111-111111111117",
          "title": "상수 루프톱 저녁",
          "note": "친구들과 공연 이야기를 나눈 밤",
          "place_title": "상수 루프톱",
          "address": "서울 마포구",
          "location_lat": 37.5519,
          "location_lng": 126.9215,
          "date": "2026-04-23T12:00:00Z",
          "captured_at": "2026-04-23T12:00:00Z",
          "photo_url": "https://example.com/cover.jpg",
          "photo_urls": ["https://example.com/cover.jpg", "https://example.com/second.jpg"],
          "categories": ["food"],
          "emotions": ["joy", "grateful"],
          "reaction_count": 3,
          "created_at": "2026-04-23T12:01:00Z"
        }
        """.data(using: .utf8)!

        let memory = try decoder.decode(DBMemory.self, from: json)
        let encoded = try encoder.encode(memory)
        let decoded = try decoder.decode(DBMemory.self, from: encoded)

        XCTAssertEqual(decoded, memory)
        XCTAssertEqual(decoded.userId.uuidString.uppercased(), "00000000-0000-0000-0000-000000000017".uppercased())
        XCTAssertEqual(decoded.placeTitle, "상수 루프톱")
        XCTAssertEqual(decoded.photoURLs.count, 2)
        XCTAssertEqual(decoded.reactionCount, 3)
    }

    func test_dbMemoryInsertEncodesSnakeCaseJSON() throws {
        let insert = DBMemoryInsert(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            title: "한강 산책",
            note: "노을을 보며 천천히 걸었던 시간",
            placeTitle: "여의도 한강공원",
            address: nil,
            locationLat: 37.5283,
            locationLng: 126.9326,
            date: Date(timeIntervalSince1970: 1_776_086_400),
            capturedAt: Date(timeIntervalSince1970: 1_776_086_400),
            photoURL: nil,
            photoURLs: [],
            categories: ["walk"],
            emotions: ["calm"]
        )

        let encoded = try encoder.encode(insert)
        let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual((object?["user_id"] as? String)?.uppercased(), "00000000-0000-0000-0000-000000000017".uppercased())
        XCTAssertEqual((object?["id"] as? String)?.uppercased(), "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa".uppercased())
        XCTAssertEqual((object?["group_id"] as? String)?.uppercased(), "11111111-1111-4111-8111-111111111117".uppercased())
        XCTAssertEqual(object?["place_title"] as? String, "여의도 한강공원")
        XCTAssertEqual(object?["location_lat"] as? Double, 37.5283)
        XCTAssertEqual(object?["location_lng"] as? Double, 126.9326)
        XCTAssertNotNil(object?["photo_urls"])
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
