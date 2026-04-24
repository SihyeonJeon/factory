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

    init(preSelectedPhotoID: String?) {
        self.photoReference = preSelectedPhotoID.flatMap(ComposerLaunchPhotoReference.init(rawValue:))
    }

    static func from(url: URL) -> ComposerLaunchRoute? {
        guard case let .composer(preSelectedPhotoID) = DeepLinkRouter.parse(url) else { return nil }
        return ComposerLaunchRoute(preSelectedPhotoID: preSelectedPhotoID)
    }
}
