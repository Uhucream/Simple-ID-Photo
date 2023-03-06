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
    private enum IDPhotoProcessSelection {
        case backgroundColor
        case size
    }
    
    private let BACKGROUND_COLORS: [Color] = [
        .idPhotoBackgroundColors.blue,
        .idPhotoBackgroundColors.gray
    ]
    
    @State private var selectedProcess: IDPhotoProcessSelection = .backgroundColor
    
    @Binding var selectedBackgroundColor: Color
    
    @Binding var selectedIDPhotoSize: IDPhotoSizeVariant
    
    @Binding var previewUIImage: UIImage?
    
    private(set) var onTapDismissButtonCallback: (() -> Void)? = nil

    private(set) var onTapDoneButtonCallback: (() -> Void)? = nil
    
    func onTapDismissButton(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onTapDismissButtonCallback = action
        
        return view
    }
    
    func onTapDoneButton(action: @escaping () -> Void) -> Self {
        var view = self
        
        view.onTapDoneButtonCallback = action
        
        return view
    }
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                ZStack {
                    if selectedProcess == .backgroundColor {
                        Text("背景色")
                            .fontWeight(.light)
                    }
                    
                    if selectedProcess == .size {
                        Text("サイズ")
                            .fontWeight(.light)
                    }
                }
                .font(Font.subheadline)
                .foregroundColor(.white)
                .transaction { transaction in
                    transaction.animation = .none
                }
            }
            .padding()
            
            Spacer()
            
            ZStack {
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
            
            Spacer()
            
            VStack(spacing: 0) {
                ZStack {
                    if self.selectedProcess == .backgroundColor {
                        HStack {
                            Spacer()
                            
                            IDPhotoBackgroundColorPicker(
                                availableBackgroundColors: BACKGROUND_COLORS,
                                selectedBackgroundColor: $selectedBackgroundColor
                            )
                            
                            Spacer()
                        }
                    }
                    
                    if self.selectedProcess == .size {
                        IDPhotoSizePicker(selectedIDPhotoSize: $selectedIDPhotoSize)
                    }
                }
                .transaction { transaction in
                    transaction.animation = .none
                }
                
                HStack(alignment: .center) {
                    Button(
                        role: .destructive,
                        action: {
                            self.onTapDismissButtonCallback?()
                        }
                    ) {
                        Label("終了", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .padding()
                    }
                    .controlSize(.mini)
                    
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 12) {
                        Button(
                            action: {
                                var transaction: Transaction = .init(animation: .easeInOut)
                                
                                transaction.disablesAnimations = true
                                
                                withTransaction(transaction) {
                                    self.selectedProcess = .backgroundColor
                                }
                            }
                        ) {
                            VStack(spacing: 2) {
                                Label("背景色", systemImage: "paintbrush")
                                    .labelStyle(.iconOnly)
                                    .padding(8)
                                
                                Circle()
                                    .frame(width: 4, height: 4)
                                    .foregroundColor(self.selectedProcess == .backgroundColor ? .yellow : .clear)
                            }
                        }
                        .tint(.white)
                        
                        Button(
                            action: {
                                var transaction: Transaction = .init(animation: .easeInOut)
                                
                                transaction.disablesAnimations = true
                                
                                withTransaction(transaction) {
                                    self.selectedProcess = .size
                                }
                            }
                        ) {
                            VStack(spacing: 2) {
                                Label("サイズ", systemImage: "person.crop.rectangle")
                                    .labelStyle(.iconOnly)
                                    .padding(8)
                                
                                Circle()
                                    .frame(width: 4, height: 4)
                                    .foregroundColor(self.selectedProcess == .size ? .yellow : .clear)
                            }
                        }
                        .tint(.white)
                    }
                    
                    Spacer()
                    
                    Button(
                        action: {
                            onTapDoneButtonCallback?()
                        }
                    ) {
                        Image(systemName: "checkmark")
                            .padding()
                    }
                    .tint(.yellow)
                    .controlSize(.mini)
                }
                .frame(maxHeight: 28)
                .padding(.vertical)
                .padding(.horizontal, 4)
            }
        }
        .background {
            Color
                .fixedBlack
                .overlay {
                    BlurView(blurStyle: .systemChromeMaterialDark)
                }
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct CreateIDPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        CreateIDPhotoView(
            selectedBackgroundColor: .constant(
                Color.idPhotoBackgroundColors.blue
            ),
            selectedIDPhotoSize: .constant(.original),
            previewUIImage: .constant(
                .init(named: "TimCook")
            )
        )
    }
}
