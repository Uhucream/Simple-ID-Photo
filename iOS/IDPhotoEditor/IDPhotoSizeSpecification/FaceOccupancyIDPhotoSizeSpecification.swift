//
//  FaceOccupancyIDPhotoSizeSpecification.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 標準の写り方 (顔が写真全体に占める割合を一定にする) の仕様書
struct FaceOccupancyIDPhotoSizeSpecification: IDPhotoSizeSpecification {
    let id: String

    /// 写真の物理寸法
    let millimeterSize: MeasurementSize

    /// 顔 (頭頂〜顎) の高さ
    let millimeterFaceHeight: Measurement<UnitLength>

    /// 頭頂から写真上端までの余白
    let millimeterCrownMargin: Measurement<UnitLength>

    let requiresSubjectDetection: Bool = true

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        let faceWithHairRect: CGRect = subject.faceWithHairRect

        let photoMillimeterWidth: Double = millimeterSize.width.converted(to: .millimeters).value
        let photoMillimeterHeight: Double = millimeterSize.height.converted(to: .millimeters).value

        let faceMillimeterHeight: Double = millimeterFaceHeight.converted(to: .millimeters).value
        let crownMillimeterMargin: Double = millimeterCrownMargin.converted(to: .millimeters).value

        guard
            faceWithHairRect != .null,
            faceWithHairRect.height > .zero,
            photoMillimeterWidth > .zero,
            photoMillimeterHeight > .zero,
            faceMillimeterHeight > .zero
        else { throw IDPhotoEditor.Error.croppingRegionUnsatisfiable }

        let faceHeightRatio: Double = faceMillimeterHeight / photoMillimeterHeight
        let aspectRatio: Double = photoMillimeterWidth / photoMillimeterHeight

        let croppingRectHeight: CGFloat = faceWithHairRect.height / faceHeightRatio
        let croppingRectWidth: CGFloat = croppingRectHeight * aspectRatio

        let crownMarginRatio: Double = crownMillimeterMargin / photoMillimeterHeight
        let crownMargin: CGFloat = croppingRectHeight * crownMarginRatio

        let remainderWidthOfFaceAndPhoto: CGFloat = croppingRectWidth - faceWithHairRect.width

        let croppingRectOriginX: CGFloat = faceWithHairRect.origin.x - (remainderWidthOfFaceAndPhoto / 2)
        let croppingRectOriginY: CGFloat = (faceWithHairRect.maxY + crownMargin) - croppingRectHeight

        let croppingRect: CGRect = .init(
            x: croppingRectOriginX,
            y: croppingRectOriginY,
            width: croppingRectWidth,
            height: croppingRectHeight
        )

        return croppingRect
    }
}
