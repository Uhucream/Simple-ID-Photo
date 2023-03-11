//
//  CreateIDPhotoViewContainer.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2023/01/11
//
//

import SwiftUI
import Combine
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import VideoToolbox
import UniformTypeIdentifiers

struct CreateIDPhotoViewContainer: View {
    
    static let CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH: FileManager.SearchPathDirectory = .libraryDirectory
    static let CREATED_ID_PHOTO_SAVE_FOLDER_NAME: String = "CreatedPhotos"
    
    @Environment(\.managedObjectContext) var viewContext
    
    @Environment(\.dismiss) var dismiss
    
    private var sourcePhotoTemporaryURL: URL
    
    private var sourcePhotoCIImage: CIImage? {
        return .init(contentsOf: sourcePhotoTemporaryURL)
    }
    
    private var sourceImageOrientation: UIImage.Orientation
    
    private var visionFrameworkHelper: VisionFrameworkHelper {
        .init(
            sourceCIImage: sourcePhotoCIImage,
            sourceImageOrientation: .init(sourceImageOrientation)
        )
    }
    
    private var detectedFaceRect: CGRect {
        get async throws {
            try await detectingFaceRect() ?? .zero
        }
    }
    
    @State private var previewUIImage: UIImage? = nil
    
    @State private var selectedBackgroundColor: Color = .idPhotoBackgroundColors.blue
    @State private var selectedIDPhotoSizeVariant: IDPhotoSizeVariant = .original
    
    @State private var croppingRect: CGRect = .zero
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    private(set) var onDoneCreateIDPhotoProcessCallback: ((CreatedIDPhoto) -> Void)?
    
    init(sourcePhotoURL: URL) {
        
        self.sourcePhotoTemporaryURL = sourcePhotoURL
        
        let uiImageFromURL: UIImage = .init(url: sourcePhotoURL)
        let orientationFixedUIImage: UIImage? = uiImageFromURL.orientationFixed()
        
        self.sourceImageOrientation = orientationFixedUIImage?.imageOrientation ?? .up
        
        _previewUIImage = State(initialValue: orientationFixedUIImage)
    }
    
    func onDoneCreateIDPhotoProcess(action: @escaping (CreatedIDPhoto) -> Void) -> Self {
        var view = self
        
        view.onDoneCreateIDPhotoProcessCallback = action
        
        return view
    }
    
    func showDiscardViewConfirmationDialog() -> Void {
        shouldShowDiscardViewConfirmationDialog = true
    }
    
    func detectingFaceRect() async throws -> CGRect? {
        do {
            let detectedRect: CGRect? = try await visionFrameworkHelper.detectFaceIncludingHairRectangle()
            
            return detectedRect
        } catch {
            throw error
        }
    }
    
    func refreshPreviewImage(newImage: UIImage) -> Void {
        self.previewUIImage = newImage
    }
    
    func paintingImageBackgroundColor(
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
            let paintedSourcePhoto: CIImage? = try await paintingImageBackgroundColor(
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
    
    func handleTapDoneButton() -> Void {
        Task {
            do {
                
                guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
                
                let composedIDPhoto: CIImage? = await self.composeIDPhoto(
                    sourcePhoto: sourcePhotoCIImage,
                    idPhotoSizeVariant: self.selectedIDPhotoSizeVariant,
                    backgroundColor: self.selectedBackgroundColor
                )
                
                guard let composedIDPhoto = composedIDPhoto else { return }
                
                let isHEICSupported: Bool = (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(UTType.heic.identifier)
                
                let saveFileUTType: UTType = isHEICSupported ? .heic : .jpeg
                
                let saveFileName: String = ProcessInfo.processInfo.globallyUniqueString
                
                let saveDestinationDirectoryURL: URL? = fetchOrCreateDirectoryURL(
                    directoryName: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_NAME,
                    relativeTo: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH
                )
                
                guard let saveDestinationDirectoryURL = saveDestinationDirectoryURL else { return }
                
                let savedFileURL: URL? = try saveImageToSpecifiedDirectory(
                    ciImage: composedIDPhoto,
                    fileName: saveFileName,
                    fileType: saveFileUTType,
                    to: saveDestinationDirectoryURL
                )
                
                guard let savedFileURL = savedFileURL else { return }
                
                let imageFileNameWithPathExtension: String = savedFileURL.lastPathComponent
                
                var dateFormatterForExif: DateFormatter {
                    
                    let formatter: DateFormatter = .init()
                    
                    formatter.locale = NSLocale.system
                    formatter.dateFormat =  "yyyy:MM:dd HH:mm:ss"
                    
                    return formatter
                }
                
                let sourcePhotoProperties: [String: Any] = sourcePhotoCIImage.properties
                let sourcePhotoExif: [String: Any]? = sourcePhotoProperties[kCGImagePropertyExifDictionary as String] as? [String: Any]
                
                let sourcePhotoShotDateString: String? = sourcePhotoExif?[kCGImagePropertyExifDateTimeOriginal as String] as? String
                
                let sourcePhotoShotDate: Date? = dateFormatterForExif.date(from: sourcePhotoShotDateString ?? "")
                
                let sourcePhotoSaveDirectoryRootPath: FileManager.SearchPathDirectory = .libraryDirectory
                let sourcePhotoSaveDirectoryRelativePath: String = "SourcePhotos"
                
                let fileManager: FileManager = .default
                
                let libraryDirectoryURL: URL = try fileManager.url(
                    for: sourcePhotoSaveDirectoryRootPath,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                
                let sourcePhotoPermanentURL: URL = libraryDirectoryURL
                    .appendingPathComponent(sourcePhotoSaveDirectoryRelativePath, conformingTo: .fileURL)
                    .appendingPathComponent(sourcePhotoTemporaryURL.lastPathComponent, conformingTo: .fileURL)
                
                try fileManager.moveItem(
                    at: sourcePhotoTemporaryURL,
                    to: sourcePhotoPermanentURL
                )
                
                let sourcePhotoSavedDirectory: SavedFilePath = .init(
                    on: viewContext,
                    rootSearchPathDirectory: sourcePhotoSaveDirectoryRootPath,
                    relativePathFromRootSearchPath: sourcePhotoSaveDirectoryRelativePath
                )
                
                let newSourcePhotoRecord: SourcePhoto = .init(
                    on: viewContext,
                    imageFileName: sourcePhotoTemporaryURL.lastPathComponent,
                    shotDate: sourcePhotoShotDate,
                    savedDirectory: sourcePhotoSavedDirectory
                )
                
                let newCreatedIDPhoto: CreatedIDPhoto = try registerCreatedIDPhotoRecord(
                    imageFileName: imageFileNameWithPathExtension,
                    saveDirectoryPath: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_NAME,
                    relativeTo: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH,
                    sourcePhotoRecord: newSourcePhotoRecord
                )
                
                onDoneCreateIDPhotoProcessCallback?(newCreatedIDPhoto)
            } catch {
                print(error)
            }
        }
    }
    
    var body: some View {
        ZStack {
            if #available(iOS 16, *) {
                CreateIDPhotoView(
                    selectedBackgroundColor: $selectedBackgroundColor,
                    selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
                    previewUIImage: $previewUIImage.animation()
                )
                .onTapDismissButton {
                    showDiscardViewConfirmationDialog()
                }
                .onTapDoneButton(action: handleTapDoneButton)
                .toolbar(.hidden)
            } else {
                CreateIDPhotoView(
                    selectedBackgroundColor: $selectedBackgroundColor,
                    selectedIDPhotoSize: $selectedIDPhotoSizeVariant,
                    previewUIImage: $previewUIImage.animation()
                )
                .onTapDismissButton {
                    showDiscardViewConfirmationDialog()
                }
                .onTapDoneButton(action: handleTapDoneButton)
                .navigationBarHidden(true)
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
        .confirmationDialog(
            "証明写真作成を終了",
            isPresented: $shouldShowDiscardViewConfirmationDialog
        ) {
            Button(
                role: .destructive,
                action: {
                    
                    deleteTemporarySavedSourcePhotoFile()
                    
                    dismiss()
                }
            ) {
                Text("保存せずに終了")
            }
        }
    }
}

extension CreateIDPhotoViewContainer {
    func registerCreatedIDPhotoRecord(
        imageFileName: String,
        saveDirectoryPath: String,
        relativeTo rootSearchPathDirectory: FileManager.SearchPathDirectory,
        sourcePhotoRecord: SourcePhoto
    ) throws -> CreatedIDPhoto {
        do {
            let appliedBackgroundColor: AppliedBackgroundColor = .init(
                on: viewContext,
                color: self.selectedBackgroundColor
            )
            
            let selectedIDPhotoSizeVariant: IDPhotoSizeVariant = self.selectedIDPhotoSizeVariant
            
            let appliedIDPhotoFaceHeight: AppliedIDPhotoFaceHeight = .init(
                on: viewContext,
                millimetersHeight: selectedIDPhotoSizeVariant.photoSize.faceHeight.value
            )
            
            let appliedMarginsAroundFace: AppliedMarginsAroundFace = .init(
                on: viewContext,
                bottom: selectedIDPhotoSizeVariant.photoSize.marginBottom?.value ?? -1,
                top: selectedIDPhotoSizeVariant.photoSize.marginTop.value
            )
            
            let appliedIDPhotoSize: AppliedIDPhotoSize = .init(
                on: viewContext,
                millimetersHeight: selectedIDPhotoSizeVariant.photoSize.height.value,
                millimetersWidth: selectedIDPhotoSizeVariant.photoSize.width.value,
                sizeVariant: selectedIDPhotoSizeVariant,
                faceHeight: appliedIDPhotoFaceHeight,
                marginsAroundFace: appliedMarginsAroundFace
            )
            
            let savedDirectory: SavedFilePath = .init(
                on: viewContext,
                rootSearchPathDirectory: rootSearchPathDirectory,
                relativePathFromRootSearchPath: saveDirectoryPath
            )
            
            let newCreatedIDPhotoRecord: CreatedIDPhoto = .init(
                on: viewContext,
                createdAt: .now,
                imageFileName: imageFileName,
                updatedAt: .now,
                appliedBackgroundColor: appliedBackgroundColor,
                appliedIDPhotoSize: appliedIDPhotoSize,
                savedDirectory: savedDirectory,
                sourcePhoto: sourcePhotoRecord
            )
            
            try viewContext.save()
            
            return newCreatedIDPhotoRecord
        } catch {
            throw error
        }
    }
    
    func deleteTemporarySavedSourcePhotoFile() -> Void {
        do {
            try FileManager.default.removeItem(at: sourcePhotoTemporaryURL)
        } catch {
            print(error)
        }
    }
}

extension CreateIDPhotoViewContainer {
    
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

extension CreateIDPhotoViewContainer {
    
    func saveImageToSpecifiedDirectory(
        ciImage: CIImage,
        fileName: String,
        fileType: UTType,
        to saveDestinationDirectoryURL: URL
    ) throws -> URL? {
        
        let saveFilePathURL: URL = saveDestinationDirectoryURL
            .appendingPathComponent(fileName, conformingTo: fileType)
        
        let ciContext: CIContext = .init()
        
        do {
            if fileType == .jpeg {
                let jpegData: Data? = ciImage.jpegData(
                    ciContext: ciContext,
                    colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                )
                
                guard let jpegData = jpegData else { return nil }
                
                try jpegData.write(to: saveFilePathURL)
                
                return saveFilePathURL
            }
            
            let heicData: Data? = ciImage.heifData(
                ciContext: ciContext,
                format: .RGBA8,
                colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            )
            
            guard let heicData = heicData else { return nil }
            
            try heicData.write(to: saveFilePathURL)
            
            return saveFilePathURL
        } catch {
            throw error
        }
    }
}

struct CreateIDPhotoViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUIImage: UIImage = UIImage(named: "TimCook")!
        
        let sampleImageURL: URL = sampleUIImage.saveOnLibraryCachesForTest(fileName: "TimCook")!
        
        NavigationView {
            CreateIDPhotoViewContainer(
                sourcePhotoURL: sampleImageURL
            )
        }
    }
}
