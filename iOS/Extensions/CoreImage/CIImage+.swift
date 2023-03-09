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
    
    func jpegData(
        ciContext: CIContext = .init(),
        colorSpace: CGColorSpace
    ) -> Data? {
        
        let jpegData: Data? = ciContext
            .jpegRepresentation(
                of: self,
                colorSpace: colorSpace
            )
        
        return jpegData
    }
    
    func heifData(
        ciContext: CIContext = .init(),
        format: CIFormat,
        colorSpace: CGColorSpace
    ) -> Data? {
        
        let heifData: Data? = ciContext
            .heifRepresentation(
                of: self,
                format: format,
                colorSpace: colorSpace
            )
        
        return heifData
    }
}
