import Foundation
import Photos
import Supabase
import UIKit

struct UploadedPhoto: Sendable {
    let storagePath: String
    let remoteURL: URL?
    let width: Int
    let height: Int
    let bytes: Int
}

enum PhotoUploadError: Error, LocalizedError, Equatable {
    case assetLoadFailed
    case encodingFailed
    case tooLarge(Int)
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .assetLoadFailed:
            return "사진을 불러올 수 없어요."
        case .encodingFailed:
            return "사진을 변환하는 데 실패했어요."
        case .tooLarge(let n):
            return "사진이 너무 큽니다 (\(n)MB)."
        case .uploadFailed(let msg):
            return "업로드 실패: \(msg)"
        }
    }
}

protocol PhotoUploading: Sendable {
    func upload(
        assets: [PHAsset],
        groupId: UUID,
        memoryId: UUID,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> [UploadedPhoto]

    func signedURL(storagePath: String, expiresIn: Int) async throws -> URL?
    func delete(paths: [String]) async
}

protocol PhotoUploaderClient: Sendable {
    func upload(path: String, data: Data) async throws
    func createSignedURL(path: String, expiresIn: Int) async throws -> URL?
    func remove(paths: [String]) async throws
}

actor PhotoUploader: PhotoUploading {
    private let bucket = "memories"
    private let maxEdge: CGFloat = 2048
    private let jpegQuality: CGFloat = 0.82
    private let maxBytes = 25 * 1024 * 1024
    private let maxRetryCount = 3
    private let baseRetryDelayNanoseconds: UInt64 = 300_000_000
    private let client: PhotoUploaderClient

    init(client: PhotoUploaderClient = SupabasePhotoUploaderClient()) {
        self.client = client
    }

    static func storagePath(groupId: UUID, memoryId: UUID, filename: String) -> String {
        "\(groupId.uuidString.lowercased())/\(memoryId.uuidString.lowercased())/\(filename)"
    }

    func upload(
        assets: [PHAsset],
        groupId: UUID,
        memoryId: UUID,
        progress: @Sendable @escaping (Double) -> Void = { _ in }
    ) async throws -> [UploadedPhoto] {
        let total = Double(assets.count)
        var uploaded: [UploadedPhoto] = []

        for (index, asset) in assets.enumerated() {
            let imageData = try await loadJPEG(from: asset)
            guard imageData.count <= maxBytes else {
                throw PhotoUploadError.tooLarge(Int(ceil(Double(imageData.count) / 1_000_000.0)))
            }

            let filename = "\(UUID().uuidString).jpg"
            let path = Self.storagePath(groupId: groupId, memoryId: memoryId, filename: filename)

            try await uploadImageData(imageData, path: path)

            let signedURL = try? await signedURL(storagePath: path)
            uploaded.append(
                UploadedPhoto(
                    storagePath: path,
                    remoteURL: signedURL,
                    width: asset.pixelWidth,
                    height: asset.pixelHeight,
                    bytes: imageData.count
                )
            )
            progress(total == 0 ? 1 : Double(index + 1) / total)
        }

        return uploaded
    }

    func signedURL(storagePath: String, expiresIn: Int = 60 * 60 * 24 * 7) async throws -> URL? {
        try await client.createSignedURL(path: storagePath, expiresIn: expiresIn)
    }

    func delete(paths: [String]) async {
        guard paths.isEmpty == false else { return }
        _ = try? await client.remove(paths: paths)
    }

    func uploadImageData(_ data: Data, path: String) async throws {
        var lastError: Error?

        for attempt in 0...maxRetryCount {
            do {
                try await client.upload(path: path, data: data)
                return
            } catch {
                lastError = error
                guard attempt < maxRetryCount else { break }

                let multiplier = UInt64(1 << attempt)
                try? await Task.sleep(nanoseconds: baseRetryDelayNanoseconds * multiplier)
            }
        }

        throw PhotoUploadError.uploadFailed(lastError?.localizedDescription ?? "알 수 없는 오류")
    }

    private func loadJPEG(from asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: maxEdge, height: maxEdge),
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return
                }
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    continuation.resume(throwing: PhotoUploadError.assetLoadFailed)
                    return
                }
                if info?[PHImageErrorKey] != nil {
                    continuation.resume(throwing: PhotoUploadError.assetLoadFailed)
                    return
                }
                guard let image else {
                    continuation.resume(throwing: PhotoUploadError.assetLoadFailed)
                    return
                }
                guard let jpeg = image.jpegData(compressionQuality: self.jpegQuality) else {
                    continuation.resume(throwing: PhotoUploadError.encodingFailed)
                    return
                }
                continuation.resume(returning: jpeg)
            }
        }
    }
}

private struct SupabasePhotoUploaderClient: PhotoUploaderClient {
    private var storage: SupabaseStorageClient { SupabaseService.shared.storage }
    private let bucket = "memories"

    func upload(path: String, data: Data) async throws {
        _ = try await storage.from(bucket).upload(
            path,
            data: data,
            options: FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg",
                upsert: false
            )
        )
    }

    func createSignedURL(path: String, expiresIn: Int) async throws -> URL? {
        try await storage.from(bucket).createSignedURL(path: path, expiresIn: expiresIn)
    }

    func remove(paths: [String]) async throws {
        _ = try await storage.from(bucket).remove(paths: paths)
    }
}
