import StoreKit
import Combine

/// StoreKit 2 订阅管理 — 一次性买断
/// 产品 ID 需在 App Store Connect 中配置：
///   - com.owl.aide.pro.lifetime（一次性 $2.99）
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var product: Product?
    @Published var isPurchased = false
    @Published var isLoading = false
    @Published var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task {
            for await result in Transaction.updates {
                await handleTransaction(result)
            }
        }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - 拉取产品

    func loadProducts() async {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        do {
            let products = try await Product.products(for: ["com.owl.aide.pro.lifetime"])
            await MainActor.run { product = products.first }
        } catch {
            await MainActor.run { purchaseError = "加载产品失败" }
        }
    }

    // MARK: - 购买

    func purchase() async {
        guard let product = product else { return }
        await MainActor.run { isLoading = true; purchaseError = nil }
        defer { Task { @MainActor in isLoading = false } }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handleTransaction(verification)
            case .userCancelled:
                break
            case .pending:
                await MainActor.run { purchaseError = "购买处理中，请稍候" }
            @unknown default:
                break
            }
        } catch {
            await MainActor.run { purchaseError = error.localizedDescription }
        }
    }

    // MARK: - 验证

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == "com.owl.aide.pro.lifetime",
               transaction.revocationDate == nil {
                await MainActor.run { isPurchased = true }
                return
            }
        }
        await MainActor.run { isPurchased = false }
    }

    func restorePurchases() async {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        try? await AppStore.sync()
        await checkPurchaseStatus()
    }

    // MARK: - 内部

    private func handleTransaction(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
            await checkPurchaseStatus()
        }
    }
}
