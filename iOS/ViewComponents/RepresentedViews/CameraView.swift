//
//  CameraView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/06
//  
//

import SwiftUI
import UniformTypeIdentifiers

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    @Binding var pictureURL: URL?

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

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parentView.dismiss()
        }
    }
}
