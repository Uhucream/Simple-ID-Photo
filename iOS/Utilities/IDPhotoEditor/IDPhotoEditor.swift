//
//  IDPhotoEditor.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2025/02/10
//

import CoreGraphics
import CoreImage
import Foundation
import SwiftUI
import UIKit
import Vision

public final class IDPhotoEditor {
    public let sourceImage: CIImage
    public let outputResolution: OutputResolution
    public let sourceImageOrientation: CGImagePropertyOrientation

    private var cachedFaceArea: DetectedFaceArea?
    private var cachedSegmentationMask: CIImage?
    private var cachedContourMask: CIImage?
    private var paintedOriginalSizeImage: CIImage
    private var currentSelectedBackgroundColor: Color?
    private var currentCroppingRule: CroppingRule?

    public init(
        sourceImage: CIImage,
        outputResolution: OutputResolution = .airPrint,
        sourceImageOrientation: CGImagePropertyOrientation = .up
    ) {
        self.sourceImage = sourceImage
        self.outputResolution = outputResolution
        self.sourceImageOrientation = sourceImageOrientation
        self.paintedOriginalSizeImage = sourceImage
    }

    public func prepare() async throws {
        if cachedFaceArea == nil {
            cachedFaceArea = try await loadFaceArea()
        }
        if cachedSegmentationMask == nil {
            cachedSegmentationMask = try await loadSegmentationMask()
        }
        if cachedContourMask == nil {
            cachedContourMask = try await loadContourMask()
        }
    }

    public func croppedImage(using rule: CroppingRule) async throws -> CIImage {
        currentCroppingRule = rule
        let faceArea = try await loadFaceArea()
        let croppingRect = rule.cropRect(in: sourceImage.extent, faceArea: faceArea)
        if croppingRect == .null || croppingRect.isEmpty {
            return paintedOriginalSizeImage
        }

        return paintedOriginalSizeImage.cropped(to: croppingRect)
    }

    public func paintedImage(with color: Color) async throws -> CIImage {
        if currentSelectedBackgroundColor == color {
            return applyCurrentCrop(to: paintedOriginalSizeImage)
        }

        if color == .clear {
            currentSelectedBackgroundColor = color
            paintedOriginalSizeImage = sourceImage
            return applyCurrentCrop(to: sourceImage)
        }

        let mask = try await loadSegmentationMask()

        let cgColor: CGColor? = {
            if #available(iOS 17, *) {
                return color.resolve(in: EnvironmentValues()).cgColor
            }

            return color.cgColor ?? UIColor(color).cgColor
        }()

        guard let cgColor else {
            throw EditorError.invalidBackgroundColor
        }

        let background = CIImage(color: CIColor(cgColor: cgColor))
            .cropped(to: CGRect(origin: .zero, size: sourceImage.extent.size))

        let paintedImage = sourceImage.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputMaskImageKey: mask,
                kCIInputBackgroundImageKey: background
            ]
        )

        currentSelectedBackgroundColor = color
        paintedOriginalSizeImage = paintedImage
        return applyCurrentCrop(to: paintedImage)
    }
}

public extension IDPhotoEditor {
    enum EditorError: Error {
        case invalidBackgroundColor
        case missingSegmentationMask
        case missingFaceArea
        case missingFaceContour
    }

    private func loadFaceArea() async throws -> DetectedFaceArea {
        if let cachedFaceArea {
            return cachedFaceArea
        }
        let faceArea = try await detectFaceArea()
        cachedFaceArea = faceArea
        return faceArea
    }

    private func loadSegmentationMask() async throws -> CIImage {
        if let cachedSegmentationMask {
            return cachedSegmentationMask
        }
        let mask = try await scaledSegmentationMask(from: sourceImage, qualityLevel: .accurate)
        cachedSegmentationMask = mask
        return mask
    }

    private func loadContourMask() async throws -> CIImage {
        if let cachedContourMask {
            return cachedContourMask
        }
        let mask = try await scaledSegmentationMask(from: sourceImage, qualityLevel: .balanced)
        cachedContourMask = mask
        return mask
    }

    private func applyCurrentCrop(to image: CIImage) -> CIImage {
        guard let currentCroppingRule, let cachedFaceArea else {
            return image
        }

        let croppingRect = currentCroppingRule.cropRect(in: sourceImage.extent, faceArea: cachedFaceArea)
        if croppingRect == .null || croppingRect.isEmpty { return image }

        return image.cropped(to: croppingRect)
    }
}

public extension IDPhotoEditor {
    struct OriginalSizeCroppingRule: CroppingRule, Sendable, Equatable {
        public let size: MeasurementSize = .zero

        public init() {}

        public func cropRect(in imageExtent: CGRect, faceArea: DetectedFaceArea) -> CGRect {
            imageExtent
        }
    }
}

private extension IDPhotoEditor {
    func scaledSegmentationMask(
        from image: CIImage,
        qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel
    ) async throws -> CIImage {
        if #unavailable(iOS 17) {
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = qualityLevel
            request.preferBackgroundProcessing = true

            let handler = VNImageRequestHandler(
                ciImage: image,
                orientation: sourceImageOrientation,
                options: [:]
            )
            try handler.perform([request])
            guard let pixelBuffer = request.results?.first?.pixelBuffer else {
                throw EditorError.missingSegmentationMask
            }

            let maskImage = CIImage(cvPixelBuffer: pixelBuffer)
            let scaleX = image.extent.width / maskImage.extent.width
            let scaleY = image.extent.height / maskImage.extent.height
            return maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        }

        guard #available(iOS 17, *) else {
            throw EditorError.missingSegmentationMask
        }

        let request = VNGeneratePersonInstanceMaskRequest()
        request.preferBackgroundProcessing = true

        let handler = VNImageRequestHandler(
            ciImage: image,
            orientation: sourceImageOrientation
        )
        try handler.perform([request])
        guard let result = request.results?.first else {
            throw EditorError.missingSegmentationMask
        }

        let foremostPersonInstanceMask = try result.generateScaledMaskForImage(
            forInstances: IndexSet(integer: 1),
            from: handler
        )
        let maskImage = CIImage(cvPixelBuffer: foremostPersonInstanceMask)
        let scaleX = image.extent.width / maskImage.extent.width
        let scaleY = image.extent.height / maskImage.extent.height
        return maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }

    func detectFaceArea() async throws -> DetectedFaceArea {
        let imageExtent = sourceImage.extent
        let imageSize = imageExtent.size

        async let segmentationMaskImage = loadContourMask()

        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        faceLandmarksRequest.preferBackgroundProcessing = true
        let faceHandler = VNImageRequestHandler(
            ciImage: sourceImage,
            orientation: sourceImageOrientation,
            options: [:]
        )

        try faceHandler.perform([faceLandmarksRequest])
        guard let faceObservation = faceLandmarksRequest.results?.first else {
            throw EditorError.missingFaceArea
        }
        guard let faceContour = faceObservation.landmarks?.faceContour else {
            throw EditorError.missingFaceContour
        }

        let contourRequest = VNDetectContoursRequest()
        contourRequest.detectsDarkOnLight = false
        contourRequest.preferBackgroundProcessing = true
        contourRequest.contrastAdjustment = 1.0

        let contourHandler = VNImageRequestHandler(
            ciImage: try await segmentationMaskImage,
            orientation: sourceImageOrientation
        )
        try contourHandler.perform([contourRequest])
        guard let contourObservation = contourRequest.results?.first else {
            throw EditorError.missingFaceArea
        }
        guard let humanContour = contourObservation.topLevelContours.max(by: { $0.pointCount < $1.pointCount }) else {
            throw EditorError.missingFaceArea
        }

        let contourBoundingBox = humanContour.normalizedPath.boundingBox
        let denormalizedContourBox = VNImageRectForNormalizedRect(
            contourBoundingBox,
            Int(imageSize.width),
            Int(imageSize.height)
        )

        let denormalizedFaceRect = VNImageRectForNormalizedRect(
            faceObservation.boundingBox,
            Int(imageSize.width),
            Int(imageSize.height)
        )

        let faceContourPoints = faceContour.pointsInImage(imageSize: imageSize)
        guard let bottomPoint = faceContourPoints.min(by: { $0.y < $1.y }) else {
            throw EditorError.missingFaceContour
        }

        let chinBottomY = bottomPoint.y
        let headTopY = denormalizedContourBox.maxY
        let faceBounds = CGRect(
            origin: CGPoint(x: denormalizedFaceRect.origin.x, y: chinBottomY),
            size: CGSize(width: denormalizedFaceRect.width, height: headTopY - chinBottomY)
        )

        return DetectedFaceArea(
            faceBounds: faceBounds,
            headTopY: headTopY,
            chinBottomY: chinBottomY
        )
    }
}

public extension IDPhotoEditor {
    struct DetectedFaceArea: Sendable, Equatable {
        public let faceBounds: CGRect
        public let headTopY: CGFloat
        public let chinBottomY: CGFloat

        public init(faceBounds: CGRect, headTopY: CGFloat, chinBottomY: CGFloat) {
            self.faceBounds = faceBounds
            self.headTopY = headTopY
            self.chinBottomY = chinBottomY
        }
    }
}

public extension IDPhotoEditor {
    struct OutputResolution: Sendable, Equatable {
        public let pixelDensity: Double

        public init(pixelDensity: Double) {
            self.pixelDensity = pixelDensity
        }

        public static let airPrint: OutputResolution = .init(pixelDensity: 72)
    }
}

public extension IDPhotoEditor {
    protocol CroppingRule: Sendable {
        var size: MeasurementSize { get }

        func cropRect(in imageExtent: CGRect, faceArea: DetectedFaceArea) -> CGRect
    }
}

public extension IDPhotoEditor {
    struct StandardCroppingRule: CroppingRule, Sendable, Equatable {
        public let size: MeasurementSize
        public let faceHeight: Measurement<UnitLength>
        public let marginTop: Measurement<UnitLength>

        public init(
            size: MeasurementSize,
            faceHeight: Measurement<UnitLength>,
            marginTop: Measurement<UnitLength>
        ) {
            self.size = size
            self.faceHeight = faceHeight
            self.marginTop = marginTop
        }

        public func cropRect(in imageExtent: CGRect, faceArea: DetectedFaceArea) -> CGRect {
            if faceArea.faceBounds == .null || faceArea.faceBounds.isEmpty { return .null }

            let faceHeightRatio: Double = faceHeight.value / size.height.value
            let aspectRatio: Double = size.width.value / size.height.value

            let idPhotoHeight: CGFloat = faceArea.faceBounds.height / faceHeightRatio
            let idPhotoWidth: CGFloat = idPhotoHeight * aspectRatio

            let marginTopRatio: Double = marginTop.value / size.height.value
            let marginTopLength: CGFloat = idPhotoHeight * marginTopRatio

            let remainingWidth: CGFloat = idPhotoWidth - faceArea.faceBounds.size.width
            let originX: CGFloat = faceArea.faceBounds.origin.x - (remainingWidth / 2)
            let originY: CGFloat = (faceArea.faceBounds.maxY + marginTopLength) - idPhotoHeight

            return CGRect(
                origin: CGPoint(x: originX, y: originY),
                size: CGSize(width: idPhotoWidth, height: idPhotoHeight)
            )
        }
    }
}

public extension IDPhotoEditor {
    struct PassportCroppingRule: CroppingRule, Sendable, Equatable {
        public let size: MeasurementSize = .init(
            width: .init(value: 35, unit: .millimeters),
            height: .init(value: 45, unit: .millimeters)
        )
        public let faceHeight: Measurement<UnitLength> = .init(value: 34, unit: .millimeters)
        public let topMargin: Measurement<UnitLength> = .init(value: 4, unit: .millimeters)

        public init() {}

        public func cropRect(in imageExtent: CGRect, faceArea: DetectedFaceArea) -> CGRect {
            let faceHeightPixels = faceArea.headTopY - faceArea.chinBottomY
            if faceHeightPixels <= 0 { return .null }

            let aspectRatio: Double = size.width.value / size.height.value
            let faceHeightRatio: Double = faceHeight.value / size.height.value

            let idealHeight: CGFloat = faceHeightPixels / faceHeightRatio
            let idealWidth: CGFloat = idealHeight * aspectRatio

            let marginTopRatio: Double = topMargin.value / size.height.value
            let marginTopLength: CGFloat = idealHeight * marginTopRatio

            let originX: CGFloat = faceArea.faceBounds.midX - (idealWidth / 2)
            let originY: CGFloat = (faceArea.headTopY + marginTopLength) - idealHeight

            let idealRect = CGRect(
                origin: CGPoint(x: originX, y: originY),
                size: CGSize(width: idealWidth, height: idealHeight)
            )

            if imageExtent.contains(idealRect) {
                return idealRect
            }

            let availableWidth: CGFloat = min(idealWidth, imageExtent.width)
            let adjustedHeight: CGFloat = availableWidth / aspectRatio
            let adjustedMarginTop: CGFloat = adjustedHeight * marginTopRatio
            let adjustedOriginX: CGFloat = faceArea.faceBounds.midX - (availableWidth / 2)
            let adjustedOriginY: CGFloat = (faceArea.headTopY + adjustedMarginTop) - adjustedHeight

            return CGRect(
                origin: CGPoint(x: adjustedOriginX, y: adjustedOriginY),
                size: CGSize(width: availableWidth, height: adjustedHeight)
            )
        }
    }
}

public extension IDPhotoEditor {
    struct TrimmedCroppingRule: CroppingRule, Sendable, Equatable {
        public struct Insets: Sendable, Equatable {
            public let top: Measurement<UnitLength>
            public let bottom: Measurement<UnitLength>
            public let leading: Measurement<UnitLength>
            public let trailing: Measurement<UnitLength>

            public init(
                top: Measurement<UnitLength>,
                bottom: Measurement<UnitLength>,
                leading: Measurement<UnitLength>,
                trailing: Measurement<UnitLength>
            ) {
                self.top = top
                self.bottom = bottom
                self.leading = leading
                self.trailing = trailing
            }
        }

        public let baseRule: CroppingRule
        public let trimInsets: Insets

        public init(baseRule: CroppingRule, trimInsets: Insets) {
            self.baseRule = baseRule
            self.trimInsets = trimInsets
        }

        public var size: MeasurementSize {
            baseRule.size
        }

        public func cropRect(in imageExtent: CGRect, faceArea: DetectedFaceArea) -> CGRect {
            let baseRect = baseRule.cropRect(in: imageExtent, faceArea: faceArea)
            if baseRect == .null || baseRect.isEmpty { return baseRect }

            let widthRatio = CGFloat(trimInsets.leading.value + trimInsets.trailing.value) / size.width.value
            let heightRatio = CGFloat(trimInsets.top.value + trimInsets.bottom.value) / size.height.value

            let trimWidth: CGFloat = baseRect.width * widthRatio
            let trimHeight: CGFloat = baseRect.height * heightRatio

            let originX = baseRect.origin.x + (baseRect.width * CGFloat(trimInsets.leading.value / size.width.value))
            let originY = baseRect.origin.y + (baseRect.height * CGFloat(trimInsets.bottom.value / size.height.value))

            return CGRect(
                origin: CGPoint(x: originX, y: originY),
                size: CGSize(width: baseRect.width - trimWidth, height: baseRect.height - trimHeight)
            )
        }
    }
}
public extension IDPhotoEditor.CroppingRule where Self == IDPhotoEditor.PassportCroppingRule {
    static var passport: Self {
        .init()
    }
}

public extension IDPhotoEditor.CroppingRule where Self == IDPhotoEditor.OriginalSizeCroppingRule {
    static var original: Self {
        .init()
    }
}

public extension IDPhotoEditor.CroppingRule where Self == IDPhotoEditor.StandardCroppingRule {
    static var w30_h24: Self {
        standardRule(width: 30, height: 24)
    }

    static var w40_h30: Self {
        standardRule(width: 40, height: 30)
    }

    static var w45_h35: Self {
        standardRule(width: 45, height: 35)
    }

    static var w25_h25: Self {
        standardRule(width: 25, height: 25)
    }

    static var w30_h25: Self {
        standardRule(width: 30, height: 25)
    }

    static var w30_h30: Self {
        standardRule(width: 30, height: 30)
    }

    static var w60_h40: Self {
        standardRule(width: 60, height: 40)
    }

    static var w60_h45: Self {
        standardRule(width: 60, height: 45)
    }

    private static func standardRule(width: Double, height: Double) -> Self {
        let size = MeasurementSize(
            width: .init(value: width, unit: .millimeters),
            height: .init(value: height, unit: .millimeters)
        )
        let faceHeight = Measurement<UnitLength>(
            value: height * 0.6,
            unit: .millimeters
        )
        let marginTop = Measurement<UnitLength>(value: 4, unit: .millimeters)

        return .init(size: size, faceHeight: faceHeight, marginTop: marginTop)
    }
}
