//
//  ActivityView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/25
//  
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    let excludedActivityTypes: [UIActivity.ActivityType]?
    
    private(set) var onCompleteWithItemsCallback: UIActivityViewController.CompletionWithItemsHandler?
    
    func onCompleteWithItems(action: @escaping UIActivityViewController.CompletionWithItemsHandler) -> Self {
        var view = self
        
        view.onCompleteWithItemsCallback = action
        
        return view
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {

        let activityViewController: UIActivityViewController = .init(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        activityViewController.excludedActivityTypes = self.excludedActivityTypes
        
        activityViewController.completionWithItemsHandler = self.onCompleteWithItemsCallback
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}
