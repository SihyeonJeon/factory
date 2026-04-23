import XCTest
@testable import MemoryMap

/// Korean-string coverage for `round_foundation_reset_r1`. Ensures the plain-Swift
/// `UnfadingLocalized` namespace is populated AND referenced by production code
/// (via the representative keys each touched view uses).
final class UnfadingLocalizedTests: XCTestCase {

    func test_tab_labels_are_korean_and_non_empty() {
        XCTAssertEqual(UnfadingLocalized.Tab.map, "지도")
        XCTAssertEqual(UnfadingLocalized.Tab.rewind, "리와인드")
        XCTAssertEqual(UnfadingLocalized.Tab.groups, "그룹")
    }

    func test_accessibility_labels_contain_korean() {
        XCTAssertTrue(UnfadingLocalized.Accessibility.mapTabLabel.contains("지도"))
        XCTAssertTrue(UnfadingLocalized.Accessibility.rewindTabLabel.contains("리와인드"))
        XCTAssertTrue(UnfadingLocalized.Accessibility.groupsTabLabel.contains("그룹"))
        XCTAssertFalse(UnfadingLocalized.Accessibility.showCurrentLocationHint.isEmpty)
    }

    func test_summary_sample_copy_is_non_empty_korean() {
        XCTAssertFalse(UnfadingLocalized.Summary.tonightsRewind.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Summary.sampleTitle.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Summary.sampleBody.isEmpty)
        // Spot check the body really is in Korean (contains at least one Hangul syllable)
        XCTAssertTrue(containsHangul(UnfadingLocalized.Summary.sampleBody))
    }

    func test_composer_navigation_strings_present() {
        XCTAssertEqual(UnfadingLocalized.Composer.navTitle, "새 추억")
        XCTAssertEqual(UnfadingLocalized.Composer.save, "저장")
        XCTAssertEqual(UnfadingLocalized.Common.cancel, "취소")
    }

    func test_premium_strings_present() {
        XCTAssertEqual(UnfadingLocalized.Premium.title, "Unfading 프리미엄")
        XCTAssertEqual(UnfadingLocalized.Premium.monthlyTitle, "월간 구독")
        XCTAssertEqual(UnfadingLocalized.Premium.yearlyTitle, "연간 구독")
        XCTAssertEqual(UnfadingLocalized.Premium.yearlyBadge, "33% 절약")
        XCTAssertEqual(UnfadingLocalized.Premium.currentFree, "무료 플랜")
        XCTAssertEqual(UnfadingLocalized.Premium.currentPremium, "프리미엄 활성")
        XCTAssertEqual(UnfadingLocalized.Premium.restore, "구매 복원")
        XCTAssertEqual(UnfadingLocalized.Premium.loading, "상품 불러오는 중…")
    }

    func test_draft_tag_helper_maps_known_ids() {
        XCTAssertEqual(UnfadingLocalized.draftTag(id: "joy", fallback: "Joy"), "기쁨")
        XCTAssertEqual(UnfadingLocalized.draftTag(id: "calm", fallback: "Calm"), "차분함")
        XCTAssertEqual(UnfadingLocalized.draftTag(id: "grateful", fallback: "Grateful"), "감사")
        XCTAssertEqual(UnfadingLocalized.draftTag(id: "nostalgic", fallback: "Nostalgic"), "그리움")
    }

    func test_draft_tag_helper_returns_fallback_for_unknown_id() {
        XCTAssertEqual(
            UnfadingLocalized.draftTag(id: "unmapped", fallback: "Fallback"),
            "Fallback"
        )
    }

    func test_place_suggestion_helper_returns_korean_for_known_ids() {
        let sangsu = UnfadingLocalized.placeSuggestion(id: "sangsu-rooftop", fallbackTitle: "", fallbackSubtitle: "")
        XCTAssertEqual(sangsu.title, "상수 루프톱")
        XCTAssertEqual(sangsu.subtitle, "서울 마포구")
    }

    func test_mode_aware_copy_keeps_couple_and_group_labels_distinct() {
        XCTAssertEqual(UnfadingLocalized.Home.memoryTitle(for: .couple), "우리의 추억")
        XCTAssertEqual(UnfadingLocalized.Home.memoryTitle(for: .general), "크루 기록")
        XCTAssertEqual(UnfadingLocalized.Home.collapsedMemoryTitle(for: .couple, count: 23), "우리의 추억 23 · 위로 스와이프")
        XCTAssertEqual(UnfadingLocalized.Home.collapsedMemoryTitle(for: .general, count: 23), "크루 기록 23 · 위로 스와이프")
        XCTAssertEqual(UnfadingLocalized.Home.groupSubtitle(mode: .couple, memberCount: 2, days: 99), "함께한 지 99일")
        XCTAssertEqual(UnfadingLocalized.Home.groupSubtitle(mode: .general, memberCount: 5, days: 99), "5명 · 99일")
    }

    func test_mode_aware_surface_copy_covers_home_calendar_rewind_and_group_hub() {
        XCTAssertTrue(UnfadingLocalized.Home.rewindHintTitle(for: .couple).contains("우리"))
        XCTAssertTrue(UnfadingLocalized.Home.rewindHintTitle(for: .general).contains("크루"))
        XCTAssertTrue(UnfadingLocalized.Calendar.emptyDayTitle(for: .couple).contains("우리"))
        XCTAssertTrue(UnfadingLocalized.Calendar.emptyDayTitle(for: .general).contains("크루"))
        XCTAssertTrue(UnfadingLocalized.Rewind.coverHeadline(for: .general).contains("크루"))
        XCTAssertEqual(UnfadingLocalized.Rewind.timeTogetherTitle(for: .couple), "함께 보낸 시간")
        XCTAssertEqual(UnfadingLocalized.Rewind.timeTogetherTitle(for: .general), "크루가 함께한 시간")
        XCTAssertEqual(UnfadingLocalized.Groups.memberCountFormat(2, mode: .couple), "둘만의 기록")
        XCTAssertEqual(UnfadingLocalized.Groups.memberCountFormat(5, mode: .general), "멤버 5명")
    }

    // MARK: Helper

    private func containsHangul(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0xAC00...0xD7A3).contains(scalar.value)
        }
    }
}
