import Foundation

private func tr(_ key: StaticString, _ value: String.LocalizationValue) -> String {
    String(localized: key, defaultValue: value)
}

// vibe-limit-checked: 8 accessibility copy, 7 Korean UI fidelity, 11 sample-data mapping
/// User-facing string namespace backed by `Localizable.xcstrings`.
/// All SwiftUI `Text`, `Label`, and accessibility copy in `App/` and
/// `Features/` must resolve through this namespace so API call sites stay stable
/// while localization lives in the string catalog.
enum UnfadingLocalized {

    // MARK: Tab labels

    enum Tab {
        static var map: String { tr("UnfadingLocalized.Tab.map", "지도") }
        static var calendar: String { tr("UnfadingLocalized.Tab.calendar", "캘린더") }
        static var compose: String { tr("UnfadingLocalized.Tab.compose", "추억") }
        static var rewind: String { tr("UnfadingLocalized.Tab.rewind", "리와인드") }
        static var settings: String { tr("UnfadingLocalized.Tab.settings", "설정") }
        // Deprecated (R2 MVP only; R3 demoted Groups to a row under Settings)
        static var groups: String { tr("UnfadingLocalized.Tab.groups", "그룹") }
    }

    // MARK: Accessibility

    enum Accessibility {
        static var mapTabLabel: String { tr("UnfadingLocalized.Accessibility.mapTabLabel", "지도 탭") }
        static var mapTabHint: String { tr("UnfadingLocalized.Accessibility.mapTabHint", "지도에서 추억 핀과 장소 기록을 둘러봅니다.") }
        static var calendarTabLabel: String { tr("UnfadingLocalized.Accessibility.calendarTabLabel", "캘린더 탭") }
        static var calendarTabHint: String { tr("UnfadingLocalized.Accessibility.calendarTabHint", "날짜별로 추억을 훑어봅니다.") }
        static var composeTabLabel: String { tr("UnfadingLocalized.Accessibility.composeTabLabel", "추억 만들기 탭") }
        static var composeTabHint: String { tr("UnfadingLocalized.Accessibility.composeTabHint", "새 추억을 기록하는 화면을 엽니다.") }
        static var rewindTabLabel: String { tr("UnfadingLocalized.Accessibility.rewindTabLabel", "리와인드 탭") }
        static var rewindTabHint: String { tr("UnfadingLocalized.Accessibility.rewindTabHint", "리와인드 순간과 알림 설정을 확인합니다.") }
        static var settingsTabLabel: String { tr("UnfadingLocalized.Accessibility.settingsTabLabel", "설정 탭") }
        static var settingsTabHint: String { tr("UnfadingLocalized.Accessibility.settingsTabHint", "앱 설정과 그룹 관리에 접근합니다.") }
        static var groupsTabLabel: String { tr("UnfadingLocalized.Accessibility.groupsTabLabel", "그룹 탭") }
        static var groupsTabHint: String { tr("UnfadingLocalized.Accessibility.groupsTabHint", "그룹을 만들고 초대와 참여를 관리합니다.") }

        static var showCurrentLocationLabel: String { tr("UnfadingLocalized.Accessibility.showCurrentLocationLabel", "현재 위치 보기") }
        static var showCurrentLocationHint: String { tr("UnfadingLocalized.Accessibility.showCurrentLocationHint", "위치 권한이 있을 때 지도를 현재 위치로 이동합니다.") }

        static var addMemoryLabel: String { tr("UnfadingLocalized.Accessibility.addMemoryLabel", "추억 추가") }
        static var addMemoryHint: String { tr("UnfadingLocalized.Accessibility.addMemoryHint", "새 추억 기록 화면을 엽니다.") }
        static var mapPinHint: String { tr("UnfadingLocalized.Accessibility.mapPinHint", "탭하면 이 추억의 요약을 엽니다.") }
        static var filterRowLabel: String { tr("UnfadingLocalized.Accessibility.filterRowLabel", "추억 필터") }
        static var filterRowHint: String { tr("UnfadingLocalized.Accessibility.filterRowHint", "가로로 넘겨 지도에 표시할 추억 종류를 고릅니다.") }
        static var bottomSheetHandleLabel: String { tr("UnfadingLocalized.Accessibility.bottomSheetHandleLabel", "추억 요약 패널") }
        static var bottomSheetHandleHint: String { tr("UnfadingLocalized.Accessibility.bottomSheetHandleHint", "위아래로 드래그해 패널 높이를 조절합니다.") }
        static var memorySummaryHint: String { tr("UnfadingLocalized.Accessibility.memorySummaryHint", "상세 보기를 선택하면 추억 상세 화면으로 이동합니다.") }
        static var shareRewindHint: String { tr("UnfadingLocalized.Accessibility.shareRewindHint", "리와인드 순간을 공유합니다.") }
        static var rewatchRewindHint: String { tr("UnfadingLocalized.Accessibility.rewatchRewindHint", "리와인드 스토리를 다시 엽니다.") }
        static var inviteGroupHint: String { tr("UnfadingLocalized.Accessibility.inviteGroupHint", "현재 그룹에 새 멤버를 초대합니다.") }
        static var premiumExploreHint: String { tr("UnfadingLocalized.Accessibility.premiumExploreHint", "프리미엄 요금제 안내 화면을 엽니다.") }
        static var premiumComingSoonHint: String { tr("UnfadingLocalized.Accessibility.premiumComingSoonHint", "프리미엄 결제는 아직 사용할 수 없습니다.") }
        static var placeEditHint: String { tr("UnfadingLocalized.Accessibility.placeEditHint", "장소 선택 화면을 엽니다.") }
        static var useCurrentLocationComposerHint: String { tr("UnfadingLocalized.Accessibility.useCurrentLocationComposerHint", "위치 권한 상태에 따라 현재 위치를 사용하거나 복구 안내를 엽니다.") }
        static var openSettingsHint: String { tr("UnfadingLocalized.Accessibility.openSettingsHint", "설정 앱에서 위치 접근 권한을 변경합니다.") }
        static var searchPlaceHint: String { tr("UnfadingLocalized.Accessibility.searchPlaceHint", "장소 검색 화면을 엽니다.") }
        static var onboardingSkipHint: String { tr("UnfadingLocalized.Accessibility.onboardingSkipHint", "온보딩을 마치고 앱으로 이동합니다.") }
        static var onboardingStartHint: String { tr("UnfadingLocalized.Accessibility.onboardingStartHint", "온보딩을 완료하고 앱을 시작합니다.") }
        static var resetMapOrientationLabel: String { tr("UnfadingLocalized.Accessibility.resetMapOrientationLabel", "지도 방향 초기화") }
        static var sheetBackLabel: String { tr("UnfadingLocalized.Accessibility.sheetBackLabel", "이전") }
        static var clearSelectionLabel: String { tr("UnfadingLocalized.Accessibility.clearSelectionLabel", "선택 해제") }
        static var clearSelectionHint: String { tr("UnfadingLocalized.Accessibility.clearSelectionHint", "지도 선택을 지우고 큐레이션 시트로 돌아갑니다.") }
        static var photoUploadInProgressLabel: String { tr("UnfadingLocalized.Accessibility.photoUploadInProgressLabel", "사진 업로드 중") }
        static var addMemoryAtPlaceLabel: String { tr("UnfadingLocalized.Accessibility.addMemoryAtPlaceLabel", "이 장소에 추억 추가") }

        static func mapPinLabel(title: String) -> String {
            tr("UnfadingLocalized.Accessibility.mapPinLabel", "추억 핀, \(title)")
        }

        static func filterChipHint(title: String, isSelected: Bool) -> String {
            if isSelected {
                return tr("UnfadingLocalized.Accessibility.filterChipHint.selected", "\(title) 필터를 해제합니다.")
            }
            return tr("UnfadingLocalized.Accessibility.filterChipHint.unselected", "\(title) 필터를 적용합니다.")
        }

        static func memorySummaryLabel(title: String, body: String) -> String {
            tr("UnfadingLocalized.Accessibility.memorySummaryLabel", "\(title). \(body)")
        }

        static func monthNavigationHint(monthTitle: String) -> String {
            tr("UnfadingLocalized.Accessibility.monthNavigationHint", "\(monthTitle) 달력으로 이동합니다.")
        }

        static var requiredStrings: [String] {
            [
            mapTabLabel,
            mapTabHint,
            calendarTabLabel,
            calendarTabHint,
            composeTabLabel,
            composeTabHint,
            rewindTabLabel,
            rewindTabHint,
            settingsTabLabel,
            settingsTabHint,
            groupsTabLabel,
            groupsTabHint,
            showCurrentLocationLabel,
            showCurrentLocationHint,
            addMemoryLabel,
            addMemoryHint,
            mapPinHint,
            filterRowLabel,
            filterRowHint,
            bottomSheetHandleLabel,
            bottomSheetHandleHint,
            memorySummaryHint,
            shareRewindHint,
            rewatchRewindHint,
            inviteGroupHint,
            premiumExploreHint,
            premiumComingSoonHint,
            placeEditHint,
            useCurrentLocationComposerHint,
            openSettingsHint,
            searchPlaceHint,
            onboardingSkipHint,
            onboardingStartHint,
            resetMapOrientationLabel,
            sheetBackLabel,
            clearSelectionLabel,
            clearSelectionHint,
            photoUploadInProgressLabel,
            addMemoryAtPlaceLabel
            ]
        }
    }

    // MARK: Photo grid

    enum PhotoGrid {
        static var addPhoto: String { tr("UnfadingLocalized.PhotoGrid.addPhoto", "사진 추가") }
        static var removePhoto: String { tr("UnfadingLocalized.PhotoGrid.removePhoto", "사진 삭제") }
        static var loading: String { tr("UnfadingLocalized.PhotoGrid.loading", "불러오는 중") }
        static var loadFailed: String { tr("UnfadingLocalized.PhotoGrid.loadFailed", "사진을 불러오지 못했어요") }
    }

    // MARK: Home

    enum Home {
        static var newMemory: String { tr("UnfadingLocalized.Home.newMemory", "새 추억") }
        static var navTitle: String { tr("UnfadingLocalized.Home.navTitle", "추억 지도") }
        static var searchLabel: String { tr("UnfadingLocalized.Home.searchLabel", "검색") }
        static var searchHint: String { tr("UnfadingLocalized.Home.searchHint", "장소나 추억을 검색합니다.") }
        static var addMemoryFab: String { tr("UnfadingLocalized.Home.addMemoryFab", "추억 기록") }
        static var incomingMemoryToast: String { tr("UnfadingLocalized.Home.incomingMemoryToast", "새 추억이 도착했어요") }
        static var incomingMemoryBadge: String { tr("UnfadingLocalized.Home.incomingMemoryBadge", "새 추억 도착") }
        static var groupChipPlaceholder: String { tr("UnfadingLocalized.Home.groupChipPlaceholder", "우리 그룹") }
        static var groupChipHint: String { tr("UnfadingLocalized.Home.groupChipHint", "현재 그룹을 바꾸거나 그룹 허브를 엽니다.") }
        static var filterAll: String { tr("UnfadingLocalized.Home.filterAll", "전체") }
        static var filterDate: String { tr("UnfadingLocalized.Home.filterDate", "데이트") }
        static var filterTrip: String { tr("UnfadingLocalized.Home.filterTrip", "여행") }
        static var filterAnniversary: String { tr("UnfadingLocalized.Home.filterAnniversary", "기념일") }
        static var filterFood: String { tr("UnfadingLocalized.Home.filterFood", "맛집") }
        static var rewindHintTitle: String { tr("UnfadingLocalized.Home.rewindHintTitle", "이번 달 리와인드") }
        static var rewindHintBody: String { tr("UnfadingLocalized.Home.rewindHintBody", "함께 남긴 장소와 사진을 모아 한 번에 돌아봐요.") }
        static var rewindHintCta: String { tr("UnfadingLocalized.Home.rewindHintCta", "리와인드 보기") }

        static func rewindHintTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Home.rewindHintTitle.couple", "이번 달 우리의 리와인드")
            case .general:
                return tr("UnfadingLocalized.Home.rewindHintTitle.general", "이번 달 크루 리와인드")
            }
        }

        static func rewindHintBody(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Home.rewindHintBody.couple", "둘이 남긴 장소와 사진을 모아 한 번에 돌아봐요.")
            case .general:
                return tr("UnfadingLocalized.Home.rewindHintBody.general", "크루가 남긴 장소와 사진을 모아 한 번에 돌아봐요.")
            }
        }

        static func groupSubtitle(mode: GroupMode, memberCount: Int, days: Int) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Home.groupSubtitle.couple", "함께한 지 \(days)일")
            case .general:
                return tr("UnfadingLocalized.Home.groupSubtitle.general", "\(max(memberCount, 1))명 · \(days)일")
            }
        }

        static func memoryTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Home.memoryTitle.couple", "우리의 추억")
            case .general:
                return tr("UnfadingLocalized.Home.memoryTitle.general", "크루 기록")
            }
        }

        static func collapsedMemoryTitle(for mode: GroupMode, count: Int) -> String {
            tr("UnfadingLocalized.Home.collapsedMemoryTitle", "\(memoryTitle(for: mode)) \(count) · 위로 스와이프")
        }

        static func clusterMarkerLabel(place: String, count: Int) -> String {
            tr("UnfadingLocalized.Home.clusterMarkerLabel", "\(place), 추억 \(count)개")
        }

        static func eventAccessibilityLabel(title: String, place: String, photoCount: Int) -> String {
            tr("UnfadingLocalized.Home.eventAccessibilityLabel", "\(title), \(place), 사진 \(photoCount)장")
        }

        static func memoryRowAccessibilityLabel(place: String, time: String, note: String) -> String {
            tr("UnfadingLocalized.Home.memoryRowAccessibilityLabel", "\(place), \(time), \(note)")
        }

        static func dateAccessibilityLabel(month: Int, day: Int) -> String {
            tr("UnfadingLocalized.Home.dateAccessibilityLabel", "\(month)월 \(day)일")
        }

        static func progressPercent(_ percent: Int) -> String {
            tr("UnfadingLocalized.Home.progressPercent", "\(percent)%")
        }

        static func offlineQueueBanner(_ count: Int) -> String {
            tr("UnfadingLocalized.Home.offlineQueueBanner", "대기 중 \(count)건 — 연결 복귀 시 자동 저장")
        }
    }

    // MARK: Search

    enum Search {
        static var title: String { tr("UnfadingLocalized.Search.title", "추억 검색") }
        static var placeholder: String { tr("UnfadingLocalized.Search.placeholder", "장소, 메모, 태그로 검색") }
        static var clearQuery: String { tr("UnfadingLocalized.Search.clearQuery", "검색어 지우기") }
        static var recentTitle: String { tr("UnfadingLocalized.Search.recentTitle", "최근 검색어") }
        static var clearRecent: String { tr("UnfadingLocalized.Search.clearRecent", "모두 지우기") }
        static var emptyRecent: String { tr("UnfadingLocalized.Search.emptyRecent", "최근 검색어가 아직 없어요.") }
        static var emptyResults: String { tr("UnfadingLocalized.Search.emptyResults", "검색 결과가 없어요.") }
        static var noGroup: String { tr("UnfadingLocalized.Search.noGroup", "검색할 그룹을 먼저 선택해주세요.") }
        static var searchFailed: String { tr("UnfadingLocalized.Search.searchFailed", "검색 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.") }
    }

    // MARK: Common

    enum Common {
        static var cancel: String { tr("UnfadingLocalized.Common.cancel", "취소") }
        static var confirm: String { tr("UnfadingLocalized.Common.confirm", "확인") }
    }

    // MARK: Share Extension

    enum ShareExtension {
        static var opening: String { tr("UnfadingLocalized.ShareExtension.opening", "Unfading 여는 중") }
        static var openingMessage: String { tr("UnfadingLocalized.ShareExtension.openingMessage", "공유한 사진을 추억 기록 화면으로 보내고 있어요.") }
        static var unsupported: String { tr("UnfadingLocalized.ShareExtension.unsupported", "이 사진은 아직 바로 가져올 수 없어요.") }
        static var close: String { tr("UnfadingLocalized.ShareExtension.close", "닫기") }
    }

    // MARK: Auth

    enum Auth {
        static var signInTab: String { tr("UnfadingLocalized.Auth.signInTab", "로그인") }
        static var signUpTab: String { tr("UnfadingLocalized.Auth.signUpTab", "회원가입") }
        static var appleSignIn: String { tr("UnfadingLocalized.Auth.appleSignIn", "Apple로 계속하기") }
        static var orDivider: String { tr("UnfadingLocalized.Auth.orDivider", "또는") }
        static var emailPlaceholder: String { tr("UnfadingLocalized.Auth.emailPlaceholder", "이메일") }
        static var passwordPlaceholder: String { tr("UnfadingLocalized.Auth.passwordPlaceholder", "비밀번호") }
        static var signInPrimary: String { tr("UnfadingLocalized.Auth.signInPrimary", "로그인") }
        static var signUpPrimary: String { tr("UnfadingLocalized.Auth.signUpPrimary", "계정 만들기") }
        static var forgotPassword: String { tr("UnfadingLocalized.Auth.forgotPassword", "비밀번호를 잊으셨나요?") }
        static var forgotPasswordSubmit: String { tr("UnfadingLocalized.Auth.forgotPasswordSubmit", "재설정 링크 보내기") }
        static var emailSent: String { tr("UnfadingLocalized.Auth.emailSent", "재설정 이메일을 보냈어요. 받은편지함을 확인해주세요.") }
        static var welcomeTitle: String { tr("UnfadingLocalized.Auth.welcomeTitle", "Unfading") }
        static var welcomeSubtitle: String { tr("UnfadingLocalized.Auth.welcomeSubtitle", "함께한 장소, 함께 남기는 추억") }
        static var invalidCredentials: String { tr("UnfadingLocalized.Auth.invalidCredentials", "이메일 또는 비밀번호가 올바르지 않습니다.") }
        static var appleSignInFailed: String { tr("UnfadingLocalized.Auth.appleSignInFailed", "Apple 로그인에 실패했습니다. 다시 시도해주세요.") }
        static var networkError: String { tr("UnfadingLocalized.Auth.networkError", "네트워크 오류. 잠시 후 다시 시도해주세요.") }
        static var passwordTooShort: String { tr("UnfadingLocalized.Auth.passwordTooShort", "비밀번호는 8자 이상이어야 합니다.") }
        static var signOutConfirm: String { tr("UnfadingLocalized.Auth.signOutConfirm", "로그아웃 하시겠습니까?") }
        static var signOut: String { tr("UnfadingLocalized.Auth.signOut", "로그아웃") }
        static var guest: String { tr("UnfadingLocalized.Auth.guest", "게스트") }
        static var modePickerLabel: String { tr("UnfadingLocalized.Auth.modePickerLabel", "인증 방식") }
        static var appleSignInHint: String { tr("UnfadingLocalized.Auth.appleSignInHint", "Apple 계정으로 계속합니다.") }
        static var primaryHint: String { tr("UnfadingLocalized.Auth.primaryHint", "입력한 이메일과 비밀번호로 계속합니다.") }
        static var forgotPasswordHint: String { tr("UnfadingLocalized.Auth.forgotPasswordHint", "이메일로 비밀번호 재설정 링크를 보냅니다.") }
    }

    // MARK: Onboarding

    enum Onboarding {
        static var slide1Title: String { tr("UnfadingLocalized.Onboarding.slide1Title", "추억을 지도 위에 남기다") }
        static var slide1Body: String { tr("UnfadingLocalized.Onboarding.slide1Body", "함께 간 장소를 핀으로 기록하고 언제든 다시 꺼내 봐요.") }
        static var slide2Title: String { tr("UnfadingLocalized.Onboarding.slide2Title", "장소 기반 리와인드") }
        static var slide2Body: String { tr("UnfadingLocalized.Onboarding.slide2Body", "그 자리에 다시 서면 예전 추억이 부드럽게 돌아와요.") }
        static var slide3Title: String { tr("UnfadingLocalized.Onboarding.slide3Title", "둘, 또는 함께") }
        static var slide3Body: String { tr("UnfadingLocalized.Onboarding.slide3Body", "커플부터 친구 그룹까지. 우리만의 지도를 만들어 봐요.") }
        static var startCta: String { tr("UnfadingLocalized.Onboarding.startCta", "시작하기") }
        static var skipCta: String { tr("UnfadingLocalized.Onboarding.skipCta", "건너뛰기") }
        static var pageIndicatorHint: String { tr("UnfadingLocalized.Onboarding.pageIndicatorHint", "페이지 이동") }
    }

    // MARK: Empty states

    enum EmptyState {
        static var rewindTitle: String { tr("UnfadingLocalized.EmptyState.rewindTitle", "아직 리와인드가 없어요") }
        static var rewindBody: String { tr("UnfadingLocalized.EmptyState.rewindBody", "함께 만든 순간이 쌓이면 이곳에 나타나요.") }
        static var composerPhotoHint: String { tr("UnfadingLocalized.EmptyState.composerPhotoHint", "사진을 추가하면 시간과 장소가 자동으로 채워져요.") }
    }

    // MARK: Rewind

    enum Rewind {
        static var navTitle: String { tr("UnfadingLocalized.Rewind.navTitle", "리와인드") }
        static var shareLabel: String { tr("UnfadingLocalized.Rewind.shareLabel", "공유") }
        static var rewatchLabel: String { tr("UnfadingLocalized.Rewind.rewatchLabel", "다시 보기") }
        static var reminderLabel: String { tr("UnfadingLocalized.Rewind.reminderLabel", "장소 기반 알림") }
        static var reminderHint: String { tr("UnfadingLocalized.Rewind.reminderHint", "이곳 근처에 가면 관련 추억을 알려드려요.") }
        static var storyViewTitle: String { tr("UnfadingLocalized.Rewind.storyViewTitle", "리와인드 스토리") }
        static var closeLabel: String { tr("UnfadingLocalized.Rewind.closeLabel", "리와인드 닫기") }
        static var closeHint: String { tr("UnfadingLocalized.Rewind.closeHint", "닫으면 홈 요약 패널로 돌아갑니다.") }
        static var previousStoryLabel: String { tr("UnfadingLocalized.Rewind.previousStoryLabel", "이전 리와인드 카드") }
        static var nextStoryLabel: String { tr("UnfadingLocalized.Rewind.nextStoryLabel", "다음 리와인드 카드") }
        static var eyebrow: String { tr("UnfadingLocalized.Rewind.eyebrow", "REWIND") }
        static var coverHeadline: String { tr("UnfadingLocalized.Rewind.coverHeadline", "이번 달,\n함께 지나온 곳들") }
        static var coverPhotoLabel: String { tr("UnfadingLocalized.Rewind.coverPhotoLabel", "이번 달 리와인드 커버 사진") }
        static var topPlacesTitle: String { tr("UnfadingLocalized.Rewind.topPlacesTitle", "가장 많이 간 곳 TOP 3") }
        static var topPlacesSubtitle: String { tr("UnfadingLocalized.Rewind.topPlacesSubtitle", "이번 달에 가장 자주 다시 찾은 장소예요.") }
        static var firstVisitsTitle: String { tr("UnfadingLocalized.Rewind.firstVisitsTitle", "처음 가본 곳") }
        static var firstVisitsSubtitle: String { tr("UnfadingLocalized.Rewind.firstVisitsSubtitle", "새로 지도에 남긴 장소를 모았어요.") }
        static var photoDayTitle: String { tr("UnfadingLocalized.Rewind.photoDayTitle", "사진 가장 많이 찍은 날") }
        static var photoDaySubtitle: String { tr("UnfadingLocalized.Rewind.photoDaySubtitle", "셔터를 가장 많이 누른 하루예요.") }
        static var emotionCloudTitle: String { tr("UnfadingLocalized.Rewind.emotionCloudTitle", "감정 태그 클라우드") }
        static var emotionCloudSubtitle: String { tr("UnfadingLocalized.Rewind.emotionCloudSubtitle", "남긴 감정의 비율대로 크게 보여드려요.") }
        static var timeTogetherTitle: String { tr("UnfadingLocalized.Rewind.timeTogetherTitle", "함께 보낸 시간") }
        static var timeTogetherSubtitle: String { tr("UnfadingLocalized.Rewind.timeTogetherSubtitle", "장소에 머문 시간을 모두 더했어요.") }
        static var hoursTogetherUnit: String { tr("UnfadingLocalized.Rewind.hoursTogetherUnit", "시간") }
        static var timeTogetherBody: String { tr("UnfadingLocalized.Rewind.timeTogetherBody", "함께 머문 시간이 한 장의 리와인드가 되었어요.") }

        static func coverHeadline(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Rewind.coverHeadline.couple", "이번 달,\n함께 지나온 곳들")
            case .general:
                return tr("UnfadingLocalized.Rewind.coverHeadline.general", "이번 달,\n크루가 모인 곳들")
            }
        }

        static func topPlacesSubtitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Rewind.topPlacesSubtitle.couple", "이번 달에 둘이 가장 자주 다시 찾은 장소예요.")
            case .general:
                return tr("UnfadingLocalized.Rewind.topPlacesSubtitle.general", "이번 달에 크루가 가장 자주 다시 찾은 장소예요.")
            }
        }

        static func timeTogetherTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Rewind.timeTogetherTitle.couple", "함께 보낸 시간")
            case .general:
                return tr("UnfadingLocalized.Rewind.timeTogetherTitle.general", "크루가 함께한 시간")
            }
        }

        static func timeTogetherBody(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Rewind.timeTogetherBody.couple", "함께 머문 시간이 한 장의 리와인드가 되었어요.")
            case .general:
                return tr("UnfadingLocalized.Rewind.timeTogetherBody.general", "크루가 머문 시간이 한 장의 리와인드가 되었어요.")
            }
        }

        static func visitCount(_ count: Int) -> String {
            tr("UnfadingLocalized.Rewind.visitCount", "\(count)번 방문")
        }

        static func photoCount(_ count: Int) -> String {
            tr("UnfadingLocalized.Rewind.photoCount", "사진 \(count)장")
        }

        static func progressLabel(_ index: Int, total: Int) -> String {
            tr("UnfadingLocalized.Rewind.progressLabel", "리와인드 진행 \(index)/\(total)")
        }

        static func dateLabel(for moment: RewindMoment) -> String {
            moment.dateLabel
        }

        static func title(for moment: RewindMoment) -> String {
            moment.title
        }

        static func location(for moment: RewindMoment) -> String {
            moment.location
        }

        static func summary(for moment: RewindMoment) -> String {
            moment.summary
        }
    }

    // MARK: Groups

    enum Groups {
        static var navTitle: String { tr("UnfadingLocalized.Groups.navTitle", "그룹") }
        static var membersLabel: String { tr("UnfadingLocalized.Groups.membersLabel", "멤버") }
        static var inviteCta: String { tr("UnfadingLocalized.Groups.inviteCta", "초대") }
        static var coverEyebrow: String { tr("UnfadingLocalized.Groups.coverEyebrow", "함께한 기록") }
        static var modePickerLabel: String { tr("UnfadingLocalized.Groups.modePickerLabel", "모드") }
        static var onboardingTitle: String { tr("UnfadingLocalized.Groups.onboardingTitle", "그룹 시작") }
        static var createTab: String { tr("UnfadingLocalized.Groups.createTab", "새로 만들기") }
        static var joinTab: String { tr("UnfadingLocalized.Groups.joinTab", "초대 코드로 참여") }
        static var namePlaceholder: String { tr("UnfadingLocalized.Groups.namePlaceholder", "그룹 이름") }
        static var nicknamePlaceholder: String { tr("UnfadingLocalized.Groups.nicknamePlaceholder", "내 이름 (선택)") }
        static var nicknameHint: String { tr("UnfadingLocalized.Groups.nicknameHint", "이 그룹 안에서 사용할 이름") }
        static var modeCouple: String { tr("UnfadingLocalized.Groups.modeCouple", "커플") }
        static var modeGroup: String { tr("UnfadingLocalized.Groups.modeGroup", "그룹") }
        static var introPlaceholder: String { tr("UnfadingLocalized.Groups.introPlaceholder", "소개 (선택)") }
        static var createButton: String { tr("UnfadingLocalized.Groups.createButton", "만들기") }
        static var codePlaceholder: String { tr("UnfadingLocalized.Groups.codePlaceholder", "초대 코드") }
        static var joinButton: String { tr("UnfadingLocalized.Groups.joinButton", "참여하기") }
        static var createdBanner: String { tr("UnfadingLocalized.Groups.createdBanner", "그룹이 생성되었어요!") }
        static var joinedBanner: String { tr("UnfadingLocalized.Groups.joinedBanner", "그룹에 참여했어요!") }
        static var invalidCode: String { tr("UnfadingLocalized.Groups.invalidCode", "초대 코드를 확인해주세요.") }
        static var inviteCodeLabel: String { tr("UnfadingLocalized.Groups.inviteCodeLabel", "초대 코드") }
        static var copyCode: String { tr("UnfadingLocalized.Groups.copyCode", "복사") }
        static var rotateCode: String { tr("UnfadingLocalized.Groups.rotateCode", "재생성") }
        static var rotated: String { tr("UnfadingLocalized.Groups.rotated", "새 초대 코드로 바뀌었어요.") }
        static var actionFailed: String { tr("UnfadingLocalized.Groups.actionFailed", "잠시 후 다시 시도해주세요.") }
        static var edit: String { tr("UnfadingLocalized.Groups.edit", "편집") }
        static var editGroupName: String { tr("UnfadingLocalized.Groups.editGroupName", "그룹 이름 편집") }
        static var editNickname: String { tr("UnfadingLocalized.Groups.editNickname", "내 이름 편집") }
        static var groupNameUpdated: String { tr("UnfadingLocalized.Groups.groupNameUpdated", "그룹 이름을 바꿨어요.") }
        static var nicknameUpdated: String { tr("UnfadingLocalized.Groups.nicknameUpdated", "내 이름을 바꿨어요.") }
        static var notOwnerHint: String { tr("UnfadingLocalized.Groups.notOwnerHint", "그룹 이름은 만든 사람만 바꿀 수 있어요.") }
        static var pickerTitle: String { tr("UnfadingLocalized.Groups.pickerTitle", "그룹 선택") }
        static var pickerSubtitle: String { tr("UnfadingLocalized.Groups.pickerSubtitle", "여러 그룹을 동시에 쓸 수 있어요") }
        static var pickerCoupleBadge: String { tr("UnfadingLocalized.Groups.pickerCoupleBadge", "COUPLE") }
        static var pickerGroupBadge: String { tr("UnfadingLocalized.Groups.pickerGroupBadge", "GROUP") }
        static var pickerCreateNew: String { tr("UnfadingLocalized.Groups.pickerCreateNew", "새 그룹 만들기") }
        static var pickerClose: String { tr("UnfadingLocalized.Groups.pickerClose", "그룹 선택 닫기") }

        static func dayCountFormat(_ days: Int) -> String {
            tr("UnfadingLocalized.Groups.dayCountFormat", "함께한 지 \(days)일")
        }

        static func memberCountFormat(_ count: Int) -> String {
            tr("UnfadingLocalized.Groups.memberCountFormat", "멤버 \(count)명")
        }

        static func memberCountFormat(_ count: Int, mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Groups.memberCountFormat.couple", "둘만의 기록")
            case .general:
                return tr("UnfadingLocalized.Groups.memberCountFormat.general", "멤버 \(count)명")
            }
        }

        static func pickerMembersFormat(_ count: Int) -> String {
            tr("UnfadingLocalized.Groups.pickerMembersFormat", "\(count)명")
        }

        static func pickerAnniversaryFormat(_ days: Int) -> String {
            tr("UnfadingLocalized.Groups.pickerAnniversaryFormat", "함께한 지 \(days)일")
        }
    }

    // MARK: Group Hub

    enum GroupHub {
        static var navTitle: String { tr("UnfadingLocalized.GroupHub.navTitle", "그룹 허브") }
        static var overviewSection: String { tr("UnfadingLocalized.GroupHub.overviewSection", "그룹 정보") }
        static var startedAtLabel: String { tr("UnfadingLocalized.GroupHub.startedAtLabel", "시작일") }
        static var switchGroupCTA: String { tr("UnfadingLocalized.GroupHub.switchGroupCTA", "다른 그룹으로 전환") }
        static var membersSection: String { tr("UnfadingLocalized.GroupHub.membersSection", "멤버") }
        static var ownerRole: String { tr("UnfadingLocalized.GroupHub.ownerRole", "그룹장") }
        static var memberRole: String { tr("UnfadingLocalized.GroupHub.memberRole", "멤버") }
        static var partnerRole: String { tr("UnfadingLocalized.GroupHub.partnerRole", "파트너") }
        static var youSuffix: String { tr("UnfadingLocalized.GroupHub.youSuffix", "나") }
        static var inviteSection: String { tr("UnfadingLocalized.GroupHub.inviteSection", "멤버 초대") }
        static var inviteLinkLabel: String { tr("UnfadingLocalized.GroupHub.inviteLinkLabel", "초대 링크") }
        static var createInviteLink: String { tr("UnfadingLocalized.GroupHub.createInviteLink", "링크 생성") }
        static var showQRCode: String { tr("UnfadingLocalized.GroupHub.showQRCode", "QR 보기") }
        static var qrPlaceholder: String { tr("UnfadingLocalized.GroupHub.qrPlaceholder", "QR 코드는 다음 라운드에서 실제 링크와 연결돼요.") }
        static var inviteLinkCopied: String { tr("UnfadingLocalized.GroupHub.inviteLinkCopied", "초대 링크를 복사했어요.") }
        static var appearanceSection: String { tr("UnfadingLocalized.GroupHub.appearanceSection", "지도 스타일") }
        static var notificationsSection: String { tr("UnfadingLocalized.GroupHub.notificationsSection", "알림") }
        static var anniversaryToggle: String { tr("UnfadingLocalized.GroupHub.anniversaryToggle", "기념일 알림") }
        static var rewindToggle: String { tr("UnfadingLocalized.GroupHub.rewindToggle", "Rewind 알림") }
        static var memberActivityToggle: String { tr("UnfadingLocalized.GroupHub.memberActivityToggle", "멤버 활동 알림") }
        static var dataSection: String { tr("UnfadingLocalized.GroupHub.dataSection", "데이터") }
        static var iCloudStatusLabel: String { tr("UnfadingLocalized.GroupHub.iCloudStatusLabel", "iCloud 동기화") }
        static var iCloudStatusReady: String { tr("UnfadingLocalized.GroupHub.iCloudStatusReady", "준비됨") }
        static var exportJSONCTA: String { tr("UnfadingLocalized.GroupHub.exportJSONCTA", "내보내기 (JSON)") }
        static var exportPhotosCTA: String { tr("UnfadingLocalized.GroupHub.exportPhotosCTA", "사진 zip 내보내기") }
        static var exportJSONReady: String { tr("UnfadingLocalized.GroupHub.exportJSONReady", "JSON 내보내기 파일을 준비했어요.") }
        static var exportPhotosReady: String { tr("UnfadingLocalized.GroupHub.exportPhotosReady", "사진 내보내기 폴더를 준비했어요.") }
        static var exportPhotosProgressTitle: String { tr("UnfadingLocalized.GroupHub.exportPhotosProgressTitle", "사진 내보내기 준비 중") }
        static var photoExportSignedURLFailed: String { tr("UnfadingLocalized.GroupHub.photoExportSignedURLFailed", "사진 링크를 준비하지 못했어요.") }
        static var photoExportDownloadFailed: String { tr("UnfadingLocalized.GroupHub.photoExportDownloadFailed", "사진을 다운로드하지 못했어요.") }
        static var photoExportWriteFailed: String { tr("UnfadingLocalized.GroupHub.photoExportWriteFailed", "사진 내보내기 파일을 만들지 못했어요.") }
        static var dangerSection: String { tr("UnfadingLocalized.GroupHub.dangerSection", "그룹 관리") }
        static var leaveGroupCTA: String { tr("UnfadingLocalized.GroupHub.leaveGroupCTA", "그룹 떠나기") }
        static var deleteGroupCTA: String { tr("UnfadingLocalized.GroupHub.deleteGroupCTA", "그룹 삭제") }
        static var leaveWarningTitle: String { tr("UnfadingLocalized.GroupHub.leaveWarningTitle", "그룹을 떠날까요?") }
        static var leaveWarningMessage: String { tr("UnfadingLocalized.GroupHub.leaveWarningMessage", "이 그룹의 새 추억과 알림을 더 이상 볼 수 없습니다.") }
        static var deleteWarningTitle: String { tr("UnfadingLocalized.GroupHub.deleteWarningTitle", "그룹을 삭제할까요?") }
        static var deleteWarningMessage: String { tr("UnfadingLocalized.GroupHub.deleteWarningMessage", "그룹과 연결된 데이터 삭제는 되돌릴 수 없습니다.") }
        static var destructiveConfirm: String { tr("UnfadingLocalized.GroupHub.destructiveConfirm", "계속") }
        static var destructivePlaceholder: String { tr("UnfadingLocalized.GroupHub.destructivePlaceholder", "서버 작업은 다음 백엔드 라운드에서 연결됩니다.") }

        static func startedAtFormat(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = .autoupdatingCurrent
            formatter.timeZone = .autoupdatingCurrent
            formatter.setLocalizedDateFormatFromTemplate("yyyyMMdd")
            return formatter.string(from: date)
        }

        static func inviteLink(code: String) -> String {
            "https://unfading.app/join/\(code)"
        }

        static func exportPhotosProgressValue(_ percent: Int) -> String {
            tr("UnfadingLocalized.GroupHub.exportPhotosProgressValue", "\(percent)% 완료")
        }
    }

    // MARK: Map Theme

    enum MapTheme {
        static var defaultTitle: String { tr("UnfadingLocalized.MapTheme.defaultTitle", "기본") }
        static var warmTitle: String { tr("UnfadingLocalized.MapTheme.warmTitle", "웜") }
        static var monoTitle: String { tr("UnfadingLocalized.MapTheme.monoTitle", "모노") }
        static var defaultDescription: String { tr("UnfadingLocalized.MapTheme.defaultDescription", "표준 지도를 가장 담백하게 보여줘요.") }
        static var warmDescription: String { tr("UnfadingLocalized.MapTheme.warmDescription", "관심 지점을 줄이고 더 부드러운 톤으로 집중해요.") }
        static var monoDescription: String { tr("UnfadingLocalized.MapTheme.monoDescription", "채도를 낮춘 지도 위에 추억 핀만 또렷하게 남겨요.") }
        static var footer: String { tr("UnfadingLocalized.MapTheme.footer", "지도 화면에 바로 반영되며, 계정 설정과 함께 동기화됩니다.") }
        static var selected: String { tr("UnfadingLocalized.MapTheme.selected", "선택됨") }
        static var notSelected: String { tr("UnfadingLocalized.MapTheme.notSelected", "선택 안 됨") }
    }

    // MARK: Categories

    enum Categories {
        static var editorTitle: String { tr("UnfadingLocalized.Categories.editorTitle", "카테고리 편집") }
        static var editorSubtitle: String { tr("UnfadingLocalized.Categories.editorSubtitle", "기본 · 추억 / 밥 / 카페 / 경험 · 직접 추가 가능") }
        static var newCategoryLabel: String { tr("UnfadingLocalized.Categories.newCategoryLabel", "새 카테고리") }
        static var newCategoryPlaceholder: String { tr("UnfadingLocalized.Categories.newCategoryPlaceholder", "예: 산책, 공연, 전시…") }
        static var addButton: String { tr("UnfadingLocalized.Categories.addButton", "추가") }
        static var resetDefault: String { tr("UnfadingLocalized.Categories.resetDefault", "기본값") }
        static var save: String { tr("UnfadingLocalized.Categories.save", "저장") }
        static var duplicateError: String { tr("UnfadingLocalized.Categories.duplicateError", "이미 있는 카테고리예요.") }
        static var emptyNameError: String { tr("UnfadingLocalized.Categories.emptyNameError", "카테고리 이름을 입력해주세요.") }
        static var defaultMemory: String { tr("UnfadingLocalized.Categories.defaultMemory", "추억") }
        static var defaultMeal: String { tr("UnfadingLocalized.Categories.defaultMeal", "밥") }
        static var defaultCafe: String { tr("UnfadingLocalized.Categories.defaultCafe", "카페") }
        static var defaultExperience: String { tr("UnfadingLocalized.Categories.defaultExperience", "경험") }
        static var addCategory: String { tr("UnfadingLocalized.Categories.addCategory", "카테고리 추가") }
        static var close: String { tr("UnfadingLocalized.Categories.close", "카테고리 편집 닫기") }

        static func deleteCategoryLabel(_ name: String) -> String {
            tr("UnfadingLocalized.Categories.deleteCategoryLabel", "\(name) 삭제")
        }
    }

    // MARK: Calendar (stub in R3; full impl in R8)

    enum Calendar {
        static var navTitle: String { tr("UnfadingLocalized.Calendar.navTitle", "캘린더") }
        static var stubTitle: String { tr("UnfadingLocalized.Calendar.stubTitle", "달력 화면 준비 중") }
        static var stubBody: String { tr("UnfadingLocalized.Calendar.stubBody", "다가오는 라운드에서 월별 격자와 날짜별 추억 점을 구현합니다.") }
        static var weekdayHeaders: [String] {
            [
                tr("UnfadingLocalized.Calendar.weekdayHeaders.0", "일"),
                tr("UnfadingLocalized.Calendar.weekdayHeaders.1", "월"),
                tr("UnfadingLocalized.Calendar.weekdayHeaders.2", "화"),
                tr("UnfadingLocalized.Calendar.weekdayHeaders.3", "수"),
                tr("UnfadingLocalized.Calendar.weekdayHeaders.4", "목"),
                tr("UnfadingLocalized.Calendar.weekdayHeaders.5", "금"),
                tr("UnfadingLocalized.Calendar.weekdayHeaders.6", "토"),
            ]
        }
        static var previousMonthHint: String { tr("UnfadingLocalized.Calendar.previousMonthHint", "이전 달") }
        static var nextMonthHint: String { tr("UnfadingLocalized.Calendar.nextMonthHint", "다음 달") }
        static var emptyDayTitle: String { tr("UnfadingLocalized.Calendar.emptyDayTitle", "이 날의 추억이 없어요") }
        static var emptyDayBody: String { tr("UnfadingLocalized.Calendar.emptyDayBody", "지도에서 새 추억을 기록해 이 자리를 채워보세요.") }

        static func emptyDayTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Calendar.emptyDayTitle.couple", "이 날의 우리의 추억이 없어요")
            case .general:
                return tr("UnfadingLocalized.Calendar.emptyDayTitle.general", "이 날의 크루 기록이 없어요")
            }
        }

        static func emptyDayBody(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return tr("UnfadingLocalized.Calendar.emptyDayBody.couple", "지도에서 둘만의 새 추억을 기록해 이 자리를 채워보세요.")
            case .general:
                return tr("UnfadingLocalized.Calendar.emptyDayBody.general", "지도에서 크루의 새 기록을 남겨 이 자리를 채워보세요.")
            }
        }

        static func memoryCountFormat(_ count: Int) -> String {
            tr("UnfadingLocalized.Calendar.memoryCountFormat", "\(count)개의 추억")
        }

        static func monthYearFormat(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = .autoupdatingCurrent
            formatter.timeZone = .autoupdatingCurrent
            formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
            return formatter.string(from: date)
        }

        // R26 F9/F2-cal — 월 지출 + 계획 배지 + 새 계획 시트
        static var monthlyExpense: String { tr("UnfadingLocalized.Calendar.monthlyExpense", "이 달 지출") }
        static var planBadge: String { tr("UnfadingLocalized.Calendar.planBadge", "계획") }
        static var memoryBadge: String { tr("UnfadingLocalized.Calendar.memoryBadge", "추억") }
        static var addPlanCTA: String { tr("UnfadingLocalized.Calendar.addPlanCTA", "계획 추가") }
        static var planSheetTitle: String { tr("UnfadingLocalized.Calendar.planSheetTitle", "새 계획") }
        static var planTitlePlaceholder: String { tr("UnfadingLocalized.Calendar.planTitlePlaceholder", "제목") }
        static var multiDayToggle: String { tr("UnfadingLocalized.Calendar.multiDayToggle", "여행 (여러 날)") }
        static var reminderToggle: String { tr("UnfadingLocalized.Calendar.reminderToggle", "알람 받기") }
        static var reminderTimeLabel: String { tr("UnfadingLocalized.Calendar.reminderTimeLabel", "알람 시각") }
        static var savedPlan: String { tr("UnfadingLocalized.Calendar.savedPlan", "계획이 저장되었어요.") }
        static var reminderPermissionDenied: String { tr("UnfadingLocalized.Calendar.reminderPermissionDenied", "알람 권한이 꺼져 있어 알람은 울리지 않아요.") }
        static var plansForDate: String { tr("UnfadingLocalized.Calendar.plansForDate", "이 날의 계획") }
        static var futureDayHint: String { tr("UnfadingLocalized.Calendar.futureDayHint", "이 날짜는 미래라 추억 대신 계획을 추가할 수 있어요.") }
        static var monthPickerTitle: String { tr("UnfadingLocalized.Calendar.monthPickerTitle", "월 선택") }
        static var weatherSample: String { tr("UnfadingLocalized.Calendar.weatherSample", "맑음 23°") }
        static var eventsSectionTitle: String { tr("UnfadingLocalized.Calendar.eventsSectionTitle", "이벤트") }
        static var noEventsForDate: String { tr("UnfadingLocalized.Calendar.noEventsForDate", "이 날의 이벤트가 아직 없어요.") }
        static var planPlaceFallback: String { tr("UnfadingLocalized.Calendar.planPlaceFallback", "성수 카페 거리") }
        static var sendReminderCTA: String { tr("UnfadingLocalized.Calendar.sendReminderCTA", "알림 보내기") }
        static var broadcastToast: String { tr("UnfadingLocalized.Calendar.broadcastToast", "모든 멤버에게 알림을 보냈어요") }

        static func nextMeetingTitle(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = .autoupdatingCurrent
            formatter.timeZone = .autoupdatingCurrent
            formatter.setLocalizedDateFormatFromTemplate("EMd")
            return tr("UnfadingLocalized.Calendar.nextMeetingTitle", "다음 만남 — \(formatter.string(from: date))")
        }

        static func expenseCurrencyFormat(_ won: Int64) -> String {
            "₩\(won.formatted(.number.grouping(.automatic)))"
        }
    }

    // MARK: Settings (stub in R3; full impl in R11)

    enum Settings {
        static var navTitle: String { tr("UnfadingLocalized.Settings.navTitle", "설정") }
        static var stubTitle: String { tr("UnfadingLocalized.Settings.stubTitle", "설정 화면 준비 중") }
        static var stubBody: String { tr("UnfadingLocalized.Settings.stubBody", "앱 환경과 계정 설정은 다가오는 라운드에서 구성됩니다.") }
        static var profileSection: String { tr("UnfadingLocalized.Settings.profileSection", "프로필") }
        static var displayNamePlaceholder: String { tr("UnfadingLocalized.Settings.displayNamePlaceholder", "표시 이름") }
        static var displayNameUpdated: String { tr("UnfadingLocalized.Settings.displayNameUpdated", "저장되었어요.") }
        static var accountSection: String { tr("UnfadingLocalized.Settings.accountSection", "계정") }
        static var preferencesSection: String { tr("UnfadingLocalized.Settings.preferencesSection", "환경설정") }
        static var reminderToggle: String { tr("UnfadingLocalized.Settings.reminderToggle", "장소 기반 알림") }
        static var reminderHint: String { tr("UnfadingLocalized.Settings.reminderHint", "이곳 근처에 가면 관련 추억을 알려드려요.") }
        static var themeLabel: String { tr("UnfadingLocalized.Settings.themeLabel", "테마") }
        static var groupsSection: String { tr("UnfadingLocalized.Settings.groupsSection", "그룹") }
        static var groupsRow: String { tr("UnfadingLocalized.Settings.groupsRow", "그룹 관리") }
        static var groupsRowHint: String { tr("UnfadingLocalized.Settings.groupsRowHint", "그룹 허브로 이동합니다.") }
        static var premiumSection: String { tr("UnfadingLocalized.Settings.premiumSection", "프리미엄") }
        static var premiumExplore: String { tr("UnfadingLocalized.Settings.premiumExplore", "프리미엄 둘러보기") }
        static var premiumComingSoon: String { tr("UnfadingLocalized.Settings.premiumComingSoon", "출시 예정") }
        static var premiumSavingBadge: String { tr("UnfadingLocalized.Settings.premiumSavingBadge", "33% 절약") }
        static var premiumTierFreeName: String { tr("UnfadingLocalized.Settings.premiumTierFreeName", "무료") }
        static var premiumTierMonthly: String { tr("UnfadingLocalized.Settings.premiumTierMonthly", "프리미엄 월") }
        static var premiumTierAnnual: String { tr("UnfadingLocalized.Settings.premiumTierAnnual", "프리미엄 연") }
        static var premiumTierFreePrice: String { tr("UnfadingLocalized.Settings.premiumTierFreePrice", "₩0") }
        static var premiumTierMonthlyPrice: String { tr("UnfadingLocalized.Settings.premiumTierMonthlyPrice", "월 ₩4,900") }
        static var premiumTierAnnualPrice: String { tr("UnfadingLocalized.Settings.premiumTierAnnualPrice", "연 ₩39,000") }
        static var infoSection: String { tr("UnfadingLocalized.Settings.infoSection", "정보") }
        static var versionLabel: String { tr("UnfadingLocalized.Settings.versionLabel", "버전 1.0.0") }
        static var licensesRow: String { tr("UnfadingLocalized.Settings.licensesRow", "오픈소스 라이선스") }

        static func draftCountFormat(_ count: Int) -> String {
            tr("UnfadingLocalized.Settings.draftCountFormat", "임시 저장 \(count)개")
        }

        static func tierFeatures(_ tier: Int) -> [String] {
            switch tier {
            case 0:
                return [
                    tr("UnfadingLocalized.Settings.tierFeatures.0.0", "월 30개 추억"),
                    tr("UnfadingLocalized.Settings.tierFeatures.0.1", "그룹 5명"),
                    tr("UnfadingLocalized.Settings.tierFeatures.0.2", "기본 지도 스타일")
                ]
            case 1:
                return [
                    tr("UnfadingLocalized.Settings.tierFeatures.1.0", "무제한 추억"),
                    tr("UnfadingLocalized.Settings.tierFeatures.1.1", "기념일 AI 리와인드"),
                    tr("UnfadingLocalized.Settings.tierFeatures.1.2", "고급 지도 테마"),
                    tr("UnfadingLocalized.Settings.tierFeatures.1.3", "가족 그룹")
                ]
            default:
                return [
                    tr("UnfadingLocalized.Settings.tierFeatures.2.0", "무제한 추억"),
                    tr("UnfadingLocalized.Settings.tierFeatures.2.1", "고급 지도 테마"),
                    tr("UnfadingLocalized.Settings.tierFeatures.2.2", "다이어리 북 내보내기"),
                    tr("UnfadingLocalized.Settings.tierFeatures.2.3", "연간 할인")
                ]
            }
        }
    }

    // MARK: Premium

    enum Premium {
        static var title: String { tr("UnfadingLocalized.Premium.title", "Unfading 프리미엄") }
        static var heroTitle: String { tr("UnfadingLocalized.Premium.heroTitle", "Unfading 프리미엄으로 더 많은 추억을") }
        static var subtitle: String { tr("UnfadingLocalized.Premium.subtitle", "소중한 추억을 무제한으로") }
        static var monthlyTitle: String { tr("UnfadingLocalized.Premium.monthlyTitle", "월간 구독") }
        static var yearlyTitle: String { tr("UnfadingLocalized.Premium.yearlyTitle", "연간 구독") }
        static var yearlyBadge: String { tr("UnfadingLocalized.Premium.yearlyBadge", "33% 절약") }
        static var currentFree: String { tr("UnfadingLocalized.Premium.currentFree", "무료 플랜") }
        static var currentPremium: String { tr("UnfadingLocalized.Premium.currentPremium", "프리미엄 활성") }
        static var restore: String { tr("UnfadingLocalized.Premium.restore", "구매 복원") }
        static var cancel: String { tr("UnfadingLocalized.Premium.cancel", "App Store에서 언제든 취소 가능해요.") }
        static var loading: String { tr("UnfadingLocalized.Premium.loading", "상품 불러오는 중…") }
        static var subscribedBanner: String { tr("UnfadingLocalized.Premium.subscribedBanner", "프리미엄이 활성화되었어요!") }
        static var showPaywall: String { tr("UnfadingLocalized.Premium.showPaywall", "프리미엄 보기") }
        static var manage: String { tr("UnfadingLocalized.Premium.manage", "구독 관리") }
        static var manageHint: String { tr("UnfadingLocalized.Premium.manageHint", "App Store 구독 관리 화면을 엽니다.") }
        static var serverSyncFailedToast: String { tr("UnfadingLocalized.Premium.serverSyncFailedToast", "서버에 동기화하지 못했지만, 구독은 정상이에요") }
    }

    enum Theme {
        static var system: String { tr("UnfadingLocalized.Theme.system", "시스템 설정") }
        static var light: String { tr("UnfadingLocalized.Theme.light", "라이트") }
        static var dark: String { tr("UnfadingLocalized.Theme.dark", "다크") }
    }

    // MARK: Placeholder (generic "coming soon" surfaces)

    enum Placeholder {
        static var comingSoon: String { tr("UnfadingLocalized.Placeholder.comingSoon", "준비 중") }
    }

    // MARK: Summary card

    enum Summary {
        static var tonightsRewind: String { tr("UnfadingLocalized.Summary.tonightsRewind", "오늘의 리와인드") }
        static var selectedEyebrow: String { tr("UnfadingLocalized.Summary.selectedEyebrow", "선택한 추억") }
        static var sampleTitle: String { tr("UnfadingLocalized.Summary.sampleTitle", "상수 루프톱 저녁") }
        static var sampleBody: String { tr("UnfadingLocalized.Summary.sampleBody", "3년 전 오늘, 이곳에서 공연 뒤 함께 핀을 남겼습니다. 오늘 아침 새 반응 2개가 도착했습니다.") }
        static var friendCount: String { tr("UnfadingLocalized.Summary.friendCount", "친구 4명") }
        static var joyTag: String { tr("UnfadingLocalized.Summary.joyTag", "기쁨") }
        static var nightOutTag: String { tr("UnfadingLocalized.Summary.nightOutTag", "밤 나들이") }
        static var photoSetTag: String { tr("UnfadingLocalized.Summary.photoSetTag", "사진 모음") }

        /// Body text for the selected-pin state. Short-label is the pin's short
        /// label (e.g., "Dinner"); we interpolate that into a Korean sentence.
        static func selectedBodyTemplate(short: String) -> String {
            tr("UnfadingLocalized.Summary.selectedBodyTemplate", "이 핀에 남겨진 추억입니다. 짧은 메모: \(short). 전체 기록은 상세 화면에서 볼 수 있습니다.")
        }
    }

    // MARK: Composer

    enum Composer {
        // Navigation
        static var navTitle: String { tr("UnfadingLocalized.Composer.navTitle", "새 추억") }
        static var save: String { tr("UnfadingLocalized.Composer.save", "저장") }
        static var savePrimary: String { tr("UnfadingLocalized.Composer.savePrimary", "저장") }
        static var saveDraft: String { tr("UnfadingLocalized.Composer.saveDraft", "임시 저장") }

        // Sections
        static var memorySection: String { tr("UnfadingLocalized.Composer.memorySection", "추억") }
        static var photoSection: String { tr("UnfadingLocalized.Composer.photoSection", "사진") }
        static var photosSection: String { tr("UnfadingLocalized.Composer.photosSection", "사진") }
        static var placeSection: String { tr("UnfadingLocalized.Composer.placeSection", "장소") }
        static var moodSection: String { tr("UnfadingLocalized.Composer.moodSection", "감정") }
        static var moodLabel: String { tr("UnfadingLocalized.Composer.moodLabel", "감정") }
        static var emotionSection: String { tr("UnfadingLocalized.Composer.emotionSection", "감정 태그") }

        // Memory fields
        static var noteLabel: String { tr("UnfadingLocalized.Composer.noteLabel", "한 줄 기록") }
        static var noteField: String { tr("UnfadingLocalized.Composer.noteField", "짧은 메모를 남겨보세요") }
        static var eventLabel: String { tr("UnfadingLocalized.Composer.eventLabel", "이벤트") }
        static var timeLabel: String { tr("UnfadingLocalized.Composer.timeLabel", "시간") }
        static var sampleTime: String { tr("UnfadingLocalized.Composer.sampleTime", "오늘 오후 8:40") }
        static var timeInferredPrompt: String { tr("UnfadingLocalized.Composer.timeInferredPrompt", "사진의 시간 정보를 기준으로 제안했어요.") }
        static var timeEditAction: String { tr("UnfadingLocalized.Composer.timeEditAction", "시간 조정") }

        // Photos
        static var addFromLibrary: String { tr("UnfadingLocalized.Composer.addFromLibrary", "보관함에서 추가") }
        static var metadataHint: String { tr("UnfadingLocalized.Composer.metadataHint", "첫 사진의 메타데이터로 시간과 장소를 미리 채울 수 있습니다.") }

        // Place
        static var selectedPlace: String { tr("UnfadingLocalized.Composer.selectedPlace", "선택한 장소") }
        static var choosePlaceManually: String { tr("UnfadingLocalized.Composer.choosePlaceManually", "장소 직접 선택") }
        static var useCurrentLocation: String { tr("UnfadingLocalized.Composer.useCurrentLocation", "현재 위치 사용") }
        static var samplePlace: String { tr("UnfadingLocalized.Composer.samplePlace", "상수동 루프톱") }
        static var placeConfirmPrompt: String { tr("UnfadingLocalized.Composer.placeConfirmPrompt", "저장하기 전에 장소가 맞는지 확인해 주세요.") }
        static var placeEditAction: String { tr("UnfadingLocalized.Composer.placeEditAction", "장소 변경") }
        static var placeholderChoose: String { tr("UnfadingLocalized.Composer.placeholderChoose", "장소를 선택하세요") }
        static var placeholderCurrent: String { tr("UnfadingLocalized.Composer.placeholderCurrent", "현재 위치") }

        // Denied recovery sheet
        static var locationAccessOff: String { tr("UnfadingLocalized.Composer.locationAccessOff", "위치 접근 꺼짐") }
        static var locationRecoveryHint: String { tr("UnfadingLocalized.Composer.locationRecoveryHint", "장소를 직접 선택하면 이 추억을 저장할 수 있습니다. 현재 위치 자동 입력을 사용하려면 설정에서 위치 접근을 다시 켜세요.") }
        static var currentPlace: String { tr("UnfadingLocalized.Composer.currentPlace", "현재 장소") }
        static var searchForPlace: String { tr("UnfadingLocalized.Composer.searchForPlace", "장소 검색") }
        static var openSettings: String { tr("UnfadingLocalized.Composer.openSettings", "설정 열기") }
        static var locationNeededTitle: String { tr("UnfadingLocalized.Composer.locationNeededTitle", "위치 권한 필요") }
        static var done: String { tr("UnfadingLocalized.Composer.done", "완료") }

        // Manual place picker sheet
        static var useTypedPlace: String { tr("UnfadingLocalized.Composer.useTypedPlace", "입력한 장소 사용") }
        static var nearbyOptions: String { tr("UnfadingLocalized.Composer.nearbyOptions", "근처 장소") }
        static var searchPlaces: String { tr("UnfadingLocalized.Composer.searchPlaces", "장소 검색") }
        static var choosePlaceTitle: String { tr("UnfadingLocalized.Composer.choosePlaceTitle", "장소 선택") }

        // R26 feedback — place picker + photo seed (F3/F5/F6/F7)
        static var notThisPlaceCta: String { tr("UnfadingLocalized.Composer.notThisPlaceCta", "이 위치가 아닌가요?") }
        static var placePickerTitle: String { tr("UnfadingLocalized.Composer.placePickerTitle", "장소 선택") }
        static var pickerMapTab: String { tr("UnfadingLocalized.Composer.pickerMapTab", "지도에서") }
        static var pickerSearchTab: String { tr("UnfadingLocalized.Composer.pickerSearchTab", "검색") }
        static var pickerCurrentTab: String { tr("UnfadingLocalized.Composer.pickerCurrentTab", "현재 위치") }
        static var pickerMapHint: String { tr("UnfadingLocalized.Composer.pickerMapHint", "지도를 길게 눌러 장소를 선택하세요.") }
        static var pickerMapConfirm: String { tr("UnfadingLocalized.Composer.pickerMapConfirm", "이 위치 선택") }
        static var pickerNoResults: String { tr("UnfadingLocalized.Composer.pickerNoResults", "결과가 없어요.") }
        static var pickerLocating: String { tr("UnfadingLocalized.Composer.pickerLocating", "현재 위치 찾는 중...") }
        static var pickerUseThis: String { tr("UnfadingLocalized.Composer.pickerUseThis", "선택") }
        static var photoSeedBanner: String { tr("UnfadingLocalized.Composer.photoSeedBanner", "사진으로 시간과 장소를 자동으로 채웠어요.") }
        static var photoSeedBannerLocationOnly: String { tr("UnfadingLocalized.Composer.photoSeedBannerLocationOnly", "사진으로 장소를 자동으로 채웠어요.") }
        static var photoSeedBannerTimeOnly: String { tr("UnfadingLocalized.Composer.photoSeedBannerTimeOnly", "사진으로 시간을 자동으로 채웠어요.") }
        static var locationDeniedShortTab: String { tr("UnfadingLocalized.Composer.locationDeniedShortTab", "위치 권한이 꺼져 있어요.") }

        // R31 Composer rebuild
        static var confirmLabel: String { tr("UnfadingLocalized.Composer.confirmLabel", "확인 필요") }
        static var confirmThisPlace: String { tr("UnfadingLocalized.Composer.confirmThisPlace", "이 장소 맞아요") }
        static var changePlace: String { tr("UnfadingLocalized.Composer.changePlace", "장소 변경") }
        static var useCurrent: String { tr("UnfadingLocalized.Composer.useCurrent", "현재 위치로") }
        static var eventFieldTitle: String { tr("UnfadingLocalized.Composer.eventFieldTitle", "이벤트") }
        static var eventBindToSameDay: String { tr("UnfadingLocalized.Composer.eventBindToSameDay", "같은 날 이벤트에 묶임") }
        static var eventCreateNew: String { tr("UnfadingLocalized.Composer.eventCreateNew", "새 이벤트 만들기") }
        static var eventTripToggle: String { tr("UnfadingLocalized.Composer.eventTripToggle", "여행 (여러 날)") }
        static var eventStartDate: String { tr("UnfadingLocalized.Composer.eventStartDate", "시작") }
        static var eventEndDate: String { tr("UnfadingLocalized.Composer.eventEndDate", "종료") }
        static var participantsFieldTitle: String { tr("UnfadingLocalized.Composer.participantsFieldTitle", "이 추억의 참여자") }
        static var participantsAll: String { tr("UnfadingLocalized.Composer.participantsAll", "전원 포함") }
        static var participantsCountFormat: String { tr("UnfadingLocalized.Composer.participantsCountFormat", "%d/%d명") }
        static var emotionJoy: String { tr("UnfadingLocalized.Composer.emotionJoy", "행복") }
        static var emotionCalm: String { tr("UnfadingLocalized.Composer.emotionCalm", "여유로움") }
        static var emotionThrill: String { tr("UnfadingLocalized.Composer.emotionThrill", "설레임") }
        static var emotionWarm: String { tr("UnfadingLocalized.Composer.emotionWarm", "따뜻함") }
        static var emotionFun: String { tr("UnfadingLocalized.Composer.emotionFun", "즐거움") }
        static var emotionSpecial: String { tr("UnfadingLocalized.Composer.emotionSpecial", "특별함") }
        static var emotionMoving: String { tr("UnfadingLocalized.Composer.emotionMoving", "뭉클함") }
        static var costLabel: String { tr("UnfadingLocalized.Composer.costLabel", "지출 (선택)") }
        static var costPlaceholder: String { tr("UnfadingLocalized.Composer.costPlaceholder", "₩ 금액 입력") }
        static var sourceAlbum: String { tr("UnfadingLocalized.Composer.sourceAlbum", "앨범") }
        static var sourceCamera: String { tr("UnfadingLocalized.Composer.sourceCamera", "카메라") }
        static var sourceFile: String { tr("UnfadingLocalized.Composer.sourceFile", "파일") }
        static var metadataSparkleNotice: String { tr("UnfadingLocalized.Composer.metadataSparkleNotice", "사진 메타데이터에서 가져온 정보") }
        static var metadataSparkleHint: String { tr("UnfadingLocalized.Composer.metadataSparkleHint", "저장 전에 장소와 시간을 확인해 주세요.") }

        static func formattedParticipantsCount(_ selected: Int, _ total: Int) -> String {
            String(format: participantsCountFormat, selected, total)
        }
    }

    // MARK: Detail

    enum Detail {
        static var navTitle: String { tr("UnfadingLocalized.Detail.navTitle", "추억 상세") }
        static var detailCta: String { tr("UnfadingLocalized.Detail.detailCta", "상세 보기") }
        static var backButton: String { tr("UnfadingLocalized.Detail.backButton", "뒤로") }
        static var shareButton: String { tr("UnfadingLocalized.Detail.shareButton", "공유") }
        static var bookmarkButton: String { tr("UnfadingLocalized.Detail.bookmarkButton", "북마크") }
        static var previousButton: String { tr("UnfadingLocalized.Detail.previousButton", "이전") }
        static var nextButton: String { tr("UnfadingLocalized.Detail.nextButton", "다음") }
        static var contributionsLabel: String { tr("UnfadingLocalized.Detail.contributionsLabel", "함께한 사람들") }
        static var moodLabel: String { tr("UnfadingLocalized.Detail.moodLabel", "감정 태그") }
        static var locationLabel: String { tr("UnfadingLocalized.Detail.locationLabel", "장소") }
        static var timeLabel: String { tr("UnfadingLocalized.Detail.timeLabel", "시간") }
        static var costLabel: String { tr("UnfadingLocalized.Detail.costLabel", "비용") }
        static var costFormat: String { tr("UnfadingLocalized.Detail.costFormat", "₩") }
        static var similarPlacesSection: String { tr("UnfadingLocalized.Detail.similarPlacesSection", "이 장소 다시 가볼까?") }
        static var eventMemoriesSection: String { tr("UnfadingLocalized.Detail.eventMemoriesSection", "이벤트 안의 다른 추억들") }
        static var participantsSection: String { tr("UnfadingLocalized.Detail.participantsSection", "같이 간 사람들") }
        static var expenseSection: String { tr("UnfadingLocalized.Detail.expenseSection", "지출") }
        static var weatherSection: String { tr("UnfadingLocalized.Detail.weatherSection", "날씨") }
        static var expenseWeatherSection: String { tr("UnfadingLocalized.Detail.expenseWeatherSection", "지출 / 날씨 상세") }
        static var addOneLineCta: String { tr("UnfadingLocalized.Detail.addOneLineCta", "한 줄 더 쓰기") }
        static var addOneLinePlaceholder: String { tr("UnfadingLocalized.Detail.addOneLinePlaceholder", "이 추억에 한 줄 덧붙이기…") }
        static var addOneLineSave: String { tr("UnfadingLocalized.Detail.addOneLineSave", "저장") }

        static func eventPosition(_ current: Int, _ total: Int) -> String {
            tr("UnfadingLocalized.Detail.eventPosition", "\(current) / \(total) · 같은 이벤트")
        }

        static func title(for pin: SampleMemoryPin) -> String {
            switch pin.id {
            case SampleMemoryPin.samples[0].id:
                return tr("UnfadingLocalized.Detail.title.sample0", "상수 루프톱 저녁")
            case SampleMemoryPin.samples[1].id:
                return tr("UnfadingLocalized.Detail.title.sample1", "한강 자전거 산책")
            case SampleMemoryPin.samples[2].id:
                return tr("UnfadingLocalized.Detail.title.sample2", "아침 산책")
            default:
                return pin.title
            }
        }

        static func place(for pin: SampleMemoryPin) -> String {
            switch pin.id {
            case SampleMemoryPin.samples[0].id:
                return tr("UnfadingLocalized.Detail.place.sample0", "서울 마포구 상수동")
            case SampleMemoryPin.samples[1].id:
                return tr("UnfadingLocalized.Detail.place.sample1", "여의도 한강공원")
            case SampleMemoryPin.samples[2].id:
                return tr("UnfadingLocalized.Detail.place.sample2", "서울 도심 산책로")
            default:
                return pin.shortLabel
            }
        }

        static func time(for pin: SampleMemoryPin) -> String {
            switch pin.id {
            case SampleMemoryPin.samples[0].id:
                return tr("UnfadingLocalized.Detail.time.sample0", "오늘 오후 8:40")
            case SampleMemoryPin.samples[1].id:
                return tr("UnfadingLocalized.Detail.time.sample1", "어제 오후 6:10")
            case SampleMemoryPin.samples[2].id:
                return tr("UnfadingLocalized.Detail.time.sample2", "그제 오전 7:20")
            default:
                return Composer.sampleTime
            }
        }

        static func moodTitle(id: String) -> String {
            draftTag(id: id, fallback: id)
        }
    }

    // MARK: Model-sourced display (helpers for sample data)

    /// Korean display for a `MemoryDraftTag.id`. Returns the fallback if unmapped.
    static func draftTag(id: String, fallback: String) -> String {
        switch id {
        case "joy":
            return tr("UnfadingLocalized.draftTag.joy", "기쁨")
        case "calm":
            return tr("UnfadingLocalized.draftTag.calm", "차분함")
        case "grateful":
            return tr("UnfadingLocalized.draftTag.grateful", "감사")
        case "nostalgic":
            return tr("UnfadingLocalized.draftTag.nostalgic", "그리움")
        case "설레임": return Composer.emotionThrill
        case "따뜻함": return Composer.emotionWarm
        case "행복": return Composer.emotionJoy
        case "여유로움": return Composer.emotionCalm
        case "즐거움": return Composer.emotionFun
        case "특별함": return Composer.emotionSpecial
        case "뭉클함": return Composer.emotionMoving
        default: return fallback
        }
    }

    /// Korean display for a `PlaceSuggestion.id`. Returns the fallback if unmapped.
    static func placeSuggestion(id: String, fallbackTitle: String, fallbackSubtitle: String) -> (title: String, subtitle: String) {
        switch id {
        case "sangsu-rooftop":
            return (
                tr("UnfadingLocalized.placeSuggestion.sangsu-rooftop.title", "상수 루프톱"),
                tr("UnfadingLocalized.placeSuggestion.sangsu-rooftop.subtitle", "서울 마포구")
            )
        case "jeju-sunrise":
            return (
                tr("UnfadingLocalized.placeSuggestion.jeju-sunrise.title", "제주 성산일출봉"),
                tr("UnfadingLocalized.placeSuggestion.jeju-sunrise.subtitle", "제주 성산읍")
            )
        case "yeouido-park":
            return (
                tr("UnfadingLocalized.placeSuggestion.yeouido-park.title", "여의도 한강공원"),
                tr("UnfadingLocalized.placeSuggestion.yeouido-park.subtitle", "서울 영등포구")
            )
        default:
            return (fallbackTitle, fallbackSubtitle)
        }
    }
}
