//
//  ScreenSizeHelper.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/07
//  
//

import Combine
import SwiftUI

final class ScreenSizeHelper: ObservableObject {
    static var shared: ScreenSizeHelper = .init()
    
    @Published var screenWidth: CGFloat = .zero
    @Published var screenHeight: CGFloat = .zero
    
    func update(screenWidth: CGFloat, screenHeight: CGFloat) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
    }
}
