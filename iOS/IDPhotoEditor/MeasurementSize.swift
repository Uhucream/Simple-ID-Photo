//
//  MeasurementSize.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2026/07/10
//
//

import Foundation

/// 幅・高さを `Measurement` で表す物理寸法
struct MeasurementSize: Codable, Equatable, Sendable {

    let width: Measurement<UnitLength>
    let height: Measurement<UnitLength>
}

extension MeasurementSize: Comparable {

    //  縦幅 (高さ) を主キー、横幅を従キーとした昇順
    static func < (lhs: MeasurementSize, rhs: MeasurementSize) -> Bool {
        if lhs.height != rhs.height {
            return lhs.height < rhs.height
        }

        return lhs.width < rhs.width
    }
}
