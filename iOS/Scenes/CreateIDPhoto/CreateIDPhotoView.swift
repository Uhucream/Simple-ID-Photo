//
//  CreateIDPhotoView.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/01/09
//  
//

import SwiftUI

struct IDPhotoBackgroundColor {
    let name: String
    let color: Color
}

struct CreateIDPhotoView: View {
    private let BACKGROUND_COLORS: [Color] = [Color(0x5FB8DE, alpha: 1.0), Color(0xA5A5AD, alpha: 1.0)]
    
    @State private var shouldShowSelectSizeSheet: Bool = false
    
    @Binding var selectedBackgroundColor: Color
    
    @Binding var previewUIImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let previewUIImage = previewUIImage {
                    Image(uiImage: previewUIImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(maxHeight: 280)
            
            Form {
                Section {
                    ScrollView(.horizontal) {
                        IDPhotoBackgroundColorPicker(
                            availableBackgroundColors: BACKGROUND_COLORS,
                            selectedBackgroundColor: $selectedBackgroundColor
                        )
                        .frame(minHeight: 48)
                        .padding()
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                } header: {
                    Text("背景色")
                }
                
                Section {
                    HStack {
                        Text("サイズを選択")
                            .foregroundColor(.tintColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .onTapGesture {
                        shouldShowSelectSizeSheet = true
                    }
                } header: {
                    Text("サイズ")
                }
            }
        }
        .background {
            Color
                .systemGroupedBackground
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $shouldShowSelectSizeSheet) {
            NavigationView {
                IDPhotoSizePickerView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(action: {
                                
                            }) {
                                Text("閉じる")
                            }
                        }
                    }
            }
        }
    }
}

struct CreateIDPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        CreateIDPhotoView(
            selectedBackgroundColor: .constant(
                Color(0x5FB8DE, alpha: 1.0)
            ),
            previewUIImage: .constant(
                .init(named: "TimCook")
            )
        )
    }
}
