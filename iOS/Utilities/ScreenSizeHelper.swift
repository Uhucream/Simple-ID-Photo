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
    
    @Published private(set) var screenSize: CGSize = .zero
    
    @Published private(set) var safeAreaInsets: EdgeInsets = .init()
    
    func updateSafeAreaInsets(_ insets: EdgeInsets) -> Void {
        self.safeAreaInsets = insets
    }
    
    func updateScreenSize(_ screenSize: CGSize) {
        self.screenSize = screenSize
    }
}
