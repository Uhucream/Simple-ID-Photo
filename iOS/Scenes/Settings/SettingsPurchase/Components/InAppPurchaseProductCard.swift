//
//  InAppPurchaseProductCard.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/20
//  
//

import SwiftUI

struct InAppPurchaseProductCard: View {
    
    let productName: String
    let productDescription: String

    let productPriceLabel: String
    
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
                
                Button(
                    action: {
                        onTapPurchaseButtonCallback?()
                    }
                ) {
                    Text(productPriceLabel)
                        .fontWeight(.bold)
                        .frame(height: 16)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
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
        
        InAppPurchaseProductCard(
            productName: "広告非表示",
            productDescription: "広告を非表示にします",
            productPriceLabel: numberFormatter.string(from: 200) ?? "¥0"
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("In App Purchase Product Card")
    }
}
