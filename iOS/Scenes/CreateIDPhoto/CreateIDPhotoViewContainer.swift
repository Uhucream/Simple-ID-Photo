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
    
    @ObservedObject var sourcePhotoRecord: SourcePhoto
    
    var visionFrameWorkHelper: VisionFrameworkHelper
    
    var sourceImage: UIImage?
    
    @State private var previewUIImage: UIImage? = nil
    @State private var sourceImageOrientation: UIImage.Orientation
    
    @State private var selectedBackgroundColor: Color = .idPhotoBackgroundColors.blue
    @State private var selectedIDPhotoSize: IDPhotoSizeVariant = .original
    
    @State private var sourceImageWithBackgroundColor: CIImage?
    
    @State private var detectedFaceRect: CGRect = .zero
    
    @State private var croppingRect: CGRect = .zero
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    init(sourcePhotoRecord: SourcePhoto, sourceUIImage: UIImage?) {
        
        _sourcePhotoRecord = .init(wrappedValue: sourcePhotoRecord)
        
        self.sourceImage = sourceUIImage
        
        self.visionFrameWorkHelper = .init(
            sourceCIImage: sourceUIImage?.ciImage(),
            sourceImageOrientation: .init(sourceUIImage?.imageOrientation ?? .up)
        )
        
        _previewUIImage = State(initialValue: sourceUIImage)

        _sourceImageOrientation = State(initialValue: sourceUIImage?.imageOrientation ?? .up)
    }
    
    func showDiscardViewConfirmationDialog() -> Void {
        shouldShowDiscardViewConfirmationDialog = true
    }
    
    func refreshPreviewImage(newImage: UIImage) -> Void {
        self.previewUIImage = newImage
    }
    
    func setIDPhotoWithBackgroundColor(with backgroundColor: Color) async -> Void {
        do {
            guard let sourceImage = sourceImage else { return }
            
            let solidColorBackgroundUIImage: UIImage? = .init(color: backgroundColor, size: sourceImage.size)
            
            guard let solidColorBackgroundCIImage = solidColorBackgroundUIImage?.ciImage() else { return }
            
            let generatedImage: CIImage? = try await visionFrameWorkHelper.combineWithBackgroundImage(with: solidColorBackgroundCIImage)
            
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
            
            registerCreatedIDPhotoRecord(
                imageFileName: imageFileNameWithPathExtension,
                saveDirectoryPath: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_NAME,
                relativeTo: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH
            )
            
            dismiss()
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
            let detectedRect: CGRect? = try? await visionFrameWorkHelper.detectFaceIncludingHairRectangle()
            
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
                    
                    deleteSavedSourcePhotoImageFile()
                    
                    deleteSourcePhotoRecord()
                    
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
        relativeTo rootSearchPathDirectory: FileManager.SearchPathDirectory
    ) -> Void {
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
            
            CreatedIDPhoto(
                on: viewContext,
                createdAt: .now,
                imageFileName: imageFileName,
                updatedAt: .now,
                appliedBackgroundColor: appliedBackgroundColor,
                appliedIDPhotoSize: appliedIDPhotoSize,
                savedDirectory: savedDirectory,
                sourcePhoto: self.sourcePhotoRecord
            )
            
            try viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func deleteSavedSourcePhotoImageFile() -> Void {
        let sourcePhotoFileURL: URL? = parseSavedSourcePhotoImageURL()
        
        guard let sourcePhotoFileURL = sourcePhotoFileURL else { return }
        
        do {
            try FileManager.default.removeItem(at: sourcePhotoFileURL)
        } catch {
            print(error)
        }
    }
    
    func deleteSourcePhotoRecord() -> Void {
        do {
            viewContext.delete(self.sourcePhotoRecord)
            
            try viewContext.save()
        } catch {
            print(error)
        }
    }
}

extension CreateIDPhotoViewContainer {
    
    func parseSavedSourcePhotoImageURL() -> URL? {

        let DEFAULT_SAVE_DIRECTORY_ROOT: FileManager.SearchPathDirectory = .libraryDirectory
        
        let LIBRARY_DIRECTORY_RAW_VALUE_INT64: Int64 = .init(DEFAULT_SAVE_DIRECTORY_ROOT.rawValue)
        
        let fileManager: FileManager = .default

        let saveDestinationRootSearchDirectory: FileManager.SearchPathDirectory = .init(
            rawValue: UInt(
                sourcePhotoRecord.savedDirectory?.rootSearchPathDirectory ?? LIBRARY_DIRECTORY_RAW_VALUE_INT64
            )
        ) ?? DEFAULT_SAVE_DIRECTORY_ROOT
        
        let saveDestinationRootSearchDirectoryURL: URL? = fileManager.urls(
            for: saveDestinationRootSearchDirectory,
            in: .userDomainMask
        ).first
        
        let relativePathFromRoot: String = sourcePhotoRecord.savedDirectory?.relativePathFromRootSearchPath ?? ""
        let fileSaveDestinationURL: URL = .init(
            fileURLWithPath: relativePathFromRoot,
            isDirectory: true,
            relativeTo: saveDestinationRootSearchDirectoryURL
        )
        
        let sourcePhotoFileName: String? = sourcePhotoRecord.imageFileName
        
        guard let sourcePhotoFileName = sourcePhotoFileName else { return nil }
        
        let sourcePhotoFileURL: URL = fileSaveDestinationURL
            .appendingPathComponent(sourcePhotoFileName, conformingTo: .fileURL)
        
        guard fileManager.fileExists(atPath: sourcePhotoFileURL.path) else { return nil }
        
        return sourcePhotoFileURL
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
        
        if fileType == .jpeg {
            do {
                let jpegData: Data? = ciContext
                    .jpegRepresentation(
                        of: ciImage,
                        colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                    )
                
                guard let jpegData = jpegData else { return nil }
                
                try jpegData.write(to: saveFilePathURL)
                
                return saveFilePathURL
            } catch {
                throw error
            }
        }
        
        do {
            let heicData: Data? = ciContext
                .heifRepresentation(
                    of: ciImage,
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
        
        let sourcePhotoMockRecord: SourcePhoto = .init(
            on: PersistenceController.preview.container.viewContext,
            imageFileName: sampleUIImage.saveOnLibraryCachesForTest(fileName: "TimCook")!.absoluteString,
            shotDate: .now.addingTimeInterval(-10000)
        )
        
        NavigationView {
            CreateIDPhotoViewContainer(
                sourcePhotoRecord: sourcePhotoMockRecord,
                sourceUIImage: sampleUIImage
            )
        }
    }
}
