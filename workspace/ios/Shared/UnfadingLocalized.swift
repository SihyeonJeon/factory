import Foundation

/// Korean user-facing string namespace. All SwiftUI `Text`, `Label`, and
/// `accessibilityLabel`/`accessibilityHint` arguments in `App/` and `Features/`
/// MUST resolve to a member of this namespace. Plain Swift (not `.xcstrings`)
/// per `round_foundation_reset_r1` decision; migrate to `Localizable.xcstrings`
/// only when multi-locale becomes a real product requirement.
enum UnfadingLocalized {

    // MARK: Tab labels

    enum Tab {
        static let map = "지도"
        static let rewind = "리와인드"
        static let groups = "그룹"
    }

    // MARK: Accessibility

    enum Accessibility {
        static let mapTabLabel = "지도 탭"
        static let mapTabHint = "지도에서 추억 핀과 장소 기록을 둘러봅니다."
        static let rewindTabLabel = "리와인드 탭"
        static let rewindTabHint = "리와인드 순간과 알림 설정을 확인합니다."
        static let groupsTabLabel = "그룹 탭"
        static let groupsTabHint = "그룹을 만들고 초대와 참여를 관리합니다."

        static let showCurrentLocationLabel = "현재 위치 보기"
        static let showCurrentLocationHint = "위치 권한이 있을 때 지도를 현재 위치로 이동합니다."

        static let addMemoryLabel = "추억 추가"
    }

    // MARK: Home

    enum Home {
        static let newMemory = "새 추억"
        static let navTitle = "추억 지도"
    }

    // MARK: Common

    enum Common {
        static let cancel = "취소"
    }

    // MARK: Rewind

    enum Rewind {
        static let navTitle = "리와인드"
    }

    // MARK: Groups

    enum Groups {
        static let navTitle = "그룹"
    }

    // MARK: Summary card

    enum Summary {
        static let tonightsRewind = "오늘의 리와인드"
        static let sampleTitle = "상수 루프톱 저녁"
        static let sampleBody = "3년 전 오늘, 이곳에서 공연 뒤 함께 핀을 남겼습니다. 오늘 아침 새 반응 2개가 도착했습니다."
        static let friendCount = "친구 4명"
        static let joyTag = "기쁨"
        static let nightOutTag = "밤 나들이"
        static let photoSetTag = "사진 모음"
    }

    // MARK: Composer

    enum Composer {
        // Navigation
        static let navTitle = "새 추억"
        static let save = "저장"

        // Sections
        static let memorySection = "추억"
        static let photosSection = "사진"
        static let placeSection = "장소"
        static let moodSection = "감정"

        // Memory fields
        static let noteField = "짧은 메모를 남겨보세요"
        static let eventLabel = "이벤트"
        static let timeLabel = "시간"
        static let sampleTime = "오늘 오후 8:40"

        // Photos
        static let addFromLibrary = "보관함에서 추가"
        static let metadataHint = "첫 사진의 메타데이터로 시간과 장소를 미리 채울 수 있습니다."

        // Place
        static let selectedPlace = "선택한 장소"
        static let choosePlaceManually = "장소 직접 선택"
        static let useCurrentLocation = "현재 위치 사용"
        static let samplePlace = "상수동 루프톱"
        static let placeholderChoose = "장소를 선택하세요"
        static let placeholderCurrent = "현재 위치"

        // Denied recovery sheet
        static let locationAccessOff = "위치 접근 꺼짐"
        static let locationRecoveryHint = "장소를 직접 선택하면 이 추억을 저장할 수 있습니다. 현재 위치 자동 입력을 사용하려면 설정에서 위치 접근을 다시 켜세요."
        static let currentPlace = "현재 장소"
        static let searchForPlace = "장소 검색"
        static let openSettings = "설정 열기"
        static let locationNeededTitle = "위치 권한 필요"
        static let done = "완료"

        // Manual place picker sheet
        static let useTypedPlace = "입력한 장소 사용"
        static let nearbyOptions = "근처 장소"
        static let searchPlaces = "장소 검색"
        static let choosePlaceTitle = "장소 선택"
    }

    // MARK: Model-sourced display (helpers for sample data)

    /// Korean display for a `MemoryDraftTag.id`. Returns the fallback if unmapped.
    static func draftTag(id: String, fallback: String) -> String {
        switch id {
        case "joy": return "기쁨"
        case "calm": return "차분함"
        case "grateful": return "감사"
        case "nostalgic": return "그리움"
        default: return fallback
        }
    }

    /// Korean display for a `PlaceSuggestion.id`. Returns the fallback if unmapped.
    static func placeSuggestion(id: String, fallbackTitle: String, fallbackSubtitle: String) -> (title: String, subtitle: String) {
        switch id {
        case "sangsu-rooftop":
            return ("상수 루프톱", "서울 마포구")
        case "jeju-sunrise":
            return ("제주 성산일출봉", "제주 성산읍")
        case "yeouido-park":
            return ("여의도 한강공원", "서울 영등포구")
        default:
            return (fallbackTitle, fallbackSubtitle)
        }
    }
}
