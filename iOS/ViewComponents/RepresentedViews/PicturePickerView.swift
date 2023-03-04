//
//  PicturePickerView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/07
//  
//

import SwiftUI
import PhotosUI

struct PicturePickerView: UIViewControllerRepresentable {
    
    private(set) var onPickerDelegatePickerFuncCallback: ((PHPickerViewController, [PHPickerResult]) -> Void)?
    
    public func onPickerDelegatePickerFuncInvoked(
        perform action: @escaping (PHPickerViewController, [PHPickerResult]) -> Void
    ) -> Self {
        var view = self
        
        view.onPickerDelegatePickerFuncCallback = action
        
        return view
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()

        configuration.filter = .images
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)

        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parentView: PicturePickerView

        init(_ parent: PicturePickerView) {
            self.parentView = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parentView.onPickerDelegatePickerFuncCallback?(picker, results)
        }
    }
}
