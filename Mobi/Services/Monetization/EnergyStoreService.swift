//
//  EnergyStoreService.swift
//  Mobi
//
//  StoreKit 2：能量补给 IAP；未配置或沙盒失败时 stub 购买即加满精力。
//

import Combine
import Foundation
import StoreKit

@MainActor
final class EnergyStoreService: ObservableObject {
    static let shared = EnergyStoreService()

    /// App Store Connect 中配置的产品 ID
    private static let productId = "mobi_energy_refill"

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPurchasing = false
    @Published private(set) var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { await listenForTransactions() }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// 加载产品列表
    func loadProducts() async {
        do {
            let ids = [Self.productId]
            products = try await Product.products(for: ids)
        } catch {
            products = []
        }
    }

    /// 发起购买；成功时在 Transaction.updates 中发放精力并 finish，此处仅返回是否发起成功
    func purchase() async -> Bool {
        guard let product = products.first else {
            await stubPurchase()
            return true
        }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await grantAndFinish(transaction: tx)
                    return true
                case .unverified:
                    purchaseError = "验证失败"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "等待批准"
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            await stubPurchase()
            return true
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let tx) = result else { continue }
            await grantAndFinish(transaction: tx)
        }
    }

    private func grantAndFinish(transaction: Transaction) async {
        if transaction.productID == Self.productId {
            EnergyManager.shared.refillToMax()
        }
        await transaction.finish()
    }

    /// 未配置产品或请求失败时：直接加满精力（开发/沙盒用）
    private func stubPurchase() async {
        EnergyManager.shared.refillToMax()
    }
}
