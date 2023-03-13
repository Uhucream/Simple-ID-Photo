//
//  IDPhotoBackgroundColorPicker.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/01/24
//  
//

import SwiftUI

struct IDPhotoBackgroundColorPicker: View {
    var availableBackgroundColors: [Color]
    
    @Binding var selectedBackgroundColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ForEach(availableBackgroundColors, id: \.self) { color in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(4)
                    .overlay {
                        
                        let colorComponents: RGBAColorComponents? = color.rgba
                        let selectedColorComponents: RGBAColorComponents? = selectedBackgroundColor.rgba
                        
                        let isRedSameValue: Bool = colorComponents?.red == selectedColorComponents?.red
                        let isGreenSameValue: Bool = colorComponents?.green == selectedColorComponents?.green
                        let isBlueSameValue: Bool = colorComponents?.blue == selectedColorComponents?.blue
                        let isAlphaSameValue: Bool = colorComponents?.alpha == selectedColorComponents?.alpha
                        
                        let isSelected: Bool = isRedSameValue && isGreenSameValue && isBlueSameValue && isAlphaSameValue
                        
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.tintColor, lineWidth: 2)
                        }
                    }
                    .onTapGesture {
                        selectedBackgroundColor = color
                    }
            }
        }
        .frame(maxHeight: 40)
    }
}

struct IDPhotoBackgroundColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        IDPhotoBackgroundColorPicker(
            availableBackgroundColors: [Color(0x5FB8DE, alpha: 1.0), Color(0xA5A5AD, alpha: 1.0)],
            selectedBackgroundColor: .constant(Color(0x5FB8DE, alpha: 1.0))
        )
    }
}
