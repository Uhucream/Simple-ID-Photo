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
    let brown: Color = .init("IDPhotoBackgroundColors/Brown")
    let gray: Color = .init("IDPhotoBackgroundColors/Gray")
    let white: Color = .init("IDPhotoBackgroundColors/White")
}

extension Color {
    static let idPhotoBackgroundColors: IDPhotoBackgroundColors = .shared
}
