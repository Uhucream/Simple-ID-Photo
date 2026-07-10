//
//  IDPhotoEditor.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

/// 証明写真エディタ。
///
/// 現実世界のエディタのメタファーで動作する: 写真を投げ込み、背景色の合成 (`painted(with:)`) と
/// 切り抜き (`cropped(to:)`) を依頼する。エディタは「作業画像」を保持しており、
/// `painted(with:)` は常に元画像から再合成して作業画像を差し替え、
/// `cropped(to:)` は作業画像を変異させずに切り抜き結果を返す。
/// したがって、ペイントとクロップをどの順番・回数で呼んでも画質は劣化せず、
/// 常に「最新の背景色 × 指定サイズ」の結果が得られる。
///
/// 座標系はすべて CoreImage 座標系 (原点は左下、単位は px)。
///
/// - Note: `painted(with:)` と `cropped(to:)` はどちらを先に呼んでもよい (呼び出し順に制約はない)。
actor IDPhotoEditor {

    let sourceCIImage: CIImage
    let sourceOrientation: CGImagePropertyOrientation

    //  被写体の検出結果 (初回の検出後にキャッシュされる)
    private var cachedSubject: IDPhotoSubject?

    //  背景合成用の人物マスク (初回の生成後にキャッシュされる)
    private var cachedPersonMaskCIImage: CIImage?

    //  作業画像 (初期値は元画像。painted(with:) で差し替えられる)
    private var workingCIImage: CIImage

    private var appliedBackgroundColor: IDPhotoBackgroundColor?

    //  VNImageRequestHandler.perform は同期かつ高負荷なため、専用のキューで実行して
    //  Swift Concurrency の協調スレッドプールをブロックしないようにする
    private static let visionRequestQueue: DispatchQueue = .init(
        label: "IDPhotoEditor.VisionRequest",
        qos: .userInitiated
    )

    /// - Parameters:
    ///   - sourceCIImage: 元画像
    ///   - orientation: 元画像の Exif orientation
    ///   - precomputedSubject: 永続化済みの検出結果。渡された場合、被写体検出の Vision 実行をスキップする
    ///   - precomputedPersonMaskCIImage: テスト用のスタブマスク。渡された場合、マスク生成の Vision 実行をスキップする
    init(
        sourceCIImage: CIImage,
        orientation: CGImagePropertyOrientation,
        precomputedSubject: IDPhotoSubject? = nil,
        precomputedPersonMaskCIImage: CIImage? = nil
    ) {
        self.sourceCIImage = sourceCIImage
        self.sourceOrientation = orientation

        self.cachedSubject = precomputedSubject
        self.cachedPersonMaskCIImage = precomputedPersonMaskCIImage

        self.workingCIImage = sourceCIImage
    }
}

//  MARK: - 公開 API
extension IDPhotoEditor {

    /// 被写体の検出結果を返す
    ///
    /// 未検出の場合は Vision を実行して検出する
    func detectedSubject() async throws -> IDPhotoSubject {
        if let cachedSubject = cachedSubject { return cachedSubject }

        let detectedSubject: IDPhotoSubject = try await detectSubject()

        self.cachedSubject = detectedSubject

        return detectedSubject
    }

    /// 検出済みの場合のみ被写体の検出結果を返す
    ///
    /// Vision は実行しない
    func alreadyDetectedSubject() -> IDPhotoSubject? {
        return cachedSubject
    }

    /// 背景色を合成し、元画像サイズの合成済み画像を返す
    ///
    /// 常に元画像から再合成するため、何度色を変えても画質は劣化しない
    @discardableResult
    func painted(with backgroundColor: IDPhotoBackgroundColor) async throws -> IDPhoto {
        switch backgroundColor {

        case .clear:
            self.workingCIImage = sourceCIImage
            self.appliedBackgroundColor = backgroundColor

            return IDPhoto(
                ciImage: sourceCIImage,
                appliedBackgroundColor: backgroundColor,
                appliedCroppingRect: nil
            )

        case .solid:
            let backgroundCIColor: CIColor? = .init(idPhotoBackgroundColor: backgroundColor)

            guard let backgroundCIColor = backgroundCIColor else {
                throw IDPhotoEditorError.invalidBackgroundColor
            }

            let solidColorBackgroundCIImage: CIImage = CIImage(color: backgroundCIColor)
                .cropped(to: CGRect(origin: .zero, size: sourceCIImage.extent.size))

            let personMaskCIImage: CIImage = try await personMask()

            let paintedCIImage: CIImage = Self.blended(
                source: sourceCIImage,
                personMask: personMaskCIImage,
                background: solidColorBackgroundCIImage
            )

            self.workingCIImage = paintedCIImage
            self.appliedBackgroundColor = backgroundColor

            return IDPhoto(
                ciImage: paintedCIImage,
                appliedBackgroundColor: backgroundColor,
                appliedCroppingRect: nil
            )
        }
    }

    /// 仕様書が生成したクロップ矩形で、現在の作業画像を切り抜いて返す
    ///
    /// 作業画像は変異しないため、続けて `painted(with:)` を呼んでも切り抜きの影響は受けない
    func cropped(to specification: any IDPhotoSizeSpecification) async throws -> IDPhoto {
        let subject: IDPhotoSubject

        if specification.requiresSubjectDetection {
            subject = try await detectedSubject()
        } else {
            subject = IDPhotoSubject(
                imageExtent: sourceCIImage.extent,
                faceWithHairRect: .null,
                crownY: .zero,
                chinY: .zero,
                eyeCenterY: nil
            )
        }

        let croppingRect: CGRect = try specification.croppingRect(for: subject)

        let croppedCIImage: CIImage = workingCIImage.cropped(to: croppingRect)

        return IDPhoto(
            ciImage: croppedCIImage,
            appliedBackgroundColor: appliedBackgroundColor,
            appliedCroppingRect: croppingRect
        )
    }
}

//  MARK: - 合成
extension IDPhotoEditor {

    /// マスクの白い領域に source を、黒い領域に background を合成する
    ///
    /// マスクと背景は source の extent に合わせて拡大される
    static func blended(
        source: CIImage,
        personMask: CIImage,
        background: CIImage
    ) -> CIImage {

        let sourceSize: CGSize = source.extent.size

        let maskScaleX: CGFloat = sourceSize.width / personMask.extent.width
        let maskScaleY: CGFloat = sourceSize.height / personMask.extent.height

        let scaledMaskCIImage: CIImage = personMask.transformed(
            by: CGAffineTransform(scaleX: maskScaleX, y: maskScaleY)
        )

        let backgroundScaleX: CGFloat = sourceSize.width / background.extent.width
        let backgroundScaleY: CGFloat = sourceSize.height / background.extent.height

        let scaledBackgroundCIImage: CIImage = background.transformed(
            by: CGAffineTransform(scaleX: backgroundScaleX, y: backgroundScaleY)
        )

        let blendedCIImage: CIImage = source.applyingFilter(
            CIFilter.blendWithMask().name,
            parameters: [
                kCIInputMaskImageKey: scaledMaskCIImage,
                kCIInputBackgroundImageKey: scaledBackgroundCIImage
            ]
        )

        return blendedCIImage
    }
}

//  MARK: - 人物マスク生成
extension IDPhotoEditor {

    //  背景合成用の人物マスク (キャッシュされる)
    private func personMask() async throws -> CIImage {
        if let cachedPersonMaskCIImage = cachedPersonMaskCIImage { return cachedPersonMaskCIImage }

        let maskPixelBuffer: CVPixelBuffer?

        if #available(iOS 17, *) {
            maskPixelBuffer = try await generatePersonInstanceMaskPixelBuffer()
        } else {
            maskPixelBuffer = try await generatePersonSegmentationMaskPixelBuffer(qualityLevel: .accurate)
        }

        guard let maskPixelBuffer = maskPixelBuffer else {
            throw IDPhotoEditorError.personNotDetected
        }

        let personMaskCIImage: CIImage = .init(cvImageBuffer: maskPixelBuffer)

        self.cachedPersonMaskCIImage = personMaskCIImage

        return personMaskCIImage
    }

    //  頭頂検出 (輪郭検出) 用のマスク。
    //  iOS 17 以降は背景合成用と同じインスタンスマスクを共用し、それ未満は balanced 品質のマスクを生成する
    private func contourDetectionMask() async throws -> CIImage {
        if #available(iOS 17, *) {
            return try await personMask()
        }

        let maskPixelBuffer: CVPixelBuffer? = try await generatePersonSegmentationMaskPixelBuffer(qualityLevel: .balanced)

        guard let maskPixelBuffer = maskPixelBuffer else {
            throw IDPhotoEditorError.personNotDetected
        }

        return CIImage(cvImageBuffer: maskPixelBuffer)
    }

    private func generatePersonSegmentationMaskPixelBuffer(
        qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel
    ) async throws -> CVPixelBuffer? {

        let segmentationRequest: VNGeneratePersonSegmentationRequest = .init()

        segmentationRequest.preferBackgroundProcessing = true

        segmentationRequest.qualityLevel = qualityLevel
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceCIImage,
            orientation: sourceOrientation
        )

        try await Self.perform([segmentationRequest], on: imageRequestHandler)

        return segmentationRequest.results?.first?.pixelBuffer
    }

    @available(iOS 17, *)
    private func generatePersonInstanceMaskPixelBuffer() async throws -> CVPixelBuffer? {

        let personInstanceMaskRequest: VNGeneratePersonInstanceMaskRequest = .init()

        personInstanceMaskRequest.preferBackgroundProcessing = true

        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: sourceCIImage,
            orientation: sourceOrientation
        )

        try await Self.perform([personInstanceMaskRequest], on: imageRequestHandler)

        guard let personInstanceMaskResult = personInstanceMaskRequest.results?.first else { return nil }

        //  MARK: 複数人物対応の拡張ポイント。
        //  将来「対象人物の選択」を実装する場合は、選択されたインスタンスをここに渡す (現状は最前面の1人固定)
        let targetPersonInstances: IndexSet = .init(integer: 1)

        let targetPersonInstanceMask: CVPixelBuffer = try personInstanceMaskResult.generateScaledMaskForImage(
            forInstances: targetPersonInstances,
            from: imageRequestHandler
        )

        return targetPersonInstanceMask
    }
}

//  MARK: - 被写体検出
extension IDPhotoEditor {

    //  被写体を検出する。
    //  VNDetectFaceLandmarksRequest の結果には頭頂の座標が含まれないため、
    //  人物マスクを VNDetectContoursRequest にかけて人物輪郭の上端を頭頂として得る
    private func detectSubject() async throws -> IDPhotoSubject {
        let sourceImageExtent: CGRect = sourceCIImage.extent
        let sourceImageSize: CGSize = sourceImageExtent.size

        let contourDetectionMaskCIImage: CIImage = try await contourDetectionMask()

        let maskScaleX: CGFloat = sourceImageSize.width / contourDetectionMaskCIImage.extent.width
        let maskScaleY: CGFloat = sourceImageSize.height / contourDetectionMaskCIImage.extent.height

        let scaledMaskCIImage: CIImage = contourDetectionMaskCIImage.transformed(
            by: CGAffineTransform(scaleX: maskScaleX, y: maskScaleY)
        )

        async let contoursObservationsTask: [VNContoursObservation]? = detectContours(on: scaledMaskCIImage)
        async let faceObservationsTask: [VNFaceObservation]? = detectFaceLandmarks(on: sourceCIImage)

        let contoursObservations: [VNContoursObservation]? = try await contoursObservationsTask
        let faceObservations: [VNFaceObservation]? = try await faceObservationsTask

        guard let personContourObservation = contoursObservations?.first else {
            throw IDPhotoEditorError.personNotDetected
        }

        guard let faceObservation = faceObservations?.first else {
            throw IDPhotoEditorError.faceNotDetected
        }

        let personContour: VNContour? = personContourObservation.topLevelContours.max { $0.pointCount < $1.pointCount }

        guard let personContour = personContour else {
            throw IDPhotoEditorError.personNotDetected
        }

        let personContourNormalizedBoundingBox: CGRect = personContour.normalizedPath.boundingBox

        let personContourBoundingBox: CGRect = VNImageRectForNormalizedRect(
            personContourNormalizedBoundingBox,
            Int(sourceImageSize.width),
            Int(sourceImageSize.height)
        )

        guard let faceContourLandmark = faceObservation.landmarks?.faceContour else {
            throw IDPhotoEditorError.faceNotDetected
        }

        let faceContourPoints: [CGPoint] = faceContourLandmark.pointsInImage(imageSize: sourceImageSize)

        guard let chinPoint: CGPoint = faceContourPoints.min(by: { $0.y < $1.y }) else {
            throw IDPhotoEditorError.faceNotDetected
        }

        let faceBoundingBox: CGRect = VNImageRectForNormalizedRect(
            faceObservation.boundingBox,
            Int(sourceImageSize.width),
            Int(sourceImageSize.height)
        )

        let crownY: CGFloat = personContourBoundingBox.maxY
        let chinY: CGFloat = chinPoint.y

        let eyeCenterY: CGFloat? = {
            let leftPupilPoints: [CGPoint] = faceObservation.landmarks?.leftPupil?.pointsInImage(imageSize: sourceImageSize) ?? []
            let rightPupilPoints: [CGPoint] = faceObservation.landmarks?.rightPupil?.pointsInImage(imageSize: sourceImageSize) ?? []

            let pupilPoints: [CGPoint] = leftPupilPoints + rightPupilPoints

            guard pupilPoints.isEmpty == false else { return nil }

            let averageY: CGFloat = pupilPoints.map(\.y).reduce(.zero, +) / CGFloat(pupilPoints.count)

            return averageY
        }()

        let faceWithHairRect: CGRect = .init(
            origin: CGPoint(
                x: faceBoundingBox.origin.x,
                y: chinY
            ),
            size: CGSize(
                width: faceBoundingBox.width,
                height: crownY - chinY
            )
        )

        return IDPhotoSubject(
            imageExtent: sourceImageExtent,
            faceWithHairRect: faceWithHairRect,
            crownY: crownY,
            chinY: chinY,
            eyeCenterY: eyeCenterY
        )
    }

    private func detectContours(on maskCIImage: CIImage) async throws -> [VNContoursObservation]? {

        let detectContoursRequest: VNDetectContoursRequest = .init()

        detectContoursRequest.preferBackgroundProcessing = true

        detectContoursRequest.contrastAdjustment = 1.0
        detectContoursRequest.maximumImageDimension = 512
        detectContoursRequest.detectsDarkOnLight = false

        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: maskCIImage,
            orientation: sourceOrientation
        )

        try await Self.perform([detectContoursRequest], on: imageRequestHandler)

        return detectContoursRequest.results
    }

    private func detectFaceLandmarks(on image: CIImage) async throws -> [VNFaceObservation]? {

        let faceLandmarksRequest: VNDetectFaceLandmarksRequest = .init()

        faceLandmarksRequest.preferBackgroundProcessing = true

        let imageRequestHandler: VNImageRequestHandler = .init(
            ciImage: image,
            orientation: sourceOrientation
        )

        try await Self.perform([faceLandmarksRequest], on: imageRequestHandler)

        return faceLandmarksRequest.results
    }
}

//  MARK: - Vision リクエスト実行
extension IDPhotoEditor {

    private static func perform(
        _ requests: [VNRequest],
        on imageRequestHandler: VNImageRequestHandler
    ) async throws {

        try await withTaskCancellationHandler {
            try Task.checkCancellation()

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                visionRequestQueue.async {
                    do {
                        try imageRequestHandler.perform(requests)

                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            requests.forEach { $0.cancel() }
        }
    }
}
