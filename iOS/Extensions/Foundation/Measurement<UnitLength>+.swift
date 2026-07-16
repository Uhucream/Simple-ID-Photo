//
//  Measurement<UnitLength>+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/21
//  
//

import Foundation

extension Measurement<UnitLength> {

    static func millimeters(_ value: Double) -> Self {
        return .init(
            value: value,
            unit: .millimeters
        )
    }

    static var zero: Self {
        return .init(value: 0, unit: .millimeters)
    }
}

extension Measurement where UnitType == UnitLength {
    func pixelLength(pixelDensity: Double) -> CGFloat {
        return self.converted(to: .inches).value * pixelDensity
    }
}
