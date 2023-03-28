//
//  EditIDPhotoViewContainer.swift
//  Simple ID Photo (iOS)
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
        .idPhotoBackgroundColors.gray,
        .idPhotoBackgroundColors.white,
        .idPhotoBackgroundColors.brown
    ]
    
    @Environment(\.managedObjectContext) private var viewContext
    
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
    
    private var availableIDPhotoSizeVariants: [IDPhotoSizeVariant] {
        let allVariants: [IDPhotoSizeVariant] = IDPhotoSizeVariant.allCases
        
        let variantsWithoutPassportAndCustom = allVariants.filter { variant in
            
            let isPassport: Bool = variant == .passport
            let isCustom: Bool = variant == .custom
            
            //  MARK: パスポートサイズを除外している都合上、通常の w35_45 だけ表示すると混乱を招く可能性があるので除外
            let is35_45: Bool = variant == .w35_h45
            
            return !(isPassport || isCustom || is35_45)
        }
        
        return variantsWithoutPassportAndCustom
    }
    
    @State private var originalCreatedIDPhotoFileURL: URL? = nil
    
    @State private var sourcePhotoFileURL: URL? = nil
    @State private var sourcePhotoCIImage: CIImage? = nil
    @State private var sourceImageOrientation: UIImage.Orientation = .up

    @State private var previewUIImage: UIImage? = nil
    
    @State private var currentSelectedProcess: IDPhotoProcessSelection = .backgroundColor
    
    @State private var selectedBackgroundColor: Color = .idPhotoBackgroundColors.blue
    @State private var selectedIDPhotoSizeVariant: IDPhotoSizeVariant = .original
    
    @State private var selectedBackgroundColorLabel: String = ""
    
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
            
            _originalCreatedIDPhotoFileURL = State(initialValue: createdIDPhotoParsedURL)
            
            let createdIDPhotoUIImage: UIImage = .init(url: createdIDPhotoParsedURL)
            
            _previewUIImage = .init(initialValue: createdIDPhotoUIImage)
            _sourceImageOrientation = .init(initialValue: createdIDPhotoUIImage.imageOrientation)
        }
        
        let appliedBackgroundColor: AppliedBackgroundColor? = editTargetCreatedIDPhoto.appliedBackgroundColor
        let appliedIDPhotoSize: AppliedIDPhotoSize? = editTargetCreatedIDPhoto.appliedIDPhotoSize
        
        if let appliedBackgroundColor = appliedBackgroundColor {
            
            let colorFromEntity: Color = .init(
                red: appliedBackgroundColor.red,
                green: appliedBackgroundColor.green,
                blue: appliedBackgroundColor.blue,
                opacity: appliedBackgroundColor.alpha
            )
            
            _selectedBackgroundColorLabel = State(initialValue: generateBackgroundColorLabel(colorFromEntity))
            
            _selectedBackgroundColor = State(initialValue: colorFromEntity)
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
            var paintedSourcePhoto: CIImage? {
                get async throws {
                    if backgroundColor == .clear {
                        return sourcePhoto
                    }
                    
                    return try await paintImageBackgroundColor(
                        sourceImage: sourcePhoto,
                        backgroundColor: backgroundColor
                    )
                }
            }
            
            guard let paintedSourcePhoto = try await paintedSourcePhoto else { return nil }
            
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
            
            let croppedImage: CIImage? = await croppingImage(sourceImage: paintedSourcePhoto, sizeVariant: idPhotoSizeVariant)
            
            return croppedImage
        } catch {
            print(error)
            
            return nil
        }
    }
    
    func generateBackgroundColorLabel(_ color: Color) -> String {
        
        let colorRGBA: RGBAColorComponents? = color.rgba
        
        if
            let colorRGBA = colorRGBA,
            let clearRGBA = Color.clear.rgba,
            colorRGBA == clearRGBA
        {
            return "背景色なし"
        }
        
        if
            let colorRGBA = colorRGBA,
            let blueRGBA = Color.idPhotoBackgroundColors.blue.rgba,
            colorRGBA == blueRGBA
        {
            return "青"
        }
        
        if
            let colorRGBA = colorRGBA,
            let grayRGBA = Color.idPhotoBackgroundColors.gray.rgba,
            colorRGBA == grayRGBA
        {
            return "グレー"
        }
        
        if
            let colorRGBA = colorRGBA,
            let whiteRGBA = Color.idPhotoBackgroundColors.white.rgba,
            colorRGBA == whiteRGBA
        {
            return "白"
        }
        
        if
            let colorRGBA = colorRGBA,
            let brownRGBA = Color.idPhotoBackgroundColors.brown.rgba,
            colorRGBA == brownRGBA
        {
            return "茶"
        }
        
        return "不明"
    }
    
    var body: some View {
        EditIDPhotoView(
            selectedProcess: $currentSelectedProcess,
            selectedBackgroundColor: $selectedBackgroundColor,
            selectedBackgroundColorLabel: $selectedBackgroundColorLabel,
            selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
            previewUIImage: $previewUIImage,
            shouldDisableDoneButton: .readOnly(!hasAnyModifications),
            availableBackgroundColors: BACKGROUND_COLORS,
            availableSizeVariants: availableIDPhotoSizeVariants
        )
        .onTapDismissButton {
            if hasAnyModifications {
                showDismissConfirmationDialog()
                
                return
            }
            
            onDismissCallback?()
        }
        .onTapDoneButton {
            Task {
                do {
                    
                    let fileManager: FileManager = .default
                    
                    guard let originalCreatedIDPhotoFileURL = self.originalCreatedIDPhotoFileURL else { return }
                    
                    let originalCreatedIDPhotoFileBaseName: String = originalCreatedIDPhotoFileURL
                        .deletingPathExtension()
                        .lastPathComponent
                    
                    let originalCreatedIDPhotoFileUTType: UTType? = UTType(filenameExtension: originalCreatedIDPhotoFileURL.pathExtension)
                    
                    guard let originalCreatedIDPhotoFileUTType = originalCreatedIDPhotoFileUTType else { return }
                    
                    guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
                    
                    let composedIDPhoto: CIImage? = await composeIDPhoto(
                        sourcePhoto: sourcePhotoCIImage,
                        idPhotoSizeVariant: self.selectedIDPhotoSizeVariant,
                        backgroundColor: self.selectedBackgroundColor
                    )
                    
                    guard let composedIDPhoto = composedIDPhoto else { return }
                    
                    let createdNewIDPhotoURL: URL?  = try createImageFile(
                        image: composedIDPhoto,
                        fileName: originalCreatedIDPhotoFileBaseName,
                        fileType: originalCreatedIDPhotoFileUTType,
                        saveDestination: fileManager.temporaryDirectory
                    )
                    
                    guard let createdNewIDPhotoURL = createdNewIDPhotoURL else { return }
                    
                    try fileManager.replaceItemAt(originalCreatedIDPhotoFileURL, withItemAt: createdNewIDPhotoURL)
                    
                    let appliedColor: Color? = isBackgroundColorChanged ? self.selectedBackgroundColor : nil
                    
                    let appliedSizeVariant: IDPhotoSizeVariant? = isIDPhotoSizeChanged ? self.selectedIDPhotoSizeVariant : nil
                    
                    try updateTargetCreatedIDPhotoRecord(
                        idPhotoBackgroundColor: appliedColor,
                        idPhotoSizeVariant: appliedSizeVariant,
                        idPhotoSize: appliedSizeVariant?.photoSize
                    )
                    
                    viewContext.refresh(self.editTargetCreatedIDPhoto, mergeChanges: true)
                    
                    onDoneSaveProcessCallback?()
                } catch {
                    print(error)
                }
            }
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
            Just(selectedIDPhotoSizeVariant)
                .combineLatest(Just(selectedBackgroundColor))
        ) { newSelectedSizeVariant, newSelectedBackgroundColor in
            
            guard hasAnyModifications else { return }
            
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
        .onReceive(Just(selectedBackgroundColor)) { newSelectedBackgroundColor in
            self.selectedBackgroundColorLabel = generateBackgroundColorLabel(newSelectedBackgroundColor)
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

// MARK: Core Data 更新関連
extension EditIDPhotoViewContainer {
    func updateTargetCreatedIDPhotoRecord(
        idPhotoBackgroundColor: Color?,
        idPhotoSizeVariant: IDPhotoSizeVariant?,
        idPhotoSize: IDPhotoSize?
    ) throws -> Void {
        do {
            if idPhotoBackgroundColor == nil &&
                idPhotoSizeVariant == nil &&
                idPhotoSize == nil {
                return
            }
            
            if let appliedBackgroundColor = idPhotoBackgroundColor {
                editTargetCreatedIDPhoto.appliedBackgroundColor = .init(
                    on: viewContext,
                    color: appliedBackgroundColor
                )
            }
            
            if
                let appliedIDPhotoSizeVariant = idPhotoSizeVariant,
                let appliedIDPhotoSize = idPhotoSize
            {
                editTargetCreatedIDPhoto.appliedIDPhotoSize = .init(
                    on: viewContext,
                    millimetersHeight: appliedIDPhotoSize.height.value,
                    millimetersWidth: appliedIDPhotoSize.width.value,
                    sizeVariant: appliedIDPhotoSizeVariant
                )
            }
            
            editTargetCreatedIDPhoto.updatedAt = .now
            
            try viewContext.save()
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
