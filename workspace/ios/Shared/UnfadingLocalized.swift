import Foundation

// vibe-limit-checked: 8 accessibility copy, 7 Korean UI fidelity, 11 sample-data mapping
/// Korean user-facing string namespace. All SwiftUI `Text`, `Label`, and
/// `accessibilityLabel`/`accessibilityHint` arguments in `App/` and `Features/`
/// MUST resolve to a member of this namespace. Plain Swift (not `.xcstrings`)
/// per `round_foundation_reset_r1` decision; migrate to `Localizable.xcstrings`
/// only when multi-locale becomes a real product requirement.
enum UnfadingLocalized {

    // MARK: Tab labels

    enum Tab {
        static let map = "지도"
        static let calendar = "캘린더"
        static let compose = "추억"
        static let rewind = "리와인드"
        static let settings = "설정"
        // Deprecated (R2 MVP only; R3 demoted Groups to a row under Settings)
        static let groups = "그룹"
    }

    // MARK: Accessibility

    enum Accessibility {
        static let mapTabLabel = "지도 탭"
        static let mapTabHint = "지도에서 추억 핀과 장소 기록을 둘러봅니다."
        static let calendarTabLabel = "캘린더 탭"
        static let calendarTabHint = "날짜별로 추억을 훑어봅니다."
        static let composeTabLabel = "추억 만들기 탭"
        static let composeTabHint = "새 추억을 기록하는 화면을 엽니다."
        static let rewindTabLabel = "리와인드 탭"
        static let rewindTabHint = "리와인드 순간과 알림 설정을 확인합니다."
        static let settingsTabLabel = "설정 탭"
        static let settingsTabHint = "앱 설정과 그룹 관리에 접근합니다."
        static let groupsTabLabel = "그룹 탭"
        static let groupsTabHint = "그룹을 만들고 초대와 참여를 관리합니다."

        static let showCurrentLocationLabel = "현재 위치 보기"
        static let showCurrentLocationHint = "위치 권한이 있을 때 지도를 현재 위치로 이동합니다."

        static let addMemoryLabel = "추억 추가"
        static let addMemoryHint = "새 추억 기록 화면을 엽니다."
        static let mapPinHint = "탭하면 이 추억의 요약을 엽니다."
        static let filterRowLabel = "추억 필터"
        static let filterRowHint = "가로로 넘겨 지도에 표시할 추억 종류를 고릅니다."
        static let bottomSheetHandleLabel = "추억 요약 패널"
        static let bottomSheetHandleHint = "위아래로 드래그해 패널 높이를 조절합니다."
        static let memorySummaryHint = "상세 보기를 선택하면 추억 상세 화면으로 이동합니다."
        static let shareRewindHint = "리와인드 순간을 공유합니다."
        static let rewatchRewindHint = "리와인드 스토리를 다시 엽니다."
        static let inviteGroupHint = "현재 그룹에 새 멤버를 초대합니다."
        static let premiumExploreHint = "프리미엄 요금제 안내 화면을 엽니다."
        static let premiumComingSoonHint = "프리미엄 결제는 아직 사용할 수 없습니다."
        static let placeEditHint = "장소 선택 화면을 엽니다."
        static let useCurrentLocationComposerHint = "위치 권한 상태에 따라 현재 위치를 사용하거나 복구 안내를 엽니다."
        static let openSettingsHint = "설정 앱에서 위치 접근 권한을 변경합니다."
        static let searchPlaceHint = "장소 검색 화면을 엽니다."
        static let onboardingSkipHint = "온보딩을 마치고 앱으로 이동합니다."
        static let onboardingStartHint = "온보딩을 완료하고 앱을 시작합니다."
        static let resetMapOrientationLabel = "지도 방향 초기화"
        static let sheetBackLabel = "이전"
        static let clearSelectionLabel = "선택 해제"
        static let clearSelectionHint = "지도 선택을 지우고 큐레이션 시트로 돌아갑니다."
        static let photoUploadInProgressLabel = "사진 업로드 중"
        static let addMemoryAtPlaceLabel = "이 장소에 추억 추가"

        static func mapPinLabel(title: String) -> String {
            "추억 핀, \(title)"
        }

        static func filterChipHint(title: String, isSelected: Bool) -> String {
            isSelected ? "\(title) 필터를 해제합니다." : "\(title) 필터를 적용합니다."
        }

        static func memorySummaryLabel(title: String, body: String) -> String {
            "\(title). \(body)"
        }

        static func monthNavigationHint(monthTitle: String) -> String {
            "\(monthTitle) 달력으로 이동합니다."
        }

        static let requiredStrings: [String] = [
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

    // MARK: Photo grid

    enum PhotoGrid {
        static let addPhoto = "사진 추가"
        static let removePhoto = "사진 삭제"
        static let loading = "불러오는 중"
        static let loadFailed = "사진을 불러오지 못했어요"
    }

    // MARK: Home

    enum Home {
        static let newMemory = "새 추억"
        static let navTitle = "추억 지도"
        static let searchLabel = "검색"
        static let searchHint = "장소나 추억을 검색합니다."
        static let addMemoryFab = "추억 기록"
        static let groupChipPlaceholder = "우리 그룹"
        static let groupChipHint = "현재 그룹을 바꾸거나 그룹 허브를 엽니다."
        static let filterAll = "전체"
        static let filterDate = "데이트"
        static let filterTrip = "여행"
        static let filterAnniversary = "기념일"
        static let filterFood = "맛집"
        static let rewindHintTitle = "이번 달 리와인드"
        static let rewindHintBody = "함께 남긴 장소와 사진을 모아 한 번에 돌아봐요."
        static let rewindHintCta = "리와인드 보기"

        static func rewindHintTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple: return "이번 달 우리의 리와인드"
            case .general: return "이번 달 크루 리와인드"
            }
        }

        static func rewindHintBody(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return "둘이 남긴 장소와 사진을 모아 한 번에 돌아봐요."
            case .general:
                return "크루가 남긴 장소와 사진을 모아 한 번에 돌아봐요."
            }
        }

        static func groupSubtitle(mode: GroupMode, memberCount: Int, days: Int) -> String {
            switch mode {
            case .couple:
                return "함께한 지 \(days)일"
            case .general:
                return "\(max(memberCount, 1))명 · \(days)일"
            }
        }

        static func memoryTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple: return "우리의 추억"
            case .general: return "크루 기록"
            }
        }

        static func collapsedMemoryTitle(for mode: GroupMode, count: Int) -> String {
            "\(memoryTitle(for: mode)) \(count) · 위로 스와이프"
        }

        static func clusterMarkerLabel(place: String, count: Int) -> String {
            "\(place), 추억 \(count)개"
        }

        static func eventAccessibilityLabel(title: String, place: String, photoCount: Int) -> String {
            "\(title), \(place), 사진 \(photoCount)장"
        }

        static func memoryRowAccessibilityLabel(place: String, time: String, note: String) -> String {
            "\(place), \(time), \(note)"
        }

        static func dateAccessibilityLabel(month: Int, day: Int) -> String {
            "\(month)월 \(day)일"
        }

        static func progressPercent(_ percent: Int) -> String {
            "\(percent)%"
        }
    }

    // MARK: Common

    enum Common {
        static let cancel = "취소"
        static let confirm = "확인"
    }

    // MARK: Auth

    enum Auth {
        static let signInTab = "로그인"
        static let signUpTab = "회원가입"
        static let emailPlaceholder = "이메일"
        static let passwordPlaceholder = "비밀번호"
        static let signInPrimary = "로그인"
        static let signUpPrimary = "계정 만들기"
        static let forgotPassword = "비밀번호를 잊으셨나요?"
        static let forgotPasswordSubmit = "재설정 링크 보내기"
        static let emailSent = "재설정 이메일을 보냈어요. 받은편지함을 확인해주세요."
        static let welcomeTitle = "Unfading"
        static let welcomeSubtitle = "함께한 장소, 함께 남기는 추억"
        static let invalidCredentials = "이메일 또는 비밀번호가 올바르지 않습니다."
        static let networkError = "네트워크 오류. 잠시 후 다시 시도해주세요."
        static let passwordTooShort = "비밀번호는 8자 이상이어야 합니다."
        static let signOutConfirm = "로그아웃 하시겠습니까?"
        static let signOut = "로그아웃"
        static let guest = "게스트"
        static let modePickerLabel = "인증 방식"
        static let primaryHint = "입력한 이메일과 비밀번호로 계속합니다."
        static let forgotPasswordHint = "이메일로 비밀번호 재설정 링크를 보냅니다."
    }

    // MARK: Onboarding

    enum Onboarding {
        static let slide1Title = "추억을 지도 위에 남기다"
        static let slide1Body = "함께 간 장소를 핀으로 기록하고 언제든 다시 꺼내 봐요."
        static let slide2Title = "장소 기반 리와인드"
        static let slide2Body = "그 자리에 다시 서면 예전 추억이 부드럽게 돌아와요."
        static let slide3Title = "둘, 또는 함께"
        static let slide3Body = "커플부터 친구 그룹까지. 우리만의 지도를 만들어 봐요."
        static let startCta = "시작하기"
        static let skipCta = "건너뛰기"
        static let pageIndicatorHint = "페이지 이동"
    }

    // MARK: Empty states

    enum EmptyState {
        static let rewindTitle = "아직 리와인드가 없어요"
        static let rewindBody = "함께 만든 순간이 쌓이면 이곳에 나타나요."
        static let composerPhotoHint = "사진을 추가하면 시간과 장소가 자동으로 채워져요."
    }

    // MARK: Rewind

    enum Rewind {
        static let navTitle = "리와인드"
        static let shareLabel = "공유"
        static let rewatchLabel = "다시 보기"
        static let reminderLabel = "장소 기반 알림"
        static let reminderHint = "이곳 근처에 가면 관련 추억을 알려드려요."
        static let storyViewTitle = "리와인드 스토리"
        static let closeLabel = "리와인드 닫기"
        static let closeHint = "닫으면 홈 요약 패널로 돌아갑니다."
        static let previousStoryLabel = "이전 리와인드 카드"
        static let nextStoryLabel = "다음 리와인드 카드"
        static let eyebrow = "REWIND"
        static let coverHeadline = "이번 달,\n함께 지나온 곳들"
        static let coverPhotoLabel = "이번 달 리와인드 커버 사진"
        static let topPlacesTitle = "가장 많이 간 곳 TOP 3"
        static let topPlacesSubtitle = "이번 달에 가장 자주 다시 찾은 장소예요."
        static let firstVisitsTitle = "처음 가본 곳"
        static let firstVisitsSubtitle = "새로 지도에 남긴 장소를 모았어요."
        static let photoDayTitle = "사진 가장 많이 찍은 날"
        static let photoDaySubtitle = "셔터를 가장 많이 누른 하루예요."
        static let emotionCloudTitle = "감정 태그 클라우드"
        static let emotionCloudSubtitle = "남긴 감정의 비율대로 크게 보여드려요."
        static let timeTogetherTitle = "함께 보낸 시간"
        static let timeTogetherSubtitle = "장소에 머문 시간을 모두 더했어요."
        static let hoursTogetherUnit = "시간"
        static let timeTogetherBody = "함께 머문 시간이 한 장의 리와인드가 되었어요."

        static func coverHeadline(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return "이번 달,\n함께 지나온 곳들"
            case .general:
                return "이번 달,\n크루가 모인 곳들"
            }
        }

        static func topPlacesSubtitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return "이번 달에 둘이 가장 자주 다시 찾은 장소예요."
            case .general:
                return "이번 달에 크루가 가장 자주 다시 찾은 장소예요."
            }
        }

        static func timeTogetherTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple: return "함께 보낸 시간"
            case .general: return "크루가 함께한 시간"
            }
        }

        static func timeTogetherBody(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return "함께 머문 시간이 한 장의 리와인드가 되었어요."
            case .general:
                return "크루가 머문 시간이 한 장의 리와인드가 되었어요."
            }
        }

        static func visitCount(_ count: Int) -> String {
            "\(count)번 방문"
        }

        static func photoCount(_ count: Int) -> String {
            "사진 \(count)장"
        }

        static func progressLabel(_ index: Int, total: Int) -> String {
            "리와인드 진행 \(index)/\(total)"
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
        static let navTitle = "그룹"
        static let membersLabel = "멤버"
        static let inviteCta = "초대"
        static let coverEyebrow = "함께한 기록"
        static let modePickerLabel = "모드"
        static let onboardingTitle = "그룹 시작"
        static let createTab = "새로 만들기"
        static let joinTab = "초대 코드로 참여"
        static let namePlaceholder = "그룹 이름"
        static let nicknamePlaceholder = "내 이름 (선택)"
        static let nicknameHint = "이 그룹 안에서 사용할 이름"
        static let modeCouple = "커플"
        static let modeGroup = "그룹"
        static let introPlaceholder = "소개 (선택)"
        static let createButton = "만들기"
        static let codePlaceholder = "초대 코드"
        static let joinButton = "참여하기"
        static let createdBanner = "그룹이 생성되었어요!"
        static let joinedBanner = "그룹에 참여했어요!"
        static let invalidCode = "초대 코드를 확인해주세요."
        static let inviteCodeLabel = "초대 코드"
        static let copyCode = "복사"
        static let rotateCode = "재생성"
        static let rotated = "새 초대 코드로 바뀌었어요."
        static let actionFailed = "잠시 후 다시 시도해주세요."
        static let edit = "편집"
        static let editGroupName = "그룹 이름 편집"
        static let editNickname = "내 이름 편집"
        static let groupNameUpdated = "그룹 이름을 바꿨어요."
        static let nicknameUpdated = "내 이름을 바꿨어요."
        static let notOwnerHint = "그룹 이름은 만든 사람만 바꿀 수 있어요."
        static let pickerTitle = "그룹 선택"
        static let pickerSubtitle = "여러 그룹을 동시에 쓸 수 있어요"
        static let pickerCoupleBadge = "COUPLE"
        static let pickerGroupBadge = "GROUP"
        static let pickerCreateNew = "새 그룹 만들기"
        static let pickerClose = "그룹 선택 닫기"

        static func dayCountFormat(_ days: Int) -> String {
            "함께한 지 \(days)일"
        }

        static func memberCountFormat(_ count: Int) -> String {
            "멤버 \(count)명"
        }

        static func memberCountFormat(_ count: Int, mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return "둘만의 기록"
            case .general:
                return "멤버 \(count)명"
            }
        }

        static func pickerMembersFormat(_ count: Int) -> String {
            "\(count)명"
        }

        static func pickerAnniversaryFormat(_ days: Int) -> String {
            "함께한 지 \(days)일"
        }
    }

    // MARK: Group Hub

    enum GroupHub {
        static let navTitle = "그룹 허브"
        static let overviewSection = "그룹 정보"
        static let startedAtLabel = "시작일"
        static let switchGroupCTA = "다른 그룹으로 전환"
        static let membersSection = "멤버"
        static let ownerRole = "그룹장"
        static let memberRole = "멤버"
        static let partnerRole = "파트너"
        static let youSuffix = "나"
        static let inviteSection = "멤버 초대"
        static let inviteLinkLabel = "초대 링크"
        static let createInviteLink = "링크 생성"
        static let showQRCode = "QR 보기"
        static let qrPlaceholder = "QR 코드는 다음 라운드에서 실제 링크와 연결돼요."
        static let inviteLinkCopied = "초대 링크를 복사했어요."
        static let appearanceSection = "지도 스타일"
        static let mapThemeToggle = "지도 테마"
        static let iconPackToggle = "아이콘 팩"
        static let sprint7Placeholder = "Sprint 7에서 프리미엄 스타일과 연결됩니다."
        static let notificationsSection = "알림"
        static let anniversaryToggle = "기념일 알림"
        static let rewindToggle = "Rewind 알림"
        static let memberActivityToggle = "멤버 활동 알림"
        static let dataSection = "데이터"
        static let iCloudStatusLabel = "iCloud 동기화"
        static let iCloudStatusReady = "준비됨"
        static let exportAllCTA = "전체 내보내기"
        static let exportPlaceholder = "R49에서 JSON과 사진 ZIP 내보내기를 완성합니다."
        static let dangerSection = "그룹 관리"
        static let leaveGroupCTA = "그룹 떠나기"
        static let deleteGroupCTA = "그룹 삭제"
        static let leaveWarningTitle = "그룹을 떠날까요?"
        static let leaveWarningMessage = "이 그룹의 새 추억과 알림을 더 이상 볼 수 없습니다."
        static let deleteWarningTitle = "그룹을 삭제할까요?"
        static let deleteWarningMessage = "그룹과 연결된 데이터 삭제는 되돌릴 수 없습니다."
        static let destructiveConfirm = "계속"
        static let destructivePlaceholder = "서버 작업은 다음 백엔드 라운드에서 연결됩니다."

        static func startedAtFormat(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .autoupdatingCurrent
            formatter.dateFormat = "yyyy.MM.dd"
            return formatter.string(from: date)
        }

        static func inviteLink(code: String) -> String {
            "https://unfading.app/join/\(code)"
        }
    }

    // MARK: Categories

    enum Categories {
        static let editorTitle = "카테고리 편집"
        static let editorSubtitle = "기본 · 추억 / 밥 / 카페 / 경험 · 직접 추가 가능"
        static let newCategoryLabel = "새 카테고리"
        static let newCategoryPlaceholder = "예: 산책, 공연, 전시…"
        static let addButton = "추가"
        static let resetDefault = "기본값"
        static let save = "저장"
        static let duplicateError = "이미 있는 카테고리예요."
        static let emptyNameError = "카테고리 이름을 입력해주세요."
        static let defaultMemory = "추억"
        static let defaultMeal = "밥"
        static let defaultCafe = "카페"
        static let defaultExperience = "경험"
        static let addCategory = "카테고리 추가"
        static let close = "카테고리 편집 닫기"

        static func deleteCategoryLabel(_ name: String) -> String {
            "\(name) 삭제"
        }
    }

    // MARK: Calendar (stub in R3; full impl in R8)

    enum Calendar {
        static let navTitle = "캘린더"
        static let stubTitle = "달력 화면 준비 중"
        static let stubBody = "다가오는 라운드에서 월별 격자와 날짜별 추억 점을 구현합니다."
        static let weekdayHeaders = ["일", "월", "화", "수", "목", "금", "토"]
        static let previousMonthHint = "이전 달"
        static let nextMonthHint = "다음 달"
        static let emptyDayTitle = "이 날의 추억이 없어요"
        static let emptyDayBody = "지도에서 새 추억을 기록해 이 자리를 채워보세요."

        static func emptyDayTitle(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return "이 날의 우리의 추억이 없어요"
            case .general:
                return "이 날의 크루 기록이 없어요"
            }
        }

        static func emptyDayBody(for mode: GroupMode) -> String {
            switch mode {
            case .couple:
                return "지도에서 둘만의 새 추억을 기록해 이 자리를 채워보세요."
            case .general:
                return "지도에서 크루의 새 기록을 남겨 이 자리를 채워보세요."
            }
        }

        static func memoryCountFormat(_ count: Int) -> String {
            "\(count)개의 추억"
        }

        static func monthYearFormat(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy년 M월"
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .autoupdatingCurrent
            return formatter.string(from: date)
        }

        // R26 F9/F2-cal — 월 지출 + 계획 배지 + 새 계획 시트
        static let monthlyExpense = "이 달 지출"
        static let planBadge = "계획"
        static let memoryBadge = "추억"
        static let addPlanCTA = "계획 추가"
        static let planSheetTitle = "새 계획"
        static let planTitlePlaceholder = "제목"
        static let multiDayToggle = "여행 (여러 날)"
        static let reminderToggle = "알람 받기"
        static let reminderTimeLabel = "알람 시각"
        static let savedPlan = "계획이 저장되었어요."
        static let reminderPermissionDenied = "알람 권한이 꺼져 있어 알람은 울리지 않아요."
        static let plansForDate = "이 날의 계획"
        static let futureDayHint = "이 날짜는 미래라 추억 대신 계획을 추가할 수 있어요."
        static let monthPickerTitle = "월 선택"
        static let weatherSample = "맑음 23°"
        static let eventsSectionTitle = "이벤트"
        static let noEventsForDate = "이 날의 이벤트가 아직 없어요."
        static let planPlaceFallback = "성수 카페 거리"
        static let sendReminderCTA = "알림 보내기"
        static let broadcastToast = "모든 멤버에게 알림을 보냈어요"

        static func nextMeetingTitle(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .autoupdatingCurrent
            formatter.dateFormat = "E M/d"
            return "다음 만남 — \(formatter.string(from: date))"
        }

        static func expenseCurrencyFormat(_ won: Int64) -> String {
            "₩\(won.formatted(.number.grouping(.automatic)))"
        }
    }

    // MARK: Settings (stub in R3; full impl in R11)

    enum Settings {
        static let navTitle = "설정"
        static let stubTitle = "설정 화면 준비 중"
        static let stubBody = "앱 환경과 계정 설정은 다가오는 라운드에서 구성됩니다."
        static let profileSection = "프로필"
        static let displayNamePlaceholder = "표시 이름"
        static let displayNameUpdated = "저장되었어요."
        static let accountSection = "계정"
        static let preferencesSection = "환경설정"
        static let reminderToggle = "장소 기반 알림"
        static let reminderHint = "이곳 근처에 가면 관련 추억을 알려드려요."
        static let themeLabel = "테마"
        static let groupsSection = "그룹"
        static let groupsRow = "그룹 관리"
        static let groupsRowHint = "그룹 허브로 이동합니다."
        static let premiumSection = "프리미엄"
        static let premiumExplore = "프리미엄 둘러보기"
        static let premiumComingSoon = "출시 예정"
        static let premiumSavingBadge = "33% 절약"
        static let premiumTierFreeName = "무료"
        static let premiumTierMonthly = "프리미엄 월"
        static let premiumTierAnnual = "프리미엄 연"
        static let premiumTierFreePrice = "₩0"
        static let premiumTierMonthlyPrice = "월 ₩4,900"
        static let premiumTierAnnualPrice = "연 ₩39,000"
        static let infoSection = "정보"
        static let versionLabel = "버전 1.0.0"
        static let licensesRow = "오픈소스 라이선스"

        static func draftCountFormat(_ count: Int) -> String {
            "임시 저장 \(count)개"
        }

        static func tierFeatures(_ tier: Int) -> [String] {
            switch tier {
            case 0:
                return ["월 30개 추억", "그룹 5명", "기본 지도 스타일"]
            case 1:
                return ["무제한 추억", "기념일 AI 리와인드", "고급 지도 테마", "가족 그룹"]
            default:
                return ["무제한 추억", "고급 지도 테마", "다이어리 북 내보내기", "연간 할인"]
            }
        }
    }

    // MARK: Premium

    enum Premium {
        static let title = "Unfading 프리미엄"
        static let heroTitle = "Unfading 프리미엄으로 더 많은 추억을"
        static let subtitle = "소중한 추억을 무제한으로"
        static let monthlyTitle = "월간 구독"
        static let yearlyTitle = "연간 구독"
        static let yearlyBadge = "33% 절약"
        static let currentFree = "무료 플랜"
        static let currentPremium = "프리미엄 활성"
        static let restore = "구매 복원"
        static let cancel = "App Store에서 언제든 취소 가능해요."
        static let loading = "상품 불러오는 중…"
        static let subscribedBanner = "프리미엄이 활성화되었어요!"
        static let showPaywall = "프리미엄 보기"
        static let manage = "구독 관리"
        static let manageHint = "App Store 구독 관리 화면을 엽니다."
        static let serverSyncFailedToast = "서버에 동기화하지 못했지만, 구독은 정상이에요"
    }

    enum Theme {
        static let system = "시스템 설정"
        static let light = "라이트"
        static let dark = "다크"
    }

    // MARK: Placeholder (generic "coming soon" surfaces)

    enum Placeholder {
        static let comingSoon = "준비 중"
    }

    // MARK: Summary card

    enum Summary {
        static let tonightsRewind = "오늘의 리와인드"
        static let selectedEyebrow = "선택한 추억"
        static let sampleTitle = "상수 루프톱 저녁"
        static let sampleBody = "3년 전 오늘, 이곳에서 공연 뒤 함께 핀을 남겼습니다. 오늘 아침 새 반응 2개가 도착했습니다."
        static let friendCount = "친구 4명"
        static let joyTag = "기쁨"
        static let nightOutTag = "밤 나들이"
        static let photoSetTag = "사진 모음"

        /// Body text for the selected-pin state. Short-label is the pin's short
        /// label (e.g., "Dinner"); we interpolate that into a Korean sentence.
        static func selectedBodyTemplate(short: String) -> String {
            "이 핀에 남겨진 추억입니다. 짧은 메모: \(short). 전체 기록은 상세 화면에서 볼 수 있습니다."
        }
    }

    // MARK: Composer

    enum Composer {
        // Navigation
        static let navTitle = "새 추억"
        static let save = "저장"
        static let savePrimary = "저장"
        static let saveDraft = "임시 저장"

        // Sections
        static let memorySection = "추억"
        static let photoSection = "사진"
        static let photosSection = "사진"
        static let placeSection = "장소"
        static let moodSection = "감정"
        static let moodLabel = "감정"
        static let emotionSection = "감정 태그"

        // Memory fields
        static let noteLabel = "한 줄 기록"
        static let noteField = "짧은 메모를 남겨보세요"
        static let eventLabel = "이벤트"
        static let timeLabel = "시간"
        static let sampleTime = "오늘 오후 8:40"
        static let timeInferredPrompt = "사진의 시간 정보를 기준으로 제안했어요."
        static let timeEditAction = "시간 조정"

        // Photos
        static let addFromLibrary = "보관함에서 추가"
        static let metadataHint = "첫 사진의 메타데이터로 시간과 장소를 미리 채울 수 있습니다."

        // Place
        static let selectedPlace = "선택한 장소"
        static let choosePlaceManually = "장소 직접 선택"
        static let useCurrentLocation = "현재 위치 사용"
        static let samplePlace = "상수동 루프톱"
        static let placeConfirmPrompt = "저장하기 전에 장소가 맞는지 확인해 주세요."
        static let placeEditAction = "장소 변경"
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

        // R26 feedback — place picker + photo seed (F3/F5/F6/F7)
        static let notThisPlaceCta = "이 위치가 아닌가요?"
        static let placePickerTitle = "장소 선택"
        static let pickerMapTab = "지도에서"
        static let pickerSearchTab = "검색"
        static let pickerCurrentTab = "현재 위치"
        static let pickerMapHint = "지도를 길게 눌러 장소를 선택하세요."
        static let pickerMapConfirm = "이 위치 선택"
        static let pickerNoResults = "결과가 없어요."
        static let pickerLocating = "현재 위치 찾는 중..."
        static let pickerUseThis = "선택"
        static let photoSeedBanner = "사진으로 시간과 장소를 자동으로 채웠어요."
        static let photoSeedBannerLocationOnly = "사진으로 장소를 자동으로 채웠어요."
        static let photoSeedBannerTimeOnly = "사진으로 시간을 자동으로 채웠어요."
        static let locationDeniedShortTab = "위치 권한이 꺼져 있어요."

        // R31 Composer rebuild
        static let confirmLabel = "확인 필요"
        static let confirmThisPlace = "이 장소 맞아요"
        static let changePlace = "장소 변경"
        static let useCurrent = "현재 위치로"
        static let eventFieldTitle = "이벤트"
        static let eventBindToSameDay = "같은 날 이벤트에 묶임"
        static let eventCreateNew = "새 이벤트 만들기"
        static let eventTripToggle = "여행 (여러 날)"
        static let eventStartDate = "시작"
        static let eventEndDate = "종료"
        static let participantsFieldTitle = "이 추억의 참여자"
        static let participantsAll = "전원 포함"
        static let participantsCountFormat = "%d/%d명"
        static let emotionJoy = "행복"
        static let emotionCalm = "여유로움"
        static let emotionThrill = "설레임"
        static let emotionWarm = "따뜻함"
        static let emotionFun = "즐거움"
        static let emotionSpecial = "특별함"
        static let emotionMoving = "뭉클함"
        static let costLabel = "지출 (선택)"
        static let costPlaceholder = "₩ 금액 입력"
        static let sourceAlbum = "앨범"
        static let sourceCamera = "카메라"
        static let sourceFile = "파일"
        static let metadataSparkleNotice = "사진 메타데이터에서 가져온 정보"
        static let metadataSparkleHint = "저장 전에 장소와 시간을 확인해 주세요."

        static func formattedParticipantsCount(_ selected: Int, _ total: Int) -> String {
            String(format: participantsCountFormat, selected, total)
        }
    }

    // MARK: Detail

    enum Detail {
        static let navTitle = "추억 상세"
        static let detailCta = "상세 보기"
        static let backButton = "뒤로"
        static let shareButton = "공유"
        static let bookmarkButton = "북마크"
        static let previousButton = "이전"
        static let nextButton = "다음"
        static let contributionsLabel = "함께한 사람들"
        static let moodLabel = "감정 태그"
        static let locationLabel = "장소"
        static let timeLabel = "시간"
        static let costLabel = "비용"
        static let costFormat = "₩"
        static let similarPlacesSection = "이 장소 다시 가볼까?"
        static let eventMemoriesSection = "이벤트 안의 다른 추억들"
        static let participantsSection = "같이 간 사람들"
        static let expenseSection = "지출"
        static let weatherSection = "날씨"
        static let expenseWeatherSection = "지출 / 날씨 상세"
        static let addOneLineCta = "한 줄 더 쓰기"
        static let addOneLinePlaceholder = "이 추억에 한 줄 덧붙이기…"
        static let addOneLineSave = "저장"

        static func eventPosition(_ current: Int, _ total: Int) -> String {
            "\(current) / \(total) · 같은 이벤트"
        }

        static func title(for pin: SampleMemoryPin) -> String {
            switch pin.id {
            case SampleMemoryPin.samples[0].id: return "상수 루프톱 저녁"
            case SampleMemoryPin.samples[1].id: return "한강 자전거 산책"
            case SampleMemoryPin.samples[2].id: return "아침 산책"
            default: return pin.title
            }
        }

        static func place(for pin: SampleMemoryPin) -> String {
            switch pin.id {
            case SampleMemoryPin.samples[0].id: return "서울 마포구 상수동"
            case SampleMemoryPin.samples[1].id: return "여의도 한강공원"
            case SampleMemoryPin.samples[2].id: return "서울 도심 산책로"
            default: return pin.shortLabel
            }
        }

        static func time(for pin: SampleMemoryPin) -> String {
            switch pin.id {
            case SampleMemoryPin.samples[0].id: return "오늘 오후 8:40"
            case SampleMemoryPin.samples[1].id: return "어제 오후 6:10"
            case SampleMemoryPin.samples[2].id: return "그제 오전 7:20"
            default: return Composer.sampleTime
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
        case "joy": return "기쁨"
        case "calm": return "차분함"
        case "grateful": return "감사"
        case "nostalgic": return "그리움"
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
