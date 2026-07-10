//
//  EdgeCutIDPhotoSizeTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Testing
import CoreGraphics
@testable import SimpleIDPhoto

@Suite("EdgeCutIDPhotoSizeSpecification (派生サイズ: 元サイズからのカット)")
struct EdgeCutIDPhotoSizeTests {

    private let subject: IDPhotoSubject = .init(
        imageExtent: CGRect(x: 0, y: 0, width: 3000, height: 4000),
        faceWithHairRect: CGRect(x: 1200, y: 2000, width: 600, height: 900),
        crownY: 2900,
        chinY: 2000,
        eyeCenterY: 2450
    )

    /// 元サイズ 30 × 40 mm。この被写体でのクロップ矩形は (937.5, 1550, 1125, 1500)
    private let baseSize: FaceOccupancyIDPhotoSizeSpecification = .init(
        id: "test.base.w30h40",
        dimensions: MeasurementSize(width: .millimeters(30), height: .millimeters(40)),
        millimeterFaceHeight: .millimeters(24),
        millimeterCrownMargin: .millimeters(4)
    )

    @Test("下部カット: 上端は固定され、origin.y が上がり高さが減る")
    func bottomCutKeepsTopEdgeFixed() throws {
        let specification: EdgeCutIDPhotoSizeSpecification = .init(
            id: "test.square30",
            baseSize: baseSize,
            millimeterBottomCut: .millimeters(10),
            millimeterHorizontalCutPerSide: .zero
        )

        let baseRect: CGRect = try baseSize.croppingRect(for: subject)
        let croppingRect: CGRect = try specification.croppingRect(for: subject)

        //  px/mm = 1500 / 40 = 37.5 → 下部カット 10mm = 375px
        #expect(abs(croppingRect.origin.y - (baseRect.origin.y + 375)) < 0.0001)
        #expect(abs(croppingRect.height - (baseRect.height - 375)) < 0.0001)

        //  上端 (CoreImage 座標系の maxY) は固定
        #expect(abs(croppingRect.maxY - baseRect.maxY) < 0.0001)

        //  横カットなし
        #expect(abs(croppingRect.origin.x - baseRect.origin.x) < 0.0001)
        #expect(abs(croppingRect.width - baseRect.width) < 0.0001)
    }

    @Test("左右カット: 左右均等に詰められる")
    func horizontalCutIsSymmetric() throws {
        let specification: EdgeCutIDPhotoSizeSpecification = .init(
            id: "test.cut",
            baseSize: baseSize,
            millimeterBottomCut: .millimeters(10),
            millimeterHorizontalCutPerSide: .millimeters(5)
        )

        let baseRect: CGRect = try baseSize.croppingRect(for: subject)
        let croppingRect: CGRect = try specification.croppingRect(for: subject)

        //  px/mm = 37.5 → 左右各 5mm = 187.5px
        #expect(abs(croppingRect.origin.x - (baseRect.origin.x + 187.5)) < 0.0001)
        #expect(abs(croppingRect.width - (baseRect.width - 375)) < 0.0001)

        //  中心の X は変わらない
        #expect(abs(croppingRect.midX - baseRect.midX) < 0.0001)
    }

    @Test("millimeterSize はカット後の寸法を返す")
    func millimeterSizeReflectsCuts() {
        let specification: EdgeCutIDPhotoSizeSpecification = .init(
            id: "test.cut",
            baseSize: baseSize,
            millimeterBottomCut: .millimeters(10),
            millimeterHorizontalCutPerSide: .millimeters(5)
        )

        #expect(specification.millimeterSize == MeasurementSize(width: .millimeters(20), height: .millimeters(30)))
    }
}
