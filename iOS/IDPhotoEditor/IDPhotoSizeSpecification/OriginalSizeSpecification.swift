//
//  OriginalSizeSpecification.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation
import CoreGraphics

/// オリジナルサイズ (切り抜きなし) の仕様書
///
/// クロップ矩形として元画像の extent をそのまま返す
struct OriginalSizeSpecification: IDPhotoSizeSpecification {

    let id: String = "original"

    let millimeterSize: MeasurementSize? = nil

    let requiresSubjectDetection: Bool = false

    func croppingRect(for subject: IDPhotoSubject) throws -> CGRect {
        return subject.imageExtent
    }
}

extension IDPhotoSizeSpecification where Self == OriginalSizeSpecification {

    /// オリジナルサイズ (切り抜きなし)
    static var original: OriginalSizeSpecification {
        return .init()
    }
}
