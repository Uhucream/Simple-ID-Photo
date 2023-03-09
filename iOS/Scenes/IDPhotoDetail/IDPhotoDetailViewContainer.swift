//
//  IDPhotoDetailViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import SwiftUI

struct IDPhotoDetailViewContainer: View {
    
    @ObservedObject var createdIDPhoto: CreatedIDPhoto
    
    @State private var selectedIDPhotoProcess: IDPhotoProcessSelection? = nil
    
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
    
    private func dismissEditIDPhotoView() -> Void {
        self.selectedIDPhotoProcess = nil
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

struct IDPhotoDetailViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let mockCreatedIDPhoto: CreatedIDPhoto = .init(
                on: PersistenceController.preview.container.viewContext,
                createdAt: .now.addingTimeInterval(-1000),
                imageFileName: nil,
                updatedAt: .now
            )
            
            IDPhotoDetailViewContainer(createdIDPhoto: mockCreatedIDPhoto)
        }
    }
}
