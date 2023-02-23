//
//  Color+IDPhotoBackgroundColors.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/02/23
//  
//

import SwiftUI

final class IDPhotoBackgroundColors {
    static let shared: IDPhotoBackgroundColors = .init()
    
    private init() {}
    
    let blue: Color = .init("IDPhotoBackgroundColors/Blue")
    let gray: Color = .init("IDPhotoBackgroundColors/Gray")
}

extension Color {
    static let idPhotoBackgroundColors: IDPhotoBackgroundColors = .shared
}
