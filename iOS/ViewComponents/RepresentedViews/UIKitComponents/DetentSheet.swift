//
//  DetentSheet.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/25
//  
//

import SwiftUI

@available(iOS, deprecated: 16)
struct DetentSheet<Content: View>: UIViewRepresentable {
    
    @Binding var isPresented: Bool
    
    @Binding var selectedDetent: UISheetPresentationController.Detent?
    
    let presentationDetents: [UISheetPresentationController.Detent]
    
    let presentationDragIndicatorVisibility: Visibility
    
    @ViewBuilder var content: () -> Content
    
    func makeUIView(context: Context) -> UIView {
        let emptyUIView: UIView = .init()
        
        return emptyUIView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
        let contentHostingController: UIHostingController<Content> = .init(rootView: self.content())
        
        if let sheetController = contentHostingController.sheetPresentationController {
            
            sheetController.delegate = context.coordinator
            
            sheetController.detents = self.presentationDetents
            sheetController.prefersGrabberVisible = presentationDragIndicatorVisibility == .visible
            sheetController.prefersScrollingExpandsWhenScrolledToEdge = false

            if let selectedDetent = selectedDetent, selectedDetent == .medium() {
                sheetController.selectedDetentIdentifier = .medium
            }

            if let selectedDetent = selectedDetent, selectedDetent == .large() {
                sheetController.selectedDetentIdentifier = .large
            }

            sheetController.largestUndimmedDetentIdentifier = .medium
        }
        
        if !isPresented {
            uiView.window?.rootViewController?.dismiss(animated: true)
            
            return
        }
        
        uiView.window?.rootViewController?.present(contentHostingController, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISheetPresentationControllerDelegate {
        
        private let owner: DetentSheet
        
        init(_ owner: DetentSheet) {
            self.owner = owner
        }
        
        func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
            let newSelectedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = sheetPresentationController.selectedDetentIdentifier
            
            if newSelectedDetentIdentifier == .medium {
                self.owner.selectedDetent = .medium()
            }
            
            if newSelectedDetentIdentifier == .large {
                self.owner.selectedDetent = .large()
            }
        }
    }
}
