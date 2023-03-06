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
    
    private static let SOURCE_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH: FileManager.SearchPathDirectory = .libraryDirectory
    private static let SOURCE_PHOTO_SAVE_FOLDER_NAME: String = "SourcePhotos"
    
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
    
    @State private var shouldShowDeleteConfirmDialog: Bool = false
    
    @State private var isPhotoLoadingInProgress: Bool = false
    
    @State private var userSelectedImageURL: URL? = nil
    
    @State private var createdSourcePhotoRecord: SourcePhoto? = nil
    
    @State private var currentEditMode: EditMode = .inactive
    @State private var deletingTargetHistories: [CreatedIDPhoto] = []
    
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
            
            let sourcePhotosDirectoryURL: URL? = fetchOrCreateDirectoryURL(
                directoryName: TopViewContainer.SOURCE_PHOTO_SAVE_FOLDER_NAME,
                relativeTo: TopViewContainer.SOURCE_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH
            )
            
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
            
            let sourcePhotosDirectoryURL: URL? = fetchOrCreateDirectoryURL(
                directoryName: TopViewContainer.SOURCE_PHOTO_SAVE_FOLDER_NAME,
                relativeTo: TopViewContainer.SOURCE_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH
            )
            
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
    
    func registerNewSourcePhotoRecord(
        imageURL: URL
    ) -> SourcePhoto? {
        do {
            
            let ciImageFromURL: CIImage? = .init(contentsOf: imageURL)
            
            let imageProperties: [String: Any]? = ciImageFromURL?.properties
            let imageExif = imageProperties?[kCGImagePropertyExifDictionary as String] as? [String: Any]
            
            let imageShotDateString: String? = imageExif?[kCGImagePropertyExifDateTimeOriginal as String] as? String
            
            var dateFormatterForExif: DateFormatter {
                
                let formatter: DateFormatter = .init()
                
                formatter.locale = NSLocale.system
                formatter.dateFormat =  "yyyy:MM:dd HH:mm:ss"
                
                return formatter
            }
            
            let imageShotDate: Date? = dateFormatterForExif.date(from: imageShotDateString ?? "")
            
            let sourcePhotoSavedDirectory: SavedFilePath = .init(
                on: viewContext,
                rootSearchPathDirectory: TopViewContainer.SOURCE_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH,
                relativePathFromRootSearchPath: TopViewContainer.SOURCE_PHOTO_SAVE_FOLDER_NAME
            )
            
            let newSourcePhoto: SourcePhoto = .init(
                on: self.viewContext,
                imageFileName: imageURL.lastPathComponent,
                shotDate: imageShotDate ?? .now,
                savedDirectory: sourcePhotoSavedDirectory
            )
            
            try viewContext.save()
            
            return newSourcePhoto
        } catch {
            print(error)
            
            return nil
        }
    }
    
    func deleteCreatedIDPhotoRecord(_ targetCreatedIDPhoto: CreatedIDPhoto) -> Void {
        do {
            if let appliedBackgroundColorRecord = targetCreatedIDPhoto.appliedBackgroundColor {
                viewContext.delete(appliedBackgroundColorRecord)
            }
            
            if let faceHeightRecord = targetCreatedIDPhoto.appliedIDPhotoSize?.faceHeight {
                viewContext.delete(faceHeightRecord)
            }
            
            if let marginsAroundFaceRecord = targetCreatedIDPhoto.appliedIDPhotoSize?.marginsAroundFace {
                viewContext.delete(marginsAroundFaceRecord)
            }
            
            if let appliedIDPhotoSizeRecord = targetCreatedIDPhoto.appliedIDPhotoSize {
                viewContext.delete(appliedIDPhotoSizeRecord)
            }
            
            if let sourcePhotoSavedDirectoryRecord = targetCreatedIDPhoto.sourcePhoto?.savedDirectory {
                viewContext.delete(sourcePhotoSavedDirectoryRecord)
            }
            
            if let sourcePhotoRecord = targetCreatedIDPhoto.sourcePhoto {
                viewContext.delete(sourcePhotoRecord)
            }
            
            if let createdIDPhotoSavedDirectoryRecord = targetCreatedIDPhoto.savedDirectory {
                viewContext.delete(createdIDPhotoSavedDirectoryRecord)
            }
            
            viewContext.delete(targetCreatedIDPhoto)
            
            try viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func showDeleteConfirmationDialog() -> Void {
        self.shouldShowDeleteConfirmDialog = true
    }
    
    var body: some View {
        ZStack {
            TopView(
                currentEditMode: $currentEditMode,
                createdIDPhotoHistories: createdIDPhotoHistories,
                onTapSelectFromAlbumButton: {
                    showPicturePickerView()
                },
                onTapTakePictureButton: {
                    showCameraView()
                }
            )
            .onDeleteHistoryCard { deletingTargetHistories in
                self.deletingTargetHistories = deletingTargetHistories
                
                self.showDeleteConfirmationDialog()
            }
            .confirmationDialog(
                "本当に削除しますか？",
                isPresented: $shouldShowDeleteConfirmDialog,
                titleVisibility: .visible,
                presenting: deletingTargetHistories
            ) { deletingTargetHistories in
                Button(
                    role: .destructive,
                    action: {
                        
                        deletingTargetHistories
                            .forEach { deletingTargetHistory in
                                
                                let DEFAULT_FILE_SAVE_ROOT_SEARCH_PATH_DIRECTORY: FileManager.SearchPathDirectory = .libraryDirectory
                                
                                let sourcePhotoRecord: SourcePhoto? = deletingTargetHistory.sourcePhoto
                                let sourcePhotoFileName: String? = sourcePhotoRecord?.imageFileName
                                
                                let sourcePhotoSavedDirectory: SavedFilePath? = sourcePhotoRecord?.savedDirectory
                                
                                if
                                    let sourcePhotoFileName = sourcePhotoFileName,
                                    let sourcePhotoSavedDirectory = sourcePhotoSavedDirectory
                                {
                                 
                                    let destinationRootSearchPathDirectory: FileManager.SearchPathDirectory = .init(
                                        rawValue:  UInt(sourcePhotoSavedDirectory.rootSearchPathDirectory)
                                    ) ?? DEFAULT_FILE_SAVE_ROOT_SEARCH_PATH_DIRECTORY
                                    
                                    deleteSavedFile(
                                        fileName: sourcePhotoFileName,
                                        in: sourcePhotoSavedDirectory.relativePathFromRootSearchPath ?? "",
                                        relativeTo: destinationRootSearchPathDirectory
                                    )
                                }
                                
                                let createdIDPhotoFileName: String? = deletingTargetHistory.imageFileName
                                
                                let createdIDPhotoSavedDirectory: SavedFilePath? = deletingTargetHistory.savedDirectory
                                
                                if
                                    let createdIDPhotoFileName = createdIDPhotoFileName,
                                    let createdIDPhotoSavedDirectory = createdIDPhotoSavedDirectory
                                {
                                 
                                    let destinationRootSearchPathDirectory: FileManager.SearchPathDirectory = .init(
                                        rawValue:  UInt(createdIDPhotoSavedDirectory.rootSearchPathDirectory)
                                    ) ?? DEFAULT_FILE_SAVE_ROOT_SEARCH_PATH_DIRECTORY
                                    
                                    deleteSavedFile(
                                        fileName: createdIDPhotoFileName,
                                        in: createdIDPhotoSavedDirectory.relativePathFromRootSearchPath ?? "",
                                        relativeTo: destinationRootSearchPathDirectory
                                    )
                                }
                                
                                
                                deleteCreatedIDPhotoRecord(deletingTargetHistory)
                            }
                    }
                ) {
                    Text("削除する")
                }
            } message: { _ in
                Text("削除した証明写真は復元できません")
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if createdIDPhotoHistories.count > 0 {
                        EditButton()
                    }
                }
            }
            .environment(\.editMode, $currentEditMode)
            
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
            CameraView(pictureURL: $userSelectedImageURL)
        }
        .fullScreenCover(item: $createdSourcePhotoRecord) { sourcePhotoRecord in
            if let pictureURL = userSelectedImageURL,
               let uiimageFromURL = UIImage(url: pictureURL),
               let orientationFixedUIImage = uiimageFromURL.orientationFixed()
            {
                CreateIDPhotoViewContainer(
                    sourcePhotoRecord: sourcePhotoRecord,
                    sourceUIImage: orientationFixedUIImage
                )
            }
        }
        .onChange(of: userSelectedImageURL) { newUserSelectedImageURL in

            guard let newUserSelectedImageURL = newUserSelectedImageURL else { return }
            
            let newSourcePhotoRecord: SourcePhoto? = registerNewSourcePhotoRecord(imageURL: newUserSelectedImageURL)
            
            self.createdSourcePhotoRecord = newSourcePhotoRecord
        }
        .onDrop(of: [.image], isTargeted: nil, perform: setPictureURLFromDroppedItem)
    }
}

extension TopViewContainer {

    private func deleteSavedFile(
        fileName: String,
        in relativeFilePathFromRoot: String,
        relativeTo rootSearchPathDirectory: FileManager.SearchPathDirectory,
        with fileManager: FileManager = .default
    ) -> Void {
        
        let fileSaveRootDirectoryURL: URL? = fileManager.urls(for: rootSearchPathDirectory, in: .userDomainMask).first
        
        let fileSaveDestinationURL: URL = .init(
            fileURLWithPath: relativeFilePathFromRoot,
            isDirectory: true,
            relativeTo: fileSaveRootDirectoryURL
        )
        
        let savedFilePathURL: URL = fileSaveDestinationURL
            .appendingPathComponent(fileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: savedFilePathURL.path) else { return }
        
        do {
            try fileManager.removeItem(at: savedFilePathURL)
        } catch {
            print(error)
        }
    }
    
    private func fetchOrCreateDirectoryURL(directoryName: String, relativeTo searchPathDirectory: FileManager.SearchPathDirectory) -> URL? {
        let fileManager: FileManager = .default
        
        let searchPathDirectoryURL: URL? = fileManager.urls(for: searchPathDirectory, in: .userDomainMask).first
        
        guard let searchPathDirectoryURL = searchPathDirectoryURL else { return nil }
        
        let targetDirectoryURL: URL = searchPathDirectoryURL
            .appendingPathComponent(directoryName, conformingTo: .directory)
        
        var objcTrue: ObjCBool = .init(true)
        
        let isTargetDirectoryExists: Bool = fileManager.fileExists(atPath: targetDirectoryURL.path, isDirectory: &objcTrue)
        
        if isTargetDirectoryExists {
            return targetDirectoryURL
        }
        
        do {
            try fileManager.createDirectory(at: targetDirectoryURL, withIntermediateDirectories: true)
            
            return targetDirectoryURL
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
