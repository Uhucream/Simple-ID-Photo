//
//  SettingsPurchaseView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/19
//  
//

import SwiftUI
import StoreKit

struct SettingsPurchaseView: View {
    
    private var numberFormatter: NumberFormatter {
        let formatter: NumberFormatter = .init()
        
        formatter.numberStyle = .currency
        formatter.locale = .init(identifier: "ja_JP")
        
        return formatter
    }
    
    @Binding var availableProducts: [Product]
    @Binding var purchasedProductIdentifiers: Set<String>
    
    private var nonConsumableProducts: [Product] {
        availableProducts
            .filter { product in
                return product.type == .nonConsumable
            }
            .sorted { $0.price < $1.price }
    }
    
    private var treatProducts: [Product] {
        availableProducts
            .filter { product in
                return product.type == .consumable
            }
            .sorted { $0.price < $1.price }
    }
    
    private(set) var onTapPurchaseButtonCallback: ((Product) -> Void)?
    
    private(set) var onTapRestorePurchaseButtonCallback: (() -> Void)?
    
    func onTapPurchaseButton(action: @escaping (Product) -> Void) -> Self {
        var view = self
        
        view.onTapPurchaseButtonCallback = action
        
        return view
    }
    
    func onTapRestorePurchaseButton(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onTapRestorePurchaseButtonCallback = action
        
        return view
    }
    
    var body: some View {
        Form {
            if nonConsumableProducts.count > 0 {
                Section {
                    ForEach(nonConsumableProducts, id: \.id) { consumableProduct in
                        
                        let isProductPurchased: Bool = purchasedProductIdentifiers.contains(consumableProduct.id)
                        
                        InAppPurchaseProductCard(
                            productName: consumableProduct.displayName,
                            productDescription: consumableProduct.description,
                            purchaseButtonLabel: isProductPurchased ? "購入済み" : consumableProduct.displayPrice,
                            purchaseButtonStyle: .borderedProminent
                        )
                        .onTapPurchaseButton {
                            self.onTapPurchaseButtonCallback?(consumableProduct)
                        }
                        .disabled(isProductPurchased)
                    }
                }
            }
            
            Section {
                Button(
                    action: {
                        onTapRestorePurchaseButtonCallback?()
                    }
                ) {
                    Text("購入の復元")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .buttonStyle(.borderless)
            }
            
            if treatProducts.count > 0 {
                Section {
                    ForEach(treatProducts, id: \.id) { treatProduct in

                        let isProductPurchased: Bool = purchasedProductIdentifiers.contains(treatProduct.id)

                        let productIcon: String = InAppPurchaseHelper.consumableProductIcon(of: treatProduct)

                        InAppPurchaseProductCard(
                            productIcon: productIcon,
                            productName: treatProduct.displayName,
                            productDescription: treatProduct.description,
                            purchaseButtonLabel: isProductPurchased ? "もう一回" : treatProduct.displayPrice,
                            purchaseButtonStyle: isProductPurchased ? .bordered : .borderedProminent
                        )
                        .onTapPurchaseButton {
                            self.onTapPurchaseButtonCallback?(treatProduct)
                        }
                    }
                } header: {
                    Text("開発者にご馳走する")
                }
            }
        }
    }
}

struct SettingsPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsPurchaseView(
            availableProducts: .constant([]),
            purchasedProductIdentifiers: .constant([])
        )
    }
}
