//
//  EditIDPhotoViewContainer.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/07
//  
//

import SwiftUI
import UIKit
import CoreData
import Combine
import UniformTypeIdentifiers

struct EditIDPhotoViewContainer: View {
    
    private let BACKGROUND_COLORS: [Color] = [
        .idPhotoBackgroundColors.blue,
        .idPhotoBackgroundColors.gray
    ]
    
    @ObservedObject var editTargetCreatedIDPhoto: CreatedIDPhoto
    
    private var visionFrameworkHelper: VisionFrameworkHelper {
        
        let helper: VisionFrameworkHelper = .init(
            sourceCIImage: sourcePhotoCIImage,
            sourceImageOrientation: .init(self.sourceImageOrientation)
        )

        return helper
    }
    
    @State private var sourcePhotoFileURL: URL? = nil
    @State private var sourcePhotoCIImage: CIImage? = nil
    @State private var sourceImageOrientation: UIImage.Orientation = .up
    
    @State private var previewUIImage: UIImage? = nil
    
    @State private var currentSelectedProcess: IDPhotoProcessSelection = .backgroundColor
    
    @State private var selectedBackgroundColor: Color = .idPhotoBackgroundColors.blue
    @State private var selectedIDPhotoSizeVariant: IDPhotoSizeVariant = .original
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    @State private var isBackgroundColorChanged: Bool = false
    @State private var isIDPhotoSizeChanged: Bool = false

    private var hasAnyModifications: Bool {
        return isBackgroundColorChanged || isIDPhotoSizeChanged
    }
    
    private(set) var onDismissCallback: (() -> Void)?
    private(set) var onDoneSaveProcessCallback: (() -> Void)?
    
    init(
        initialDisplayProcess: IDPhotoProcessSelection,
        editTargetCreatedIDPhoto: CreatedIDPhoto
    ) {
        
        _editTargetCreatedIDPhoto = ObservedObject(wrappedValue: editTargetCreatedIDPhoto)
        
        _currentSelectedProcess = State(initialValue: initialDisplayProcess)

        if
            let createdIDPhotoFileName = editTargetCreatedIDPhoto.imageFileName,
            let createdIDPhotoSavedDirectory = editTargetCreatedIDPhoto.savedDirectory
        {

            let createdIDPhotoParsedURL: URL? = parseSavedFileURL(
                fileName: createdIDPhotoFileName,
                savedFilePath: createdIDPhotoSavedDirectory
            )
            
            guard let createdIDPhotoParsedURL = createdIDPhotoParsedURL else { return }
            
            let createdIDPhotoUIImage: UIImage = .init(url: createdIDPhotoParsedURL)
            
            _previewUIImage = .init(initialValue: createdIDPhotoUIImage)
            _sourceImageOrientation = .init(initialValue: createdIDPhotoUIImage.imageOrientation)
        }
        
        let appliedBackgroundColor: AppliedBackgroundColor? = editTargetCreatedIDPhoto.appliedBackgroundColor
        let appliedIDPhotoSize: AppliedIDPhotoSize? = editTargetCreatedIDPhoto.appliedIDPhotoSize
        
        if let appliedBackgroundColor = appliedBackgroundColor {
            _selectedBackgroundColor = State(
                initialValue: Color(
                    red: appliedBackgroundColor.red,
                    green: appliedBackgroundColor.green,
                    blue: appliedBackgroundColor.blue,
                    opacity: appliedBackgroundColor.alpha
                )
            )
        }
        
        if let appliedIDPhotoSize = appliedIDPhotoSize {
            
            let appliedIDPhotoSizeVariant: IDPhotoSizeVariant? = .init(
                rawValue: Int(appliedIDPhotoSize.sizeVariant)
            )
            
            guard let appliedIDPhotoSizeVariant = appliedIDPhotoSizeVariant else { return }
            
            _selectedIDPhotoSizeVariant = .init(initialValue: appliedIDPhotoSizeVariant)
        }
    }
    
    func onDismiss(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onDismissCallback = action
        
        return view
    }
    
    func onDoneSaveProcess(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onDoneSaveProcessCallback = action
        
        return view
    }
    
    func showDismissConfirmationDialog() -> Void {
        shouldShowDiscardViewConfirmationDialog = true
    }
    
    func paintImageBackgroundColor(
        sourceImage: CIImage,
        backgroundColor: Color
    ) async throws -> CIImage? {
        do {
            let solidColorBackgroundUIImage: UIImage? = .init(color: backgroundColor, size: sourceImage.extent.size)
            
            guard let solidColorBackgroundCIImage = solidColorBackgroundUIImage?.ciImage() else { return nil }
            
            let generatedImage: CIImage? = try await visionFrameworkHelper.combineWithBackgroundImage(with: solidColorBackgroundCIImage)
            
            return generatedImage
        } catch {
            throw error
        }
    }
    
    var body: some View {
        EditIDPhotoView(
            selectedProcess: $currentSelectedProcess,
            selectedBackgroundColor: $selectedBackgroundColor,
            selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
            previewUIImage: $previewUIImage,
            shouldDisableDoneButton: Binding<Bool>(
                get: {
                    return !hasAnyModifications
                },
                set: { _ in
                }
            ),
            availableBackgroundColors: BACKGROUND_COLORS
        )
        .onTapDismissButton {
            if hasAnyModifications {
                showDismissConfirmationDialog()
                
                return
            }
            
            onDismissCallback?()
        }
        .onTapDoneButton {
            onDoneSaveProcessCallback?()
        }
        .confirmationDialog(
            "編集を終了しますか？",
            isPresented: $shouldShowDiscardViewConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button(
                role: .destructive,
                action: {
                    onDismissCallback?()
                }
            ) {
                Text("編集を終了")
            }
        } message: {
            Text("加えた変更は保存されません")
        }
        .task {
            guard let sourcePhotoRecord = self.editTargetCreatedIDPhoto.sourcePhoto else { return }
            
            guard let sourcePhotoFileName = sourcePhotoRecord.imageFileName else { return }
            
            guard let sourcePhotoSavedFilePath = sourcePhotoRecord.savedDirectory else { return }
            
            let sourcePhotoFileURL: URL? = self.parseSavedFileURL(
                fileName: sourcePhotoFileName,
                savedFilePath: sourcePhotoSavedFilePath
            )
            
            guard let sourcePhotoFileURL = sourcePhotoFileURL else { return }
            
            let uiImageFromURL: UIImage = .init(url: sourcePhotoFileURL)
            let orientationFixedUIImage: UIImage? = uiImageFromURL.orientationFixed()
            
            self.sourcePhotoCIImage = orientationFixedUIImage?.ciImage()
            
            self.sourcePhotoFileURL = sourcePhotoFileURL
        }
        .onReceive(
            Just(selectedBackgroundColor)
        ) { newSelectedBackgroundColor in
            Task {
                guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
                
                let paintedSourcePhoto: CIImage? = try await paintImageBackgroundColor(
                    sourceImage: sourcePhotoCIImage,
                    backgroundColor: newSelectedBackgroundColor
                )
                
                guard let paintedSourcePhotoUIImage: UIImage = paintedSourcePhoto?.uiImage(orientation: self.sourceImageOrientation) else { return }
                
                Task { @MainActor in
                    self.previewUIImage = paintedSourcePhotoUIImage
                }
            }
        }
        .onReceive(
            Just(selectedIDPhotoSizeVariant)
        ) { newIDPhotoSizeVariant in
            
            let DEFAULT_ID_PHOTO_SIZE_VARIANT: IDPhotoSizeVariant = .original
            let DEFAULT_ID_PHOTO_SIZE_VARIANT_INT32: Int32 = Int32(DEFAULT_ID_PHOTO_SIZE_VARIANT.rawValue)
            
            let currentAppliedIDPhotoSizeOnRecord: IDPhotoSizeVariant = .init(
                rawValue: Int(editTargetCreatedIDPhoto.appliedIDPhotoSize?.sizeVariant ?? DEFAULT_ID_PHOTO_SIZE_VARIANT_INT32)
            ) ?? DEFAULT_ID_PHOTO_SIZE_VARIANT
            
            let isIDPhotoSizeChanged: Bool = newIDPhotoSizeVariant != currentAppliedIDPhotoSizeOnRecord
            
            self.isIDPhotoSizeChanged = isIDPhotoSizeChanged
        }
        .onReceive(
            Just(selectedBackgroundColor)
        ) { newBackgroundColor in
            
            let originalBackgroundColorComponents: AppliedBackgroundColor? = editTargetCreatedIDPhoto.appliedBackgroundColor
            let newBackgroundColorComponents: RGBAColorComponents? = newBackgroundColor.rgba
            
            let isRedChanged: Bool = newBackgroundColorComponents?.red != CGFloat(originalBackgroundColorComponents?.red ?? 0)
            let isGreenChanged: Bool = newBackgroundColorComponents?.green != CGFloat(originalBackgroundColorComponents?.green ?? 0)
            let isBlueChanged: Bool = newBackgroundColorComponents?.blue != CGFloat(originalBackgroundColorComponents?.blue ?? 0)
            let isAlphaChanged: Bool = newBackgroundColorComponents?.alpha != CGFloat(originalBackgroundColorComponents?.alpha ?? 0)
            
            let isBackgroundColorChanged: Bool = isRedChanged || isGreenChanged || isBlueChanged || isAlphaChanged
            
            self.isBackgroundColorChanged = isBackgroundColorChanged
        }
    }
}

extension EditIDPhotoViewContainer {
    func parseSavedFileURL(
        fileName: String,
        savedFilePath: SavedFilePath
    ) -> URL? {
        
        let fileManager: FileManager = .default
        
        let parentDirectoryPathURL: URL? = savedFilePath.parseToDirectoryFileURL()
        
        guard let parentDirectoryPathURL = parentDirectoryPathURL else { return nil }
        
        let filePathURL: URL = parentDirectoryPathURL
            .appendingPathComponent(fileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: filePathURL.path) else { return nil }
        
        return filePathURL
    }
}

struct EditIDPhotoViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        
        let persistenceController: PersistenceController = .preview
        let viewContext: NSManagedObjectContext = persistenceController.container.viewContext
        
        let fetchRequestOfCreatedIDPhoto: NSFetchRequest<CreatedIDPhoto> = {
            let fetchRequest: NSFetchRequest<CreatedIDPhoto> = CreatedIDPhoto.fetchRequest()
            
            fetchRequest.fetchLimit = 1
            
            return fetchRequest
        }()
        
        let mockCreatedIDPhotoRecord: CreatedIDPhoto = {
            let createdIDPhoto: CreatedIDPhoto? = try? viewContext.fetch(fetchRequestOfCreatedIDPhoto).first
            
            if let createdIDPhoto = createdIDPhoto {
                return createdIDPhoto
            }
            
            let imageFileName: String = "SampleIDPhoto"
            
            let createdFileURL: URL? = UIImage(named: imageFileName)!.saveOnLibraryCachesForTest(fileName: imageFileName)
            
            let createdFileNameWithExtension: String? = createdFileURL?.lastPathComponent
            
            return .init(
                on: viewContext,
                createdAt: .distantPast,
                imageFileName: createdFileNameWithExtension,
                updatedAt: .now,
                savedDirectory: SavedFilePath(
                    on: viewContext,
                    rootSearchPathDirectory: .cachesDirectory,
                    relativePathFromRootSearchPath: ""
                )
            )
        }()
        
        EditIDPhotoViewContainer(
            initialDisplayProcess: .backgroundColor,
            editTargetCreatedIDPhoto: mockCreatedIDPhotoRecord
        )
        .environment(\.managedObjectContext, viewContext)
    }
}
