//
//  DiscontinuedIDPhotoSize.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/10
//
//

import Foundation
import CoreGraphics

/// 廃止された規格サイズ
///
/// 現行の規格一覧にはないが、過去に作成された証明写真が使っているサイズを、保存済みの物理寸法から標準の写り方で再現する。
struct DiscontinuedIDPhotoSize: IDPhotoSizeSpecification {

    let millimeterWidth: Double
    let millimeterHeight: Double

    let requiresSubjectDetection: Bool = true

    var id: String {
        return "discontinued.w\(Int(millimeterWidth))h\(Int(millimeterHeight))"
    }

    var millimeterSize: MeasurementSize {
        return standardSpecification.millimeterSize
    }

    private var standardSpecification: FaceOccupancyIDPhotoSizeSpecification {
        return .japanStandardFraming(
            id: id,
            millimeterWidth: millimeterWidth,
            millimeterHeight: millimeterHeight
        )
    }

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        return try standardSpecification.croppingRect(for: subject)
    }
}
