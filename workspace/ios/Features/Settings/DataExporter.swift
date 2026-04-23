import Foundation
import UIKit

actor DataExporter {
    enum ExportError: LocalizedError {
        case signedURLUnavailable(String)
        case downloadFailed(String)
        case writeFailed(String)

        var errorDescription: String? {
            switch self {
            case .signedURLUnavailable:
                return UnfadingLocalized.GroupHub.photoExportSignedURLFailed
            case .downloadFailed:
                return UnfadingLocalized.GroupHub.photoExportDownloadFailed
            case .writeFailed:
                return UnfadingLocalized.GroupHub.photoExportWriteFailed
            }
        }
    }

    private let fileManager: FileManager
    private let session: URLSession
    private let documentsDirectory: URL
    private let temporaryDirectory: URL

    init(
        fileManager: FileManager = .default,
        session: URLSession = .shared,
        documentsDirectory: URL? = nil,
        temporaryDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        self.session = session
        self.documentsDirectory = documentsDirectory
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.temporaryDirectory = temporaryDirectory ?? fileManager.temporaryDirectory
    }

    func exportJSON(memories: [DBMemory]) async throws -> URL {
        let url = documentsDirectory.appendingPathComponent("export-\(timestampToken())").appendingPathExtension("json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(memories)
        try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic])
        return url
    }

    func exportPhotos(memories: [DBMemory], uploader: any PhotoUploading) async throws -> URL {
        try await exportPhotos(memories: memories, uploader: uploader, progress: { _ in })
    }

    func exportPhotos(
        memories: [DBMemory],
        uploader: any PhotoUploading,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        try await performBackgroundExport(named: "photo-export") {
            let refs = photoReferences(from: memories)
            let packageURL = temporaryDirectory.appendingPathComponent("photo-export-\(timestampToken())", isDirectory: true)
            try fileManager.createDirectory(at: packageURL.deletingLastPathComponent(), withIntermediateDirectories: true)

            var wrappers: [String: FileWrapper] = [:]
            if refs.isEmpty {
                progress(1)
            }

            for (index, ref) in refs.enumerated() {
                let resolvedURL = try await resolvedPhotoURL(for: ref.path, uploader: uploader)
                let data = try await downloadPhotoData(from: resolvedURL)
                let ext = preferredExtension(for: resolvedURL)
                let filename = "memory-\(String(format: "%03d", ref.memoryIndex + 1))-photo-\(String(format: "%03d", ref.photoIndex + 1)).\(ext)"
                let wrapper = FileWrapper(regularFileWithContents: data)
                wrapper.preferredFilename = filename
                wrappers[filename] = wrapper
                progress(Double(index + 1) / Double(refs.count))
            }

            let directoryWrapper = FileWrapper(directoryWithFileWrappers: wrappers)
            try coordinatedWrite(wrapper: directoryWrapper, to: packageURL)
            return packageURL
        }
    }

    private func coordinatedWrite(wrapper: FileWrapper, to destinationURL: URL) throws {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var writeError: Error?

        coordinator.coordinate(writingItemAt: destinationURL, options: .forReplacing, error: &coordinationError) { coordinatedURL in
            do {
                if fileManager.fileExists(atPath: coordinatedURL.path) {
                    try fileManager.removeItem(at: coordinatedURL)
                }
                try wrapper.write(to: coordinatedURL, options: .atomic, originalContentsURL: nil)
            } catch {
                writeError = error
            }
        }

        if let coordinationError {
            throw ExportError.writeFailed(coordinationError.localizedDescription)
        }
        if let writeError {
            throw ExportError.writeFailed(writeError.localizedDescription)
        }
    }

    private func photoReferences(from memories: [DBMemory]) -> [PhotoReference] {
        memories.enumerated().flatMap { memoryIndex, memory in
            let paths = memory.photoURLs.isEmpty ? [memory.photoURL].compactMap { $0 } : memory.photoURLs
            return paths.enumerated().map { photoIndex, path in
                PhotoReference(memoryIndex: memoryIndex, photoIndex: photoIndex, path: path)
            }
        }
    }

    private func resolvedPhotoURL(for path: String, uploader: any PhotoUploading) async throws -> URL {
        if let remoteURL = URL(string: path), let scheme = remoteURL.scheme?.lowercased(), ["http", "https", "file"].contains(scheme) {
            return remoteURL
        }

        guard let signedURL = try await uploader.signedURL(storagePath: path, expiresIn: 60 * 60) else {
            throw ExportError.signedURLUnavailable(path)
        }
        return signedURL
    }

    private func downloadPhotoData(from url: URL) async throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        let (data, response) = try await session.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw ExportError.downloadFailed(url.absoluteString)
        }
        return data
    }

    private func preferredExtension(for url: URL) -> String {
        let ext = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        return ext.isEmpty ? "jpg" : ext.lowercased()
    }

    private func performBackgroundExport<T>(
        named taskName: String,
        operation: () async throws -> T
    ) async throws -> T {
        let identifier = UIApplication.shared.beginBackgroundTask(withName: taskName)
        defer {
            if identifier != .invalid {
                UIApplication.shared.endBackgroundTask(identifier)
            }
        }

        return try await operation()
    }

    private func timestampToken() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .autoupdatingCurrent
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

private struct PhotoReference {
    let memoryIndex: Int
    let photoIndex: Int
    let path: String
}
