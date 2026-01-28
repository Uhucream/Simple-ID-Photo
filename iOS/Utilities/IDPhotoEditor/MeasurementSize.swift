//
//  MeasurementSize.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2025/02/10
//

import CoreGraphics
import Foundation

public struct MeasurementSize: Sendable, Equatable {
    public let width: Measurement<UnitLength>
    public let height: Measurement<UnitLength>

    public init(width: Measurement<UnitLength>, height: Measurement<UnitLength>) {
        self.width = width
        self.height = height
    }

    public func cgSize(pixelDensity: Double) -> CGSize {
        let inchesWidth: Measurement<UnitLength> = width.converted(to: .inches)
        let inchesHeight: Measurement<UnitLength> = height.converted(to: .inches)

        return CGSize(
            width: CGFloat(inchesWidth.value * pixelDensity),
            height: CGFloat(inchesHeight.value * pixelDensity)
        )
    }
}

extension MeasurementSize {
    static let zero: MeasurementSize = .init(
        width: .init(value: .zero, unit: .millimeters),
        height: .init(value: .zero, unit: .millimeters)
    )
}
