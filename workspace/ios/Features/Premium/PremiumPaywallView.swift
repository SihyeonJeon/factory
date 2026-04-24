import StoreKit
import SwiftUI

// vibe-limit-checked: 4 StoreKit 2 product buttons, 7 Korean purchase copy, 8 44pt a11y controls
struct PremiumPaywallView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: SubscriptionStore
    @State private var alertMessage: String?
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                    header
                    stateBanner
                    productList
                    restoreButton
                    footer
                }
                .padding(UnfadingTheme.Spacing.xl)
            }
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Premium.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        dismiss()
                    }
                }
            }
            .task {
                if store.products.isEmpty {
                    await store.loadProducts()
                }
            }
            .alert(UnfadingLocalized.Premium.title, isPresented: isShowingAlert) {
                Button(UnfadingLocalized.Common.confirm, role: .cancel) {
                    alertMessage = nil
                }
            } message: {
                Text(alertMessage ?? "")
            }
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    UnfadingToast(message: toastMessage)
                        .padding(.horizontal, UnfadingTheme.Spacing.xl)
                        .padding(.bottom, UnfadingTheme.Spacing.xl)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: toastMessage)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Premium.heroTitle)
                .font(UnfadingTheme.Font.title())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
            Text(UnfadingLocalized.Premium.subtitle)
                .font(UnfadingTheme.Font.subheadline())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
        }
    }

    @ViewBuilder
    private var stateBanner: some View {
        if store.hasPremium {
            Label(UnfadingLocalized.Premium.subscribedBanner, systemImage: "checkmark.seal.fill")
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, UnfadingTheme.Spacing.lg)
                .background(UnfadingTheme.Color.primarySoft, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact))
        }
    }

    @ViewBuilder
    private var productList: some View {
        if store.isLoading {
            HStack(spacing: UnfadingTheme.Spacing.md) {
                ProgressView()
                Text(UnfadingLocalized.Premium.loading)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        } else {
            VStack(spacing: UnfadingTheme.Spacing.md) {
                ForEach(sortedProducts, id: \.id) { product in
                    productButton(product)
                }
            }
        }
    }

    private var restoreButton: some View {
        Button {
            Task { await restorePurchases() }
        } label: {
            Label(UnfadingLocalized.Premium.restore, systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("premium-restore-button")
        .accessibilityHint(UnfadingLocalized.Premium.restore)
    }

    private var footer: some View {
        Text("취소는 \(UnfadingLocalized.Premium.cancel)")
            .font(UnfadingTheme.Font.subheadline())
            .foregroundStyle(UnfadingTheme.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sortedProducts: [Product] {
        store.products.sorted { lhs, rhs in
            productRank(lhs.id) < productRank(rhs.id)
        }
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    alertMessage = nil
                }
            }
        )
    }

    private func productButton(_ product: Product) -> some View {
        Button {
            Task { await purchase(product) }
        } label: {
            HStack(alignment: .center, spacing: UnfadingTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                    HStack(spacing: UnfadingTheme.Spacing.sm) {
                        Text(title(for: product))
                            .font(UnfadingTheme.Font.subheadlineSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        if product.id == Self.yearlyProductID {
                            Text(UnfadingLocalized.Premium.yearlyBadge)
                                .font(UnfadingTheme.Font.captionSemibold())
                                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                                .padding(.vertical, UnfadingTheme.Spacing.xs)
                                .background(UnfadingTheme.Color.primary, in: Capsule())
                        }
                    }
                    Text(product.displayName)
                        .font(UnfadingTheme.Font.subheadline())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.primary)
            }
            .padding(UnfadingTheme.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(UnfadingTheme.Color.sheet, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityIdentifier(accessibilityIdentifier(for: product))
        .accessibilityHint(title(for: product))
    }

    private func purchase(_ product: Product) async {
        do {
            _ = try await store.purchase(product)
            if let warning = store.consumePendingServerSyncMessage() {
                toastMessage = warning
                try? await Task.sleep(for: .seconds(1.8))
                dismiss()
                toastMessage = nil
            } else {
                dismiss()
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func restorePurchases() async {
        do {
            try await store.restore()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func title(for product: Product) -> String {
        switch product.id {
        case Self.monthlyProductID:
            return UnfadingLocalized.Premium.monthlyTitle
        case Self.yearlyProductID:
            return UnfadingLocalized.Premium.yearlyTitle
        default:
            return product.displayName
        }
    }

    private func accessibilityIdentifier(for product: Product) -> String {
        switch product.id {
        case Self.monthlyProductID:
            return "premium-monthly-button"
        case Self.yearlyProductID:
            return "premium-yearly-button"
        default:
            return "premium-product-button"
        }
    }

    private func productRank(_ productID: String) -> Int {
        switch productID {
        case Self.monthlyProductID:
            return 0
        case Self.yearlyProductID:
            return 1
        default:
            return 2
        }
    }

    private static let monthlyProductID = "com.jeonsihyeon.memorymap.premium.monthly"
    private static let yearlyProductID = "com.jeonsihyeon.memorymap.premium.yearly"
}
