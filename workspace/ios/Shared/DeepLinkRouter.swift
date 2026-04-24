import Foundation
import SwiftUI

enum DeepLinkTarget: Equatable, Sendable {
    case memory(UUID)
    case event(UUID)
    case composer(preSelectedPhotoID: String?)
    case rewind
}

enum DeepLinkRouter {
    static func parse(_ url: URL) -> DeepLinkTarget? {
        guard let scheme = url.scheme?.lowercased() else { return nil }

        switch scheme {
        case "unfading":
            return parseCustomScheme(url)
        case "https":
            return parseUniversalLink(url)
        default:
            return nil
        }
    }

    private static func parseCustomScheme(_ url: URL) -> DeepLinkTarget? {
        guard let host = url.host?.lowercased() else { return nil }

        switch host {
        case "memory":
            return parseUUIDPath(url).map(DeepLinkTarget.memory)
        case "event":
            return parseUUIDPath(url).map(DeepLinkTarget.event)
        case "composer":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let photoID = components?.queryItems?.first(where: { $0.name == "photo" })?.value
            return .composer(preSelectedPhotoID: photoID?.trimmedNilIfEmpty)
        case "rewind":
            return url.path.isEmpty || url.path == "/" ? .rewind : nil
        default:
            return nil
        }
    }

    private static func parseUniversalLink(_ url: URL) -> DeepLinkTarget? {
        guard url.host?.lowercased() == "unfading.app" else { return nil }

        let components = pathComponents(for: url)
        guard components.count == 2, let id = UUID(uuidString: components[1]) else { return nil }

        switch components[0].lowercased() {
        case "memory":
            return .memory(id)
        case "event":
            return .event(id)
        default:
            return nil
        }
    }

    private static func parseUUIDPath(_ url: URL) -> UUID? {
        let components = pathComponents(for: url)
        guard components.count == 1 else { return nil }
        return UUID(uuidString: components[0])
    }

    private static func pathComponents(for url: URL) -> [String] {
        url.path.split(separator: "/").map(String.init)
    }
}

@MainActor
final class DeepLinkStore: ObservableObject {
    @Published var pendingDeepLink: DeepLinkTarget?
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
