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

final class VisionIDPhotoGenerator: ObservableObject {
    var sourceCIImage: CIImage?
    
    var sourceImageOrientation: CGImagePropertyOrientation
    
    @Published var generatedIDPhoto: CIImage? = nil
    
    @Published var idPhotoSize: CGSize = .init(width: 1296, height: 746)
    @Published var idPhotoBackgroundColor: Color = .init(0x5FB8DE, alpha: 1.0)
    
    private var sourceImageSize: CGSize = .zero
    
    lazy var faceWithHairRectangle: CGRect = .zero
    
    init(sourceCIImage: CIImage?, sourceImageOrientation: CGImagePropertyOrientation) {
        self.sourceCIImage = sourceCIImage
        
        self.sourceImageOrientation = sourceImageOrientation
        
        guard let sourceCIImage = sourceCIImage else { return }
        
        self.sourceImageSize = sourceCIImage.extent.size
    }
    
    func performPersonSegmentationRequest() async throws -> Void {

        let segmentationRequest: VNGeneratePersonSegmentationRequest = .init()
        
        segmentationRequest.qualityLevel = .accurate
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        guard let sourceCIImage: CIImage = sourceCIImage else { return }
        
        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceCIImage,
            orientation: self.sourceImageOrientation,
            options: [:]
        )
        
        do {
            try imageRequestHandler.perform([segmentationRequest])
            
            let mask = segmentationRequest.results!.first!
            let maskBuffer = mask.pixelBuffer
            
            async let maskedImage: CIImage? = maskSourceImage(maskBuffer)
            
            guard let maskedImage = await maskedImage else { return }
            
            DispatchQueue.main.async {
                self.generatedIDPhoto = maskedImage
            }
        } catch {
            throw error
        }
    }
    
    func performHumanRectanglesAndFaceLandmarksRequest() -> Void {
        
        let humanRectanglesRequest: VNDetectHumanRectanglesRequest = .init()
        
        let faceLandmarksRequest: VNDetectFaceLandmarksRequest = .init()
        
        guard let sourceCIImage = sourceCIImage else { return }
        
        let imageReqeustHandler: VNImageRequestHandler = .init(
            ciImage: sourceCIImage,
            orientation: self.sourceImageOrientation,
            options: [:]
        )
        
        do {
            try imageReqeustHandler.perform([humanRectanglesRequest, faceLandmarksRequest])

            self.faceWithHairRectangle = getFaceWithHairRectangle(
                imageSize: sourceCIImage.extent.size,
                humanRectanglesRequest: humanRectanglesRequest,
                faceLandmarksRequest: faceLandmarksRequest
            )
        } catch {
            print(error)
        }
    }
}

extension VisionIDPhotoGenerator {
    func maskSourceImage(_ maskPixelBuffer: CVPixelBuffer) async -> CIImage? {
        
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
        
        return blendedCIImage
    }
    
    func getFaceWithHairRectangle(imageSize: CGSize, humanRectanglesRequest: VNDetectHumanRectanglesRequest, faceLandmarksRequest: VNDetectFaceLandmarksRequest) -> CGRect {
        
        guard let humanObservation = humanRectanglesRequest.results?.first as? VNHumanObservation else { return .zero }

        guard let faceObservation = faceLandmarksRequest.results?.first as? VNFaceObservation else { return CGRect.zero }
        
        let humanNormalizedRectangle: CGRect = humanObservation.boundingBox
        
        let denormalizedHumanRectangle: CGRect = VNImageRectForNormalizedRect(humanNormalizedRectangle, Int(imageSize.width), Int(imageSize.height))

        guard let faceContourLandmark2D = faceObservation.landmarks?.faceContour else { return CGRect.zero }
        
        let denormalizedFaceContourPoints: [CGPoint] = faceContourLandmark2D.pointsInImage(imageSize: imageSize)
        
        let faceNormalizedRectangle: CGRect = faceObservation.boundingBox
        
        let denormalizedFaceRectangle: CGRect = VNImageRectForNormalizedRect(faceNormalizedRectangle, Int(imageSize.width), Int(imageSize.height))
        
        guard let bottomPointOfFaceWithHairRect: CGPoint = denormalizedFaceContourPoints.min(by: { $0.y < $1.y }) else { return CGRect.zero }
        
        let bottomYOfFaceWithHairRect =  bottomPointOfFaceWithHairRect.y
        
        let topYOfFaceWithHairRect: CGFloat = denormalizedHumanRectangle.maxY
        let topLeftXOfFaceWithHairRect: CGFloat = denormalizedFaceRectangle.origin.x
        
        let faceWithHairRectWidth: CGFloat = denormalizedFaceRectangle.width

        let faceWithHairRectHeight: CGFloat = topYOfFaceWithHairRect - bottomYOfFaceWithHairRect
        
        let faceWithHairRectangle: CGRect = .init(
            origin: CGPoint(
                x: topLeftXOfFaceWithHairRect,
                y: bottomYOfFaceWithHairRect
            ),
            size: CGSize(
                width: Double(faceWithHairRectWidth),
                height: Double(faceWithHairRectHeight)
            )
        )
        
        return faceWithHairRectangle
    }
}
