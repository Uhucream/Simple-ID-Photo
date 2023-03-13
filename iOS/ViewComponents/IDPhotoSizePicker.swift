//
//  IDPhotoSizePicker.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/01/24
//  
//

import SwiftUI

struct IDPhotoSizePicker: View {
    @Binding var selectedIDPhotoSize: IDPhotoSizeVariant
    
    private func renderSelectionLabelText(_ sizeVariant: IDPhotoSizeVariant) -> Text {
        if sizeVariant == .original {
            return Text("オリジナル")
        }
        
        if sizeVariant == .passport {
            return Text("パスポート (35 x 45 mm)")
        }
        
        let photoWidth: Int = Int(sizeVariant.photoSize.width.value)
        
        return Text("\(photoWidth) x \(projectGlobalMeasurementFormatter.string(from: sizeVariant.photoSize.height))")
    }
    
    var body: some View {
        HStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(IDPhotoSizeVariant.allCases, id: \.self) { sizeSelection in
                            let isSelected: Bool = self.selectedIDPhotoSize == sizeSelection
                            
                            ZStack {
                                renderSelectionLabelText(sizeSelection)
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
                        if selectedIDPhotoSize == .original {
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
        IDPhotoSizePicker(selectedIDPhotoSize: .constant(.original))
            .previewLayout(.sizeThatFits)
    }
}
