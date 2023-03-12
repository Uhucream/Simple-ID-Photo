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
    
    @State private var shouldShowSettingsView: Bool = false
    
    @State private var shouldShowPicturePickerView: Bool = false
    
    @State private var shouldShowCameraView: Bool = false
    
    @State private var shouldShowCreateIDPhotoView: Bool = false
    
    @State private var shouldShowDeleteConfirmDialog: Bool = false
    @State private var shouldShowDeleteAllConfirmDialog: Bool = false
    
    @State private var isPhotoLoadingInProgress: Bool = false
    
    @State private var userSelectedImageURL: URL? = nil
    
    @State private var displayTargetIDPhotoDetailView: AnyView? = nil
    @State private var navigationLinkSelectionForIDPhotoDetailView: Int? = nil
    
    @State private var currentEditMode: EditMode = .inactive
    @State private var deletingTargetHistories: [CreatedIDPhoto] = []
    
    func showSettingsView() -> Void {
        shouldShowSettingsView = true
    }
    
    func showPicturePickerView() -> Void {
        shouldShowPicturePickerView = true
    }
    
    func showCameraView() -> Void {
        shouldShowCameraView = true
    }
    
    func showIDPhotoDetailView(displayingCreatedIDPhoto: CreatedIDPhoto) -> Void {
        self.displayTargetIDPhotoDetailView = AnyView(
            IDPhotoDetailViewContainer(createdIDPhoto: displayingCreatedIDPhoto)
        )
        
        self.navigationLinkSelectionForIDPhotoDetailView = 0
    }
    
    func dismissSettingsView() -> Void {
        shouldShowSettingsView = false
    }
    
    func dismissCreateIDPhotoView() -> Void {
        self.shouldShowCreateIDPhotoView = false
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
            
            let fileManager: FileManager = .default
            
            let temporaryDirectoryURL: URL = fileManager.temporaryDirectory
            let newFileName: String = ProcessInfo.processInfo.globallyUniqueString
            
            let newFileURL: URL = temporaryDirectoryURL
                .appendingPathComponent(newFileName, conformingTo: .fileURL)
                .appendingPathExtension(url.pathExtension)
            
            try? fileManager.copyItem(at: url, to: newFileURL)
            
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
            
            let fileManager: FileManager = .default
            
            let temporaryDirectoryURL: URL = fileManager.temporaryDirectory
            let newFileName: String = ProcessInfo.processInfo.globallyUniqueString
            
            let newFileURL: URL = temporaryDirectoryURL
                .appendingPathComponent(newFileName, conformingTo: .fileURL)
                .appendingPathExtension(url.pathExtension)
            
            try? fileManager.copyItem(at: url, to: newFileURL)

            self.userSelectedImageURL = newFileURL
            
            self.isPhotoLoadingInProgress = false
        }

        return true
    }
    
    func deleteCreatedIDPhotoRecord(_ targetCreatedIDPhoto: CreatedIDPhoto) -> Void {
        do {
            viewContext.delete(targetCreatedIDPhoto)
            
            try viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func deleteCreatedIDPhotoAndSavedFiles(_ targetCreatedIDPhoto: CreatedIDPhoto) -> Void {

        let DEFAULT_FILE_SAVE_ROOT_SEARCH_PATH_DIRECTORY: FileManager.SearchPathDirectory = .libraryDirectory
        
        let sourcePhotoRecord: SourcePhoto? = targetCreatedIDPhoto.sourcePhoto
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
        
        let createdIDPhotoFileName: String? = targetCreatedIDPhoto.imageFileName
        
        let createdIDPhotoSavedDirectory: SavedFilePath? = targetCreatedIDPhoto.savedDirectory
        
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

        deleteCreatedIDPhotoRecord(targetCreatedIDPhoto)
    }
    
    func showDeleteConfirmationDialog() -> Void {
        self.shouldShowDeleteConfirmDialog = true
    }
    
    var body: some View {
        ZStack {
            TopView(
                currentEditMode: $currentEditMode,
                createdIDPhotoHistories: createdIDPhotoHistories,
                dropAllowedFileUTTypes: [.image],
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
            .onDropFile(action: setPictureURLFromDroppedItem)
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
                                deleteCreatedIDPhotoAndSavedFiles(deletingTargetHistory)
                            }
                    }
                ) {
                    Text("削除する")
                }
            } message: { _ in
                Text("削除した証明写真は復元できません")
            }
            .confirmationDialog(
                "本当にすべて削除しますか？",
                isPresented: $shouldShowDeleteAllConfirmDialog,
                titleVisibility: .visible,
                presenting: createdIDPhotoHistories
            ) { createdAllHistories in
                Button(
                    role: .destructive,
                    action: {
                        createdAllHistories
                            .forEach { deletingTargetHistory in
                                deleteCreatedIDPhotoAndSavedFiles(deletingTargetHistory)
                            }
                    }
                ) {
                    Text("削除する")
                }
            } message: { _ in
                Text("削除した証明写真は復元できません")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: {
                            showSettingsView()
                        }
                    ) {
                        Label("設定", systemImage: "gearshape")
                            .labelStyle(.iconOnly)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if createdIDPhotoHistories.count > 0 {
                        EditButton()
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if currentEditMode.isEditing {
                        Button(
                            action: {
                                shouldShowDeleteAllConfirmDialog = true
                            }
                        ) {
                            Text("すべて消去")
                        }
                    }
                }
            }
            .environment(\.editMode, $currentEditMode)
            .onChange(of: createdIDPhotoHistories.count) { newHistoriesCount in
                guard newHistoriesCount == 0 else { return }
                
                self.currentEditMode = .inactive
            }
            
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
        .sheet(isPresented: $shouldShowSettingsView) {
            NavigationView {
                SettingsTopView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(
                                action: {
                                    dismissSettingsView()
                                }
                            ) {
                                Text("閉じる")
                            }
                        }
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
        .fullScreenCover(isPresented: $shouldShowCreateIDPhotoView) {
            if let userSelectedImageURL = userSelectedImageURL {
                CreateIDPhotoViewContainer(
                    sourcePhotoURL: userSelectedImageURL
                )
                .onDoneCreateIDPhotoProcess { newCreatedIDPhoto in
                    self.dismissCreateIDPhotoView()
                    
                    self.showIDPhotoDetailView(displayingCreatedIDPhoto: newCreatedIDPhoto)
                }
            }
        }
        .background {
            NavigationLink(
                destination: displayTargetIDPhotoDetailView,
                tag: 0,
                selection: $navigationLinkSelectionForIDPhotoDetailView
            ) {
                EmptyView()
            }
            .hidden()
        }
        .onChange(of: userSelectedImageURL) { newUserSelectedImageURL in

            let isSelectedImageURLNotNil: Bool = newUserSelectedImageURL != nil
            
            self.shouldShowCreateIDPhotoView = isSelectedImageURLNotNil
        }
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
