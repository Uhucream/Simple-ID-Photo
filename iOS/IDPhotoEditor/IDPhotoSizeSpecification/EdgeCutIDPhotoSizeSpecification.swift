//
//  EdgeCutIDPhotoSizeSpecification.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 派生サイズ (元サイズをカットして作るサイズ) の仕様書
struct EdgeCutIDPhotoSizeSpecification: IDPhotoSizeSpecification {
    let id: String

    /// カット元のサイズ仕様書
    let baseSize: FaceOccupancyIDPhotoSizeSpecification

    /// 下部のカット量
    let millimeterBottomCut: Measurement<UnitLength>

    /// 左右それぞれのカット量
    let millimeterHorizontalCutPerSide: Measurement<UnitLength>

    let requiresSubjectDetection: Bool = true

    var millimeterSize: MeasurementSize {
        let baseMillimeterWidth: Double = baseSize.millimeterSize.width.converted(to: .millimeters).value
        let baseMillimeterHeight: Double = baseSize.millimeterSize.height.converted(to: .millimeters).value

        let bottomCutMillimeters: Double = millimeterBottomCut.converted(to: .millimeters).value
        let horizontalCutPerSideMillimeters: Double = millimeterHorizontalCutPerSide.converted(to: .millimeters).value

        return MeasurementSize(
            width: .millimeters(baseMillimeterWidth - (horizontalCutPerSideMillimeters * 2)),
            height: .millimeters(baseMillimeterHeight - bottomCutMillimeters)
        )
    }

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        let baseCroppingRect: CGRect = try baseSize.croppingRect(for: subject)

        let baseMillimeterHeight: Double = baseSize.millimeterSize.height.converted(to: .millimeters).value

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
            throw IDPhotoEditor.Error.croppingRegionUnsatisfiable
        }

        return croppingRect
    }
}
