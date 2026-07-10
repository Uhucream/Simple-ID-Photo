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
