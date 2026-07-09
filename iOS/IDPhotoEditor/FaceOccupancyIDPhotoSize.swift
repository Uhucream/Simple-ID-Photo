//
//  FaceOccupancyIDPhotoSize.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// 標準の写り方 (顔が写真全体に占める割合を一定にする) の仕様書。
///
/// カスタムサイズもこの仕様書で表現できる (寸法・顔の高さ・頭上の余白がすべてパラメータであるため)。
struct FaceOccupancyIDPhotoSize: IDPhotoSizeSpecification {

    let id: String

    /// 写真の物理寸法
    let dimensions: MillimeterSize

    /// 顔 (頭頂〜顎) の高さ
    let millimeterFaceHeight: Double

    /// 頭頂から写真上端までの余白
    let millimeterCrownMargin: Double

    var millimeterSize: MillimeterSize? {
        return dimensions
    }

    init(
        id: String,
        dimensions: MillimeterSize,
        millimeterFaceHeight: Double,
        millimeterCrownMargin: Double
    ) {
        self.id = id
        self.dimensions = dimensions

        self.millimeterFaceHeight = millimeterFaceHeight
        self.millimeterCrownMargin = millimeterCrownMargin
    }

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        let faceWithHairRect: CGRect = subject.faceWithHairRect

        guard
            faceWithHairRect != .null,
            faceWithHairRect.height > .zero,
            dimensions.width > .zero,
            dimensions.height > .zero,
            millimeterFaceHeight > .zero
        else { throw IDPhotoEditorError.croppingRegionUnsatisfiable }

        let faceHeightRatio: Double = millimeterFaceHeight / dimensions.height
        let aspectRatio: Double = dimensions.width / dimensions.height

        let croppingRectHeight: CGFloat = faceWithHairRect.height / faceHeightRatio
        let croppingRectWidth: CGFloat = croppingRectHeight * aspectRatio

        let crownMarginRatio: Double = millimeterCrownMargin / dimensions.height
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
