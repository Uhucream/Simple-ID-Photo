//
//  Animation+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/08
//  
//

import SwiftUI

extension Animation {
    //    https://easings.net/ja#easeOutQuart
    static let easeOutQuart: Animation = .timingCurve(0.25, 1, 0.5, 1)
    
    static func easeOutQuart(duration: Double) -> Animation {
        return .timingCurve(0.25, 1, 0.5, 1, duration: duration)
    }
}
