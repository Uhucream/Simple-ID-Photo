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
    
    private(set) var onPickedPictureCallback: ((UIImagePickerController, [UIImagePickerController.InfoKey: Any]) -> Void)?
    
    private(set) var onCancelledCallback: ((UIImagePickerController) -> Void)?
    
    func onPickedPicture(action: @escaping (UIImagePickerController, [UIImagePickerController.InfoKey: Any]) -> Void) -> Self {
        var view = self
        
        view.onPickedPictureCallback = action
        
        return view
    }
    
    func onCancelled(action: @escaping (UIImagePickerController) -> Void) -> Self {
        var view = self
        
        view.onCancelledCallback = action
        
        return view
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {

        let imagePickerController = UIImagePickerController()

        imagePickerController.delegate = context.coordinator

        imagePickerController.sourceType = .camera
        imagePickerController.mediaTypes = [UTType.image.identifier]
        
        imagePickerController.cameraDevice = .front
        imagePickerController.cameraFlashMode = .off

        return imagePickerController
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
            parentView.onPickedPictureCallback?(picker, info)
        }

        func imagePickerControllerDidCancel(_ imagePickerController: UIImagePickerController) {
            parentView.onCancelledCallback?(imagePickerController)
        }
    }
}
