//
//  CreateIDPhotoView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/01/09
//  
//

import SwiftUI

struct IDPhotoBackgroundColor {
    let name: String
    let color: Color
}

enum IDPhotoProcessSelection: Int, Identifiable {
    case backgroundColor
    case size
    
    var id: Int {
        return self.rawValue
    }
}

struct CreateIDPhotoView: View {
    private let BACKGROUND_COLORS: [Color] = [
        .idPhotoBackgroundColors.blue,
        .idPhotoBackgroundColors.gray,
        .idPhotoBackgroundColors.white,
        .idPhotoBackgroundColors.brown,
    ]
    
    @State private var selectedProcess: IDPhotoProcessSelection = .backgroundColor
    
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedBackgroundColorLabel: String
    
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
            
            Spacer()
            
            VStack(spacing: 0) {
                ZStack {
                    if self.selectedProcess == .backgroundColor {
                        VStack(spacing: 16) {
                            Text(selectedBackgroundColorLabel)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 4))
                                .environment(\.colorScheme, .dark)
                            
                            HStack {
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.clear)
                                        .aspectRatio(1.0, contentMode: .fit)
                                        .overlay(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                                        .padding(4)
                                        .overlay {
                                            if selectedBackgroundColor == .clear {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.tintColor, lineWidth: 2)
                                            }
                                        }
                                        .overlay {
                                            Image(systemName: "nosign")
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxHeight: 40)
                                        .environment(\.colorScheme, .dark)
                                        .onTapGesture {
                                            self.selectedBackgroundColor = .clear
                                        }
                                    
                                    IDPhotoBackgroundColorPicker(
                                        availableBackgroundColors: BACKGROUND_COLORS,
                                        selectedBackgroundColor: $selectedBackgroundColor
                                    )
                                }
                                
                                Spacer()
                            }
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
                        role: .cancel,
                        action: {
                            self.onTapDismissButtonCallback?()
                        }
                    ) {
                        Label("終了", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .padding()
                    }
                    .controlSize(.mini)
                    .tint(.white)
                    .environment(\.colorScheme, .dark)
                    
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
            selectedBackgroundColorLabel: .constant("青"),
            selectedIDPhotoSize: .constant(.original),
            previewUIImage: .constant(
                .init(named: "TimCook")
            )
        )
    }
}
