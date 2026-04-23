import XCTest
@testable import MemoryMap

@MainActor
final class SubscriptionStoreTests: XCTestCase {
    fileprivate actor StubSubscriptionServerSyncer: SubscriptionServerSyncing {
        var validateCalls: [SubscriptionValidationPayload] = []
        var fetchCalls = 0
        var validationResult = SubscriptionValidationResult(ok: true, status: "active", expiresAtRaw: nil)
        var validationError: Error?
        var currentSubscription: SubscriptionServerRow?

        func validateSubscription(_ payload: SubscriptionValidationPayload) async throws -> SubscriptionValidationResult {
            validateCalls.append(payload)
            if let validationError {
                throw validationError
            }
            return validationResult
        }

        func fetchCurrentSubscription() async throws -> SubscriptionServerRow? {
            fetchCalls += 1
            return currentSubscription
        }
    }

    private struct StubError: LocalizedError {
        let errorDescription: String? = "stub failure"
    }

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

    func test_sync_subscription_for_testing_invokes_edge_function_stub_with_payload() async {
        let syncer = StubSubscriptionServerSyncer()
        let store = SubscriptionStore(serverSyncer: syncer)
        let payload = SubscriptionValidationPayload(
            originalTransactionId: "1000000999",
            productId: SubscriptionStore.productIDs[0],
            bundleId: "com.jeonsihyeon.memorymap",
            environment: "sandbox"
        )

        await store.syncSubscriptionToServerForTesting(payload)

        let loggedCalls = await syncer.validateCalls
        XCTAssertEqual(loggedCalls, [payload])
        XCTAssertFalse(store.hasPendingServerSync)
        XCTAssertNil(store.consumePendingServerSyncMessage())
    }

    func test_sync_subscription_for_testing_marks_pending_warning_when_edge_function_fails() async {
        let syncer = StubSubscriptionServerSyncer()
        await syncer.setValidationErrorForTest(StubError())
        let store = SubscriptionStore(serverSyncer: syncer)
        let payload = SubscriptionValidationPayload(
            originalTransactionId: "1000001000",
            productId: SubscriptionStore.productIDs[1],
            bundleId: "com.jeonsihyeon.memorymap",
            environment: "production"
        )

        await store.syncSubscriptionToServerForTesting(payload)

        let loggedCalls = await syncer.validateCalls
        XCTAssertEqual(loggedCalls, [payload])
        XCTAssertTrue(store.hasPendingServerSync)
        XCTAssertEqual(store.consumePendingServerSyncMessage(), UnfadingLocalized.Premium.serverSyncFailedToast)
    }
}

private extension SubscriptionStoreTests.StubSubscriptionServerSyncer {
    func setValidationErrorForTest(_ error: Error?) {
        validationError = error
    }
}
