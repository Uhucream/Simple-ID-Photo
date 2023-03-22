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
    
    var gyoza: String {
        return Bundle.main.object(forInfoDictionaryKey: "InAppPurchaseGyozaProductIdentifier") as? String ?? "com.temporary.gyoza"
    }
    
    var ramen: String {
        return Bundle.main.object(forInfoDictionaryKey: "InAppPurchaseRamenProductIdentifier") as? String ?? "com.temporary.ramen"
    }
}

fileprivate class InAppPurchaseProductIdentifier {
    
    private init() {}
    
    static let nonConsumable: NonConsumableProductIdentifier = .shared
    
    static let consumable: ConsumableProductIdentifier = .shared
}

fileprivate class ConsumableProductIcon {
    
    private init() {}
    
    static let beer: String = "🍺"
    
    static let gyoza: String = "🥟"
    
    static let ramen: String = "🍜"
}

public enum StoreError: Error {
    case failedVerification
}

@MainActor
final class InAppPurchaseHelper: ObservableObject {
    
    static let shared: InAppPurchaseHelper = .init()
    
    @Published private(set) var availableProducts: [Product] = []
    
    @Published private(set) var purchasedProductIdentifiers: Set<String> = []
    
    private let appStorage: AppStorageStore = .shared
    
    var transactionsListenerTask: Task<Void, Never>? = nil
    
    private let keyValueStore: NSUbiquitousKeyValueStore = .default
    
    private var cancellable: Set<AnyCancellable> = .init()
    
    init() {
        transactionsListenerTask = listenForTransactions()
        
        Task {
            try await loadAvailableProducts()
            
            refreshPurchasedProductIdentifiersForConsumableProducts()
            
            await refreshPurchasedProductIdentifiers()
            
            $purchasedProductIdentifiers
                .map { newIdentifiers in
                    let isHideAdsPurchased: Bool = newIdentifiers.contains(InAppPurchaseProductIdentifier.nonConsumable.hideAds)
                    
                    return isHideAdsPurchased
                }
                .assign(to: \.appStorage.isHideAdPurchased, on: self)
                .store(in: &cancellable)
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
                    InAppPurchaseProductIdentifier.consumable.beer,
                    InAppPurchaseProductIdentifier.consumable.gyoza,
                    InAppPurchaseProductIdentifier.consumable.ramen,
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
                    
                    if transaction.revocationDate != nil {
                        await self.removeRevocatedProductIdentifiers(transaction: transaction)
                    }
                    
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
            
            if verifiedTransaction.revocationDate != nil {
                await removeRevocatedProductIdentifiers(transaction: verifiedTransaction)
                
                return
            }
            
            self.purchasedProductIdentifiers.insert(verifiedTransaction.productID)
        }
    }
    
    func refreshPurchasedProductIdentifiersForConsumableProducts() -> Void {
        availableProducts.forEach { product in
            let productIdentifier: String = product.id
            
            let productPurchasedCount: Int64 = self.keyValueStore.longLong(forKey: productIdentifier)
            
            guard productPurchasedCount > 0 else { return }
            
            purchasedProductIdentifiers.insert(productIdentifier)
        }
    }
    
    func removeRevocatedProductIdentifiers(transaction: Transaction) async -> Void {
        self.purchasedProductIdentifiers.remove(transaction.productID)
        
        print("revocated product: \(transaction.productID)")
    }
    
    //  MARK: 非消耗型は .finish() されると Transaction.all にも含まれなくなるので、iCloud Key-Value Store に購入回数を保管する。(iCloud  なら購入アカウントと一致しているケースが大半のため。)
    func incrementConsumableProductPurchasedCount(productIdentifier: String) -> Void {
        let currentPurchasedCount: Int64 = self.keyValueStore.longLong(forKey: productIdentifier)
        
        let newPurchaseCount: Int64 = currentPurchasedCount + 1
        
        self.keyValueStore.set(newPurchaseCount, forKey: productIdentifier)
        
        self.keyValueStore.synchronize()
    }
    
    func purchase(_ product: Product) async throws {
        
        let result = try await product.purchase()
        
        guard case .success(let verificationResult) = result else { return }
        
        guard case .verified(let verifiedTransaction) = verificationResult else { return }

        if verifiedTransaction.productType == .consumable {
            incrementConsumableProductPurchasedCount(productIdentifier: verifiedTransaction.productID)
            refreshPurchasedProductIdentifiersForConsumableProducts()
            
            await verifiedTransaction.finish()
            
            return
        }
        
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

extension InAppPurchaseHelper {
    static func consumableProductIcon(of product: Product) -> String {
        if product.id == ConsumableProductIdentifier.shared.beer {
            return ConsumableProductIcon.beer
        }
        
        if product.id == ConsumableProductIdentifier.shared.gyoza {
            return ConsumableProductIcon.gyoza
        }
        
        if product.id == ConsumableProductIdentifier.shared.ramen {
            return ConsumableProductIcon.ramen
        }
        
        return ""
    }
}
