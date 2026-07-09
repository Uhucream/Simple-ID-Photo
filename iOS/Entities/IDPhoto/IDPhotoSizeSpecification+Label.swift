//
//  IDPhotoSizeSpecification+Label.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation

//  MARK: 表示名の解決 (仕様書 ID がキー)。
//  国際化対応 (roadmap 6) では、ここのリテラルを String Catalog のキーに差し替えるだけでよい
extension IDPhotoSizeSpecification {

    /// ピッカーなどに表示するサイズ名。
    /// 数値サイズは MeasurementFormatter によってロケールに応じてフォーマットされる
    var pickerLabel: String {
        if self.id == JapanIDPhotoSizes.original.id {
            return "オリジナル"
        }

        guard let millimeterSize = self.millimeterSize else { return "オリジナル" }

        let millimeterWidth: Int = .init(millimeterSize.width)

        let heightMeasurement: Measurement<UnitLength> = .init(
            value: millimeterSize.height,
            unit: .millimeters
        )

        return "\(millimeterWidth) x \(projectGlobalMeasurementFormatter.string(from: heightMeasurement))"
    }
}
