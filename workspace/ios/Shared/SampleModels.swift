import CoreLocation
import SwiftUI

struct SampleMemoryPin: Identifiable {
    let id = UUID()
    let title: String
    let shortLabel: String
    let coordinate: CLLocationCoordinate2D
    let symbol: String
    let color: Color

    static let samples: [SampleMemoryPin] = [
        .init(title: "Rooftop Dinner", shortLabel: "Dinner", coordinate: .init(latitude: 37.5519, longitude: 126.9215), symbol: "fork.knife", color: .orange),
        .init(title: "Han River Ride", shortLabel: "Ride", coordinate: .init(latitude: 37.5283, longitude: 126.9326), symbol: "bicycle", color: .blue),
        .init(title: "Sunrise Walk", shortLabel: "Dawn", coordinate: .init(latitude: 37.5700, longitude: 126.9768), symbol: "sunrise.fill", color: .pink)
    ]
}

struct RewindMoment: Identifiable {
    let id = UUID()
    let dateLabel: String
    let title: String
    let location: String
    let summary: String
    let people: String
    let mood: String
    let gradient: LinearGradient

    static let samples: [RewindMoment] = [
        .init(
            dateLabel: "3 years ago today",
            title: "Concert afterglow",
            location: "Mangwon, Seoul",
            summary: "A rooftop dinner turned into your group's most reacted memory set.",
            people: "Minji, Yuna, 2 more",
            mood: "Joy",
            gradient: LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        .init(
            dateLabel: "1 year ago",
            title: "Late-night river ride",
            location: "Yeouido Hangang Park",
            summary: "Your ride log and sunset shots still drive the most rewind opens.",
            people: "Joon, Haru",
            mood: "Calm",
            gradient: LinearGradient(colors: [.blue, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    ]
}

struct GroupPreview: Identifiable {
    let id = UUID()
    let name: String
    let members: String
    let summary: String

    static let samples: [GroupPreview] = [
        .init(name: "Weekend Club", members: "8 members", summary: "Pins across Seoul food spots, concerts, and river rides."),
        .init(name: "Family Trips", members: "5 members", summary: "Shared memories, rewind reminders, and place-based albums.")
    ]
}

struct PlaceSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String

    static let samples: [PlaceSuggestion] = [
        .init(id: "sangsu-rooftop", title: "Sangsu Rooftop", subtitle: "Mapo-gu, Seoul", systemImage: "building.2"),
        .init(id: "jeju-sunrise", title: "Jeju Sunrise Trail", subtitle: "Seongsan-eup, Jeju", systemImage: "sunrise"),
        .init(id: "yeouido-park", title: "Yeouido Hangang Park", subtitle: "Yeongdeungpo-gu, Seoul", systemImage: "figure.walk")
    ]

    static func matching(_ query: String) -> [PlaceSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            return samples
        }

        return samples.filter { suggestion in
            suggestion.title.localizedCaseInsensitiveContains(trimmedQuery)
                || suggestion.subtitle.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}

enum MemoryComposerEvidenceMode: String {
    case none
    case deniedRecovery
    case manualPlacePicker
}

struct MemoryDraftTag: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String

    static let samples: [MemoryDraftTag] = [
        .init(id: "joy", title: "Joy", systemImage: "sun.max"),
        .init(id: "calm", title: "Calm", systemImage: "moon.stars"),
        .init(id: "grateful", title: "Grateful", systemImage: "heart"),
        .init(id: "nostalgic", title: "Nostalgic", systemImage: "sparkles")
    ]
}
