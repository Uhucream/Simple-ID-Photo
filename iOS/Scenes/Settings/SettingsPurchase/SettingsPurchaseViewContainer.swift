//
//  SettingsPurchaseViewContainer.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/19
//  
//

import SwiftUI
import StoreKit
import Percentage

struct SettingsPurchaseViewContainer: View {
    
    @EnvironmentObject private var screenSizeHelper: ScreenSizeHelper
    
    @EnvironmentObject private var inAppPurchaseHelper: InAppPurchaseHelper
    
    @State private var shouldShowProgressView: Bool = false
    
    func showProgressView() -> Void {
        self.shouldShowProgressView = true
    }
    
    func hideProgressView() -> Void {
        self.shouldShowProgressView = false
    }
    
    func purchaseProduct(_ product: Product) -> Void {
        Task {
            do {
                try await inAppPurchaseHelper.purchase(product)
            } catch {
                print(error)
            }
        }
    }
    
    func restorePurchases() -> Void {
        Task {
            do {
                showProgressView()
                
                try await AppStore.sync()
            } catch {
                print(error)
            }
            
            hideProgressView()
        }
    }
    
    var body: some View {
        SettingsPurchaseView(
            availableProducts: .constant(inAppPurchaseHelper.availableProducts.sorted { $0.price < $1.price }),
            purchasedProductIdentifiers: .constant(inAppPurchaseHelper.purchasedProductIdentifiers)
        )
        .onTapPurchaseButton(action: purchaseProduct)
        .onTapRestorePurchaseButton(action: restorePurchases)
        .overlay {
            Group {
                if shouldShowProgressView {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                            .overlay(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 30%.of(screenSizeHelper.screenSize.width))
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }
        }
    }
}

struct SettingsPurchaseViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        let inAppPurchaseHelper: InAppPurchaseHelper = .shared
        
        GeometryReader { geometry in
            
            let screenSize: CGSize = geometry.size
            
            SettingsPurchaseViewContainer()
                .onAppear {
                    screenSizeHelper.updateScreenSize(screenSize)
                }
                .onChange(of: screenSize) { newSize in
                    screenSizeHelper.updateScreenSize(newSize)
                }
                .environmentObject(screenSizeHelper)
                .environmentObject(inAppPurchaseHelper)
        }
    }
}
