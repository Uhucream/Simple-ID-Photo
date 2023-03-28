//
//  IDPhotoSizePicker.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/01/24
//  
//

import SwiftUI

struct IDPhotoSizePicker: View {
    
    var availableSizeVariants: [IDPhotoSizeVariant]
    
    var renderSelectonLabel: (IDPhotoSizeVariant) -> Text
    
    @Binding var selectedIDPhotoSize: IDPhotoSizeVariant
    
    var body: some View {
        HStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(availableSizeVariants, id: \.self) { sizeSelection in
                            let isSelected: Bool = self.selectedIDPhotoSize == sizeSelection
                            
                            ZStack {
                                renderSelectonLabel(sizeSelection)
                                    .font(.system(size: 14.0, design: .rounded))
                                    .fontWeight(.regular)
                            }
                            .foregroundColor(
                                isSelected ? .fixedWhite : .fixedLightGray
                            )
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background {
                                ZStack {
                                    if isSelected {
                                        BlurView(blurStyle: .systemChromeMaterialDark)
                                            .background {
                                                Color.fixedLightGray
                                            }
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .onTapGesture {
                                selectedIDPhotoSize = sizeSelection
                            }
                            .id(sizeSelection)
                        }
                    }
                    .padding()
                    .onAppear {
                        
                        let currentSelectedVariantIndex: Int = availableSizeVariants.firstIndex(of: self.selectedIDPhotoSize) ?? 0
                        
                        if currentSelectedVariantIndex == 0 {
                            return
                        }
                        
                        scrollViewProxy.scrollTo(selectedIDPhotoSize)
                    }
                }
            }
        }
    }
}

struct IDPhotoSizePicker_Previews: PreviewProvider {
    static var previews: some View {
        let renderVariantLabel: (IDPhotoSizeVariant) -> Text = { (variant: IDPhotoSizeVariant) in
            if variant == .original {
                return Text("オリジナル")
            }
            
            if variant == .passport {
                return Text("パスポート (35 x 45 mm)")
            }
            
            let photoWidth: Int = Int(variant.photoSize.width.value)
            
            return Text("\(photoWidth) x \(projectGlobalMeasurementFormatter.string(from: variant.photoSize.height))")
        }
        
        IDPhotoSizePicker(
            availableSizeVariants: IDPhotoSizeVariant.allCases,
            renderSelectonLabel: renderVariantLabel,
            selectedIDPhotoSize: .constant(.original)
        )
        .previewLayout(.sizeThatFits)
    }
}
