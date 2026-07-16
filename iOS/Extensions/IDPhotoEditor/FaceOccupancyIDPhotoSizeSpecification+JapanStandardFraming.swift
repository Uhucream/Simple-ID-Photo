//
//  FaceOccupancyIDPhotoSizeSpecification+JapanStandardFraming.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/10
//
//

import Foundation

extension FaceOccupancyIDPhotoSizeSpecification {
    //  日本の標準の写り方 (顔占有率・頭上余白) で仕様書を生成する。
    //  顔占有率60% / 頭上余白4mm は暫定値 (適正値は要調査)
    static func japanStandardFraming(
        id: String,
        millimeterWidth: Double,
        millimeterHeight: Double
    ) -> FaceOccupancyIDPhotoSizeSpecification {
        let provisionalFaceHeightRatio: Double = 60 / 100

        return FaceOccupancyIDPhotoSizeSpecification(
            id: id,
            millimeterSize: MeasurementSize(
                width: .millimeters(millimeterWidth),
                height: .millimeters(millimeterHeight)
            ),
            millimeterFaceHeight: .millimeters(millimeterHeight * provisionalFaceHeightRatio),
            millimeterCrownMargin: .millimeters(4)
        )
    }
}
