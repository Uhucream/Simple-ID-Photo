//
//  EdgeCutIDPhotoSizeSpecification.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 派生サイズ (元サイズをカットして作るサイズ) の仕様書。
///
/// DNP の仕様に基づき、縦方向のカットは写真の下部のみ (上端は固定)、横方向のカットは左右均等。
/// 詳細は `.claude/docs/photo_size_spec.md` 第7章を参照。
struct EdgeCutIDPhotoSizeSpecification: IDPhotoSizeSpecification {

    let id: String

    /// カット元のサイズ仕様書
    let baseSize: FaceOccupancyIDPhotoSizeSpecification

    /// 下部のカット量
    let millimeterBottomCut: Measurement<UnitLength>

    /// 左右それぞれのカット量
    let millimeterHorizontalCutPerSide: Measurement<UnitLength>

    var millimeterSize: MeasurementSize? {
        let baseMillimeterWidth: Double = baseSize.dimensions.width.converted(to: .millimeters).value
        let baseMillimeterHeight: Double = baseSize.dimensions.height.converted(to: .millimeters).value

        let bottomCutMillimeters: Double = millimeterBottomCut.converted(to: .millimeters).value
        let horizontalCutPerSideMillimeters: Double = millimeterHorizontalCutPerSide.converted(to: .millimeters).value

        return MeasurementSize(
            width: .millimeters(baseMillimeterWidth - (horizontalCutPerSideMillimeters * 2)),
            height: .millimeters(baseMillimeterHeight - bottomCutMillimeters)
        )
    }

    init(
        id: String,
        baseSize: FaceOccupancyIDPhotoSizeSpecification,
        millimeterBottomCut: Measurement<UnitLength>,
        millimeterHorizontalCutPerSide: Measurement<UnitLength>
    ) {
        self.id = id
        self.baseSize = baseSize

        self.millimeterBottomCut = millimeterBottomCut
        self.millimeterHorizontalCutPerSide = millimeterHorizontalCutPerSide
    }

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        let baseCroppingRect: CGRect = try baseSize.croppingRect(for: subject)

        let baseMillimeterHeight: Double = baseSize.dimensions.height.converted(to: .millimeters).value

        let pixelsPerMillimeter: CGFloat = baseCroppingRect.height / baseMillimeterHeight

        let bottomCut: CGFloat = millimeterBottomCut.converted(to: .millimeters).value * pixelsPerMillimeter
        let horizontalCutPerSide: CGFloat = millimeterHorizontalCutPerSide.converted(to: .millimeters).value * pixelsPerMillimeter

        //  CoreImage 座標系 (原点は左下) では、下部カット = origin.y を上げて高さを減らす (上端は固定される)
        let croppingRect: CGRect = .init(
            x: baseCroppingRect.origin.x + horizontalCutPerSide,
            y: baseCroppingRect.origin.y + bottomCut,
            width: baseCroppingRect.width - (horizontalCutPerSide * 2),
            height: baseCroppingRect.height - bottomCut
        )

        guard croppingRect.width > .zero, croppingRect.height > .zero else {
            throw IDPhotoEditorError.croppingRegionUnsatisfiable
        }

        return croppingRect
    }
}
