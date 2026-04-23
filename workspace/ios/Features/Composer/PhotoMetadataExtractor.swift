import CoreLocation
import Foundation
import Photos

struct PhotoSeed: Equatable {
    let creationDate: Date?
    let coordinate: CLLocationCoordinate2D?
    let heading: Double?

    static func == (lhs: PhotoSeed, rhs: PhotoSeed) -> Bool {
        lhs.creationDate == rhs.creationDate
            && lhs.coordinate?.latitude == rhs.coordinate?.latitude
            && lhs.coordinate?.longitude == rhs.coordinate?.longitude
            && lhs.heading == rhs.heading
    }
}

enum PhotoMetadataExtractor {
    static func extract(from asset: PHAsset) -> PhotoSeed {
        extract(creationDate: asset.creationDate, location: asset.location)
    }

    static func extract(creationDate: Date?, location: CLLocation?) -> PhotoSeed {
        PhotoSeed(
            creationDate: creationDate,
            coordinate: location?.coordinate,
            heading: location?.course
        )
    }
}
