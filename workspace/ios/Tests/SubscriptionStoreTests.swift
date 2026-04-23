import XCTest
@testable import MemoryMap

@MainActor
final class SubscriptionStoreTests: XCTestCase {

    func test_product_ids_match_subscription_constants() {
        XCTAssertEqual(
            SubscriptionStore.productIDs,
            [
                "com.jeonsihyeon.memorymap.premium.monthly",
                "com.jeonsihyeon.memorymap.premium.yearly"
            ]
        )
    }

    func test_has_premium_derives_from_purchased_product_ids() {
        XCTAssertFalse(SubscriptionStore().hasPremium)

        let store = SubscriptionStore(purchasedProductIDs: [SubscriptionStore.productIDs[0]])
        XCTAssertTrue(store.hasPremium)
    }

    func test_purchase_error_equatable_and_localized_description() {
        XCTAssertEqual(SubscriptionStore.PurchaseError.userCancelled, .userCancelled)
        XCTAssertEqual(SubscriptionStore.PurchaseError.pending, .pending)
        XCTAssertEqual(SubscriptionStore.PurchaseError.failed("서명 검증 실패"), .failed("서명 검증 실패"))
        XCTAssertNotEqual(SubscriptionStore.PurchaseError.failed("A"), .failed("B"))

        XCTAssertEqual(SubscriptionStore.PurchaseError.userCancelled.localizedDescription, "구매가 취소되었어요.")
        XCTAssertEqual(SubscriptionStore.PurchaseError.pending.localizedDescription, "결제 승인 대기 중입니다.")
        XCTAssertEqual(SubscriptionStore.PurchaseError.failed("서명 검증 실패").localizedDescription, "결제 실패: 서명 검증 실패")
        XCTAssertEqual(SubscriptionStore.PurchaseError.notSignedIn.localizedDescription, "Apple ID 로그인이 필요해요.")
    }

    func test_load_products_completes_with_storekit_configuration() async {
        let store = SubscriptionStore()
        await store.loadProducts()
        XCTAssertFalse(store.isLoading)
    }
}
