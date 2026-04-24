import Foundation

enum ComposerLaunchPhotoReference: Equatable {
    case assetIdentifier(String)
    case tempFilePath(String)

    init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if trimmed.hasPrefix("/") || trimmed.hasPrefix("file://") {
            self = .tempFilePath(trimmed)
        } else {
            self = .assetIdentifier(trimmed)
        }
    }
}

struct ComposerLaunchRoute: Equatable {
    let photoReference: ComposerLaunchPhotoReference?

    static func from(url: URL) -> ComposerLaunchRoute? {
        guard url.scheme?.lowercased() == "unfading", url.host?.lowercased() == "composer" else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let photoValue = components?.queryItems?.first(where: { $0.name == "photo" })?.value
        return ComposerLaunchRoute(photoReference: photoValue.flatMap(ComposerLaunchPhotoReference.init(rawValue:)))
    }
}
