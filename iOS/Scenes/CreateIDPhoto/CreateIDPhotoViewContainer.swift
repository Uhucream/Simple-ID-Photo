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
    var sourceCIImage: CIImage?
    
    @State private var previewUIImage: UIImage?
    
    @State private var idPhotoBackgroundColor: Color = Color(0x5FB8DE, alpha: 1.0)
    
    @State private var idPhotoSize: CGSize = .init(width: 1296, height: 746)
    
    init(sourceCIImage: CIImage?) {
        
        self.sourceCIImage = sourceCIImage
        
        if let unwrappedSourceCIImage = sourceCIImage {
            _previewUIImage = State(initialValue: UIImage(ciImage: unwrappedSourceCIImage))
        } else {
            _previewUIImage = State(initialValue: nil)
        }
    }
    
    func maskSourceImage(_ maskPixelBuffer: CVPixelBuffer) -> Void {
        
        guard let solidColorBackgroundUIImage: UIImage = .init(color: idPhotoBackgroundColor, size: idPhotoSize) else { return }
        guard let solidColorBackgroundCGImage: CGImage = solidColorBackgroundUIImage.cgImage else { return }
        
        guard let sourceCIImage = sourceCIImage else { return }
        
        let backgroundCIImage: CIImage = .init(cgImage: solidColorBackgroundCGImage)
        let maskCIImage: CIImage = .init(cvImageBuffer: maskPixelBuffer)
        
        let maskScaleX = sourceCIImage.extent.width / maskCIImage.extent.width
        let maskScaleY = sourceCIImage.extent.height / maskCIImage.extent.height
        
        let scaledMaskCIImage = maskCIImage
            .transformed(
                by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0)
            )
        
        let backgroundImageScaleX = sourceCIImage.extent.width / backgroundCIImage.extent.width
        let backgroundImageScaleY = sourceCIImage.extent.height / backgroundCIImage.extent.height
        
        let scaledBackgroundCIImage = backgroundCIImage
            .transformed(
                by: __CGAffineTransformMake(backgroundImageScaleX, 0, 0, backgroundImageScaleY, 0, 0)
            )
        
        let blendWithMaskFilter = CIFilter.blendWithMask()
        
        blendWithMaskFilter.inputImage = sourceCIImage
        blendWithMaskFilter.backgroundImage = scaledBackgroundCIImage
        blendWithMaskFilter.maskImage = scaledMaskCIImage
        
        guard let blendedCIImage: CIImage = blendWithMaskFilter.outputImage else { return }
        
        let ciContext: CIContext = .init()
        
        guard let filteredCGImage = ciContext.createCGImage(blendedCIImage, from: blendedCIImage.extent) else { return }
        
        let filteredUIImage: UIImage = .init(cgImage: filteredCGImage)
        
        previewUIImage = filteredUIImage
    }
    
    func performVisionRequest() -> Void {

        let segmentationRequest: VNGeneratePersonSegmentationRequest = .init()
        
        segmentationRequest.qualityLevel = .accurate
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        guard let sourceCIImage: CIImage = sourceCIImage else { return }
        
        let imageRequestHandler: VNImageRequestHandler = .init(ciImage: sourceCIImage, options: [:])
        
        do {
            try imageRequestHandler.perform([segmentationRequest])
            
            let mask = segmentationRequest.results!.first!
            let maskBuffer = mask.pixelBuffer
            
            maskSourceImage(maskBuffer)
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        CreateIDPhotoView(
            selectedBackgroundColor: $idPhotoBackgroundColor,
            previewUIImage: $previewUIImage
        )
        .task {
            performVisionRequest()
        }
        .onChange(of: idPhotoBackgroundColor)  { _ in
            performVisionRequest()
        }
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
