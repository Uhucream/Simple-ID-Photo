//
//  UIImage+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/11
//  
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

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
    
    //    MARK: Generate an UIImage from an URL
    //
    //    http://web.archive.org/web/20230125022524/https://www.rasukarusan.com/entry/2019/01/07/233207
    convenience init(url: URL) {
        do {
            let data = try Data(contentsOf: url)

            self.init(data: data)!

            return
        } catch {
            print("Error: \(error)")
        }

        self.init()
    }
    
    func ciImage() -> CIImage? {
        if let ciImage = self.ciImage {
            return ciImage
        }
        
        if let cgImage = self.cgImage {
            return CIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
    //    https://gist.github.com/schickling/b5d86cb070130f80bb40?permalink_comment_id=3500925#gistcomment-3500925
    func orientationFixed() -> UIImage? {
        
        if self.imageOrientation == .up {
            return self
        }
        
        let imageSize: CGSize = self.size
        
        let imageOrientation: UIImage.Orientation = self.imageOrientation
        
        var transform: CGAffineTransform = .identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: imageSize.width, y: imageSize.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: imageSize.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: imageSize.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        // Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: imageSize.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: imageSize.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break
        }
        
        guard var cgImage = self.cgImage else {
            return nil
        }
        
        autoreleasepool {
            var context: CGContext?
            
            guard
                let colorSpace = cgImage.colorSpace,
                let _context = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else {
                return
            }

            context = _context
            
            context?.concatenate(transform)
            
            var drawRect: CGRect = .zero

            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                drawRect.size = CGSize(width: imageSize.height, height: imageSize.width)
            default:
                drawRect.size = CGSize(width: imageSize.width, height: imageSize.height)
            }
            
            context?.draw(cgImage, in: drawRect)
            
            guard let newCGImage = context?.makeImage() else {
                return
            }

            cgImage = newCGImage
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .up)

        return uiImage
    }
    
    func saveOnLibraryCachesForTest(
        fileName: String,
        fileManager: FileManager = .default
    ) -> URL? {
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        
        let fileURL = cacheDirectory.appendingPathComponent(fileName, conformingTo: .png)
        let filePath = fileURL.path
        
        if !fileManager.fileExists(atPath: filePath) {

            guard let pngData = self.pngData() else { return nil }
            
            fileManager.createFile(atPath: filePath, contents: pngData)
        }
         
        return fileURL
    }
}
