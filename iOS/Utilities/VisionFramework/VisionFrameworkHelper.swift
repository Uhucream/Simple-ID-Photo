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
        
        segmentationRequest.preferBackgroundProcessing = true
        
        segmentationRequest.qualityLevel = qualityLevel
        segmentationRequest.outputPixelFormat = outputPixelFormat
        
        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceImage,
            orientation: imageOrientation,
            options: [:]
        )
        
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try imageRequestHandler.perform([segmentationRequest])
                    
                    continuation.resume(returning: segmentationRequest.results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            segmentationRequest.cancel()
        }
    }
    
    public func performDetectContoursRequest(
        sourceImage: CIImage,
        imageOrientation: CGImagePropertyOrientation,
        contrastAdjustment: Float = 2.0,
        maximumImageDimension: Int = 512,
        detectsDarkOnLight: Bool = true
    ) async throws -> [VNContoursObservation]? {

        let detectContoursRequest: VNDetectContoursRequest = .init()
        
        detectContoursRequest.preferBackgroundProcessing = true
        
        detectContoursRequest.contrastAdjustment = contrastAdjustment
        detectContoursRequest.maximumImageDimension = maximumImageDimension
        detectContoursRequest.detectsDarkOnLight = detectsDarkOnLight
        
        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceImage,
            orientation: imageOrientation
        )
        
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try imageRequestHandler.perform([detectContoursRequest])
                    
                    continuation.resume(returning: detectContoursRequest.results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            detectContoursRequest.cancel()
        }
    }
    
    public func performFaceLandmarksRequest(
        sourceImage: CIImage,
        imageOrientation: CGImagePropertyOrientation
    ) async throws -> [VNFaceObservation]? {
        
        let faceLandmarksRequest: VNDetectFaceLandmarksRequest = .init()
        
        faceLandmarksRequest.preferBackgroundProcessing = true
        
        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceImage,
            orientation: imageOrientation,
            options: [:]
        )
        
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try imageRequestHandler.perform([faceLandmarksRequest])
                    
                    continuation.resume(returning: faceLandmarksRequest.results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            faceLandmarksRequest.cancel()
        }
    }
}

extension VisionFrameworkHelper {

    func maskImage(
        inputImage: CIImage,
        maskBuffer: CVPixelBuffer,
        backgroundImage: CIImage
    ) -> CIImage {
        
        let inputImageSize: CGSize = inputImage.extent.size
        
        let maskCIImage: CIImage = .init(cvImageBuffer: maskBuffer)
        
        let maskScaleX = inputImageSize.width / maskCIImage.extent.width
        let maskScaleY = inputImageSize.height / maskCIImage.extent.height
        
        let scaledMaskCIImage = maskCIImage.transformed(
            by: CGAffineTransform(scaleX: maskScaleX, y: maskScaleY)
        )
        
        let backgroundImageScaleX = inputImageSize.width / backgroundImage.extent.width
        let backgroundImageScaleY = inputImageSize.height / backgroundImage.extent.height
        
        let scaledBackgroundImage = backgroundImage.transformed(
            by: CGAffineTransform(scaleX: backgroundImageScaleX, y: backgroundImageScaleY)
        )
        
        let blendedCIImage: CIImage = inputImage.applyingFilter(
            CIFilter.blendWithMask().name,
            parameters: [
                kCIInputMaskImageKey: scaledMaskCIImage,
                kCIInputBackgroundImageKey: scaledBackgroundImage
            ]
        )
        
        return blendedCIImage
    }
}

extension VisionFrameworkHelper {
    
    public func combinedImage(with backgroundImage: CIImage) async throws -> CIImage? {
        do {

            guard let sourceCIImage: CIImage = sourceCIImage else { return nil }
            
            var segmentationMask: CVPixelBuffer? {
                get async throws {
                    if #unavailable(iOS 17) {
                        let pixelBufferObservations: [VNPixelBufferObservation]? = try await self.performPersonSegmentationRequest(
                            sourceImage: sourceCIImage,
                            imageOrientation: self.sourceImageOrientation,
                            qualityLevel: .accurate
                        )
                        
                        let personSegmentationMask: CVPixelBuffer? = pixelBufferObservations?.first?.pixelBuffer
                        
                        return personSegmentationMask
                    }
                    
                    guard #available(iOS 17, *) else { return nil }
                    
                    let personInstanceMaskRequest: VNGeneratePersonInstanceMaskRequest = .init()
                    
                    personInstanceMaskRequest.preferBackgroundProcessing = true
                    
                    let imageRequestHandler: VNImageRequestHandler = .init(
                        ciImage: sourceCIImage,
                        orientation: self.sourceImageOrientation
                    )
                    
                    try await imageRequestHandler.perform([personInstanceMaskRequest])
                    
                    guard let result = personInstanceMaskRequest.results?.first else { return nil }
                    
                    let foremostPersonInstanceMask: CVPixelBuffer = try result.generateScaledMaskForImage(
                        forInstances: IndexSet(integer: 1),
                        from: imageRequestHandler
                    )
                    
                    return foremostPersonInstanceMask
                }
            }
            
            guard let segmentationMask: CVPixelBuffer = try await segmentationMask else { return nil }
            
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
    
    public func detectFaceIncludingHairRectangle() async throws -> CGRect {
        do {
            guard let sourceCIImage = sourceCIImage else { return .null }
            
            let sourceImageExtent: CGRect = sourceCIImage.extent
            let sourceImageSize: CGSize = sourceImageExtent.size
            
            var segmentationMask: CVPixelBuffer? {
                get async throws {
                    if #unavailable(iOS 17) {
                        let pixelBufferObservations: [VNPixelBufferObservation]? = try await self.performPersonSegmentationRequest(
                            sourceImage: sourceCIImage,
                            imageOrientation: self.sourceImageOrientation,
                            qualityLevel: .balanced
                        )
                        
                        let personSegmentationMask: CVPixelBuffer? = pixelBufferObservations?.first?.pixelBuffer
                        
                        return personSegmentationMask
                    }
                    
                    guard #available(iOS 17, *) else { return nil }
                    
                    let personInstanceMaskRequest: VNGeneratePersonInstanceMaskRequest = .init()
                    
                    personInstanceMaskRequest.preferBackgroundProcessing = true
                    
                    let imageRequestHandler: VNImageRequestHandler = .init(
                        ciImage: sourceCIImage,
                        orientation: self.sourceImageOrientation
                    )
                    
                    try await imageRequestHandler.perform([personInstanceMaskRequest])
                    
                    guard let result = personInstanceMaskRequest.results?.first else { return nil }
                    
                    let foremostPersonInstanceMask: CVPixelBuffer = try result.generateScaledMaskForImage(
                        forInstances: IndexSet(integer: 1),
                        from: imageRequestHandler
                    )
                    
                    return foremostPersonInstanceMask
                }
            }
            
            guard let segmentationMask: CVPixelBuffer = try await segmentationMask else { return .null }
            
            let maskCIImage: CIImage = .init(cvImageBuffer: segmentationMask)
            
            let maskScaleX = sourceCIImage.extent.width / maskCIImage.extent.width
            let maskScaleY = sourceCIImage.extent.height / maskCIImage.extent.height
            
            let scaledMaskCIImage: CIImage = maskCIImage
                .transformed(
                    by: CGAffineTransform(scaleX: maskScaleX, y: maskScaleY)
                )
            
            async let contoursObservations: [VNContoursObservation]? = try performDetectContoursRequest(
                sourceImage: scaledMaskCIImage,
                imageOrientation: self.sourceImageOrientation,
                contrastAdjustment: 1.0,
                detectsDarkOnLight: false
            )
            
            async let faceObservations: [VNFaceObservation]? = try performFaceLandmarksRequest(
                sourceImage: sourceCIImage,
                imageOrientation: self.sourceImageOrientation
            )
            
            guard let firstContourObservation = try await contoursObservations?.first else { return .null }
            
            guard let firstFaceObservation = try await faceObservations?.first else { return .null }
            
            let segmentationMaskPersonContour: VNContour? = firstContourObservation.topLevelContours.max { $0.pointCount < $1.pointCount }
            
            guard let segmentationMaskPersonContour = segmentationMaskPersonContour else { return .null }
            
            let segmentationMaskPersonContourNormalizedBoundingBox: CGRect = segmentationMaskPersonContour.normalizedPath.boundingBox
            
            let denormalizedContourBoundingBox: CGRect = VNImageRectForNormalizedRect(
                segmentationMaskPersonContourNormalizedBoundingBox,
                Int(sourceImageSize.width),
                Int(sourceImageSize.height)
            )

            guard let faceContourLandmark2D = firstFaceObservation.landmarks?.faceContour else { return .null }
            
            let denormalizedFaceContourPoints: [CGPoint] = faceContourLandmark2D.pointsInImage(imageSize: sourceImageSize)
            
            let faceNormalizedRectangle: CGRect = firstFaceObservation.boundingBox
            
            let denormalizedFaceRectangle: CGRect = VNImageRectForNormalizedRect(
                faceNormalizedRectangle,
                Int(sourceImageSize.width),
                Int(sourceImageSize.height)
            )
            
            guard let bottomPointOfFaceWithHairRect: CGPoint = denormalizedFaceContourPoints.min(by: { $0.y < $1.y }) else { return .null }
            
            let bottomYOfFaceWithHairRect =  bottomPointOfFaceWithHairRect.y
            
            let topYOfFaceWithHairRect: CGFloat = denormalizedContourBoundingBox.maxY
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
