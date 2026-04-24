import Foundation
import SwiftUI
import UIKit

/// Renders a memories-bucket photo from a storage path such as "<gid>/<mid>/<name>.jpg".
struct RemoteImageView: View {
    let storagePath: String?
    var contentMode: ContentMode = .fill
    var uploader: any PhotoUploading = PhotoUploader()
    var cache: RemoteImageSignedURLCache = .shared
    var imageDataProvider: RemoteImageDataProvider = RemoteImageLoader.liveImageData(from:)

    @State private var reloadToken = 0
    @StateObject private var loader = RemoteImageLoader()

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                if loader.isResolving {
                    shimmerPlaceholder
                } else if loader.loadErrorMessage != nil {
                    failurePlaceholder
                } else {
                    fallbackPlaceholder
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: loader.image)
        .task(id: RemoteImageRequestKey(path: storagePath, reloadToken: reloadToken)) {
            await loader.load(
                storagePath: storagePath,
                uploader: uploader,
                cache: cache,
                imageDataProvider: imageDataProvider
            )
        }
    }

    private var fallbackPlaceholder: some View {
        RemoteImagePlaceholderCard(
            isLoading: false,
            errorMessage: nil,
            retry: nil
        )
    }

    private var shimmerPlaceholder: some View {
        RemoteImagePlaceholderCard(
            isLoading: true,
            errorMessage: nil,
            retry: nil
        )
    }

    private var failurePlaceholder: some View {
        RemoteImagePlaceholderCard(
            isLoading: false,
            errorMessage: loader.loadErrorMessage ?? "사진을 다시 불러오지 못했어요.",
            retry: retry
        )
    }

    private func retry() {
        loader.reset()
        reloadToken += 1
    }
}

struct RemoteImageRequestKey: Hashable {
    let path: String?
    let reloadToken: Int
}

final class RemoteImageSignedURLCache {
    static let shared = RemoteImageSignedURLCache()

    private let cache = NSCache<NSString, RemoteImageCacheEntry>()
    private let refreshLeadTime: TimeInterval
    private var now: () -> Date
    private var memoryWarningObserver: NSObjectProtocol?

    init(
        refreshLeadTime: TimeInterval = 5 * 60,
        now: @escaping () -> Date = Date.init
    ) {
        self.refreshLeadTime = refreshLeadTime
        self.now = now
        cache.countLimit = 60
        cache.totalCostLimit = 40 * 1_024 * 1_024
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.removeAll()
        }
    }

    deinit {
        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }

    func url(for path: String) -> URL? {
        guard let cached = cache.object(forKey: path as NSString) else { return nil }
        guard let expiry = cached.expiry else {
            return cached.url
        }

        let remaining = expiry.timeIntervalSince(now())
        guard remaining > refreshLeadTime else {
            cache.removeObject(forKey: path as NSString)
            return nil
        }
        return cached.url
    }

    func store(url: URL, for path: String, expiresIn: Int) {
        let expiry = now().addingTimeInterval(TimeInterval(expiresIn))
        let entry = cache.object(forKey: path as NSString) ?? RemoteImageCacheEntry()
        entry.url = url
        entry.expiry = expiry
        cache.setObject(entry, forKey: path as NSString, cost: entry.cacheCost)
    }

    func image(for path: String) -> UIImage? {
        cache.object(forKey: path as NSString)?.image
    }

    func store(image: UIImage, for path: String) {
        let entry = cache.object(forKey: path as NSString) ?? RemoteImageCacheEntry()
        entry.image = image
        cache.setObject(entry, forKey: path as NSString, cost: entry.cacheCost)
    }

    func removeValue(for path: String) {
        cache.removeObject(forKey: path as NSString)
    }

    func removeAll() {
        cache.removeAllObjects()
    }

    func setNow(_ provider: @escaping () -> Date) {
        now = provider
    }
}

typealias RemoteImageDataProvider = @Sendable (URL) async throws -> Data

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isResolving = false
    @Published private(set) var loadErrorMessage: String?

    func load(
        storagePath: String?,
        uploader: any PhotoUploading,
        cache: RemoteImageSignedURLCache,
        imageDataProvider: RemoteImageDataProvider
    ) async {
        reset()

        guard let path = storagePath, path.isEmpty == false else {
            return
        }

        if let cachedImage = cache.image(for: path) {
            image = cachedImage
            return
        }

        isResolving = true
        do {
            let expiresIn = 60 * 60 * 24 * 7
            let resolvedURL: URL
            if let cachedURL = cache.url(for: path) {
                resolvedURL = cachedURL
            } else if let signedURL = try await uploader.signedURL(storagePath: path, expiresIn: expiresIn) {
                cache.store(url: signedURL, for: path, expiresIn: expiresIn)
                resolvedURL = signedURL
            } else {
                loadErrorMessage = "사진을 다시 불러오지 못했어요."
                isResolving = false
                return
            }

            let data = try await imageDataProvider(resolvedURL)
            guard let resolvedImage = UIImage(data: data) else {
                loadErrorMessage = "사진을 다시 불러오지 못했어요."
                isResolving = false
                return
            }

            cache.store(image: resolvedImage, for: path)
            image = resolvedImage
        } catch {
            loadErrorMessage = "사진을 다시 불러오지 못했어요."
        }

        isResolving = false
    }

    func reset() {
        image = nil
        isResolving = false
        loadErrorMessage = nil
    }

    static func liveImageData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

private final class RemoteImageCacheEntry: NSObject {
    var url: URL?
    var expiry: Date?
    var image: UIImage?

    var cacheCost: Int {
        guard let image else { return 1 }
        if let cgImage = image.cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }
        let size = image.size
        let scale = image.scale
        return max(Int(size.width * scale * size.height * scale * 4), 1)
    }
}

private struct RemoteImagePlaceholderCard: View {
    let isLoading: Bool
    let errorMessage: String?
    let retry: (() -> Void)?
    @State private var shimmerActive = false

    var body: some View {
        ZStack {
            RemoteImageSampleGradient()

            if isLoading {
                shimmerLayer
            }

            VStack(spacing: UnfadingTheme.Spacing.sm) {
                Image(systemName: errorMessage == nil ? "photo" : "photo.badge.exclamationmark")
                    .imageScale(.large)
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary.opacity(0.92))

                if let errorMessage {
                    Text(errorMessage)
                        .font(UnfadingTheme.Font.footnote())
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, UnfadingTheme.Spacing.lg)

                    if let retry {
                        Button(action: retry) {
                            Label("다시 시도", systemImage: "arrow.clockwise")
                                .font(UnfadingTheme.Font.footnoteSemibold())
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                                .frame(minWidth: 120, minHeight: 44)
                                .padding(.horizontal, UnfadingTheme.Spacing.md)
                                .background(
                                    UnfadingTheme.Color.card.opacity(0.92),
                                    in: Capsule()
                                )
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .padding(UnfadingTheme.Spacing.lg)
        }
        .onAppear {
            guard isLoading else { return }
            shimmerActive = true
        }
    }

    private var shimmerLayer: some View {
        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
            .fill(.white.opacity(0.16))
            .overlay {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0),
                                    .white.opacity(0.35),
                                    .white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(18))
                        .frame(width: proxy.size.width * 0.55)
                        .offset(x: shimmerActive ? proxy.size.width * 0.78 : -proxy.size.width * 0.78)
                        .animation(
                            .linear(duration: 1.1).repeatForever(autoreverses: false),
                            value: shimmerActive
                        )
                }
                .clipped()
            }
    }
}

private struct RemoteImageSampleGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                UnfadingTheme.Color.primary.opacity(0.95),
                UnfadingTheme.Color.rose.opacity(0.82),
                UnfadingTheme.Color.lavender.opacity(0.76)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
