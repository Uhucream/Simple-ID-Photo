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
    
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(
        entity: CreatedIDPhoto.entity(),
        sortDescriptors: [
            .init(
                keyPath: \CreatedIDPhoto.createdAt,
                ascending: false
            )
        ]
    ) var createdIDPhotoHistories: FetchedResults<CreatedIDPhoto>
    
    @State private var shouldShowPicturePickerView: Bool = false
    
    @State private var shouldShowCameraView: Bool = false
    
    @State private var shouldShowCreateIDPhotoView: Bool = false
    
    @State private var isPhotoLoadingInProgress: Bool = false
    
    @State private var userSelectedImageURL: URL? = nil
    
    func showPicturePickerView() -> Void {
        shouldShowPicturePickerView = true
    }
    
    func showCameraView() -> Void {
        shouldShowCameraView = true
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

            self.userSelectedImageURL = newFileURL
            
            self.isPhotoLoadingInProgress = false
        }

        return true
    }
    
    var body: some View {
        ZStack {
            TopView(
                createdIDPhotoHistories: createdIDPhotoHistories,
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
            PicturePickerView(
                pictureURL: $userSelectedImageURL,
                isLoadingInProgress: $isPhotoLoadingInProgress
            )
            .onPictureSelected {
                self.shouldShowPicturePickerView = false
            }
        }
        .fullScreenCover(isPresented: $shouldShowCameraView) {
            CameraView(pictureURL: $userSelectedImageURL)
        }
        .onChange(of: userSelectedImageURL) { newSelectedImageURL in
            guard newSelectedImageURL != nil else { return }
            
            shouldShowCreateIDPhotoView = true
        }
        .onDrop(of: [.image], isTargeted: nil, perform: setPictureURLFromDroppedItem)
        .background {
            NavigationLink(isActive: $shouldShowCreateIDPhotoView) {
                if let pictureURL = userSelectedImageURL,
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
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(screenSizeHelper)
        }
    }
}
