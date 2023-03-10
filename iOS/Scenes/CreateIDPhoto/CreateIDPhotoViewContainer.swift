//
//  CreateIDPhotoViewContainer.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2023/01/11
//
//

import SwiftUI
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
    
    var visionFrameworkHelper: VisionFrameworkHelper {
        .init(
            sourceCIImage: sourcePhotoCIImage,
            sourceImageOrientation: .init(sourceImageOrientation)
        )
    }
    
    var sourcePhotoTemporaryURL: URL
    
    var sourcePhotoCIImage: CIImage? {
        return .init(contentsOf: sourcePhotoTemporaryURL)
    }
    
    var sourceImageOrientation: UIImage.Orientation
    
    @State private var previewUIImage: UIImage? = nil
    
    @State private var selectedBackgroundColor: Color = .idPhotoBackgroundColors.blue
    @State private var selectedIDPhotoSize: IDPhotoSizeVariant = .original
    
    @State private var sourceImageWithBackgroundColor: CIImage?
    
    @State private var detectedFaceRect: CGRect = .zero
    
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
    
    func refreshPreviewImage(newImage: UIImage) -> Void {
        self.previewUIImage = newImage
    }
    
    func setIDPhotoWithBackgroundColor(with backgroundColor: Color) async -> Void {
        do {
            guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }
            
            let solidColorBackgroundUIImage: UIImage? = .init(color: backgroundColor, size: sourcePhotoCIImage.extent.size)
            
            guard let solidColorBackgroundCIImage = solidColorBackgroundUIImage?.ciImage() else { return }
            
            let generatedImage: CIImage? = try await visionFrameworkHelper.combineWithBackgroundImage(with: solidColorBackgroundCIImage)
            
            guard let generatedImage = generatedImage else { return }
            guard let generatedUIImage = generatedImage.uiImage(orientation: self.sourceImageOrientation) else { return }
            
            Task { @MainActor in
                self.sourceImageWithBackgroundColor = generatedImage
                
                self.previewUIImage = generatedUIImage
            }
        } catch {
            print(error)
        }
    }
    
    func cropImage() -> Void {
        
        guard let sourceImageWithBackgroundColor = sourceImageWithBackgroundColor else { return }
        
        if selectedIDPhotoSize == .original {

            self.previewUIImage = sourceImageWithBackgroundColor.uiImage(orientation: self.sourceImageOrientation)
            
            return
        }
        
        if selectedIDPhotoSize == .passport {
//            cropImageAsPassportSize()
            
            return
        }
        
        if self.detectedFaceRect == .zero { return }
        
        let faceHeightRatio: Double = selectedIDPhotoSize.photoSize.faceHeight.value / selectedIDPhotoSize.photoSize.height.value
        
        let idPhotoAspectRatio: Double = selectedIDPhotoSize.photoSize.width.value / selectedIDPhotoSize.photoSize.height.value
        
        let idPhotoHeight: CGFloat = self.detectedFaceRect.height / faceHeightRatio
        let idPhotoWidth: CGFloat = idPhotoHeight * idPhotoAspectRatio
        
        let marginTopRatio: Double = selectedIDPhotoSize.photoSize.marginTop.value / selectedIDPhotoSize.photoSize.height.value
        
        let marginTop: CGFloat = idPhotoHeight * marginTopRatio
        
        let remainderWidthOfFaceAndPhoto: CGFloat = idPhotoWidth - self.detectedFaceRect.size.width
        
        let originXOfCroppingRect: CGFloat = self.detectedFaceRect.origin.x - (remainderWidthOfFaceAndPhoto / 2)
        let originYOfCroppingRect: CGFloat = (self.detectedFaceRect.maxY + marginTop) - idPhotoHeight
        
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
        
        self.croppingRect = croppingRect
        
        let croppedImage = sourceImageWithBackgroundColor.cropped(to: croppingRect)
        
        self.previewUIImage = croppedImage.uiImage(orientation: self.sourceImageOrientation)
    }
    
    //    func cropImageAsPassportSize() -> Void {
    //
    //    }
    
    func handleTapDoneButton() -> Void {
        do {
            guard let sourcePhotoCIImage = sourcePhotoCIImage else { return }

            guard let generatedIDPhoto = sourceImageWithBackgroundColor else { return }
            
            let isHEICSupported: Bool = (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(UTType.heic.identifier)
            
            let saveFileUTType: UTType = isHEICSupported ? .heic : .jpeg
            
            let saveFileName: String = ProcessInfo.processInfo.globallyUniqueString
            
            let saveDestinationDirectoryURL: URL? = fetchOrCreateDirectoryURL(
                directoryName: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_NAME,
                relativeTo: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH
            )
            
            guard let saveDestinationDirectoryURL = saveDestinationDirectoryURL else { return }
            
            let savedFileURL: URL? = try saveImageToSpecifiedDirectory(
                ciImage: generatedIDPhoto,
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
            
            try fileManager.copyItem(
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
    
    var body: some View {
        ZStack {
            if #available(iOS 16, *) {
                CreateIDPhotoView(
                    selectedBackgroundColor: $selectedBackgroundColor,
                    selectedIDPhotoSize: $selectedIDPhotoSize,
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
                    selectedIDPhotoSize: $selectedIDPhotoSize,
                    previewUIImage: $previewUIImage.animation()
                )
                .onTapDismissButton {
                    showDiscardViewConfirmationDialog()
                }
                .onTapDoneButton(action: handleTapDoneButton)
                .navigationBarHidden(true)
            }
        }
        .task {
            await setIDPhotoWithBackgroundColor(with: self.selectedBackgroundColor)
        }
        .task {
            let detectedRect: CGRect? = try? await visionFrameworkHelper.detectFaceIncludingHairRectangle()
            
            guard let detectedRect = detectedRect else { return }
            
            Task { @MainActor in
                self.detectedFaceRect = detectedRect
            }
        }
        .onChange(of: selectedBackgroundColor)  { newSelectedBackgroundColor in
            Task {
                await setIDPhotoWithBackgroundColor(with: newSelectedBackgroundColor)
            }
        }
        .onChange(of: self.selectedIDPhotoSize) { _ in
            self.cropImage()
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
            
            let selectedIDPhotoSizeVariant: IDPhotoSizeVariant = self.selectedIDPhotoSize
            
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
