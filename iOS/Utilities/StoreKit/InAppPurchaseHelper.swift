//
//  InAppPurchaseHelper.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/19
//  
//

import Combine
import StoreKit

fileprivate class NonConsumableProductIdentifier {
    
    static let shared: NonConsumableProductIdentifier = .init()
    
    private init() {}
    
    var hideAds: String {
        return Bundle.main.object(forInfoDictionaryKey: "InAppPurchaseHideAdsProductIdentifier") as? String ?? "com.temporary.hide_ads"
    }
}

fileprivate class ConsumableProductIdentifier {
    
    static let shared: ConsumableProductIdentifier = .init()
    
    private init() {}
    
    var beer: String {
        return Bundle.main.object(forInfoDictionaryKey: "InAppPurchaseBeerProductIdentifier") as? String ?? "com.temporary.beer"
    }
}

fileprivate class InAppPurchaseProductIdentifier {
    
    private init() {}
    
    static let nonConsumable: NonConsumableProductIdentifier = .shared
    
    static let consumable: ConsumableProductIdentifier = .shared
}

public enum StoreError: Error {
    case failedVerification
}

@MainActor
final class InAppPurchaseHelper: ObservableObject {
    
    static let shared: InAppPurchaseHelper = .init()
    
    @Published private(set) var availableProducts: [Product] = []
    
    @Published private(set) var purchasedProductIdentifiers: Set<String> = []
    
    var transactionsListenerTask: Task<Void, Never>? = nil
    
    init() {
        transactionsListenerTask = listenForTransactions()
        
        Task {
            try await loadAvailableProducts()
            
            await refreshPurchasedProductIdentifiers()
        }
    }
    
    deinit {
        transactionsListenerTask?.cancel()
    }
    
    func loadAvailableProducts() async throws -> Void {
        do {
            let fetchedProducts: [Product] = try await Product.products(
                for: [
                    InAppPurchaseProductIdentifier.nonConsumable.hideAds,
                    InAppPurchaseProductIdentifier.consumable.beer
                ]
            )
            
            await refreshPurchasedProductIdentifiers()
            
            self.availableProducts = fetchedProducts
        } catch {
            throw error
        }
    }
    
    func listenForTransactions() -> Task<Void, Never> {
        return Task.detached(priority: .background) { [unowned self] in
            for await updatesVerificationResult in Transaction.updates {
                do {
                    let transaction = try await checkVerified(result: updatesVerificationResult)
                    
                    await self.refreshPurchasedProductIdentifiers()
                    
                    await transaction.finish()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func refreshPurchasedProductIdentifiers() async -> Void {

        let currentEntitlements = Transaction.currentEntitlements
        
        for await currentEntitlement in currentEntitlements {

            guard case .verified(let verifiedTransaction) = currentEntitlement else { return }
            
            if verifiedTransaction.productType == .consumable { return }
            
            let purchasedProduct: Product? = availableProducts.first { product in
                return product.id == verifiedTransaction.productID
            }
            
            guard let purchasedProduct = purchasedProduct else { return }
            
            self.purchasedProductIdentifiers.insert(purchasedProduct.id)
        }
    }
    
    func purchase(_ product: Product) async throws {
        
        let result = try await product.purchase()
        
        guard case .success(let verificationResult) = result else { return }
        
        guard case .verified(let verifiedTransaction) = verificationResult else { return }
        
        await verifiedTransaction.finish()
        
        await self.refreshPurchasedProductIdentifiers()
    }
    
    //  MARK: https://developer.apple.com/documentation/storekit/in-app_purchase/implementing_a_store_in_your_app_using_the_storekit_api
    func checkVerified<T>(result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification

        case .verified(let verifiedResult):
            //The result is verified. Return the unwrapped value.
            return verifiedResult
        }
    }
}
