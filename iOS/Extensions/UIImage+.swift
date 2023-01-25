//
//  UIImage+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/11
//  
//

import SwiftUI
import UIKit

extension UIImage {

    //    MARK: Generate an UIImage with solid color
    //
    //    http://web.archive.org/web/20230111055752/https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift/33675160#33675160
    //
    convenience init?(color: Color, size: CGSize = .zero) {
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)

        let uiColor: UIColor = .init(color)
        
        uiColor.setFill()

        UIRectFill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }

        self.init(cgImage: cgImage)
    }
}