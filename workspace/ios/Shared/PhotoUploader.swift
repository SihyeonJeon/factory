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

actor PhotoUploader: PhotoUploading {
    private var storage: SupabaseStorageClient { SupabaseService.shared.storage }
    private let bucket = "memories"
    private let maxEdge: CGFloat = 2048
    private let jpegQuality: CGFloat = 0.82
    private let maxBytes = 25 * 1024 * 1024

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

            do {
                _ = try await storage.from(bucket).upload(
                    path,
                    data: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: false
                    )
                )
            } catch {
                throw PhotoUploadError.uploadFailed(error.localizedDescription)
            }

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
        try await storage.from(bucket).createSignedURL(path: storagePath, expiresIn: expiresIn)
    }

    func delete(paths: [String]) async {
        guard paths.isEmpty == false else { return }
        _ = try? await storage.from(bucket).remove(paths: paths)
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
