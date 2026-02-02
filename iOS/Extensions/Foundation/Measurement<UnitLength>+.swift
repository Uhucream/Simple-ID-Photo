//
//  Measurement<UnitLength>+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/21
//  
//

import Foundation

extension Measurement where UnitType == UnitLength {
    static func millimeters(_ value: Double) -> Measurement<UnitLength> {
        return Measurement<UnitLength>(value: value, unit: .millimeters)
    }

    func pixelLength(pixelDensity: Double) -> CGFloat {
        return self.converted(to: .inches).value * pixelDensity
    }
}
