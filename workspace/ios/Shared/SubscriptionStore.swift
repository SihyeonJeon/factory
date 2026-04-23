import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    static let productIDs: [String] = [
        "com.jeonsihyeon.memorymap.premium.monthly",
        "com.jeonsihyeon.memorymap.premium.yearly"
    ]

    enum PurchaseError: Error, Equatable, LocalizedError {
        case userCancelled
        case pending
        case failed(String)
        case notSignedIn

        var errorDescription: String? {
            switch self {
            case .userCancelled:
                return "구매가 취소되었어요."
            case .pending:
                return "결제 승인 대기 중입니다."
            case .failed(let message):
                return "결제 실패: \(message)"
            case .notSignedIn:
                return "Apple ID 로그인이 필요해요."
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String>
    @Published private(set) var isLoading = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init(purchasedProductIDs: Set<String> = []) {
        self.purchasedProductIDs = purchasedProductIDs
        updatesTask = Task { [weak self] in
            for await verification in Transaction.updates {
                await self?.handle(verification)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var hasPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Self.productIDs)
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                ids.insert(transaction.productID)
            }
        }
        purchasedProductIDs = ids
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                } else {
                    throw PurchaseError.failed("서명 검증 실패")
                }
            case .userCancelled:
                throw PurchaseError.userCancelled
            case .pending:
                throw PurchaseError.pending
            @unknown default:
                throw PurchaseError.failed("알 수 없는 상태")
            }
        } catch {
            throw error
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = verification {
            await transaction.finish()
            await refreshEntitlements()
        }
    }
}
