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

struct NamedAnchor<T>: Identifiable {
    let id: UUID = .init()

    let name: String
    let anchor: Anchor<T>
}

extension NamedAnchor<CGRect>: Equatable { }

struct NamedBoundsPreferenceKey: PreferenceKey {
    static var defaultValue: [NamedAnchor<CGRect>] = [] // << use something persistent

    static func reduce(value: inout [NamedAnchor<CGRect>], nextValue: () -> [NamedAnchor<CGRect>]) {
        value = value + nextValue()
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

fileprivate let CROP_VIEW_IMAGE_HORIZONTAL_PADDING: CGFloat = 8

fileprivate let CROP_VIEW_ANIMATION_DURATION_SECONDS: Double = 0.5

struct CreateIDPhotoView: View {
    private let BACKGROUND_COLORS: [Color] = [
        .idPhotoBackgroundColors.blue,
        .idPhotoBackgroundColors.gray,
        .idPhotoBackgroundColors.white,
        .idPhotoBackgroundColors.brown,
    ]
    
    @Namespace private var previewImageNamespace
    
    @State private var previewImageActualSize: CGSize = .zero

    @Binding var selectedProcess: IDPhotoProcessSelection
    
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedBackgroundColorLabel: String
    
    @Binding var selectedIDPhotoSize: IDPhotoSizeVariant
    
    @Binding var originalSizePreviewUIImage: UIImage?
    @Binding var croppedPreviewUIImage: UIImage?
    
    @Binding var croppingCGRect: CGRect
    
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
        
        guard let originalSizePreviewUIImage = originalSizePreviewUIImage else { return 1 }
        
        return originalSizePreviewUIImage.size.width / previewCroppingCGRect.size.width
    }
    
    private var previewImageOffset: CGSize {
        if previewImageActualSize == .zero { return .zero }

        guard let originalSizePreviewUIImage = originalSizePreviewUIImage else { return .zero }

        let previewImageActualScaleX = previewImageActualSize.width / originalSizePreviewUIImage.size.width
        let previewImageActualScaleY = previewImageActualSize.height / originalSizePreviewUIImage.size.height

        // MARK: .scaleEffect モディファイアで Image を拡大しても、View の外周の大きさが変わるわけではないため、画面に表示されている画像の実際の縮小率分だけ移動量を縮小する必要がある
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
            }
            .frame(maxHeight: 28)
            .padding(.vertical)
            .padding(.horizontal, 4)
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(selectedProcess == .backgroundColor ? "背景色" : "サイズ")
                .fontWeight(.light)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .transaction { transaction in
                    transaction.animation = .none
                }

            Spacer()

            if previewCroppingCGRect != .zero {
                // MARK: 座標取得用
                //
                Color.clear
                    .aspectRatio(previewCroppingCGRect.size, contentMode: .fit)
                    .padding(.horizontal, CROP_VIEW_IMAGE_HORIZONTAL_PADDING)
                    .anchorPreference(
                        key: NamedBoundsPreferenceKey.self,
                        value: .bounds
                    ) {
                        [NamedAnchor(name: "croppingFrame", anchor: $0)]
                    }
            }

            Spacer()

            BottomControlButtons()
        }
        .backgroundPreferenceValue(NamedBoundsPreferenceKey.self) { namedAnchors in
            if let namedAnchor = namedAnchors.filter({ $0.name == "croppingFrame" }).last {
                GeometryReader { croppingFrameProxy in
                    ZStack {
                        if selectedProcess == .backgroundColor, let croppedPreviewUIImage {
                            Image(uiImage: croppedPreviewUIImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .position(
                                    x: croppingFrameProxy[namedAnchor.anchor].midX,
                                    y: croppingFrameProxy[namedAnchor.anchor].midY
                                )
                        }

                        if selectedProcess == .size, let originalSizePreviewUIImage {
                            Image(uiImage: originalSizePreviewUIImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .overlay {
                                    GeometryReader { imageGeometry in
                                        Color.clear
                                            .preference(key: SizePreferenceKey.self, value: imageGeometry.size)
                                            .onPreferenceChange(SizePreferenceKey.self) { imageSize in
                                                previewImageActualSize = imageSize
                                            }
                                    }
                                }
                                .padding(.horizontal, CROP_VIEW_IMAGE_HORIZONTAL_PADDING)
                                .offset(previewImageOffset)
                                .animation(
                                    .easeOutQuart(duration: CROP_VIEW_ANIMATION_DURATION_SECONDS),
                                    value: previewImageOffset
                                )
                                .scaleEffect(previewImageViewScalingAmount)
                                .position(
                                    x: croppingFrameProxy[namedAnchor.anchor].midX,
                                    y: croppingFrameProxy[namedAnchor.anchor].midY
                                )
                                .animation(
                                    .easeOutQuart(duration: CROP_VIEW_ANIMATION_DURATION_SECONDS),
                                    value: previewImageViewScalingAmount
                                )
                                .transition(.scale)
                        }
                    }
                    .transaction { transaction in
                        transaction.animation = .none
                    }
                }
                .overlay {
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(.regularMaterial)
                            .reverseMask {
                                if previewCroppingCGRect.size != .zero {
                                    Rectangle()
                                        .aspectRatio(previewCroppingCGRect.size, contentMode: .fit)
                                        .padding(.horizontal, CROP_VIEW_IMAGE_HORIZONTAL_PADDING)
                                        .position(
                                            x: proxy[namedAnchor.anchor].midX,
                                            y: proxy[namedAnchor.anchor].midY + proxy.safeAreaInsets.top
                                        )

                                }
                            }
                            .overlay {
                                if previewCroppingCGRect.size != .zero {
                                    Rectangle()
                                        .stroke(.white, lineWidth: 2)
                                        .aspectRatio(previewCroppingCGRect.size, contentMode: .fit)
                                        .padding(.horizontal, CROP_VIEW_IMAGE_HORIZONTAL_PADDING)
                                        .position(
                                            x: proxy[namedAnchor.anchor].midX,
                                            y: proxy[namedAnchor.anchor].midY + proxy.safeAreaInsets.top
                                        )

                                }
                            }
                            .opacity(selectedProcess == .size ? 1 : 0)
                            .ignoresSafeArea()
                            .animation(
                                .easeOutQuart(duration: CROP_VIEW_ANIMATION_DURATION_SECONDS),
                                value: previewImageViewScalingAmount
                            )
                            .transition(.scale)
                            .environment(\.colorScheme, .dark)
                    }
                }
            }
        }
        .background {
            Color
                .black
                .overlay(.bar, in: Rectangle())
                .environment(\.colorScheme, .dark)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct CreateIDPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        CreateIDPhotoView(
            selectedProcess: .constant(.backgroundColor),
            selectedBackgroundColor: .constant(
                Color.idPhotoBackgroundColors.blue
            ),
            selectedBackgroundColorLabel: .constant("青"),
            selectedIDPhotoSize: .constant(.original),
            originalSizePreviewUIImage: .constant(
                .init(named: "TimCook")
            ),
            croppedPreviewUIImage: .constant(
                .init(named: "TimCook")
            ),
            croppingCGRect: .constant(CGRect(origin: .zero, size: UIImage(named: "TimCook")!.size)),
            availableSizeVariants: IDPhotoSizeVariant.allCases
        )
    }
}
