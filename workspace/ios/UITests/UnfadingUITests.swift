import XCTest

final class UnfadingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UI_TEST_AUTH_STUB", "-UI_TEST_SKIP_ONBOARDING", "-UI_TEST_GROUP_STUB"]
        app.launchEnvironment["UNFADING_UI_TEST"] = "1"
    }

    func testAuthStubSkipsToRootTabView() {
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["지도"].waitForExistence(timeout: 5))
    }

    func testSignedOutShowsAuthLanding() {
        let signedOutApp = XCUIApplication()
        signedOutApp.launchArguments = ["-UI_TEST_RESET_DEFAULTS"]
        signedOutApp.launch()

        XCTAssertTrue(signedOutApp.buttons["auth-primary-button"].waitForExistence(timeout: 5))
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

    func testMapBottomSheetSnapGestures() {
        app.launch()
        tapTab("지도")

        let sheet = app.otherElements["unfading-bottom-sheet"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForSheet(sheet, value: "default"))

        sheet.swipeUp()
        XCTAssertTrue(waitForSheet(sheet, value: "expanded"))

        sheet.swipeDown()
        XCTAssertTrue(waitForSheet(sheet, value: "default"))

        sheet.swipeDown()
        XCTAssertTrue(waitForSheet(sheet, value: "collapsed"))
    }

    func testGroupOnboardingShownWhenNoGroup() {
        let noGroupApp = XCUIApplication()
        noGroupApp.launchArguments = ["-UI_TEST_AUTH_STUB", "-UI_TEST_SKIP_ONBOARDING"]
        noGroupApp.launchEnvironment["UNFADING_UI_TEST"] = "1"
        noGroupApp.launch()

        XCTAssertTrue(noGroupApp.buttons["group-create-button"].waitForExistence(timeout: 5))
    }

    private func tapTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    private func waitForSheet(_ sheet: XCUIElement, value: String) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: sheet)
        return XCTWaiter.wait(for: [expectation], timeout: 3) == .completed
    }

    private func attachScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
