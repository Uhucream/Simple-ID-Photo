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
    @Environment(\.dismiss) private var dismiss

    @Binding var pictureURL: URL?
    
    @Binding var isLoadingInProgress: Bool

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

            parentView.dismiss()
            
            self.parentView.isLoadingInProgress = true

            guard let provider = results.first?.itemProvider else {
                return
            }

            let typeIdentifier = UTType.image.identifier
            
            guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else {
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let error = error {
                    print("error: \(error)")

                    return
                }
                
                guard let url = url else {
                    return
                }

                let fileName = "\(Int(Date().timeIntervalSince1970)).\(url.pathExtension)"

                let newFileURL: URL = .init(fileURLWithPath: NSTemporaryDirectory() + fileName)

                try? FileManager.default.copyItem(at: url, to: newFileURL)

                self.parentView.pictureURL = newFileURL
                
                self.parentView.isLoadingInProgress = false
            }
        }
    }
}
