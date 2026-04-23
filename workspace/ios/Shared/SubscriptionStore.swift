import Foundation
import StoreKit
import Supabase

struct SubscriptionValidationPayload: Encodable, Equatable {
    let originalTransactionId: String
    let productId: String
    let bundleId: String
    let environment: String
}

struct SubscriptionValidationResult: Decodable, Equatable {
    let ok: Bool
    let status: String
    let expiresAtRaw: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case status
        case expiresAtRaw = "expires_at"
    }

    var expiresAt: Date? {
        expiresAtRaw.flatMap(SubscriptionStore.edgeDateFormatter.date(from:))
    }
}

struct SubscriptionServerRow: Decodable, Equatable {
    let productId: String
    let originalTransactionId: String
    let expiresAt: Date?
    let status: String

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case originalTransactionId = "original_transaction_id"
        case expiresAt = "expires_at"
        case status
    }
}

protocol SubscriptionServerSyncing: Sendable {
    func validateSubscription(_ payload: SubscriptionValidationPayload) async throws -> SubscriptionValidationResult
    func fetchCurrentSubscription() async throws -> SubscriptionServerRow?
}

struct LiveSubscriptionServerSyncer: SubscriptionServerSyncing {
    private let client: SupabaseClient
    private let database: PostgrestClient

    init(
        client: SupabaseClient = SupabaseService.shared.client,
        database: PostgrestClient = SupabaseService.shared.database
    ) {
        self.client = client
        self.database = database
    }

    func validateSubscription(_ payload: SubscriptionValidationPayload) async throws -> SubscriptionValidationResult {
        let decoder = JSONDecoder()
        return try await client.functions.invoke(
            "validate-subscription",
            options: .init(body: payload),
            decoder: decoder
        )
    }

    func fetchCurrentSubscription() async throws -> SubscriptionServerRow? {
        let rows: [SubscriptionServerRow] = try await database.from("subscriptions")
            .select("product_id,original_transaction_id,expires_at,status")
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}

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
    @Published private(set) var hasPendingServerSync = false

    private var updatesTask: Task<Void, Never>?
    private let serverSyncer: any SubscriptionServerSyncing
    private var pendingServerSyncMessage: String?

    init(
        purchasedProductIDs: Set<String> = [],
        serverSyncer: any SubscriptionServerSyncing = LiveSubscriptionServerSyncer()
    ) {
        self.purchasedProductIDs = purchasedProductIDs
        self.serverSyncer = serverSyncer
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
        var latestTransaction: Transaction?
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                ids.insert(transaction.productID)
                if let currentLatest = latestTransaction {
                    if transaction.purchaseDate > currentLatest.purchaseDate {
                        latestTransaction = transaction
                    }
                } else {
                    latestTransaction = transaction
                }
            }
        }
        purchasedProductIDs = ids
        await refreshServerMirrorState(localProductIDs: ids, latestTransaction: latestTransaction)
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await validateSubscriptionOnServer(using: transaction)
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

    func consumePendingServerSyncMessage() -> String? {
        let message = pendingServerSyncMessage
        pendingServerSyncMessage = nil
        return message
    }

    func syncSubscriptionToServerForTesting(_ payload: SubscriptionValidationPayload) async {
        await validateSubscriptionOnServer(payload: payload, warningMessage: UnfadingLocalized.Premium.serverSyncFailedToast)
    }

    private func validateSubscriptionOnServer(using transaction: Transaction) async {
        guard let payload = makeValidationPayload(from: transaction) else {
            markServerSyncWarning()
            return
        }

        await validateSubscriptionOnServer(payload: payload, warningMessage: warningMessage(for: transaction))
    }

    private func validateSubscriptionOnServer(payload: SubscriptionValidationPayload, warningMessage: String) async {
        do {
            _ = try await serverSyncer.validateSubscription(payload)
            clearServerSyncWarning()
        } catch {
            markServerSyncWarning(message: warningMessage)
        }
    }

    private func refreshServerMirrorState(localProductIDs: Set<String>, latestTransaction: Transaction?) async {
        guard !localProductIDs.isEmpty else {
            clearServerSyncWarning()
            return
        }

        do {
            let row = try await serverSyncer.fetchCurrentSubscription()
            let isMirrored = row.map { localProductIDs.contains($0.productId) && Self.activeStatuses.contains($0.status) } ?? false
            if isMirrored {
                clearServerSyncWarning()
            } else {
                if let latestTransaction {
                    pendingServerSyncMessage = pendingServerSyncMessage ?? warningMessage(for: latestTransaction)
                } else {
                    pendingServerSyncMessage = pendingServerSyncMessage ?? UnfadingLocalized.Premium.serverSyncFailedToast
                }
                hasPendingServerSync = true
            }
        } catch {
            if let latestTransaction {
                pendingServerSyncMessage = pendingServerSyncMessage ?? warningMessage(for: latestTransaction)
            } else {
                pendingServerSyncMessage = pendingServerSyncMessage ?? UnfadingLocalized.Premium.serverSyncFailedToast
            }
            hasPendingServerSync = true
        }
    }

    private func makeValidationPayload(from transaction: Transaction) -> SubscriptionValidationPayload? {
        guard let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty else {
            return nil
        }

        return SubscriptionValidationPayload(
            originalTransactionId: String(transaction.originalID),
            productId: transaction.productID,
            bundleId: bundleId,
            environment: Self.serverEnvironment(for: transaction)
        )
    }

    private func warningMessage(for transaction: Transaction) -> String {
        _ = transaction
        return UnfadingLocalized.Premium.serverSyncFailedToast
    }

    private func markServerSyncWarning(message: String = UnfadingLocalized.Premium.serverSyncFailedToast) {
        pendingServerSyncMessage = pendingServerSyncMessage ?? message
        hasPendingServerSync = true
    }

    private func clearServerSyncWarning() {
        hasPendingServerSync = false
        pendingServerSyncMessage = nil
    }

    private static func serverEnvironment(for transaction: Transaction) -> String {
        switch transaction.environment {
        case .production:
            return "production"
        default:
            return "sandbox"
        }
    }

    fileprivate static let edgeDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let activeStatuses: Set<String> = ["active", "in_grace_period", "in_billing_retry"]
}
