//
//  IDPhotoSize.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/23
//  
//

import Foundation

struct IDPhotoSize {
    
    let width: Measurement<UnitLength>
    let height: Measurement<UnitLength>
    
    /// 顔の高さ
    let faceHeight: Measurement<UnitLength>

    ///  頭の上の余白
    let marginTop: Measurement<UnitLength>
    
    ///  顎の下の余白
    let marginBottom: Measurement<UnitLength>?
    
    init(
        width: Measurement<UnitLength>,
        height: Measurement<UnitLength>,
        faceHeight: Measurement<UnitLength>,
        marginTop: Measurement<UnitLength>,
        marginBottom: Measurement<UnitLength>? = nil
    ) {
        self.width = width
        self.height = height
        
        self.faceHeight = faceHeight
        
        self.marginTop = marginTop
        self.marginBottom = marginBottom
    }
    
    func cgsize(pixelDensity: Int) -> CGSize {
        
        let inchesWidth: Measurement<UnitLength> = self.width.converted(to: .inches)
        let inchesHeight: Measurement<UnitLength> = self.height.converted(to: .inches)
        
        let pixelWidth: CGFloat = .init(inchesWidth.value * Double(pixelDensity))
        let pixelHeight: CGFloat = .init(inchesHeight.value * Double(pixelDensity))
        
        let pixelSize: CGSize = .init(width: pixelWidth, height: pixelHeight)
        
        return pixelSize
    }
}
