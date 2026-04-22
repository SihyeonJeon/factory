import CoreLocation
import SwiftUI

struct SampleMemoryPin: Identifiable, Hashable {
    let id: UUID
    let title: String
    let shortLabel: String
    let coordinate: CLLocationCoordinate2D
    let symbol: String
    let color: Color

    static func == (lhs: SampleMemoryPin, rhs: SampleMemoryPin) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static let samples: [SampleMemoryPin] = [
        .init(id: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!, title: "Rooftop Dinner", shortLabel: "Dinner", coordinate: .init(latitude: 37.5519, longitude: 126.9215), symbol: "fork.knife", color: UnfadingTheme.Color.primary),
        .init(id: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!, title: "Han River Ride", shortLabel: "Ride", coordinate: .init(latitude: 37.5283, longitude: 126.9326), symbol: "bicycle", color: UnfadingTheme.Color.lavender),
        .init(id: UUID(uuidString: "33333333-3333-4333-8333-333333333333")!, title: "Sunrise Walk", shortLabel: "Dawn", coordinate: .init(latitude: 37.5700, longitude: 126.9768), symbol: "sunrise.fill", color: UnfadingTheme.Color.primarySoft)
    ]

    // vibe-limit-checked: 1 architecture coherence, 11 sample data maps to detail model
    func detail() -> SampleMemoryDetail? {
        SampleMemoryDetail.samples.first { $0.pinID == id }
    }
}

struct SampleMemoryContribution: Identifiable, Hashable {
    let id: UUID = UUID()
    let authorName: String
    let authorInitial: String
    let comment: String
    let timeAgo: String
}

struct SampleMemoryDetail: Identifiable {
    let id: UUID
    let pinID: UUID
    let photoPlaceholders: [String]
    let noteBody: String
    let moodTagIDs: [String]
    let costKRW: Int?
    let contributions: [SampleMemoryContribution]

    static let samples: [SampleMemoryDetail] = [
        .init(
            id: UUID(uuidString: "aaaaaaa1-aaaa-4aaa-8aaa-aaaaaaaaaaa1")!,
            pinID: SampleMemoryPin.samples[0].id,
            photoPlaceholders: ["fork.knife", "wineglass", "camera.fill", "heart.fill", "sparkles", "person.3.fill"],
            noteBody: "상수 루프톱에서 저녁을 먹고 공연 이야기를 오래 나눴어요. 밤바람과 사진들이 아직 선명하게 남아 있어요.",
            moodTagIDs: ["joy", "grateful", "nostalgic"],
            costKRW: 68000,
            contributions: [
                .init(authorName: "시현", authorInitial: "시", comment: "다음에도 이 자리에서 다시 만나고 싶어요.", timeAgo: "방금 전"),
                .init(authorName: "민지", authorInitial: "민", comment: "사진 속 조명이 정말 따뜻했어요.", timeAgo: "10분 전")
            ]
        ),
        .init(
            id: UUID(uuidString: "bbbbbbb2-bbbb-4bbb-8bbb-bbbbbbbbbbb2")!,
            pinID: SampleMemoryPin.samples[1].id,
            photoPlaceholders: ["bicycle", "sunset.fill", "figure.outdoor.cycle", "water.waves", "camera.fill", "map.fill"],
            noteBody: "한강을 따라 달리다가 노을이 가장 진한 곳에서 멈췄어요. 천천히 돌아오던 길까지 좋은 추억이 됐어요.",
            moodTagIDs: ["calm", "grateful"],
            costKRW: nil,
            contributions: [
                .init(authorName: "준호", authorInitial: "준", comment: "달리기보다 멈춰 있던 시간이 더 좋았어요.", timeAgo: "1시간 전"),
                .init(authorName: "하루", authorInitial: "하", comment: "다음에는 돗자리도 챙겨가요.", timeAgo: "어제")
            ]
        ),
        .init(
            id: UUID(uuidString: "ccccccc3-cccc-4ccc-8ccc-ccccccccccc3")!,
            pinID: SampleMemoryPin.samples[2].id,
            photoPlaceholders: ["sunrise.fill", "leaf.fill", "figure.walk", "camera.fill", "sparkles", "mappin"],
            noteBody: "아침 공기가 차가웠지만 함께 걷다 보니 금방 따뜻해졌어요. 하루를 시작하기 좋은 산책이었어요.",
            moodTagIDs: ["calm", "nostalgic"],
            costKRW: 12000,
            contributions: [
                .init(authorName: "유나", authorInitial: "유", comment: "일찍 일어난 보람이 있었어요.", timeAgo: "2일 전")
            ]
        )
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

enum GroupMode: String, CaseIterable, Hashable {
    case couple
    case general

    var koreanTitle: String {
        self == .couple ? "커플" : "그룹"
    }
}

struct SampleGroupMember: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let initial: String
    let relation: String
}

struct SampleGroup: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let mode: GroupMode
    let members: [SampleGroupMember]
    let coverEmojis: [String]

    // vibe-limit-checked: 11 sample group data maps future persisted group model
    static let sampleCouple = SampleGroup(
        name: "우리의 지도",
        mode: .couple,
        members: [
            .init(name: "시현", initial: "시", relation: "파트너"),
            .init(name: "지호", initial: "지", relation: "파트너")
        ],
        coverEmojis: ["🌸", "🗺️", "☕️"]
    )

    static let sampleGeneral = SampleGroup(
        name: "주말 모임",
        mode: .general,
        members: [
            .init(name: "시현", initial: "시", relation: "친구"),
            .init(name: "민지", initial: "민", relation: "친구"),
            .init(name: "준호", initial: "준", relation: "친구"),
            .init(name: "유나", initial: "유", relation: "친구"),
            .init(name: "하루", initial: "하", relation: "친구")
        ],
        coverEmojis: ["🚲", "🍜", "🎧", "🌉"]
    )
}

struct SampleMemoryDraft: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var body: String
    var placeName: String
    var timestamp: Date
    var moodIDs: [String]

    // vibe-limit-checked: 11 sample draft data maps future persisted memory draft model
    static let defaultSamples: [SampleMemoryDraft] = [
        .init(
            id: UUID(uuidString: "ddddddd1-dddd-4ddd-8ddd-ddddddddddd1")!,
            title: "상수 루프톱 저녁",
            body: "친구들과 공연 이야기를 나눈 밤",
            placeName: "상수 루프톱",
            timestamp: Date(timeIntervalSince1970: 1_776_000_000),
            moodIDs: ["joy", "grateful"]
        ),
        .init(
            id: UUID(uuidString: "ddddddd2-dddd-4ddd-8ddd-ddddddddddd2")!,
            title: "한강 산책",
            body: "노을을 보며 천천히 걸었던 시간",
            placeName: "여의도 한강공원",
            timestamp: Date(timeIntervalSince1970: 1_776_086_400),
            moodIDs: ["calm", "nostalgic"]
        )
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
