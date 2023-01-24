//
//  BlurView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/24
//  
//

import SwiftUI

struct BlurView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    init(blurStyle: UIBlurEffect.Style) {
        self.blurStyle = blurStyle
    }
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
