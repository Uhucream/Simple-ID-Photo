//
//  DetentSheetModifier.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/25
//  
//

import SwiftUI

@available(iOS, deprecated: 16)
struct DetentSheetModifier<SheetContent: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    
    @Binding var selectedDetent: UISheetPresentationController.Detent?
    
    let onDismiss: (() -> Void)?
    
    let presentationDetents: [UISheetPresentationController.Detent]
    
    let presentationDragIndicatorVisibility: Visibility
    
    @ViewBuilder var sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        ZStack {
            DetentSheet(
                isPresented: $isPresented,
                selectedDetent: $selectedDetent,
                presentationDetents: presentationDetents,
                presentationDragIndicatorVisibility: presentationDragIndicatorVisibility
            ) {
                sheetContent()
                    .onDisappear {
                        self.isPresented = false
                        
                        self.onDismiss?()
                    }
            }
            
            content
        }
    }
}
