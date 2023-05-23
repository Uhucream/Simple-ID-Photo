//
//  EditIDPhotoView.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/07
//  
//

import SwiftUI

fileprivate let CROP_VIEW_IMAGE_HORIZONTAL_PADDING: CGFloat = 8

fileprivate let CROP_VIEW_ANIMATION_DURATION_SECONDS: Double = 0.5

struct EditIDPhotoView: View {

    @Namespace private var previewImageNamespace
    
    @State private var bottomControlButtonsBarSize: CGSize = .zero
    
    @State private var previewImageBoundsInScreen: CGRect = .null
    
    @Binding var selectedProcess: IDPhotoProcessSelection
    
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedBackgroundColorLabel: String
    
    @Binding var selectedIDPhotoSize: IDPhotoSizeVariant
    
    @Binding var originalSizePreviewUIImage: UIImage?
    @Binding var croppedPreviewUIImage: UIImage?
    
    @Binding var croppingCGRect: CGRect
    
    @Binding var shouldDisableDoneButton: Bool
    
    var availableBackgroundColors: [Color]
    
    var availableSizeVariants: [IDPhotoSizeVariant]
    
    private var previewCroppingCGRect: CGRect {
        let leftUpperOriginRect: CGRect = .init(
            origin: CGPoint(
                x: croppingCGRect.origin.x,
                y: (originalSizePreviewUIImage?.size.height ?? .zero) - croppingCGRect.maxY
            ),
            size: croppingCGRect.size
        )
        
        return leftUpperOriginRect
    }
    
    private var previewImageViewScalingAmount: CGFloat {
        if croppingCGRect.size == .zero { return 1 }
        
        guard let originalSizePreviewUIImage = originalSizePreviewUIImage, originalSizePreviewUIImage.size != .zero else { return 1 }
        
        return originalSizePreviewUIImage.size.width / croppingCGRect.size.width
    }
    
    private var previewImageOffset: CGSize {
        
        if previewImageBoundsInScreen.size == .zero { return .zero }

        guard let originalSizePreviewUIImage = originalSizePreviewUIImage, originalSizePreviewUIImage.size != .zero else { return .zero }
        
        let previewImageActualScaleX = previewImageBoundsInScreen.width / originalSizePreviewUIImage.size.width
        let previewImageActualScaleY = previewImageBoundsInScreen.height / originalSizePreviewUIImage.size.height
        
        return .init(
            width: (originalSizePreviewUIImage.size.width / 2 - previewCroppingCGRect.midX) * previewImageActualScaleX,
            height: (originalSizePreviewUIImage.size.height / 2 - previewCroppingCGRect.midY) * previewImageActualScaleY
        )
    }
    
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
    
    func renderSizeVariantLabel(_ variant: IDPhotoSizeVariant) -> Text {
        if variant == .original {
            return Text("オリジナル")
        }
        
        if variant == .passport {
            return Text("パスポート (35 x 45 mm)")
        }
        
        let photoWidth: Int = Int(variant.photoSize.width.value)
        
        return Text("\(photoWidth) x \(projectGlobalMeasurementFormatter.string(from: variant.photoSize.height))")
    }
    
    @ViewBuilder
    func BottomControlButtons() -> some View {
        VStack(spacing: 0) {
            ZStack {
                if self.selectedProcess == .backgroundColor {
                    VStack {
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
                                    availableBackgroundColors: self.availableBackgroundColors,
                                    selectedBackgroundColor: $selectedBackgroundColor
                                )
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                if self.selectedProcess == .size {
                    IDPhotoSizePicker(
                        availableSizeVariants: availableSizeVariants,
                        renderSelectonLabel: renderSizeVariantLabel,
                        selectedIDPhotoSize: $selectedIDPhotoSize
                    )
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
                .disabled(shouldDisableDoneButton)
            }
            .frame(maxHeight: 28)
            .padding(.vertical)
            .padding(.horizontal, 4)
        }
        .background {
            GeometryReader { buttonsGeometry in
                
                let buttonsSize: CGSize = buttonsGeometry.size
                
                Color.clear
                    .onAppear {
                        self.bottomControlButtonsBarSize = buttonsSize
                    }
                    .onChange(of: buttonsSize) { newButtonsSize in
                        self.bottomControlButtonsBarSize = newButtonsSize
                    }
            }
        }
    }
    
    @ViewBuilder
    func ChangeBackgroundColorView() -> some View {
        VStack(alignment: .center) {
            HStack {
                Text("背景色")
                    .fontWeight(.light)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding()
            
            VStack(spacing: 0) {
                Spacer()
                
                if let croppedPreviewUIImage = croppedPreviewUIImage {
                    Image(uiImage: croppedPreviewUIImage)
                        .resizable()
                        .scaledToFit()
                }
                
                Spacer()
            }
            .matchedGeometryEffect(
                id: "previewImage",
                in: previewImageNamespace
            )
            .transaction { transaction in
                transaction.disablesAnimations = selectedProcess == .size
            }
            
            BottomControlButtons()
        }
    }
    
    @ViewBuilder
    func CroppingFrame() -> some View {
        Color.clear
            .background(.regularMaterial, in: Rectangle())
            .reverseMask {
                if previewCroppingCGRect.size != .zero && previewImageBoundsInScreen != .zero {
                    Rectangle()
                        .aspectRatio(previewCroppingCGRect.size, contentMode: .fit)
                        .padding(.horizontal, CROP_VIEW_IMAGE_HORIZONTAL_PADDING)
                        .position(
                            x: UIScreen.main.bounds.width / 2,
                            y: previewImageBoundsInScreen.midY
                        )
                }
            }
            .overlay {
                if previewCroppingCGRect.size != .zero && previewImageBoundsInScreen != .zero {
                    Rectangle()
                        .stroke(.white, lineWidth: 2)
                        .aspectRatio(previewCroppingCGRect.size, contentMode: .fit)
                        .padding(.horizontal, CROP_VIEW_IMAGE_HORIZONTAL_PADDING)
                        .position(
                            x: UIScreen.main.bounds.width / 2,
                            y: previewImageBoundsInScreen.midY
                        )
                }
            }
            .environment(\.colorScheme, .dark)
    }
    
    @ViewBuilder
    func ChangeIDPhotoSizeView() -> some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Spacer()
                    
                    if let originalSizePreviewUIImage = originalSizePreviewUIImage {
                        Image(uiImage: originalSizePreviewUIImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background {
                                GeometryReader { imageGeometry in
                                    Color.clear
                                        .task(id: imageGeometry.size) {
                                            do {
                                                try await Task.sleep(milliseconds: 100)
                                                
                                                guard self.previewImageBoundsInScreen == .null else { throw CancellationError() }
                                                
                                                Task { @MainActor in
                                                    self.previewImageBoundsInScreen = imageGeometry.frame(in: .global)
                                                }
                                            } catch {
                                                print(error)
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, CROP_VIEW_IMAGE_HORIZONTAL_PADDING)
                            .offset(previewImageOffset)
                            .animation(.easeOutQuart(duration: CROP_VIEW_ANIMATION_DURATION_SECONDS), value: previewImageOffset)
                            .scaleEffect(previewImageViewScalingAmount)
                            .animation(.easeOutQuart(duration: CROP_VIEW_ANIMATION_DURATION_SECONDS), value: previewImageViewScalingAmount)
                            .transition(.scale)
                            .transaction { transaction in
                                transaction.disablesAnimations = self.croppingCGRect.size == .zero
                            }
                    }
                    
                    Spacer()
                }
                .matchedGeometryEffect(
                    id: "previewImage",
                    in: previewImageNamespace
                )
                
                if bottomControlButtonsBarSize != .zero {
                    //  MARK: これがないと、クロップの枠がサイズピッカーの上に接触してしまう
                    Rectangle()
                        .fill(.clear)
                        .aspectRatio(bottomControlButtonsBarSize, contentMode: .fit)
                }
            }
            
            CroppingFrame()
                .edgesIgnoringSafeArea(.all)
                .animation(
                    .easeOutQuart(duration: CROP_VIEW_ANIMATION_DURATION_SECONDS),
                    value: croppingCGRect
                )
                .transition(.scale)
                .overlay {
                    VStack(alignment: .center, spacing: 0) {
                        Text("サイズ")
                            .fontWeight(.light)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                        
                        BottomControlButtons()
                    }
            }
        }
    }
    
    var body: some View {
        ZStack {
            if selectedProcess == .backgroundColor {
                ChangeBackgroundColorView()
            }
            
            if selectedProcess == .size {
                ChangeIDPhotoSizeView()
            }
        }
        .transaction { transaction in
            transaction.animation = .none
        }
        .background {
            Color
                .black
                .overlay(.bar)
                .environment(\.colorScheme, .dark)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct EditIDPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        EditIDPhotoView(
            selectedProcess: .constant(.size),
            selectedBackgroundColor: .constant(
                Color.idPhotoBackgroundColors.blue
            ),
            selectedBackgroundColorLabel: .constant("青"),
            selectedIDPhotoSize: .constant(.original),
            originalSizePreviewUIImage: .constant(
                nil
            ),
            croppedPreviewUIImage: .constant(
                nil
            ),
            croppingCGRect: .constant(CGRect(origin: .zero, size: .zero)),
            shouldDisableDoneButton: .constant(true),
            availableBackgroundColors: [
                .idPhotoBackgroundColors.blue,
                .idPhotoBackgroundColors.gray
            ],
            availableSizeVariants: IDPhotoSizeVariant.allCases
        )
        .previewDisplayName("Edit ID Photo View")
    }
}
