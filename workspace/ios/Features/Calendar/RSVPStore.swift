import Combine
import Foundation

enum RSVPStatus: Equatable {
    case going
    case maybe
    case notGoing
}

@MainActor
final class RSVPStore: ObservableObject {
    @Published var rsvps: [UUID: RSVPStatus]

    init(rsvps: [UUID: RSVPStatus] = [:]) {
        self.rsvps = rsvps
    }

    var summary: String {
        let going = rsvps.values.filter { $0 == .going }.count
        let maybe = rsvps.values.filter { $0 == .maybe }.count
        let notGoing = rsvps.values.filter { $0 == .notGoing }.count
        return "✓ \(going) · ? \(maybe) · ✗ \(notGoing)"
    }

    func setStatus(_ status: RSVPStatus, for userId: UUID) {
        rsvps[userId] = status
    }

    func toggle(_ status: RSVPStatus, for userId: UUID) {
        if rsvps[userId] == status {
            rsvps.removeValue(forKey: userId)
        } else {
            rsvps[userId] = status
        }
    }
}
