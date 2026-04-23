import Foundation
import SwiftUI

/// Renders a memories-bucket photo from a storage path such as "<gid>/<mid>/<name>.jpg".
struct RemoteImageView: View {
    let storagePath: String?
    var contentMode: ContentMode = .fill
    var uploader: any PhotoUploading = PhotoUploader()
    var cache: RemoteImageSignedURLCache = .shared

    @State private var signedURL: URL?
    @State private var isResolving = false
    @State private var loadErrorMessage: String?
    @State private var reloadToken = 0

    var body: some View {
        ZStack {
            if let url = signedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        shimmerPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .transition(.opacity)
                    case .failure:
                        failurePlaceholder
                    @unknown default:
                        fallbackPlaceholder
                    }
                }
            } else {
                if isResolving {
                    shimmerPlaceholder
                } else if loadErrorMessage != nil {
                    failurePlaceholder
                } else {
                    fallbackPlaceholder
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: signedURL)
        .task(id: RemoteImageRequestKey(path: storagePath, reloadToken: reloadToken)) {
            await resolveURL()
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
            errorMessage: loadErrorMessage ?? "사진을 다시 불러오지 못했어요.",
            retry: retry
        )
    }

    private func retry() {
        signedURL = nil
        loadErrorMessage = nil
        reloadToken += 1
    }

    @MainActor
    private func resolveURL() async {
        signedURL = nil
        loadErrorMessage = nil
        isResolving = false

        guard let path = storagePath, path.isEmpty == false else {
            return
        }

        if let cachedURL = cache.url(for: path) {
            signedURL = cachedURL
            return
        }

        isResolving = true
        do {
            let expiresIn = 60 * 60 * 24 * 7
            let resolvedURL = try await uploader.signedURL(storagePath: path, expiresIn: expiresIn)
            signedURL = resolvedURL
            if let resolvedURL {
                cache.store(url: resolvedURL, for: path, expiresIn: expiresIn)
            } else {
                loadErrorMessage = "사진을 다시 불러오지 못했어요."
            }
        } catch {
            loadErrorMessage = "사진을 다시 불러오지 못했어요."
        }
        isResolving = false
    }
}

struct RemoteImageRequestKey: Hashable {
    let path: String?
    let reloadToken: Int
}

final class RemoteImageSignedURLCache {
    static let shared = RemoteImageSignedURLCache()

    private let cache = NSCache<NSString, RemoteImageSignedURLBox>()
    private let refreshLeadTime: TimeInterval
    private var now: () -> Date

    init(
        refreshLeadTime: TimeInterval = 5 * 60,
        now: @escaping () -> Date = Date.init
    ) {
        self.refreshLeadTime = refreshLeadTime
        self.now = now
    }

    func url(for path: String) -> URL? {
        guard let cached = cache.object(forKey: path as NSString) else { return nil }
        let remaining = cached.expiry.timeIntervalSince(now())
        guard remaining > refreshLeadTime else {
            cache.removeObject(forKey: path as NSString)
            return nil
        }
        return cached.url
    }

    func store(url: URL, for path: String, expiresIn: Int) {
        let expiry = now().addingTimeInterval(TimeInterval(expiresIn))
        cache.setObject(RemoteImageSignedURLBox(url: url, expiry: expiry), forKey: path as NSString)
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

private final class RemoteImageSignedURLBox: NSObject {
    let url: URL
    let expiry: Date

    init(url: URL, expiry: Date) {
        self.url = url
        self.expiry = expiry
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
