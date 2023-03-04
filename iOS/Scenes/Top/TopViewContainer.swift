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
    
    private var libraryRootDirectoryURL: URL? {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
    }
    
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
            
            let sourcePhotosDirectoryURL: URL? = fetchSourcePhotosDirectoryURL()
            
            guard let sourcePhotosDirectoryURL: URL = sourcePhotosDirectoryURL else { return }

            let fileName = ProcessInfo.processInfo.globallyUniqueString

            let newFileURL: URL = sourcePhotosDirectoryURL
                .appendingPathComponent(fileName)
                .appendingPathExtension(url.pathExtension)
            
            try? FileManager.default.copyItem(at: url, to: newFileURL)
            
            self.userSelectedImageURL = newFileURL
            
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
            
            let sourcePhotosDirectoryURL: URL? = fetchSourcePhotosDirectoryURL()
            
            guard let sourcePhotosDirectoryURL: URL = sourcePhotosDirectoryURL else { return }

            let fileName = ProcessInfo.processInfo.globallyUniqueString

            let newFileURL: URL = sourcePhotosDirectoryURL
                .appendingPathComponent(fileName)
                .appendingPathExtension(url.pathExtension)

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
            PicturePickerView()
                .onPickerDelegatePickerFuncInvoked { (phpickerViewController, phpickerResults) in
                    setPictureURLFromPHPickerSelectedItem(phpickerViewController: phpickerViewController, phpickerResults: phpickerResults)
                    
                    Task(priority: .userInitiated) {
                        do {
                            let oneMillisecond: UInt64 = 1_000_000
                            
                            self.shouldShowPicturePickerView = false
                            
                            //  MARK: これがないと、すぐに fullScreenCover が表示されてしまい、一瞬画面が真っ黒になる
                            try await Task.sleep(nanoseconds: oneMillisecond * 90)
                            
                            self.shouldShowCreateIDPhotoView = true
                        } catch {
                            print(error)
                        }
                    }
                }
        }
        .fullScreenCover(isPresented: $shouldShowCameraView) {
            //  TODO: 確定後にフリーズするので、独自のカメラUIを実装する
            CameraView(pictureURL: $userSelectedImageURL)
        }
        .fullScreenCover(isPresented: $shouldShowCreateIDPhotoView) {
            if let pictureURL = userSelectedImageURL,
               let uiimageFromURL = UIImage(url: pictureURL),
               let orientationFixedUIImage = uiimageFromURL.orientationFixed()
            {
                CreateIDPhotoViewContainer(
                    sourceUIImage: orientationFixedUIImage
                )
            }
        }
        .onDrop(of: [.image], isTargeted: nil, perform: setPictureURLFromDroppedItem)
    }
}

extension TopViewContainer {
    private func fetchSourcePhotosDirectoryURL() -> URL? {
        let fileManager: FileManager = .default
        
        guard let libraryRootDirectoryURL = libraryRootDirectoryURL else { return nil }
        
        let sourcePhotosDirectoryURL: URL = libraryRootDirectoryURL.appendingPathComponent("SourcePhotos", conformingTo: .directory)
        
        var objcTrue: ObjCBool = .init(true)
        
        let isSourcePhotosDirectoryExists: Bool  = fileManager.fileExists(atPath: sourcePhotosDirectoryURL.path, isDirectory: &objcTrue)
        
        if isSourcePhotosDirectoryExists {
            return sourcePhotosDirectoryURL
        }
        
        do {
            try fileManager.createDirectory(at: sourcePhotosDirectoryURL, withIntermediateDirectories: true)
            
            return sourcePhotosDirectoryURL
        } catch {
            print(error)
            
            return nil
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
