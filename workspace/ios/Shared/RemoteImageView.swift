import SwiftUI

/// Renders a memories-bucket photo from a storage path such as "<gid>/<mid>/<name>.jpg".
struct RemoteImageView: View {
    let storagePath: String?
    var contentMode: ContentMode = .fill
    var uploader: any PhotoUploading = PhotoUploader()

    @State private var signedURL: URL?
    @State private var loadError = false

    var body: some View {
        ZStack {
            if let url = signedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .transition(.opacity)
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .animation(.easeInOut(duration: 0.18), value: signedURL)
        .task(id: storagePath) {
            await resolveURL()
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(UnfadingTheme.Color.card)
            .overlay(
                Image(systemName: loadError ? "photo.badge.exclamationmark" : "photo")
                    .foregroundStyle(UnfadingTheme.Color.textTertiary)
            )
    }

    @MainActor
    private func resolveURL() async {
        signedURL = nil
        loadError = false

        guard let path = storagePath, path.isEmpty == false else {
            return
        }

        do {
            signedURL = try await uploader.signedURL(storagePath: path, expiresIn: 60 * 60 * 24 * 7)
        } catch {
            loadError = true
        }
    }
}
