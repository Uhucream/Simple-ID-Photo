//
//  TopViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/07
//  
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct TopViewContainer: View {
    @State private var shouldShowPicturePickerView: Bool = false
    
    @State private var shouldShowCameraView: Bool = false
    
    @State private var shouldShowCreateIDPhotoView: Bool = false
    
    @State private var isPhotoLoadingInProgress: Bool = false
    
    @State private var pictureURL: URL? = nil
    
    @State private var createdIDPhotoHistories: [CreatedIDPhotoDetail] = mockHistoriesData
    
    func showPicturePickerView() -> Void {
        shouldShowPicturePickerView = true
    }
    
    func showCameraView() -> Void {
        shouldShowCameraView = true
    }
    
    func setPictureURLFromPHPickerSelectedItem(
        phpickerViewController: PHPickerViewController,
        phpickerResults: [PHPickerResult]
    ) -> Void {
        
        self.isPhotoLoadingInProgress = true
        
        guard let itemProvider = phpickerResults.first?.itemProvider else {
            self.isPhotoLoadingInProgress = false
            
            return
        }
        
        let typeIdentifier = UTType.image.identifier
        
        guard itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier) else {
            self.isPhotoLoadingInProgress = false
            
            return
        }
        
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in

            if let error = error {
                print("error: \(error)")
                
                return
            }
            
            guard let url = url else {
                self.isPhotoLoadingInProgress = false
                
                return
            }
            
            let fileName = "\(Int(Date().timeIntervalSince1970)).\(url.pathExtension)"
            
            let newFileURL: URL = .init(fileURLWithPath: NSTemporaryDirectory() + fileName)
            
            try? FileManager.default.copyItem(at: url, to: newFileURL)
            
            self.pictureURL = newFileURL
            
            self.isPhotoLoadingInProgress = false
        }
    }
    
    func setPictureURLFromDroppedItem(itemProviders: [NSItemProvider]) -> Bool {

        guard let itemProvider = itemProviders.first else { return false }
        
        self.isPhotoLoadingInProgress = true
        
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in

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

            self.pictureURL = newFileURL
            
            self.isPhotoLoadingInProgress = false
        }

        return true
    }
    
    var body: some View {
        ZStack {
            TopView(
                createdIDPhotoHistories: $createdIDPhotoHistories,
                onTapSelectFromAlbumButton: {
                    showPicturePickerView()
                },
                onTapTakePictureButton: {
                    showCameraView()
                }
            )
            
            if self.isPhotoLoadingInProgress {
                Color
                    .clear
                    .ignoresSafeArea()
                    .overlay(.ultraThinMaterial)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .fullScreenCover(isPresented: $shouldShowPicturePickerView) {
            PicturePickerView()
                .onPickerDelegatePickerFuncInvoked { (phpickerViewController, phpickerResults) in
                    setPictureURLFromPHPickerSelectedItem(phpickerViewController: phpickerViewController, phpickerResults: phpickerResults)
                    
                    self.shouldShowPicturePickerView = false
                }
        }
        .fullScreenCover(isPresented: $shouldShowCameraView) {
            //  TODO: 確定後にフリーズするので、独自のカメラUIを実装する
            CameraView(pictureURL: $pictureURL)
        }
        .fullScreenCover(isPresented: $shouldShowCreateIDPhotoView) {
            if let pictureURL = pictureURL,
               let uiimageFromURL = UIImage(url: pictureURL),
               let orientationFixedUIImage = uiimageFromURL.orientationFixed()
            {
                CreateIDPhotoViewContainer(
                    sourceUIImage: orientationFixedUIImage
                )
            }
        }
        .onChange(of: pictureURL) { newPictureURL in
            guard newPictureURL != nil else { return }
            
            shouldShowCreateIDPhotoView = true
        }
        .onDrop(of: [.image], isTargeted: nil, perform: setPictureURLFromDroppedItem)
    }
}

struct TopViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        NavigationView {
            GeometryReader { geometry in
                TopViewContainer()
                    .onAppear {
                        screenSizeHelper.updateSafeAreaInsets(geometry.safeAreaInsets)
                        screenSizeHelper.updateScreenSize(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                    }
                    .onChange(of: geometry.safeAreaInsets) { (safeAreaInsets: EdgeInsets) in
                        screenSizeHelper.updateSafeAreaInsets(safeAreaInsets)
                    }
                    .onChange(of: geometry.size) { (screenSize: CGSize) in
                        screenSizeHelper.updateScreenSize(screenWidth: screenSize.width, screenHeight: screenSize.height)
                    }
            }
            .environmentObject(screenSizeHelper)
        }
    }
}
