//
//  ActualSize.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/13
//  
//

import Foundation

struct ActualSize: MeasurementUnitLengthSize {
    
    var width: Measurement<UnitLength>
    var height: Measurement<UnitLength>
    
    func cgSize(pixelDensity: Double) -> CGSize {

        let pixelSize: CGSize = .init(
            width: self.width.converted(to: .inches).value * pixelDensity,
            height: self.height.converted(to: .inches).value * pixelDensity
        )
        
        return pixelSize
    }
}
