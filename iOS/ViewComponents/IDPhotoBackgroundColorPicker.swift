//
//  IDPhotoBackgroundColorPicker.swift
//  Simple ID Photo (iOS)
//
//  Created by TakashiUshikoshi on 2023/01/24
//
//

import SwiftUI

struct IDPhotoBackgroundColorPicker: View {
    var availableBackgroundColors: [IDPhotoBackgroundColor]

    @Binding var selectedBackgroundColor: IDPhotoBackgroundColor

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ForEach(availableBackgroundColors) { backgroundColor in
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor.swiftUIColor)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(4)
                    .overlay {
                        let isSelected: Bool = backgroundColor == selectedBackgroundColor

                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.tintColor, lineWidth: 2)
                        }
                    }
                    .onTapGesture {
                        selectedBackgroundColor = backgroundColor
                    }
            }
        }
        .frame(maxHeight: 40)
    }
}

struct IDPhotoBackgroundColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        IDPhotoBackgroundColorPicker(
            availableBackgroundColors: IDPhotoBackgroundColor.presets,
            selectedBackgroundColor: .constant(.blue)
        )
    }
}
