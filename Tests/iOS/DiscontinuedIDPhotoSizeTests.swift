//
//  DiscontinuedIDPhotoSizeTests.swift
//  Simple ID Photo Tests
//
//  Created by TakashiUshikoshi on 2026/07/10
//
//

import Testing
import CoreGraphics
import Foundation
@testable import SimpleIDPhoto

@Suite("DiscontinuedIDPhotoSize (廃止された規格サイズ)")
struct DiscontinuedIDPhotoSizeTests {

    /// 手計算しやすい値の被写体。
    /// 顔 (髪込み) は x: 1200, 下端 (顎): 2000, 上端 (頭頂): 2900, 幅: 600
    private let subject: IDPhotoSubject = .init(
        imageExtent: CGRect(x: 0, y: 0, width: 3000, height: 4000),
        faceWithHairRect: CGRect(x: 1200, y: 2000, width: 600, height: 900),
        crownY: 2900,
        chinY: 2000,
        eyeCenterY: 2450
    )

    @Test("mm 実寸から復元した ID が寸法を表す")
    func idReflectsMillimeterDimensions() {
        let discontinuedSize: DiscontinuedIDPhotoSize = .init(millimeterWidth: 40, millimeterHeight: 50)

        #expect(discontinuedSize.id == "discontinued.w40h50")
    }

    @Test("millimeterSize が復元元の mm 実寸と一致する")
    func millimeterSizeMatchesReconstructedDimensions() {
        let discontinuedSize: DiscontinuedIDPhotoSize = .init(millimeterWidth: 40, millimeterHeight: 50)

        #expect(discontinuedSize.millimeterSize == MeasurementSize(width: .millimeters(40), height: .millimeters(50)))
    }

    @Test("標準の写り方で旧クロップ数式と同一の矩形を再現する")
    func croppingRectMatchesLegacyFormula() throws {
        let discontinuedSize: DiscontinuedIDPhotoSize = .init(millimeterWidth: 40, millimeterHeight: 50)

        let croppingRect: CGRect = try discontinuedSize.croppingRect(for: subject)

        //  顔占有率 (50 × 0.6) / 50 = 0.6 → 高さ = 900 / 0.6 = 1500
        //  幅 = 1500 × (40/50) = 1200
        //  頭上余白 = 1500 × (4/50) = 120
        //  originX = 1200 - (1200 - 600) / 2 = 900
        //  originY = (2900 + 120) - 1500 = 1520
        #expect(abs(croppingRect.origin.x - 900) < 0.0001)
        #expect(abs(croppingRect.origin.y - 1520) < 0.0001)
        #expect(abs(croppingRect.width - 1200) < 0.0001)
        #expect(abs(croppingRect.height - 1500) < 0.0001)
    }
}
