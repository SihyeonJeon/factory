import Foundation
import Photos
import XCTest
@testable import MemoryMap

@MainActor
final class DataExporterTests: XCTestCase {
    func test_exportJSON_roundTripsAndCreatesFile() async throws {
        let root = makeDirectory()
        let exporter = DataExporter(
            documentsDirectory: root.appendingPathComponent("Documents", isDirectory: true),
            temporaryDirectory: root.appendingPathComponent("tmp", isDirectory: true)
        )
        let memories = [Self.memory()]

        let url = try await exporter.exportJSON(memories: memories)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([DBMemory].self, from: data)
        XCTAssertEqual(decoded, memories)
    }

    func test_exportPhotos_createsShareableDirectory() async throws {
        let root = makeDirectory()
        let source = root.appendingPathComponent("source-photo.jpg")
        try Data([0x01, 0x02, 0x03]).write(to: source)

        let exporter = DataExporter(
            documentsDirectory: root.appendingPathComponent("Documents", isDirectory: true),
            temporaryDirectory: root.appendingPathComponent("tmp", isDirectory: true)
        )
        let memory = Self.memory(photoURLs: ["stub/path/photo.jpg"])
        let uploader = StubExportPhotoUploader(url: source)

        let url = try await exporter.exportPhotos(memories: [memory], uploader: uploader)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)

        let children = try FileManager.default.contentsOfDirectory(atPath: url.path)
        XCTAssertEqual(children.count, 1)
        XCTAssertTrue(children.first?.hasSuffix(".jpg") == true)
    }

    private func makeDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func memory(photoURLs: [String] = []) -> DBMemory {
        DBMemory(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            eventId: nil,
            title: "상수 루프톱 저녁",
            note: "친구들과 공연 이야기를 나눈 밤",
            placeTitle: "상수 루프톱",
            address: "서울 마포구",
            locationLat: 37.5519,
            locationLng: 126.9215,
            date: Date(timeIntervalSince1970: 1_776_000_000),
            capturedAt: Date(timeIntervalSince1970: 1_776_000_000),
            photoURL: nil,
            photoURLs: photoURLs,
            categories: ["food"],
            emotions: ["joy"],
            participantUserIds: [],
            cost: nil,
            reactionCount: 0,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        )
    }
}

private actor StubExportPhotoUploader: PhotoUploading {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func upload(
        assets: [PHAsset],
        groupId: UUID,
        memoryId: UUID,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> [UploadedPhoto] {
        []
    }

    func signedURL(storagePath: String, expiresIn: Int) async throws -> URL? {
        url
    }

    func delete(paths: [String]) async {}
}
