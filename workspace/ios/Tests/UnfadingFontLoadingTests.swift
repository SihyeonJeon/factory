import UIKit
import XCTest
@testable import MemoryMap

final class UnfadingFontLoadingTests: XCTestCase {
    func testGowunDodumIsBundled() {
        XCTAssertNotNil(UIFont(name: "GowunDodum-Regular", size: 14))
    }

    func testNunitoWeightsAreBundled() {
        XCTAssertNotNil(UIFont(name: "Nunito-Regular", size: 12))
        XCTAssertNotNil(UIFont(name: "Nunito-SemiBold", size: 12))
        XCTAssertNotNil(UIFont(name: "Nunito-Bold", size: 12))
        XCTAssertNotNil(UIFont(name: "Nunito-Black", size: 12))
    }

    func testFontsDoNotFallbackToSystem() {
        let got = UIFont(name: "GowunDodum-Regular", size: 14)
        XCTAssertEqual(got?.fontName, "GowunDodum-Regular")
    }
}
