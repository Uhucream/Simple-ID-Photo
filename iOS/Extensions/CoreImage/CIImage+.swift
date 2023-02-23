//
//  CIImage+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/23
//  
//

import CoreImage
import UIKit

extension CIImage {
    func cgImage() -> CGImage? {
        let context: CIContext = .init(options: nil)

        return context.createCGImage(self, from: self.extent)
    }
    
    func uiImage(orientation: UIImage.Orientation) -> UIImage? {
        guard let cgImage = self.cgImage() else { return nil }

        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}
