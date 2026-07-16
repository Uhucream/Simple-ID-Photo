//
//  IDPhotoSizeSpecification+Label.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/09
//
//

import Foundation

//  表示名の解決 (仕様書 ID がキー)。
//  国際化対応 (roadmap 6) では、ここのリテラルを String Catalog のキーに差し替えるだけでよい
extension IDPhotoSizeSpecification {

    /// ピッカーに表示するサイズ名
    ///
    /// 数値サイズは MeasurementFormatter によってロケールに応じてフォーマットされる
    var pickerLabel: String {
        guard self is OriginalSizeSpecification == false else { return "オリジナル" }

        let millimeterSize: MeasurementSize = self.millimeterSize

        let millimeterWidth: Int = .init(millimeterSize.width.converted(to: .millimeters).value)

        return "\(millimeterWidth) x \(projectGlobalMeasurementFormatter.string(from: millimeterSize.height))"
    }
}
