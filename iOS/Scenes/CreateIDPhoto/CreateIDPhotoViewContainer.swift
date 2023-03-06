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
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var sourcePhotoRecord: SourcePhoto
    
    @ObservedObject var visionIDPhotoGenerator: VisionIDPhotoGenerator
    
    @State private var previewUIImage: UIImage? = nil
    @State private var sourceImageOrientation: UIImage.Orientation
    
    @State private var selectedIDPhotoSize: IDPhotoSizeVariant = .original
    
    @State private var croppingRect: CGRect = .zero
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    init(sourcePhotoRecord: SourcePhoto, sourceUIImage: UIImage?) {
        
        _sourcePhotoRecord = .init(wrappedValue: sourcePhotoRecord)
        
        self.visionIDPhotoGenerator = .init(
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
    
    func cropImage() -> Void {

        guard let generatedCIImage: CIImage = visionIDPhotoGenerator.generatedIDPhoto else { return }
        
        if selectedIDPhotoSize == .original {
            self.previewUIImage = generatedCIImage.uiImage(orientation: .up)
            
            return
        }
        
        if selectedIDPhotoSize == .passport {
//            cropImageAsPassportSize()
            
            return
        }
        
        let faceRectWithHair: CGRect = visionIDPhotoGenerator.faceWithHairRectangle
        
        if faceRectWithHair == .zero { return }
        
        let faceHeightRatio: Double = selectedIDPhotoSize.photoSize.faceHeight.value / selectedIDPhotoSize.photoSize.height.value
        
        let idPhotoAspectRatio: Double = selectedIDPhotoSize.photoSize.width.value / selectedIDPhotoSize.photoSize.height.value
        
        let idPhotoHeight: CGFloat = faceRectWithHair.height / faceHeightRatio
        let idPhotoWidth: CGFloat = idPhotoHeight * idPhotoAspectRatio
        
        let marginTopRatio: Double = selectedIDPhotoSize.photoSize.marginTop.value / selectedIDPhotoSize.photoSize.height.value
        
        let marginTop: CGFloat = idPhotoHeight * marginTopRatio
        
        let remainderWidthOfFaceAndPhoto: CGFloat = idPhotoWidth - faceRectWithHair.size.width
        
        let originXOfCroppingRect: CGFloat = faceRectWithHair.origin.x - (remainderWidthOfFaceAndPhoto / 2)
        let originYOfCroppingRect: CGFloat = (faceRectWithHair.maxY + marginTop) - idPhotoHeight
        
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
        
        let croppedImage = generatedCIImage.cropped(to: croppingRect)
        
        self.previewUIImage = croppedImage.uiImage(orientation: self.sourceImageOrientation)
    }
    
    //    func cropImageAsPassportSize() -> Void {
    //
    //    }
    
    func handleTapDoneButton() -> Void {
        do {
            guard let generatedIDPhoto = visionIDPhotoGenerator.generatedIDPhoto else { return }
            
            let isHEICSupported: Bool = (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(UTType.heic.identifier)
            
            let saveFileUTType: UTType = isHEICSupported ? .heic : .jpeg
            
            let saveFileName: String = ProcessInfo.processInfo.globallyUniqueString
            
            let saveDestinationDirectoryURL: URL? = fetchOrCreateDirectoryURL(
                directoryName: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_NAME,
                relativeTo: CreateIDPhotoViewContainer.CREATED_ID_PHOTO_SAVE_FOLDER_ROOT_SEARCH_PATH
            )
            
            guard let saveDestinationDirectoryURL = saveDestinationDirectoryURL else { return }
            
            try saveImageToSpecifiedDirectory(
                ciImage: generatedIDPhoto,
                fileName: saveFileName,
                fileType: saveFileUTType,
                to: saveDestinationDirectoryURL
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
                    selectedBackgroundColor: $visionIDPhotoGenerator.idPhotoBackgroundColor,
                    selectedIDPhotoSize: $selectedIDPhotoSize,
                    previewUIImage: $previewUIImage.animation(),
                    onTapDismissButton: {
                        showDiscardViewConfirmationDialog()
                    }
                )
                .onTapDoneButton(action: handleTapDoneButton)
                .toolbar(.hidden)
            } else {
                CreateIDPhotoView(
                    selectedBackgroundColor: $visionIDPhotoGenerator.idPhotoBackgroundColor,
                    selectedIDPhotoSize: $selectedIDPhotoSize,
                    previewUIImage: $previewUIImage.animation(),
                    onTapDismissButton: {
                        showDiscardViewConfirmationDialog()
                    }
                )
                .onTapDoneButton(action: handleTapDoneButton)
                .navigationBarHidden(true)
            }
        }
        .task {
            try? await visionIDPhotoGenerator.performPersonSegmentationRequest()
            
            try? await visionIDPhotoGenerator.performHumanRectanglesAndFaceLandmarksRequest()
        }
        .onChange(of: visionIDPhotoGenerator.idPhotoBackgroundColor)  { _ in
            Task {
                try? await visionIDPhotoGenerator.performPersonSegmentationRequest()
            }
        }
        .onChange(of: visionIDPhotoGenerator.generatedIDPhoto) { newGeneratedIDPhoto in
            guard let newGeneratedIDPhotoUIImage: UIImage = newGeneratedIDPhoto?.uiImage(orientation: self.sourceImageOrientation) else { return }
            
            self.refreshPreviewImage(newImage: newGeneratedIDPhotoUIImage)
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
                    dismiss()
                }
            ) {
                Text("保存せずに終了")
            }
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
    ) throws -> Void {
        
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
                
                guard let jpegData = jpegData else { return }
                
                try jpegData.write(to: saveFilePathURL)
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
            
            guard let heicData = heicData else { return }
            
            try heicData.write(to: saveFilePathURL)
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
