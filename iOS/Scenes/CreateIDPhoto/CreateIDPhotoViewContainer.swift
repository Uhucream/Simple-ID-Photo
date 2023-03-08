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
    
    init(sourceUIImage: UIImage?) {
        
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
            
            Task.detached(priority: .userInitiated) {
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
    
    var body: some View {
        ZStack {
            if #available(iOS 16, *) {
                CreateIDPhotoView(
                    selectedBackgroundColor: $selectedBackgroundColor,
                    selectedIDPhotoSize: $selectedIDPhotoSize,
                    previewUIImage: $previewUIImage.animation(),
                    onTapDismissButton: {
                        showDiscardViewConfirmationDialog()
                    }
                )
                .toolbar(.hidden)
            } else {
                CreateIDPhotoView(
                    selectedBackgroundColor: $selectedBackgroundColor,
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
            await setIDPhotoWithBackgroundColor(with: self.selectedBackgroundColor)
        }
        .task {
            let detectedRect: CGRect? = try? await visionFrameWorkHelper.detectFaceIncludingHairRectangle()
            
            guard let detectedRect = detectedRect else { return }
            
            Task.detached(priority: .userInitiated) {
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
        
        NavigationView {
            CreateIDPhotoViewContainer(sourceUIImage: sampleUIImage)
        }
    }
}
