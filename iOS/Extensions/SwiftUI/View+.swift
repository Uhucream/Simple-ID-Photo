//
//  View+.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/25
//  
//

import SwiftUI

extension View {
    @available(iOS, deprecated: 16)
    func sheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        presentationDetents: [UISheetPresentationController.Detent],
        presentationDragIndicator: Visibility,
        content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            DetentSheetModifier(
                isPresented: isPresented,
                selectedDetent: .readOnly(nil),
                onDismiss: onDismiss,
                presentationDetents: presentationDetents,
                presentationDragIndicatorVisibility: presentationDragIndicator
            ) {
                content()
            }
        )
    }

    @available(iOS, deprecated: 16)
    func sheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        selectedDetent: Binding<UISheetPresentationController.Detent>,
        onDismiss: (() -> Void)? = nil,
        presentationDetents: [UISheetPresentationController.Detent],
        presentationDragIndicator: Visibility,
        content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            DetentSheetModifier(
                isPresented: isPresented,
                selectedDetent: .init(selectedDetent),
                onDismiss: onDismiss,
                presentationDetents: presentationDetents,
                presentationDragIndicatorVisibility: presentationDragIndicator
            ) {
                content()
            }
        )
    }
}
