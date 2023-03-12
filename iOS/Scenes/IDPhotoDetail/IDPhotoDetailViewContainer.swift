//
//  IDPhotoDetailViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import SwiftUI

struct IDPhotoDetailViewContainer: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var createdIDPhoto: CreatedIDPhoto
    
    @State private var selectedIDPhotoProcess: IDPhotoProcessSelection? = nil
    
    @State private var shouldShowDeleteConfirmationDialog: Bool = false
    
    private func parseCreatedIDPhotoFileURL() -> URL? {
        let DEFAULT_SAVE_DIRECTORY_ROOT: FileManager.SearchPathDirectory = .libraryDirectory
        
        let LIBRARY_DIRECTORY_RAW_VALUE_INT64: Int64 = .init(DEFAULT_SAVE_DIRECTORY_ROOT.rawValue)
        
        let fileManager: FileManager = .default
        
        let fileSaveDestinationRootSearchDirectory: FileManager.SearchPathDirectory = .init(
            rawValue: UInt(
                self.createdIDPhoto.savedDirectory?.rootSearchPathDirectory ?? LIBRARY_DIRECTORY_RAW_VALUE_INT64
            )
        ) ?? DEFAULT_SAVE_DIRECTORY_ROOT
        
        let saveDestinationRootSearchDirectoryPathURL: URL? = fileManager.urls(
            for: fileSaveDestinationRootSearchDirectory,
            in: .userDomainMask
        ).first
        
        let relativePathFromRoot: String = createdIDPhoto.savedDirectory?.relativePathFromRootSearchPath ?? ""
        let fileSaveDestinationURL: URL = .init(
            fileURLWithPath: relativePathFromRoot,
            isDirectory: true,
            relativeTo: saveDestinationRootSearchDirectoryPathURL
        )
        
        let savedPhotoFileName: String? = createdIDPhoto.imageFileName
        
        guard let savedPhotoFileName = savedPhotoFileName else { return nil }
        
        let savedPhotoFileURL: URL = fileSaveDestinationURL
            .appendingPathComponent(savedPhotoFileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: savedPhotoFileURL.path) else { return nil }
        
        return savedPhotoFileURL
    }
    
    private func showEditIDPhotoView(initialDisplayProcess: IDPhotoProcessSelection) -> Void {
        self.selectedIDPhotoProcess = initialDisplayProcess
    }
    
    private func showDeleteConfirmationDialog() -> Void {
        self.shouldShowDeleteConfirmationDialog = true
    }
    
    private func dismissEditIDPhotoView() -> Void {
        self.selectedIDPhotoProcess = nil
    }
    
    private func onTapDeleteButton() -> Void {
        do {
            let DEFAULT_SAVE_ROOT_SEARCH_PATH_DIRECTORY: FileManager.SearchPathDirectory = .libraryDirectory
            
            if let sourcePhotoRecord: SourcePhoto = createdIDPhoto.sourcePhoto {

                guard let sourcePhotoSavedDirectory: SavedFilePath = sourcePhotoRecord.savedDirectory else { return }
                
                let sourcePhotoSavedRootSearchPathDirectory: FileManager.SearchPathDirectory = .init(
                    rawValue: UInt(sourcePhotoSavedDirectory.rootSearchPathDirectory)
                ) ?? DEFAULT_SAVE_ROOT_SEARCH_PATH_DIRECTORY
                
                guard let sourcePhotoFileName: String = sourcePhotoRecord.imageFileName else { return }
                guard let relativePathFromRoot: String = sourcePhotoSavedDirectory.relativePathFromRootSearchPath else { return }
                
                try deleteSavedFile(
                    fileName: sourcePhotoFileName,
                    in: relativePathFromRoot,
                    relativeTo: sourcePhotoSavedRootSearchPathDirectory
                )
            }
            
            guard let createdIDPhotoSavedDirectory: SavedFilePath = createdIDPhoto.savedDirectory else { return }
            
            let createdIDPhotoSavedRootSearchPathDirectory: FileManager.SearchPathDirectory = .init(
                rawValue: UInt(createdIDPhotoSavedDirectory.rootSearchPathDirectory)
            ) ?? DEFAULT_SAVE_ROOT_SEARCH_PATH_DIRECTORY
            
            guard let createdIDPhotoFileName: String = createdIDPhoto.imageFileName else { return }
            guard let relativePathFromRoot: String = createdIDPhotoSavedDirectory.relativePathFromRootSearchPath else { return }
            
            try deleteSavedFile(
                fileName: createdIDPhotoFileName,
                in: relativePathFromRoot,
                relativeTo: createdIDPhotoSavedRootSearchPathDirectory
            )
            
            try deleteThisCreatedIDPhoto()
            
            dismiss()
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        VStack {
            IDPhotoDetailView(
                idPhotoImageURL: Binding<URL?>(
                    get: {
                        return parseCreatedIDPhotoFileURL()
                    },
                    set: { (newImageURL) in
                        self.createdIDPhoto.imageFileName = newImageURL?.absoluteString
                    }
                ),
                idPhotoSizeType: Binding<IDPhotoSizeVariant>(
                    get: {
                        let appliedIDPhotoSize = createdIDPhoto.appliedIDPhotoSize
                        let idPhotoSizeVariant: IDPhotoSizeVariant = IDPhotoSizeVariant(rawValue: Int(appliedIDPhotoSize?.sizeVariant ?? 0)) ?? .original
                        
                        return idPhotoSizeVariant
                    },
                    set: { (newIDPhotoSizeVariant) in
                        createdIDPhoto.appliedIDPhotoSize?.sizeVariant = Int32(newIDPhotoSizeVariant.rawValue)
                    }
                ),
                createdAt: Binding<Date>(
                    get: {
                        let createdDate: Date = createdIDPhoto.createdAt ?? .distantPast
                        
                        return createdDate
                    },
                    set: { (newDate) in
                        createdIDPhoto.createdAt = newDate
                    }
                ),
                updatedAt: Binding<Date>(
                    get: {
                        return self.createdIDPhoto.updatedAt ?? .now
                    }, set: { _ in
                        
                    }
                )
            )
            .onTapChangeSizeButton {
                showEditIDPhotoView(initialDisplayProcess: .size)
            }
            .confirmationDialog(
                "本当に削除しますか？",
                isPresented: $shouldShowDeleteConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button(
                    role: .destructive,
                    action: {
                        onTapDeleteButton()
                    }
                ) {
                    Text("削除する")
                }
            } message: {
                Text("削除した証明写真は復元できません")
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button(
                            action: {
                                showEditIDPhotoView(initialDisplayProcess: .backgroundColor)
                            }
                        ) {
                            Label("背景色を変更", systemImage: "paintbrush")
                        }

                        Button(
                            action: {
                                showEditIDPhotoView(initialDisplayProcess: .size)
                            }
                        ) {
                            Label("サイズを変更", systemImage: "person.crop.rectangle")
                        }
                        
                        Divider()
                        
                        Button(
                            role: .destructive,
                            action: {
                                showDeleteConfirmationDialog()
                            }
                        ) {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fullScreenCover(item: $selectedIDPhotoProcess) { selectedProcess in
                EditIDPhotoViewContainer(
                    initialDisplayProcess: selectedProcess,
                    editTargetCreatedIDPhoto: self.createdIDPhoto
                )
                .onDismiss {
                    dismissEditIDPhotoView()
                }
                .onDoneSaveProcess {
                    dismissEditIDPhotoView()
                }
            }
        }
    }
}

extension IDPhotoDetailViewContainer {
    private func deleteSavedFile(
        fileName: String,
        in relativeFilePathFromRoot: String,
        relativeTo rootSearchPathDirectory: FileManager.SearchPathDirectory,
        with fileManager: FileManager = .default
    ) throws -> Void {
        
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
            throw error
        }
    }
}

extension IDPhotoDetailViewContainer {
    func deleteThisCreatedIDPhoto() throws -> Void {
        do {
            viewContext.delete(self.createdIDPhoto)
            
            try viewContext.save()
        } catch {
            throw error
        }
    }
}

struct IDPhotoDetailViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            
            let mockCreatedIDPhoto: CreatedIDPhoto = .init(
                on: PersistenceController.preview.container.viewContext,
                createdAt: .now.addingTimeInterval(-1000),
                imageFileName: nil,
                updatedAt: .now
            )
            
            let screenSizeHelper: ScreenSizeHelper = .shared
            
            GeometryReader { geometry in
                
                let screenSize: CGSize = geometry.size
                
                IDPhotoDetailViewContainer(createdIDPhoto: mockCreatedIDPhoto)
                    .onAppear {
                        screenSizeHelper.updateScreenSize(screenSize)
                    }
                    .onChange(of: screenSize) { newSize in
                        screenSizeHelper.updateScreenSize(newSize)
                    }
                    .environmentObject(screenSizeHelper)
            }
        }
    }
}
