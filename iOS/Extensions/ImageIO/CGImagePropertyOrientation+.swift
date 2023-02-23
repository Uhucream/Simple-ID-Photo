//
//  CGImagePropertyOrientation+.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2023/01/25
//
//

import ImageIO
import UIKit

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .left:
            self = .left
        case .right:
            self = .right
        case .downMirrored:
            self = .downMirrored
        case .leftMirrored:
            self = .leftMirrored
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}
