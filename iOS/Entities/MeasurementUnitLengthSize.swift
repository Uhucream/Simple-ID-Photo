//
//  MeasurementUnitLengthSize.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/13
//  
//

import Foundation

protocol MeasurementUnitLengthSize {
    var width: Measurement<UnitLength> { get }
    var height: Measurement<UnitLength> { get }
    
    func cgSize(pixelDensity: Double) -> CGSize
}
