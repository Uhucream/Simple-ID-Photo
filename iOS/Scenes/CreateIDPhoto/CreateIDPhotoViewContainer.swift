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

struct CreateIDPhotoViewContainer: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var sourcePhotoRecord: SourcePhoto
    
    @ObservedObject var visionIDPhotoGenerator: VisionIDPhotoGenerator
    
    @State private var previewUIImage: UIImage? = nil
    @State private var sourceImageOrientation: UIImage.Orientation
    
    @State private var selectedIDPhotoSize: IDPhotoSizeVariant = .original
    
    @State private var croppingRect: CGRect = .zero
    
    @State private var shouldShowDiscardViewConfirmationDialog: Bool = false
    
    init(
        sourcePhotoRecord: SourcePhoto,
        sourceUIImage: UIImage?
    ) {
        
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

struct CreateIDPhotoViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUIImage: UIImage = UIImage(named: "TimCook")!
        
        let sourcePhotoMockRecord: SourcePhoto = .init(
            on: PersistenceController.preview.container.viewContext,
            imageURL: sampleUIImage.localURLForXCAssets(fileName: "TimCook")!.absoluteString,
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
