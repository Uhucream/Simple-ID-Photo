//
//  TopViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/07
//  
//

import SwiftUI
import UniformTypeIdentifiers

struct TopViewContainer: View {
    @State private var shouldShowPicturePickerView: Bool = false
    
    @State private var shouldShowCameraView: Bool = false
    
    @State private var shouldShowCreateIDPhotoView: Bool = false
    
    @State private var isThisViewDisappeared: Bool = false
    
    @State private var pictureURL: URL? = nil
    
    func showPicturePickerView() -> Void {
        shouldShowPicturePickerView = true
    }
    
    func showCameraView() -> Void {
        shouldShowCameraView = true
    }
    
    func setPictureURLFromDroppedItem(itemProviders: [NSItemProvider]) -> Bool {

        guard let itemProvider = itemProviders.first else { return false }
        
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
        }

        return true
    }
    
    var body: some View {
        ZStack {
            TopView(
                onTapSelectFromAlbumButton: {
                    showPicturePickerView()
                },
                onTapTakePictureButton: {
                    showCameraView()
                }
            )
            
            if self.pictureURL != nil && !self.isThisViewDisappeared {
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
            PicturePickerView(pictureURL: $pictureURL)
        }
        .fullScreenCover(isPresented: $shouldShowCameraView) {
            CameraView(pictureURL: $pictureURL)
        }
        .onDisappear {
            isThisViewDisappeared = true
        }
        .onChange(of: pictureURL) { newPictureURL in
            guard newPictureURL != nil else { return }
            
            shouldShowCreateIDPhotoView = true
        }
        .onDrop(of: [.image], isTargeted: nil, perform: setPictureURLFromDroppedItem)
        .background {
            NavigationLink(isActive: $shouldShowCreateIDPhotoView) {
                if let pictureURL = pictureURL,
                   let uiimageFromURL = UIImage(url: pictureURL),
                   let orientationFixedUIImage = uiimageFromURL.orientationFixed()
                {
                    CreateIDPhotoViewContainer(
                        sourceUIImage: orientationFixedUIImage
                    )
                }
            } label: {
                Color.clear
            }
            .isDetailLink(false)
        }
    }
}

struct TopViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let screenSizeHelper: ScreenSizeHelper = .shared
        
        NavigationView {
            GeometryReader { geometry in
                TopViewContainer()
                    .onAppear {
                        screenSizeHelper.update(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                    }
                    .onChange(of: geometry.size) { (screenSize: CGSize) in
                        screenSizeHelper.update(screenWidth: screenSize.width, screenHeight: screenSize.height)
                    }
            }
            .environmentObject(screenSizeHelper)
        }
    }
}
