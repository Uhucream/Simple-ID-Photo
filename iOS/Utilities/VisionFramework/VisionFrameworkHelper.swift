//
//  VisionFrameworkHelper.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/08
//  
//

import Foundation
import Vision
import CoreImage

final class VisionFrameworkHelper {
    
    private var sourceCIImage: CIImage?
    
    private var sourceImageOrientation: CGImagePropertyOrientation
    
    init(
        sourceCIImage: CIImage?,
        sourceImageOrientation: CGImagePropertyOrientation
    ) {
        self.sourceCIImage = sourceCIImage
        self.sourceImageOrientation = sourceImageOrientation
    }
    
    public func performPersonSegmentationRequest(
        sourceImage: CIImage,
        imageOrientation: CGImagePropertyOrientation,
        qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel = .fast,
        outputPixelFormat: OSType = kCVPixelFormatType_OneComponent8
    ) async throws -> [VNPixelBufferObservation]? {
        
        let segmentationRequest: VNGeneratePersonSegmentationRequest = .init()
        
        segmentationRequest.qualityLevel = qualityLevel
        segmentationRequest.outputPixelFormat = outputPixelFormat
        
        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceImage,
            orientation: imageOrientation,
            options: [:]
        )
        
        do {
            if Task.isCancelled {
                segmentationRequest.cancel()
                
                throw CancellationError()
            }
            
            try imageRequestHandler.perform([segmentationRequest])
            
            return segmentationRequest.results
        } catch {
            throw error
        }
    }
    
    public func performHumanRectanglesRequest(
        sourceImage: CIImage,
        imageOrientation: CGImagePropertyOrientation,
        upperBodyOnly: Bool = false
    ) async throws -> [VNHumanObservation]? {
        
        let humanRectanglesRequest: VNDetectHumanRectanglesRequest = .init()
        
        humanRectanglesRequest.upperBodyOnly = upperBodyOnly
        
        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceImage,
            orientation: imageOrientation,
            options: [:]
        )
        
        do {
            if Task.isCancelled {
                humanRectanglesRequest.cancel()
                
                throw CancellationError()
            }
            
            try imageRequestHandler.perform([humanRectanglesRequest])
            
            return humanRectanglesRequest.results
        } catch {
            throw error
        }
    }
    
    public func performFaceLandmarksRequest(
        sourceImage: CIImage,
        imageOrientation: CGImagePropertyOrientation
    ) async throws -> [VNFaceObservation]? {
        
        let faceLandmarksRequest: VNDetectFaceLandmarksRequest = .init()
        
        let imageReqeustHandler: VNImageRequestHandler = .init(
            ciImage: sourceImage,
            orientation: imageOrientation,
            options: [:]
        )
        
        do {
            if Task.isCancelled {
                faceLandmarksRequest.cancel()
                
                throw CancellationError()
            }
            
            try imageReqeustHandler.perform([faceLandmarksRequest])
            
            return faceLandmarksRequest.results
        } catch {
            throw error
        }
    }
}

extension VisionFrameworkHelper {

    func maskImage(
        inputImage: CIImage,
        maskBuffer: CVPixelBuffer,
        backgroundImage: CIImage
    ) -> CIImage? {
        
        let inputImageSize: CGSize = inputImage.extent.size
        
        let maskCIImage: CIImage = .init(cvImageBuffer: maskBuffer)
        
        let maskScaleX = inputImageSize.width / maskCIImage.extent.width
        let maskScaleY = inputImageSize.height / maskCIImage.extent.height
        
        let scaledMaskCIImage = maskCIImage
            .transformed(
                by: CGAffineTransform(
                    a: maskScaleX,
                    b: 0,
                    c: 0,
                    d: maskScaleY,
                    tx: 0,
                    ty: 0
                )
            )
        
        let backgroundImageScaleX = inputImageSize.width / backgroundImage.extent.width
        let backgroundImageScaleY = inputImageSize.height / backgroundImage.extent.height
        
        let scaledBackgroundImage = backgroundImage
            .transformed(
                by: CGAffineTransform(
                    a: backgroundImageScaleX,
                    b: 0,
                    c: 0,
                    d: backgroundImageScaleY,
                    tx: 0,
                    ty: 0
                )
            )
        
        let blendWithMaskFilter = CIFilter.blendWithMask()
        
        blendWithMaskFilter.inputImage = inputImage
        blendWithMaskFilter.backgroundImage = scaledBackgroundImage
        blendWithMaskFilter.maskImage = scaledMaskCIImage
        
        let blendedCIImage: CIImage? = blendWithMaskFilter.outputImage
        
        return blendedCIImage
    }
}

extension VisionFrameworkHelper {
    
    public func combineWithBackgroundImage(with backgroundImage: CIImage) async throws -> CIImage? {
        do {

            guard let sourceCIImage: CIImage = sourceCIImage else { return nil }
            
            let pixelBufferObservations: [VNPixelBufferObservation]? = try await self.performPersonSegmentationRequest(
                sourceImage: sourceCIImage,
                imageOrientation: self.sourceImageOrientation,
                qualityLevel: .accurate
            )
            
            let segmentationMask: CVPixelBuffer? = pixelBufferObservations?.first?.pixelBuffer
            
            guard let segmentationMask: CVPixelBuffer = segmentationMask else { return nil }
            
            let combinedImage: CIImage? = maskImage(
                inputImage: sourceCIImage,
                maskBuffer: segmentationMask,
                backgroundImage: backgroundImage
            )
            
            return combinedImage
        } catch {
            throw error
        }
    }
    
    public func detectFaceIncludingHairRectangle() async throws -> CGRect? {
        do {
            guard let sourceCIImage = sourceCIImage else { return nil }
            
            let sourceImageExtent: CGRect = sourceCIImage.extent
            let sourceImageSize: CGSize = sourceImageExtent.size
            
            let humanObservations: [VNHumanObservation]? = try await performHumanRectanglesRequest(
                sourceImage: sourceCIImage,
                imageOrientation: self.sourceImageOrientation
            )
            
            let faceObservations: [VNFaceObservation]? = try await performFaceLandmarksRequest(
                sourceImage: sourceCIImage,
                imageOrientation: self.sourceImageOrientation
            )
            
            guard let firstHumanObservation = humanObservations?.first else { return nil }
            
            guard let firstFaceObservation = faceObservations?.first else { return nil }
            
            let humanNormalizedRectangle: CGRect = firstHumanObservation.boundingBox
            
            let denormalizedHumanRectangle: CGRect = VNImageRectForNormalizedRect(
                humanNormalizedRectangle,
                Int(sourceImageSize.width),
                Int(sourceImageSize.height)
            )

            guard let faceContourLandmark2D = firstFaceObservation.landmarks?.faceContour else { return nil }
            
            let denormalizedFaceContourPoints: [CGPoint] = faceContourLandmark2D.pointsInImage(imageSize: sourceImageSize)
            
            let faceNormalizedRectangle: CGRect = firstFaceObservation.boundingBox
            
            let denormalizedFaceRectangle: CGRect = VNImageRectForNormalizedRect(
                faceNormalizedRectangle,
                Int(sourceImageSize.width),
                Int(sourceImageSize.height)
            )
            
            guard let bottomPointOfFaceWithHairRect: CGPoint = denormalizedFaceContourPoints.min(by: { $0.y < $1.y }) else { return nil }
            
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
        } catch {
            throw error
        }
    }
}
