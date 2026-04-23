import XCTest

final class UnfadingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UI_TEST_SKIP_ONBOARDING"]
        app.launchEnvironment["UNFADING_UI_TEST"] = "1"
    }

    func testMapTabScreenshot() {
        app.launch()
        let mapTab = app.tabBars.buttons["지도"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()
        sleep(1)
        attachScreenshot(name: "01_map_tab")
    }

    func testCalendarTabScreenshot() {
        app.launch()
        tapTab("캘린더")
        sleep(1)
        attachScreenshot(name: "02_calendar_tab")
    }

    func testRewindTabScreenshot() {
        app.launch()
        tapTab("리와인드")
        sleep(1)
        attachScreenshot(name: "03_rewind_tab")
    }

    func testSettingsTabScreenshot() {
        app.launch()
        tapTab("설정")
        sleep(1)
        attachScreenshot(name: "04_settings_tab")
    }

    func testComposerOpenScreenshot() {
        app.launch()
        tapTab("추억")
        sleep(2)
        attachScreenshot(name: "05_composer_open")
    }

    func testGroupHubFromSettings() {
        app.launch()
        tapTab("설정")
        let groupButton = app.buttons["그룹 관리"].firstMatch
        XCTAssertTrue(groupButton.waitForExistence(timeout: 5))
        groupButton.tap()
        sleep(1)
        attachScreenshot(name: "06_group_hub")
    }

    func testMemoryDetailFromSummaryCard() {
        app.launch()
        tapTab("지도")
        sleep(1)
        let detailButton = app.buttons.matching(identifier: "상세 보기").firstMatch
        if detailButton.waitForExistence(timeout: 3) {
            detailButton.tap()
            sleep(1)
            attachScreenshot(name: "07_memory_detail")
        } else {
            attachScreenshot(name: "07_memory_detail_skipped")
        }
    }

    private func tapTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    private func attachScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
