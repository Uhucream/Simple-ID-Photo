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
    @ObservedObject var visionIDPhotoGenerator: VisionIDPhotoGenerator
    
    @State private var previewUIImage: UIImage? = nil
    
    @State private var selectedIDPhotoSize: IDPhotoSizeVariant = .original
    
    @State private var croppingRect: CGRect = .zero
    
    init(sourceCIImage: CIImage?) {
        
        self.visionIDPhotoGenerator = .init(sourceCIImage: sourceCIImage)
        
        if let unwrappedSourceUIImage = sourceCIImage?.uiImage(orientation: .up) {
            _previewUIImage = State(initialValue: unwrappedSourceUIImage)
        }
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
        
        self.previewUIImage = croppedImage.uiImage(orientation: .up)
    }
    
//    func cropImageAsPassportSize() -> Void {
//
//    }
    
    var body: some View {
        CreateIDPhotoView(
            selectedBackgroundColor: $visionIDPhotoGenerator.idPhotoBackgroundColor,
            selectedIDPhotoSize: $selectedIDPhotoSize,
            previewUIImage: $previewUIImage.animation()
        )
        .task {
            try? await visionIDPhotoGenerator.performPersonSegmentationRequest()
            
            visionIDPhotoGenerator.performHumanRectanglesAndFaceLandmarksRequest()
        }
        .onChange(of: visionIDPhotoGenerator.idPhotoBackgroundColor)  { _ in
            Task {
                try? await visionIDPhotoGenerator.performPersonSegmentationRequest()
            }
        }
        .onChange(of: visionIDPhotoGenerator.generatedIDPhoto) { newGeneratedIDPhoto in
            guard let newGeneratedIDPhotoUIImage: UIImage = newGeneratedIDPhoto?.uiImage(orientation: .up) else { return }
            
            self.refreshPreviewImage(newImage: newGeneratedIDPhotoUIImage)
        }
        .onChange(of: self.selectedIDPhotoSize) { _ in
            self.cropImage()
        }
        .toolbar(.hidden)
    }
}

struct CreateIDPhotoViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUIImage: UIImage = UIImage(named: "TimCook")!
        
        NavigationView {
            CreateIDPhotoViewContainer(sourceCIImage: .init(image: sampleUIImage))
        }
    }
}
