//
//  IDPhotoSizePicker.swift
//  Simple ID Photo (iOS)
//
//  Created by TakashiUshikoshi on 2023/01/24
//
//

import SwiftUI

struct IDPhotoSizePicker: View {

    var availableSizeSpecifications: [any IDPhotoSizeSpecification]

    var renderSelectionLabel: (any IDPhotoSizeSpecification) -> Text

    @Binding var selectedSizeSpecification: any IDPhotoSizeSpecification

    var body: some View {
        HStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(availableSizeSpecifications, id: \.id) { sizeSpecification in
                            let isSelected: Bool = self.selectedSizeSpecification.id == sizeSpecification.id

                            ZStack {
                                renderSelectionLabel(sizeSpecification)
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
                                selectedSizeSpecification = sizeSpecification
                            }
                            .id(sizeSpecification.id)
                        }
                    }
                    .padding()
                    .onAppear {

                        let currentSelectedSpecificationIndex: Int = availableSizeSpecifications.firstIndex { specification in
                            return specification.id == self.selectedSizeSpecification.id
                        } ?? 0

                        if currentSelectedSpecificationIndex == 0 {
                            return
                        }

                        scrollViewProxy.scrollTo(selectedSizeSpecification.id)
                    }
                }
            }
        }
    }
}

struct IDPhotoSizePicker_Previews: PreviewProvider {
    static var previews: some View {
        let renderSpecificationLabel: (any IDPhotoSizeSpecification) -> Text = { (specification: any IDPhotoSizeSpecification) in
            return Text(specification.pickerLabel)
        }

        IDPhotoSizePicker(
            availableSizeSpecifications: JapanIDPhotoSize.allCases,
            renderSelectionLabel: renderSpecificationLabel,
            selectedSizeSpecification: .constant(OriginalSizeSpecification.original)
        )
        .previewLayout(.sizeThatFits)
    }
}
