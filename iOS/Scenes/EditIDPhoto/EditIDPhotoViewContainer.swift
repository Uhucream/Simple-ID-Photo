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
    
    private var detectedFaceRect: CGRect {
        get async throws {
            try await detectFaceRect() ?? .zero
        }
    }
    
    @State private var sourcePhotoFileURL: URL? = nil
    @State private var sourcePhotoCIImage: CIImage? = nil
    @State private var sourceImageOrientation: UIImage.Orientation = .up

    @State private var originalSizeIDPhoto: CIImage? = nil
    
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
    
    func detectFaceRect() async throws -> CGRect? {
        do {
            let detectedRect: CGRect? = try await visionFrameworkHelper.detectFaceIncludingHairRectangle()
            
            return detectedRect
        } catch {
            throw error
        }
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
    
    func croppingImage(
        sourceImage: CIImage,
        sizeVariant: IDPhotoSizeVariant
    ) async -> CIImage? {
        
        guard let detectedFaceRect = try? await detectedFaceRect else { return nil }
        
        if detectedFaceRect == .zero { return nil }
        
        let faceHeightRatio: Double = sizeVariant.photoSize.faceHeight.value / sizeVariant.photoSize.height.value
        
        let idPhotoAspectRatio: Double = sizeVariant.photoSize.width.value / sizeVariant.photoSize.height.value
        
        let idPhotoHeight: CGFloat = detectedFaceRect.height / faceHeightRatio
        let idPhotoWidth: CGFloat = idPhotoHeight * idPhotoAspectRatio
        
        let marginTopRatio: Double = sizeVariant.photoSize.marginTop.value / sizeVariant.photoSize.height.value
        
        let marginTop: CGFloat = idPhotoHeight * marginTopRatio
        
        let remainderWidthOfFaceAndPhoto: CGFloat = idPhotoWidth - detectedFaceRect.size.width
        
        let originXOfCroppingRect: CGFloat = detectedFaceRect.origin.x - (remainderWidthOfFaceAndPhoto / 2)
        let originYOfCroppingRect: CGFloat = (detectedFaceRect.maxY + marginTop) - idPhotoHeight
        
        let croppingRect: CGRect = .init(
            origin: CGPoint(
                x: originXOfCroppingRect,
                y: originYOfCroppingRect
            ),
            size: CGSize(
                width: idPhotoWidth,
                height: idPhotoHeight
            )
        )
        
        let croppedImage = sourceImage.cropped(to: croppingRect)
        
        return croppedImage
    }
    
    //  TODO: パスポートサイズの対応
    //    func cropingImageAsPassportSize(sourceImage: CIImage) -> Void {
    //
    //    }
    
    func composeIDPhoto(
        sourcePhoto: CIImage,
        idPhotoSizeVariant: IDPhotoSizeVariant,
        backgroundColor: Color
    ) async -> CIImage? {
        do {
            let paintedSourcePhoto: CIImage? = try await paintImageBackgroundColor(
                sourceImage: sourcePhoto,
                backgroundColor: backgroundColor
            )
            
            if idPhotoSizeVariant == .original {
                return paintedSourcePhoto
            }
            
//            if idPhotoSizeVariant == .passport {
//                let croppedImage: CIImage? = cropingImageAsPassportSize(sourceImage: paintedSourcePhoto)
//
//                return croppedImage
//            }

            if idPhotoSizeVariant == .passport {
                return nil
            }
            
            guard let paintedSourcePhoto = paintedSourcePhoto else { return nil }
            
            let croppedImage: CIImage? = await croppingImage(sourceImage: paintedSourcePhoto, sizeVariant: idPhotoSizeVariant)
            
            return croppedImage
        } catch {
            print(error)
            
            return nil
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
        .task {
            guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
            
            let originalAppliedBackgroundColor: AppliedBackgroundColor? = editTargetCreatedIDPhoto.appliedBackgroundColor
            
            let composedCIImage: CIImage? = await composeIDPhoto(
                sourcePhoto: sourcePhotoCIImage,
                idPhotoSizeVariant: .original,
                backgroundColor: Color(
                    red: originalAppliedBackgroundColor?.red ?? 0,
                    green: originalAppliedBackgroundColor?.green ?? 0,
                    blue: originalAppliedBackgroundColor?.blue ?? 0,
                    opacity: originalAppliedBackgroundColor?.alpha ?? 0
                )
            )
            
            Task { @MainActor in
                self.originalSizeIDPhoto = composedCIImage
            }
        }
        .onReceive(
            Just(selectedIDPhotoSizeVariant)
                .combineLatest(Just(selectedBackgroundColor))
        ) { newSelectedSizeVariant, newSelectedBackgroundColor in
            Task {
                guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
                
                let composedIDPhoto: CIImage? = await self.composeIDPhoto(
                    sourcePhoto: sourcePhotoCIImage,
                    idPhotoSizeVariant: newSelectedSizeVariant,
                    backgroundColor: newSelectedBackgroundColor
                )
                
                guard let composedIDPhotoUIImage: UIImage = composedIDPhoto?.uiImage(orientation: self.sourceImageOrientation) else { return }
                
                Task { @MainActor in
                    self.previewUIImage = composedIDPhotoUIImage
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

//  MARK: ファイル操作関連
extension EditIDPhotoViewContainer {
    
    func createImageFile(
        fileManager: FileManager = .default,
        image: CIImage,
        fileName: String,
        fileType: UTType,
        saveDestination: URL
    ) throws -> URL? {
        do {
            let ciContext: CIContext = .init()
            
            let filePathURL: URL = saveDestination
                .appendingPathComponent(fileName, conformingTo: fileType)
            
            if fileType == .jpeg {
                let jpegData: Data? = image.jpegData(
                    ciContext: ciContext,
                    colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                )
                
                try jpegData?.write(to: filePathURL)
                
                return filePathURL
            }
            
            let heifData: Data? = image.heifData(
                ciContext: ciContext,
                format: .RGBA8,
                colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            )
            
            try heifData?.write(to: filePathURL)
            
            return filePathURL
        } catch {
            throw error
        }
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
