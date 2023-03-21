//
//  InAppPurchaseProductCard.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/20
//  
//

import SwiftUI

enum PurchaseButtonStyle {
    case bordered
    case borderedProminent
}

struct InAppPurchaseProductCard: View {
    
    let productName: String
    let productDescription: String

    let purchaseButtonLabel: String
    let purchaseButtonStyle: PurchaseButtonStyle
    
    private(set) var onTapPurchaseButtonCallback: (() -> Void)?
    
    func onTapPurchaseButton(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onTapPurchaseButtonCallback = action
        
        return view
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(productName)
                    .font(.headline)
                
                Spacer()
                
                ZStack {
                    if purchaseButtonStyle == .bordered {
                        Button(
                            action: {
                                onTapPurchaseButtonCallback?()
                            }
                        ) {
                            Text(purchaseButtonLabel)
                                .font(.system(size: 15, weight: .bold))
                                .frame(height: 12)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                    
                    if purchaseButtonStyle == .borderedProminent {
                        Button(
                            action: {
                                onTapPurchaseButtonCallback?()
                            }
                        ) {
                            Text(purchaseButtonLabel)
                                .font(.system(size: 15, weight: .bold))
                                .frame(height: 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                }
            }
            
            Text(productDescription)
                .font(.caption)
                .foregroundColor(.secondaryLabel)
        }
    }
}

struct InAppPurchaseProductCard_Previews: PreviewProvider {
    static var previews: some View {
        
        let numberFormatter: NumberFormatter = {
            let formatter: NumberFormatter = .init()
            
            formatter.numberStyle = .currency
            formatter.locale = .init(identifier: "ja_JP")
            formatter.allowsFloats = false
            
            return formatter
        }()
        
        Form {
            InAppPurchaseProductCard(
                productName: "広告非表示",
                productDescription: "広告を非表示にします",
                purchaseButtonLabel: numberFormatter.string(from: 200) ?? "¥0",
                purchaseButtonStyle: .bordered
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("In App Purchase Product Card")
        }
    }
}
