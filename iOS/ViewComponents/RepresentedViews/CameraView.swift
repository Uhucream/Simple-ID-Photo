//
//  CameraView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI
import UniformTypeIdentifiers

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    @Binding var pictureURL: URL?

    private(set) var onCancelledCallback: ((UIImagePickerController) -> Void)?
    
    func onCancelled(action: @escaping (UIImagePickerController) -> Void) -> Self {
        var view = self
        
        view.onCancelledCallback = action
        
        return view
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {

        let uiImagePicker = UIImagePickerController()
        uiImagePicker.delegate = context.coordinator

        uiImagePicker.sourceType = .camera
        uiImagePicker.mediaTypes = [UTType.image.identifier]
        
        uiImagePicker.cameraDevice = .front

        return uiImagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parentView: CameraView

        init(_ parent: CameraView) {
            self.parentView = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let pictureURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
                return
            }

            parentView.pictureURL = pictureURL

            parentView.dismiss()
        }

        func imagePickerControllerDidCancel(_ imagePickerController: UIImagePickerController) {
            parentView.onCancelledCallback?(imagePickerController)
        }
    }
}
