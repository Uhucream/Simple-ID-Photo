//
//  IDPhotoEditorStateTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Testing
import CoreImage
import CoreGraphics
@testable import SimpleIDPhoto

/// IDPhotoEditor の状態遷移テスト。
///
/// Vision は一切実行しない (スタブの被写体とマスクを注入する)。
/// 「ペイント → クロップ → ペイント」のように操作を交互に呼んでも、
/// 常に「最新の背景色 × 指定サイズ」が得られることを検証する。
@Suite("IDPhotoEditor の状態遷移 (Vision 非依存)")
struct IDPhotoEditorStateTests {

    private static let SOURCE_EXTENT: CGRect = .init(x: 0, y: 0, width: 400, height: 600)

    /// 左半分が白 (人物)、右半分が黒 (背景) のスタブマスク
    private static func makeStubPersonMask() -> CIImage {
        let blackBackgroundCIImage: CIImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0))
            .cropped(to: SOURCE_EXTENT)

        let whiteLeftHalfCIImage: CIImage = CIImage(color: CIColor(red: 1, green: 1, blue: 1))
            .cropped(to: CGRect(x: 0, y: 0, width: 200, height: 600))

        return whiteLeftHalfCIImage.composited(over: blackBackgroundCIImage)
    }

    private static func makeStubSubject() -> IDPhotoSubject {
        return IDPhotoSubject(
            imageExtent: SOURCE_EXTENT,
            faceWithHairRect: CGRect(x: 50, y: 300, width: 100, height: 150),
            crownY: 450,
            chinY: 300,
            eyeCenterY: 380
        )
    }

    /// 元画像は全面赤
    private static func makeEditor() -> IDPhotoEditor {
        let redSourceCIImage: CIImage = CIImage(color: CIColor(red: 1, green: 0, blue: 0))
            .cropped(to: SOURCE_EXTENT)

        return IDPhotoEditor(
            sourceCIImage: redSourceCIImage,
            orientation: .up,
            precomputedSubject: makeStubSubject(),
            precomputedPersonMaskCIImage: makeStubPersonMask()
        )
    }

    private struct StubCropSpecification: IDPhotoSizeSpecification {
        let id: String = "test.stub"
        let millimeterSize: MeasurementSize? = MeasurementSize(width: .millimeters(20), height: .millimeters(20))

        func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
            return CGRect(x: 100, y: 100, width: 200, height: 200)
        }
    }

    private struct ThrowingCropSpecification: IDPhotoSizeSpecification {
        let id: String = "test.throwing"
        let millimeterSize: MeasurementSize? = nil

        func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
            throw IDPhotoEditorError.croppingRegionUnsatisfiable
        }
    }

    private static let blueBackgroundColor: IDPhotoBackgroundColor = .solid(red: 0, green: 0, blue: 1, alpha: 1, colorSpace: .sRGB)

    private static let brownBackgroundColor: IDPhotoBackgroundColor = .solid(red: 0.6, green: 0.4, blue: 0.2, alpha: 1, colorSpace: .sRGB)

    /// 指定座標の 1px をレンダリングして RGBA (0-1) を返す
    private static func pixelComponents(of ciImage: CIImage, at point: CGPoint) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var bitmap: [UInt8] = .init(repeating: 0, count: 4)

        let ciContext: CIContext = .init(
            options: [
                .workingColorSpace: NSNull(),
                .outputColorSpace: NSNull()
            ]
        )

        ciContext.render(
            ciImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: point.x, y: point.y, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return (
            red: Double(bitmap[0]) / 255,
            green: Double(bitmap[1]) / 255,
            blue: Double(bitmap[2]) / 255,
            alpha: Double(bitmap[3]) / 255
        )
    }

    private static func expectPixel(
        of ciImage: CIImage,
        at point: CGPoint,
        isRed red: Double,
        green: Double,
        blue: Double,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let COMPONENT_TOLERANCE: Double = 0.03

        let components: (red: Double, green: Double, blue: Double, alpha: Double) = pixelComponents(of: ciImage, at: point)

        #expect(abs(components.red - red) < COMPONENT_TOLERANCE, sourceLocation: sourceLocation)
        #expect(abs(components.green - green) < COMPONENT_TOLERANCE, sourceLocation: sourceLocation)
        #expect(abs(components.blue - blue) < COMPONENT_TOLERANCE, sourceLocation: sourceLocation)
    }

    @Test("ペイント → クロップ → ペイント: 2回目のペイントは全体サイズで、前回の合成に重ね塗りされない")
    func paintCropPaintKeepsFullSizeAndLatestColor() async throws {
        let editor: IDPhotoEditor = Self.makeEditor()

        let bluePaintedIDPhoto: IDPhoto = try await editor.painted(with: Self.blueBackgroundColor)

        //  マスク左半分 = 人物 (赤)、右半分 = 背景 (青)
        Self.expectPixel(of: bluePaintedIDPhoto.ciImage, at: CGPoint(x: 100, y: 300), isRed: 1, green: 0, blue: 0)
        Self.expectPixel(of: bluePaintedIDPhoto.ciImage, at: CGPoint(x: 300, y: 300), isRed: 0, green: 0, blue: 1)

        let croppedIDPhoto: IDPhoto = try await editor.cropped(to: StubCropSpecification())

        #expect(croppedIDPhoto.appliedCroppingRect == CGRect(x: 100, y: 100, width: 200, height: 200))

        let brownPaintedIDPhoto: IDPhoto = try await editor.painted(with: Self.brownBackgroundColor)

        //  クロップを挟んでも全体サイズのまま
        #expect(brownPaintedIDPhoto.ciImage.extent == Self.SOURCE_EXTENT)

        //  背景は青ではなく茶 (元画像から再合成されている)
        Self.expectPixel(of: brownPaintedIDPhoto.ciImage, at: CGPoint(x: 300, y: 300), isRed: 0.6, green: 0.4, blue: 0.2)

        //  人物側は元画像の赤のまま
        Self.expectPixel(of: brownPaintedIDPhoto.ciImage, at: CGPoint(x: 100, y: 300), isRed: 1, green: 0, blue: 0)
    }

    @Test("クロップ → ペイント → クロップ: 先行クロップは作業画像を変異させず、最後のクロップは最新の色 × 指定サイズを返す")
    func cropPaintCropReturnsLatestColorWithSpecifiedSize() async throws {
        let editor: IDPhotoEditor = Self.makeEditor()

        let firstCroppedIDPhoto: IDPhoto = try await editor.cropped(to: StubCropSpecification())

        //  ペイント前のクロップは元画像 (赤) の切り抜き
        #expect(firstCroppedIDPhoto.ciImage.extent == CGRect(x: 100, y: 100, width: 200, height: 200))
        Self.expectPixel(of: firstCroppedIDPhoto.ciImage, at: CGPoint(x: 150, y: 150), isRed: 1, green: 0, blue: 0)

        let bluePaintedIDPhoto: IDPhoto = try await editor.painted(with: Self.blueBackgroundColor)

        //  先行クロップの影響を受けず全体サイズ
        #expect(bluePaintedIDPhoto.ciImage.extent == Self.SOURCE_EXTENT)

        let secondCroppedIDPhoto: IDPhoto = try await editor.cropped(to: StubCropSpecification())

        #expect(secondCroppedIDPhoto.ciImage.extent == CGRect(x: 100, y: 100, width: 200, height: 200))

        //  クロップ範囲内の左側 (x < 200) は人物 (赤)、右側 (x > 200) は背景 (青)
        Self.expectPixel(of: secondCroppedIDPhoto.ciImage, at: CGPoint(x: 120, y: 200), isRed: 1, green: 0, blue: 0)
        Self.expectPixel(of: secondCroppedIDPhoto.ciImage, at: CGPoint(x: 280, y: 200), isRed: 0, green: 0, blue: 1)

        //  適用済みの背景色が結果に引き継がれる
        #expect(secondCroppedIDPhoto.appliedBackgroundColor == Self.blueBackgroundColor)
    }

    @Test("「背景色なし」でペイントすると作業画像が元画像に戻る")
    func paintingWithOriginalRestoresSourceImage() async throws {
        let editor: IDPhotoEditor = Self.makeEditor()

        try await editor.painted(with: Self.blueBackgroundColor)

        let originalPaintedIDPhoto: IDPhoto = try await editor.painted(with: .clear)

        //  背景 (右半分) も元画像の赤に戻る
        Self.expectPixel(of: originalPaintedIDPhoto.ciImage, at: CGPoint(x: 300, y: 300), isRed: 1, green: 0, blue: 0)
    }

    @Test("オリジナルサイズ仕様書でのクロップは画像全体を返す")
    func croppingToOriginalSizeReturnsFullExtent() async throws {
        let editor: IDPhotoEditor = Self.makeEditor()

        let croppedIDPhoto: IDPhoto = try await editor.cropped(to: OriginalSizeSpecification())

        #expect(croppedIDPhoto.ciImage.extent == Self.SOURCE_EXTENT)
        #expect(croppedIDPhoto.appliedCroppingRect == Self.SOURCE_EXTENT)
    }

    @Test("仕様書が throw した場合、エディタはそのまま rethrow する")
    func croppingRethrowsSpecificationError() async {
        let editor: IDPhotoEditor = Self.makeEditor()

        await #expect(throws: IDPhotoEditorError.self) {
            try await editor.cropped(to: ThrowingCropSpecification())
        }
    }
}
