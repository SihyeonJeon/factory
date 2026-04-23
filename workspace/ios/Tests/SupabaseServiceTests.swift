import XCTest
@testable import MemoryMap

final class SupabaseServiceTests: XCTestCase {
    func testSharedClientAvailable() {
        let service = SupabaseService.shared
        XCTAssertFalse(service.url.absoluteString.isEmpty)
    }

    func testConfigFromBundleReadsInfoPlist() {
        let config = SupabaseConfig.fromBundle()
        XCTAssertEqual(config.url.host, "umkbjxycdgfhgwcnfbmo.supabase.co")
        XCTAssertTrue(config.publishableKey.hasPrefix("sb_publishable_"))
    }
}
