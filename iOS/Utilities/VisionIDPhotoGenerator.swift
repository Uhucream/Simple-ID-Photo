//
//  VisionIDPhotoGenerator.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/15
//  
//

import SwiftUI
import Combine
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

@MainActor
final class VisionIDPhotoGenerator: ObservableObject {
    var sourceCIImage: CIImage?
    
    @Published var generatedIDPhoto: UIImage? = nil
    
    @Published var idPhotoSize: CGSize = .init(width: 1296, height: 746)
    @Published var idPhotoBackgroundColor: Color = .init(0x5FB8DE, alpha: 1.0)
    
    private var sourceImageSize: CGSize = .zero
    
    init(sourceCIImage: CIImage?) {
        self.sourceCIImage = sourceCIImage
        
        guard let sourceCIImage = sourceCIImage else { return }
        
        self.sourceImageSize = sourceCIImage.extent.size
    }
    
    func performPersonSegmentationRequest() async throws -> Void {

        let segmentationRequest: VNGeneratePersonSegmentationRequest = .init()
        
        segmentationRequest.qualityLevel = .accurate
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        guard let sourceCIImage: CIImage = sourceCIImage else { return }
        
        let imageRequestHandler: VNImageRequestHandler = .init(ciImage: sourceCIImage, options: [:])
        
        do {
            try imageRequestHandler.perform([segmentationRequest])
            
            let mask = segmentationRequest.results!.first!
            let maskBuffer = mask.pixelBuffer
            
            let maskedImage: UIImage? = await maskSourceImage(maskBuffer)
            
            guard let maskedImage = maskedImage else { return }
            
            self.generatedIDPhoto = maskedImage
        } catch {
            throw error
        }
    }
}

extension VisionIDPhotoGenerator {
    func maskSourceImage(_ maskPixelBuffer: CVPixelBuffer) async -> UIImage? {
        
        guard let solidColorBackgroundUIImage: UIImage = .init(color: idPhotoBackgroundColor, size: idPhotoSize) else { return nil }
        guard let solidColorBackgroundCGImage: CGImage = solidColorBackgroundUIImage.cgImage else { return nil }
        
        guard let sourceCIImage = sourceCIImage else { return nil }
        
        let backgroundCIImage: CIImage = .init(cgImage: solidColorBackgroundCGImage)
        let maskCIImage: CIImage = .init(cvImageBuffer: maskPixelBuffer)
        
        let maskScaleX = sourceImageSize.width / maskCIImage.extent.width
        let maskScaleY = sourceImageSize.height / maskCIImage.extent.height
        
        let scaledMaskCIImage = maskCIImage
            .transformed(
                by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0)
            )
        
        let backgroundImageScaleX = sourceImageSize.width / backgroundCIImage.extent.width
        let backgroundImageScaleY = sourceImageSize.height / backgroundCIImage.extent.height
        
        let scaledBackgroundCIImage = backgroundCIImage
            .transformed(
                by: __CGAffineTransformMake(backgroundImageScaleX, 0, 0, backgroundImageScaleY, 0, 0)
            )
        
        let blendWithMaskFilter = CIFilter.blendWithMask()
        
        blendWithMaskFilter.inputImage = sourceCIImage
        blendWithMaskFilter.backgroundImage = scaledBackgroundCIImage
        blendWithMaskFilter.maskImage = scaledMaskCIImage
        
        guard let blendedCIImage: CIImage = blendWithMaskFilter.outputImage else { return nil }
        
        let ciContext: CIContext = .init()
        
        guard let filteredCGImage = ciContext.createCGImage(blendedCIImage, from: blendedCIImage.extent) else { return nil }
        
        let filteredUIImage: UIImage = .init(cgImage: filteredCGImage)
        
        return filteredUIImage
    }
}
